/**
 * Verovio toolkit initialization and SVG post-processing for the Typst plugin.
 *
 * Font loading: Fonts are pre-converted from verovio's XML format to a compact
 * binary format (by scripts/fonts_to_binary.py) and embedded in the WASM binary.
 * This avoids XML parsing at init time, making font loading instant.
 *
 * SMuFL glyph fix: Verovio renders metronome note glyphs (tempo markings like
 * "♩ = 120") as <tspan font-family="Leipzig">U+ECA5</tspan> — a Private Use
 * Area character that relies on an embedded woff2 @font-face. Typst's SVG
 * renderer (resvg) cannot load woff2 fonts, so these glyphs are invisible.
 * The fix replaces PUA characters with standard Unicode musical symbols.
 */

#include "toolkit.h"
#include "vrv.h"
#include "resources.h"
#include "glyph.h"
#include "pugi/pugixml.hpp"

#include <cstring>
#include <sstream>

/* Embedded binary font data (from src/font_data.S) */
extern "C" {
    extern unsigned char font_bravura[], font_bravura_end[];
    extern unsigned char font_gootville[], font_gootville_end[];
    extern unsigned char font_leipzig[], font_leipzig_end[];
    extern unsigned char font_leland[], font_leland_end[];
    extern unsigned char font_petaluma[], font_petaluma_end[];
    extern unsigned char font_text_times[], font_text_times_end[];
    extern unsigned char font_text_times_bold[], font_text_times_bold_end[];
    extern unsigned char font_text_times_bold_italic[], font_text_times_bold_italic_end[];
    extern unsigned char font_text_times_italic[], font_text_times_italic_end[];
}

using namespace vrv;

/* ── Binary font format ──────────────────────────────────────────────
 * Header (16 bytes):
 *   uint32 magic (0x56524630 = "VRF0")
 *   uint32 units_per_em
 *   uint32 glyph_count
 *   uint32 string_pool_offset
 * Per glyph (80 bytes):
 *   uint32 codepoint
 *   int32  x, y, w, h, horiz_adv_x   (bbox, 10x scaled)
 *   int32  anchor_x[6], anchor_y[6]   (0 if absent)
 *   uint32 path_offset, path_length   (into string pool)
 * String pool: concatenated SVG path XML strings
 * ──────────────────────────────────────────────────────────────────── */

struct BinHeader {
    uint32_t magic;
    uint32_t units_per_em;
    uint32_t glyph_count;
    uint32_t string_pool_offset;
};

struct BinGlyph {
    uint32_t codepoint;
    int32_t x, y, w, h, horiz_adv_x;
    int32_t anchor_x[6], anchor_y[6];
    uint32_t path_offset, path_length;
};

static const SMuFLGlyphAnchor ANCHOR_IDS[6] = {
    SMUFL_stemDownNW, SMUFL_stemUpSE,
    SMUFL_cutOutNE, SMUFL_cutOutNW, SMUFL_cutOutSE, SMUFL_cutOutSW
};

static bool loadMusicFont(Resources &res, const char *fontName,
                          const unsigned char *data, size_t size, bool isFallback)
{
    if (size < sizeof(BinHeader)) return false;
    const BinHeader *hdr = reinterpret_cast<const BinHeader *>(data);
    if (hdr->magic != 0x56524630) return false;

    int upm = hdr->units_per_em;
    const BinGlyph *glyphs = reinterpret_cast<const BinGlyph *>(data + sizeof(BinHeader));
    const char *pool = reinterpret_cast<const char *>(data + hdr->string_pool_offset);

    // Create the loaded font entry via the public API
    // We need to insert into the font table directly
    Resources::GlyphTable glyphTable;
    for (uint32_t i = 0; i < hdr->glyph_count; i++) {
        const BinGlyph &bg = glyphs[i];
        Glyph glyph(upm);

        // Binary stores 10x-scaled ints; SetBoundingBox/SetHorizAdvX expect raw doubles
        glyph.SetBoundingBox(bg.x / 10.0, bg.y / 10.0, bg.w / 10.0, bg.h / 10.0);
        glyph.SetHorizAdvX(bg.horiz_adv_x / 10.0);

        // Code string (hex)
        char codeStr[16];
        snprintf(codeStr, sizeof(codeStr), "%04X", bg.codepoint);
        glyph.SetCodeStr(codeStr);

        // Anchors
        for (int a = 0; a < 6; a++) {
            if (bg.anchor_x[a] != 0 || bg.anchor_y[a] != 0) {
                glyph.SetAnchor(ANCHOR_IDS[a], bg.anchor_x[a], bg.anchor_y[a]);
            }
        }

        // SVG path XML
        if (bg.path_length > 0) {
            glyph.SetXML(std::string(pool + bg.path_offset, bg.path_length));
        }

        glyph.SetFallback(isFallback);
        glyphTable[(char32_t)bg.codepoint] = std::move(glyph);
    }

    res.AddLoadedFont(fontName, std::move(glyphTable), isFallback);
    return true;
}

static bool loadTextFont(Resources &res, const Resources::StyleAttributes &style,
                         const unsigned char *data, size_t size)
{
    if (size < sizeof(BinHeader)) return false;
    const BinHeader *hdr = reinterpret_cast<const BinHeader *>(data);
    if (hdr->magic != 0x56524630) return false;

    int upm = hdr->units_per_em;
    const BinGlyph *glyphs = reinterpret_cast<const BinGlyph *>(data + sizeof(BinHeader));

    Resources::GlyphTable table;
    for (uint32_t i = 0; i < hdr->glyph_count; i++) {
        const BinGlyph &bg = glyphs[i];
        Glyph glyph(upm);
        glyph.SetBoundingBox(bg.x / 10.0, bg.y / 10.0, bg.w / 10.0, bg.h / 10.0);
        glyph.SetHorizAdvX(bg.horiz_adv_x / 10.0);
        table[(char32_t)bg.codepoint] = std::move(glyph);
    }

    res.AddTextFont(style, std::move(table));
    return true;
}

