use wasmi::*;

struct HostState {
    args: Vec<u8>,
    result: Vec<u8>,
    memory: Option<Memory>,
}

fn setup(wasm_bytes: &[u8], fuel: bool) -> (Store<HostState>, Instance) {
    let mut config = Config::default();
    if fuel {
        config.consume_fuel(true);
    }
    let engine = Engine::new(&config);
    let module = Module::new(&engine, wasm_bytes).expect("failed to parse WASM module");

    let mut store = Store::new(
        &engine,
        HostState {
            args: Vec::new(),
            result: Vec::new(),
            memory: None,
        },
    );

    if fuel {
        store.set_fuel(u64::MAX).unwrap();
    }

    let mut linker = Linker::<HostState>::new(&engine);

    linker
        .func_wrap(
            "typst_env",
            "wasm_minimal_protocol_write_args_to_buffer",
            |mut caller: Caller<'_, HostState>, ptr: i32| {
                let mem = caller.data().memory.expect("memory not set");
                let data = caller.data().args.clone();
                mem.write(&mut caller, ptr as usize, &data)
                    .expect("failed to write args to guest memory");
            },
        )
        .unwrap();

    linker
        .func_wrap(
            "typst_env",
            "wasm_minimal_protocol_send_result_to_host",
            |mut caller: Caller<'_, HostState>, ptr: i32, len: i32| {
                let mem = caller.data().memory.expect("memory not set");
                let mut buf = vec![0u8; len as usize];
                mem.read(&caller, ptr as usize, &mut buf)
                    .expect("failed to read result from guest memory");
                caller.data_mut().result = buf;
            },
        )
        .unwrap();

    let instance = linker
        .instantiate_and_start(&mut store, &module)
        .expect("failed to instantiate");

    let memory = instance
        .get_memory(&store, "memory")
        .expect("missing 'memory' export");
    store.data_mut().memory = Some(memory);

    (store, instance)
}

fn call_render(
    store: &mut Store<HostState>,
    instance: &Instance,
    music_data: &[u8],
    options: &[u8],
) -> Result<Vec<u8>, String> {
    let render_func = instance
        .get_typed_func::<(i32, i32), i32>(&store, "render")
        .expect("missing 'render' export");

    {
        let state = store.data_mut();
        state.args.clear();
        state.args.extend_from_slice(music_data);
        state.args.extend_from_slice(options);
        state.result.clear();
    }

    match render_func.call(&mut *store, (music_data.len() as i32, options.len() as i32)) {
        Ok(code) => {
            let result = store.data().result.clone();
            if code == 0 {
                Ok(result)
            } else {
                Err(format!(
                    "render returned error code {}: {}",
                    code,
                    String::from_utf8_lossy(&result)
                ))
            }
        }
        Err(trap) => Err(format!("WASM trap: {trap}\nDebug: {trap:?}")),
    }
}

fn call_hello(store: &mut Store<HostState>, instance: &Instance) -> Result<Vec<u8>, String> {
    let hello_func = instance
        .get_typed_func::<(), i32>(&store, "hello")
        .expect("missing 'hello' export");

    {
        let state = store.data_mut();
        state.result.clear();
    }

    match hello_func.call(&mut *store, ()) {
        Ok(code) => {
            let result = store.data().result.clone();
            if code == 0 {
                Ok(result)
            } else {
                Err(format!(
                    "hello returned error code {}: {}",
                    code,
                    String::from_utf8_lossy(&result)
                ))
            }
        }
        Err(trap) => Err(format!("WASM trap: {trap}")),
    }
}

