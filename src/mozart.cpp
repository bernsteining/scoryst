/**
 * mozart — Typst plugin for music notation rendering via Verovio.
 *
 * Takes MusicXML (or other formats Verovio supports) as input,
 * returns SVG as output using the Typst wasm-minimal-protocol.
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <emscripten.h>

/*
 * Override abort to immediately trap.
 * Without this, emscripten's abort() calls proc_exit() which is
 * stubbed to a no-op by wasi-stub, causing execution to continue
 * in a corrupt state.
 */
extern "C" void abort() {
    __builtin_trap();
}

/* Verovio C API (from verovio/tools/c_wrapper.h) */
extern "C" {
    void *vrvToolkit_constructorFromEmbeddedZip(void);
    void vrvToolkit_destructor(void *toolkit);
    bool vrvToolkit_loadData(void *toolkit, const char *data);
    const char *vrvToolkit_renderToSVG(void *toolkit, int page_no, bool xmlDeclaration);
    bool vrvToolkit_setOptions(void *toolkit, const char *options);
    int vrvToolkit_getPageCount(void *toolkit);
    const char *vrvToolkit_getMEI(void *toolkit, const char *options);
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

static void send_result(const std::string &s) {
    wasm_minimal_protocol_send_result_to_host(s.data(), s.size());
}

/* Global toolkit instance (lazy-initialized) */
static void *g_toolkit = nullptr;

static void *get_toolkit() {
    if (!g_toolkit) {
        g_toolkit = vrvToolkit_constructorFromEmbeddedZip();
    }
    return g_toolkit;
}

/**
 * Detect ABC notation by checking for "X:" header at the start.
 */
static bool is_abc(const char *data) {
    const char *p = data;
    /* skip leading whitespace */
    while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') p++;
    return (p[0] == 'X' && p[1] == ':');
}

/**
 * For ABC input, pre-convert to MEI to work around WASM rendering issues
 * with certain ABC features (ties, etc.). Returns a malloc'd MEI string
 * that the caller must free, or nullptr if not ABC / conversion fails.
 */
static char *abc_to_mei(void *tk, const char *abc_data) {
    if (!is_abc(abc_data)) return nullptr;

    /* Load the ABC data */
    if (!vrvToolkit_loadData(tk, abc_data)) return nullptr;

    /* Export as MEI */
    const char *mei = vrvToolkit_getMEI(tk, "{}");
    if (!mei || !*mei) return nullptr;

    /* Copy the MEI string (the toolkit owns the original) */
    size_t len = strlen(mei);
    char *copy = (char *)malloc(len + 1);
    if (!copy) return nullptr;
    memcpy(copy, mei, len + 1);

    return copy;
}

/**
 * hello() -> i32
 * Simple test function that returns a static SVG.
 */
extern "C" EMSCRIPTEN_KEEPALIVE
int hello() {
    send_result("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"50\"><text x=\"10\" y=\"30\">Mozart works!</text></svg>");
    return 0;
}

/**
 * render(music_data_len: i32, options_len: i32) -> i32
 *
 * Takes music data (MusicXML, MEI, ABC, etc.) and a JSON options string.
 * Returns SVG of the first page (0 = success, 1 = error).
 */
extern "C" EMSCRIPTEN_KEEPALIVE
int render(int music_len, int options_len) {
    int total = music_len + options_len;
    char *buf = (char *)malloc(total + 2);
    if (!buf) {
        send_result("allocation failed");
        return 1;
    }

    wasm_minimal_protocol_write_args_to_buffer(buf);

    char *music_data = buf;
    memmove(buf + music_len + 1, buf + music_len, options_len);
    buf[music_len] = '\0';

    char *options = buf + music_len + 1;
    options[options_len] = '\0';

    void *tk = get_toolkit();
    if (!tk) {
        send_result("failed to initialize verovio toolkit");
        free(buf);
        return 1;
    }

    if (options_len > 0) {
        vrvToolkit_setOptions(tk, options);
    }

    /* For ABC input, pre-convert to MEI to avoid WASM rendering issues */
    char *mei = abc_to_mei(tk, music_data);
    const char *render_data = mei ? mei : music_data;

    if (!vrvToolkit_loadData(tk, render_data)) {
        send_result("verovio failed to load music data");
        free(mei);
        free(buf);
        return 1;
    }

    const char *svg = vrvToolkit_renderToSVG(tk, 1, false);
    if (!svg) {
        send_result("verovio failed to render SVG");
        free(mei);
        free(buf);
        return 1;
    }

    send_result(svg);
    free(mei);
    free(buf);
    return 0;
}

/**
 * render_page(music_data_len: i32, options_len: i32, page_str_len: i32) -> i32
 *
 * Same as render but takes a page number (as string) as third argument.
 */
extern "C" EMSCRIPTEN_KEEPALIVE
int render_page(int music_len, int options_len, int page_str_len) {
    int total = music_len + options_len + page_str_len;
    char *buf = (char *)malloc(total + 3);
    if (!buf) {
        send_result("allocation failed");
        return 1;
    }

    wasm_minimal_protocol_write_args_to_buffer(buf);

    char page_buf[16] = {0};
    if (page_str_len > 0 && page_str_len < 15) {
        memcpy(page_buf, buf + music_len + options_len, page_str_len);
    }
    page_buf[page_str_len < 15 ? page_str_len : 0] = '\0';
    int page = atoi(page_buf);
    if (page < 1) page = 1;

    char saved = buf[music_len];
    buf[music_len] = '\0';
    char *music_data = buf;

    char *options = buf + music_len + 1;
    memmove(options, buf + music_len, options_len);
    options[0] = saved;
    options[options_len] = '\0';

    void *tk = get_toolkit();
    if (!tk) {
        send_result("failed to initialize verovio toolkit");
        free(buf);
        return 1;
    }

    if (options_len > 0) {
        vrvToolkit_setOptions(tk, options);
    }

    /* For ABC input, pre-convert to MEI */
    char *mei = abc_to_mei(tk, music_data);
    const char *render_data = mei ? mei : music_data;

    if (!vrvToolkit_loadData(tk, render_data)) {
        send_result("verovio failed to load music data");
        free(mei);
        free(buf);
        return 1;
    }

    const char *svg = vrvToolkit_renderToSVG(tk, page, false);
    if (!svg) {
        send_result("verovio failed to render SVG");
        free(mei);
        free(buf);
        return 1;
    }

    send_result(svg);
    free(mei);
    free(buf);
    return 0;
}

/**
 * page_count(music_data_len: i32, options_len: i32) -> i32
 *
 * Returns the number of pages as a string.
 */
extern "C" EMSCRIPTEN_KEEPALIVE
int page_count(int music_len, int options_len) {
    int total = music_len + options_len;
    char *buf = (char *)malloc(total + 2);
    if (!buf) {
        send_result("allocation failed");
        return 1;
    }

    wasm_minimal_protocol_write_args_to_buffer(buf);

    char saved = buf[music_len];
    buf[music_len] = '\0';
    char *music_data = buf;

    char *options = buf + music_len + 1;
    memmove(options, buf + music_len, options_len);
    options[0] = saved;
    options[options_len] = '\0';

    void *tk = get_toolkit();
    if (!tk) {
        send_result("failed to initialize verovio toolkit");
        free(buf);
        return 1;
    }

    if (options_len > 0) {
        vrvToolkit_setOptions(tk, options);
    }

    /* For ABC input, pre-convert to MEI */
    char *mei = abc_to_mei(tk, music_data);
    const char *render_data = mei ? mei : music_data;

    if (!vrvToolkit_loadData(tk, render_data)) {
        send_result("verovio failed to load music data");
        free(mei);
        free(buf);
        return 1;
    }

    int count = vrvToolkit_getPageCount(tk);
    char result[16];
    int len = snprintf(result, sizeof(result), "%d", count);

    wasm_minimal_protocol_send_result_to_host(result, len);
    free(mei);
    free(buf);
    return 0;
}