/* ── SMuFL glyph fix ─────────────────────────────────────────────── */

static char32_t decodeFirstUTF8(const char *s)
{
    if (!s || !*s) return 0;
    unsigned char c0 = s[0];
    if (c0 < 0x80) return c0;
    if ((c0 & 0xE0) == 0xC0) return ((c0 & 0x1F) << 6) | (s[1] & 0x3F);
    if ((c0 & 0xF0) == 0xE0) return ((c0 & 0x0F) << 12) | ((s[1] & 0x3F) << 6) | (s[2] & 0x3F);
    if ((c0 & 0xF8) == 0xF0)
        return ((c0 & 0x07) << 18) | ((s[1] & 0x3F) << 12) | ((s[2] & 0x3F) << 6) | (s[3] & 0x3F);
    return 0;
}

static const char *smuflToUnicode(char32_t code)
{
    switch (code) {
        case 0xECA2: return "\xF0\x9D\x85\x9D"; // metNoteWhole → U+1D15D
        case 0xECA3: return "\xF0\x9D\x85\x9E"; // metNoteHalfUp → U+1D15E
        case 0xECA5: return "\xE2\x99\xA9";      // metNoteQuarterUp → U+2669 ♩
        case 0xECA7: return "\xE2\x99\xAA";      // metNote8thUp → U+266A ♪
        case 0xECB7: return "\xC2\xB7";           // metAugmentationDot → U+00B7 ·
        default:     return nullptr;
    }
}

static std::string fixSmuflTextGlyphs(const char *svg, void *toolkit)
{
    Toolkit *tk = static_cast<Toolkit *>(toolkit);
    const Resources &res = tk->GetDoc().GetResources();
    std::string fontName = res.GetCurrentFont();

    pugi::xml_document doc;
    if (!doc.load_string(svg, pugi::parse_default | pugi::parse_ws_pcdata)) return svg;

    bool modified = false;
    std::string xpath = "//tspan[@font-family='" + fontName + "']";
    for (const auto &match : doc.select_nodes(xpath.c_str())) {
        pugi::xml_node tspan = match.node();
        std::string text = tspan.text().get();
        if (text.empty()) continue;

        char32_t code = decodeFirstUTF8(text.c_str());
        if (code < 0xE000 || code > 0xF8FF) continue;

        const char *replacement = smuflToUnicode(code);
        if (!replacement) continue;

        tspan.text().set(replacement);
        tspan.remove_attribute("font-family");

        pugi::xml_node textNode = tspan.parent();
        while (textNode && std::string(textNode.name()) != "text")
            textNode = textNode.parent();
        if (textNode) {
            for (auto sibling : textNode.select_nodes(".//tspan[@font-size]")) {
                std::string sibSize = sibling.node().attribute("font-size").value();
                if (sibling.node() != tspan && !sibSize.empty()) {
                    tspan.attribute("font-size").set_value(sibSize.c_str());
                    break;
                }
            }
        }
        modified = true;
    }

    if (!modified) return svg;

    std::ostringstream ss;
    doc.save(ss, "   ", pugi::format_default | pugi::format_no_declaration);
    return ss.str();
}

static std::string g_fixedSvg;

/* ── Exported C API ──────────────────────────────────────────────── */

extern "C" {

void *vrvToolkit_constructorFromBinaryFonts()
{
    EnableLog(false);

    Toolkit *tk = new Toolkit(false);
    Resources &res = tk->GetDoc().GetResourcesForModification();

    // Load music fonts from embedded binary data
    #define LOAD_MUSIC(sym, name, fallback) \
        loadMusicFont(res, name, sym, sym##_end - sym, fallback)

    LOAD_MUSIC(font_bravura,   "Bravura",   true);
    LOAD_MUSIC(font_gootville, "Gootville", false);
    LOAD_MUSIC(font_leipzig,   "Leipzig",   true);
    LOAD_MUSIC(font_leland,    "Leland",    false);
    LOAD_MUSIC(font_petaluma,  "Petaluma",  false);

    #undef LOAD_MUSIC

    res.SetDefaultFont("Leipzig");

    // Load text fonts
    using SA = Resources::StyleAttributes;
    loadTextFont(res, SA(FONTWEIGHT_normal, FONTSTYLE_normal), font_text_times, font_text_times_end - font_text_times);
    loadTextFont(res, SA(FONTWEIGHT_bold, FONTSTYLE_normal), font_text_times_bold, font_text_times_bold_end - font_text_times_bold);
    loadTextFont(res, SA(FONTWEIGHT_bold, FONTSTYLE_italic), font_text_times_bold_italic, font_text_times_bold_italic_end - font_text_times_bold_italic);
    loadTextFont(res, SA(FONTWEIGHT_normal, FONTSTYLE_italic), font_text_times_italic, font_text_times_italic_end - font_text_times_italic);

    return tk;
}

const char *vrvToolkit_fixSmuflText(void *toolkit, const char *svg)
{
    g_fixedSvg = fixSmuflTextGlyphs(svg, toolkit);
    return g_fixedSvg.c_str();
}

void emscripten_notify_memory_growth(int) {}
long __syscall_getdents64(long, long, long) { return 0; }

} // extern "C"
