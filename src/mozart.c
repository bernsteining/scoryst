/**
 * mozart — Typst plugin for music notation rendering via Verovio.
 *
 * Takes MusicXML (or other formats Verovio supports) as input,
 * returns SVG as output using the Typst wasm-minimal-protocol.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <emscripten.h>

/* Verovio C API (from verovio/tools/c_wrapper.h) */
extern void *vrvToolkit_constructorFromEmbeddedZip(void);
extern void vrvToolkit_destructor(void *toolkit);
extern bool vrvToolkit_loadData(void *toolkit, const char *data);
extern const char *vrvToolkit_renderToSVG(void *toolkit, int page_no, bool xmlDeclaration);
extern bool vrvToolkit_setOptions(void *toolkit, const char *options);
extern int vrvToolkit_getPageCount(void *toolkit);

/* Typst wasm-minimal-protocol imports */
__attribute__((import_module("typst_env")))
__attribute__((import_name("wasm_minimal_protocol_send_result_to_host")))
extern void wasm_minimal_protocol_send_result_to_host(const char *ptr, int len);

__attribute__((import_module("typst_env")))
__attribute__((import_name("wasm_minimal_protocol_write_args_to_buffer")))
extern void wasm_minimal_protocol_write_args_to_buffer(char *ptr);

/* Global toolkit instance (lazy-initialized) */
static void *g_toolkit = NULL;

static void *get_toolkit(void) {
    if (!g_toolkit) {
        g_toolkit = vrvToolkit_constructorFromEmbeddedZip();
    }
    return g_toolkit;
}

/**
 * hello() -> i32
 * Simple test function that returns a static SVG.
 */
EMSCRIPTEN_KEEPALIVE
int hello(void) {
    const char *svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"50\"><text x=\"10\" y=\"30\">Mozart works!</text></svg>";
    wasm_minimal_protocol_send_result_to_host(svg, strlen(svg));
    return 0;
}

/**
 * render(music_data_len: i32, options_len: i32) -> i32
 *
 * Takes music data (MusicXML, MEI, ABC, etc.) and a JSON options string.
 * Returns SVG of the first page (0 = success, 1 = error).
 */
EMSCRIPTEN_KEEPALIVE
int render(int music_len, int options_len) {
    int total = music_len + options_len;
    char *buf = (char *)malloc(total + 2); /* +2 for null terminators */
    if (!buf) {
        const char *err = "allocation failed";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
        return 1;
    }

    wasm_minimal_protocol_write_args_to_buffer(buf);

    /* Null-terminate both strings */
    char *music_data = buf;
    memmove(buf + music_len + 1, buf + music_len, options_len);
    buf[music_len] = '\0';

    char *options = buf + music_len + 1;
    options[options_len] = '\0';

    void *tk = get_toolkit();
    if (!tk) {
        const char *err = "failed to initialize verovio toolkit";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
        free(buf);
        return 1;
    }

    /* Apply options if provided */
    if (options_len > 0) {
        vrvToolkit_setOptions(tk, options);
    }

    /* Load and render */
    if (!vrvToolkit_loadData(tk, music_data)) {
        const char *err = "verovio failed to load music data";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
        free(buf);
        return 1;
    }

    const char *svg = vrvToolkit_renderToSVG(tk, 1, false);
    if (!svg) {
        const char *err = "verovio failed to render SVG";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
        free(buf);
        return 1;
    }

    wasm_minimal_protocol_send_result_to_host(svg, strlen(svg));
    free(buf);
    return 0;
}

/**
 * render_page(music_data_len: i32, options_len: i32, page_str_len: i32) -> i32
 *
 * Same as render but takes a page number (as string) as third argument.
 */
EMSCRIPTEN_KEEPALIVE
int render_page(int music_len, int options_len, int page_str_len) {
    int total = music_len + options_len + page_str_len;
    char *buf = (char *)malloc(total + 3);
    if (!buf) {
        const char *err = "allocation failed";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
        return 1;
    }

    wasm_minimal_protocol_write_args_to_buffer(buf);

    /* Extract and null-terminate all three strings */
    /* We need to work backwards to avoid overwriting */
    char page_buf[16] = {0};
    if (page_str_len > 0 && page_str_len < 15) {
        memcpy(page_buf, buf + music_len + options_len, page_str_len);
    }
    page_buf[page_str_len < 15 ? page_str_len : 0] = '\0';
    int page = atoi(page_buf);
    if (page < 1) page = 1;

    /* Null-terminate music and options in-place */
    char saved = buf[music_len];
    buf[music_len] = '\0';
    char *music_data = buf;

    char *options = buf + music_len + 1;
    memmove(options, buf + music_len, options_len);
    /* restore first byte */
    options[0] = saved;
    options[options_len] = '\0';

    void *tk = get_toolkit();
    if (!tk) {
        const char *err = "failed to initialize verovio toolkit";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
        free(buf);
        return 1;
    }

    if (options_len > 0) {
        vrvToolkit_setOptions(tk, options);
    }

    if (!vrvToolkit_loadData(tk, music_data)) {
        const char *err = "verovio failed to load music data";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
        free(buf);
        return 1;
    }

    const char *svg = vrvToolkit_renderToSVG(tk, page, false);
    if (!svg) {
        const char *err = "verovio failed to render SVG";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
        free(buf);
        return 1;
    }

    wasm_minimal_protocol_send_result_to_host(svg, strlen(svg));
    free(buf);
    return 0;
}

/**
 * page_count(music_data_len: i32, options_len: i32) -> i32
 *
 * Returns the number of pages as a string.
 */
EMSCRIPTEN_KEEPALIVE
int page_count(int music_len, int options_len) {
    int total = music_len + options_len;
    char *buf = (char *)malloc(total + 2);
    if (!buf) {
        const char *err = "allocation failed";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
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
        const char *err = "failed to initialize verovio toolkit";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
        free(buf);
        return 1;
    }

    if (options_len > 0) {
        vrvToolkit_setOptions(tk, options);
    }

    if (!vrvToolkit_loadData(tk, music_data)) {
        const char *err = "verovio failed to load music data";
        wasm_minimal_protocol_send_result_to_host(err, strlen(err));
        free(buf);
        return 1;
    }

    int count = vrvToolkit_getPageCount(tk);
    char result[16];
    int len = snprintf(result, sizeof(result), "%d", count);

    wasm_minimal_protocol_send_result_to_host(result, len);
    free(buf);
    return 0;
}