fn call_page_count(
    store: &mut Store<HostState>,
    instance: &Instance,
    music_data: &[u8],
    options: &[u8],
) -> Result<Vec<u8>, String> {
    let func = instance
        .get_typed_func::<(i32, i32), i32>(&store, "page_count")
        .expect("missing 'page_count' export");

    {
        let state = store.data_mut();
        state.args.clear();
        state.args.extend_from_slice(music_data);
        state.args.extend_from_slice(options);
        state.result.clear();
    }

    match func.call(&mut *store, (music_data.len() as i32, options.len() as i32)) {
        Ok(code) => {
            let result = store.data().result.clone();
            if code == 0 {
                Ok(result)
            } else {
                Err(format!(
                    "page_count returned error code {}: {}",
                    code,
                    String::from_utf8_lossy(&result)
                ))
            }
        }
        Err(trap) => Err(format!("WASM trap: {trap}")),
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    let mut use_fuel = false;
    let mut use_hello = false;
    let mut page_count_mode = false;
    let mut positional = Vec::new();

    for arg in args.iter().skip(1) {
        match arg.as_str() {
            "--fuel" => use_fuel = true,
            "--hello" => use_hello = true,
            "--page-count" => page_count_mode = true,
            _ => positional.push(arg.as_str()),
        }
    }

    if positional.is_empty() {
        eprintln!("Usage: harness <wasm_file> <music_file> [options_json] [--fuel] [--hello] [--page-count]");
        eprintln!();
        eprintln!("  <wasm_file>     Path to scoryst.wasm");
        eprintln!("  <music_file>    Path to music data (MusicXML, ABC, MEI, Humdrum, PAE)");
        eprintln!("  [options_json]  Optional Verovio options JSON string or @file");
        eprintln!();
        eprintln!("Flags:");
        eprintln!("  --fuel          Report WASM instruction count");
        eprintln!("  --hello         Just call hello() and exit");
        eprintln!("  --page-count    Call page_count() instead of render()");
        eprintln!();
        eprintln!("SVG output goes to stdout, diagnostics to stderr.");
        std::process::exit(1);
    }

    let wasm_bytes = std::fs::read(positional[0]).expect("failed to read WASM file");

    eprintln!("Loading WASM module ({} bytes)...", wasm_bytes.len());
    let (mut store, instance) = setup(&wasm_bytes, use_fuel);
    let memory = instance.get_memory(&store, "memory").unwrap();
    eprintln!(
        "WASM module loaded. Memory: {} pages ({} MB)",
        memory.size(&store),
        memory.size(&store) as u64 * 64 / 1024
    );

    if use_hello {
        let fuel_before = if use_fuel { store.get_fuel().unwrap() } else { 0 };
        let start = std::time::Instant::now();
        match call_hello(&mut store, &instance) {
            Ok(result) => {
                let elapsed = start.elapsed();
                let fuel_used = if use_fuel {
                    fuel_before - store.get_fuel().unwrap()
                } else {
                    0
                };
                println!("{}", String::from_utf8_lossy(&result));
                if use_fuel {
                    eprintln!(
                        "OK ({:.3}ms, {} instructions)",
                        elapsed.as_secs_f64() * 1000.0,
                        fuel_used
                    );
                } else {
                    eprintln!("OK ({:.3}ms)", elapsed.as_secs_f64() * 1000.0);
                }
            }
            Err(err) => {
                eprintln!("ERROR: {err}");
                std::process::exit(1);
            }
        }
        return;
    }

    if positional.len() < 2 {
        eprintln!("ERROR: music file argument required");
        std::process::exit(1);
    }

    let music_data = std::fs::read(positional[1]).expect("failed to read music file");
    eprintln!("Music data: {} bytes from {}", music_data.len(), positional[1]);

    let options = if let Some(opts) = positional.get(2) {
        if opts.starts_with('@') {
            std::fs::read(&opts[1..]).expect("failed to read options file")
        } else {
            opts.as_bytes().to_vec()
        }
    } else {
        Vec::new()
    };

    if !options.is_empty() {
        eprintln!("Options: {}", String::from_utf8_lossy(&options));
    }

    let fuel_before = if use_fuel { store.get_fuel().unwrap() } else { 0 };
    let start = std::time::Instant::now();

    let result = if page_count_mode {
        call_page_count(&mut store, &instance, &music_data, &options)
    } else {
        call_render(&mut store, &instance, &music_data, &options)
    };

    let elapsed = start.elapsed();
    let fuel_used = if use_fuel {
        fuel_before - store.get_fuel().unwrap()
    } else {
        0
    };

    let mem_after = memory.size(&store);
    eprintln!(
        "Memory after call: {} pages ({} MB)",
        mem_after,
        mem_after as u64 * 64 / 1024
    );

    match result {
        Ok(result) => {
            let out = String::from_utf8_lossy(&result);
            println!("{out}");
            eprintln!("Result size: {} bytes", result.len());
            if use_fuel {
                eprintln!(
                    "OK ({:.3}ms, {} instructions)",
                    elapsed.as_secs_f64() * 1000.0,
                    fuel_used
                );
            } else {
                eprintln!("OK ({:.3}ms)", elapsed.as_secs_f64() * 1000.0);
            }
        }
        Err(err) => {
            if use_fuel {
                eprintln!(
                    "FAILED after {:.3}ms ({} instructions)",
                    elapsed.as_secs_f64() * 1000.0,
                    fuel_used
                );
            } else {
                eprintln!("FAILED after {:.3}ms", elapsed.as_secs_f64() * 1000.0);
            }
            eprintln!("ERROR: {err}");
            std::process::exit(1);
        }
    }
}
