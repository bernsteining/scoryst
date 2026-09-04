# Pin emsdk for reproducible builds; its bundled binaryen (wasm-opt) is used for
# both emcc's internal optimization and the Makefile's explicit wasm-opt pass, so
# the whole toolchain is one pinned version. Bump deliberately; verify the wasm
# still links (the Makefile uses em++ because recent emsdk links object-only
# inputs as C) and that every notation format still renders.
FROM docker.io/emscripten/emsdk:6.0.9

# The emsdk image doesn't put upstream/bin on PATH; add it so `make` picks up the
# bundled wasm-opt instead of needing a separately pinned binaryen.
ENV PATH="/emsdk/upstream/bin:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install wasi-stub

WORKDIR /src
