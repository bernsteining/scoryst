/**
 * verovio_plugin — Typst plugin for music notation rendering via Verovio.
 *
 * Takes MusicXML (or other formats Verovio supports) as input,
 * returns SVG as output using the Typst wasm-minimal-protocol.
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <emscripten.h>

/* Verovio C API (from verovio/tools/c_wrapper.h) */
extern "C" {
    void *vrvToolkit_constructorFromBinaryFonts(void);
    void vrvToolkit_destructor(void *toolkit);
    bool vrvToolkit_loadData(void *toolkit, const char *data);
    const char *vrvToolkit_renderToSVG(void *toolkit, int page_no, bool xmlDeclaration);
    bool vrvToolkit_setOptions(void *toolkit, const char *options);
    void vrvToolkit_resetOptions(void *toolkit);
    int vrvToolkit_getPageCount(void *toolkit);
    const char *vrvToolkit_fixSmuflText(void *toolkit, const char *svg);
}

/* Typst wasm-minimal-protocol imports */
extern "C" {
    __attribute__((import_module("typst_env")))
    __attribute__((import_name("wasm_minimal_protocol_send_result_to_host")))
    void wasm_minimal_protocol_send_result_to_host(const char *ptr, int len);

    __attribute__((import_module("typst_env")))
    __attribute__((import_name("wasm_minimal_protocol_write_args_to_buffer")))
    void wasm_minimal_protocol_write_args_to_buffer(char *ptr);
}

static void send_result(const char *s) {
    wasm_minimal_protocol_send_result_to_host(s, strlen(s));
}

/* Fresh toolkit per render — eliminates state leaking between renders.
 * Binary font loading makes construction instant (no XML parsing). */
static void *g_toolkit = nullptr;

static void *get_toolkit() {
    if (g_toolkit) {
        vrvToolkit_destructor(g_toolkit);
    }
    g_toolkit = vrvToolkit_constructorFromBinaryFonts();
    return g_toolkit;
}

/**
 * Split a contiguous argument buffer into NUL-terminated music and options strings.
 * The buffer is modified in-place. Returns pointers into buf.
 */
static void split_args(char *buf, int music_len, int options_len,
                       char **out_music, char **out_options) {
    memmove(buf + music_len + 1, buf + music_len, options_len);
    buf[music_len] = '\0';
    buf[music_len + 1 + options_len] = '\0';

    *out_music = buf;
    *out_options = buf + music_len + 1;
}

static bool load_music(void *tk, const char *music_data, const char *options,
                       int options_len) {
    if (options_len > 0) {
        vrvToolkit_setOptions(tk, options);
    }

    if (!vrvToolkit_loadData(tk, music_data)) {
        send_result("verovio failed to load music data");
        return false;
    }

    return true;
}

/**
 * render(music_data_len: i32, options_len: i32) -> i32
 */
extern "C" EMSCRIPTEN_KEEPALIVE
int render(int music_len, int options_len) {
    char *buf = (char *)malloc(music_len + options_len + 2);
    if (!buf) { send_result("allocation failed"); return 1; }

    wasm_minimal_protocol_write_args_to_buffer(buf);

    char *music_data, *options;
    split_args(buf, music_len, options_len, &music_data, &options);

    void *tk = get_toolkit();
    if (!tk) { send_result("failed to initialize verovio toolkit"); free(buf); return 1; }

    if (!load_music(tk, music_data, options, options_len)) { free(buf); return 1; }

    const char *svg = vrvToolkit_renderToSVG(tk, 1, false);
    if (!svg) { send_result("verovio failed to render SVG"); free(buf); return 1; }

    send_result(vrvToolkit_fixSmuflText(tk, svg));
    free(buf);
    return 0;
}

/**
 * render_page(music_data_len: i32, options_len: i32, page_str_len: i32) -> i32
 */
extern "C" EMSCRIPTEN_KEEPALIVE
int render_page(int music_len, int options_len, int page_str_len) {
    int total = music_len + options_len + page_str_len;
    char *buf = (char *)malloc(total + 3);
    if (!buf) { send_result("allocation failed"); return 1; }

    wasm_minimal_protocol_write_args_to_buffer(buf);

    char page_buf[16] = {0};
    if (page_str_len > 0 && page_str_len < 15) {
        memcpy(page_buf, buf + music_len + options_len, page_str_len);
    }
    int page = atoi(page_buf);
    if (page < 1) page = 1;

    char *music_data, *options;
    split_args(buf, music_len, options_len, &music_data, &options);

    void *tk = get_toolkit();
    if (!tk) { send_result("failed to initialize verovio toolkit"); free(buf); return 1; }

    if (!load_music(tk, music_data, options, options_len)) { free(buf); return 1; }

    const char *svg = vrvToolkit_renderToSVG(tk, page, false);
    if (!svg) { send_result("verovio failed to render SVG"); free(buf); return 1; }

    send_result(vrvToolkit_fixSmuflText(tk, svg));
    free(buf);
    return 0;
}

/**
 * page_count(music_data_len: i32, options_len: i32) -> i32
 */
extern "C" EMSCRIPTEN_KEEPALIVE
int page_count(int music_len, int options_len) {
    char *buf = (char *)malloc(music_len + options_len + 2);
    if (!buf) { send_result("allocation failed"); return 1; }

    wasm_minimal_protocol_write_args_to_buffer(buf);

    char *music_data, *options;
    split_args(buf, music_len, options_len, &music_data, &options);

    void *tk = get_toolkit();
    if (!tk) { send_result("failed to initialize verovio toolkit"); free(buf); return 1; }

    if (!load_music(tk, music_data, options, options_len)) { free(buf); return 1; }

    int count = vrvToolkit_getPageCount(tk);
    char result[16];
    int len = snprintf(result, sizeof(result), "%d", count);

    wasm_minimal_protocol_send_result_to_host(result, len);
    free(buf);
    return 0;
}
