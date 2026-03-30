/**
 * Verovio toolkit initialization and SVG post-processing for the Typst plugin.
 *
 * SMuFL glyph fix: Verovio renders metronome note glyphs (tempo markings like
 * "♩ = 120") as <tspan font-family="Leipzig">U+ECA5</tspan> — a Private Use
 * Area character that relies on an embedded woff2 @font-face. Typst's SVG
 * renderer (resvg) cannot load woff2 fonts, so these glyphs are invisible.
 *
 * The fix replaces SMuFL PUA characters with standard Unicode musical symbols
 * and switches from the SMuFL font to the document's text font, keeping glyphs
 * in the SVG text flow with correct baseline alignment.
 */

#include "toolkit.h"
#include "vrv.h"
#include "filereader.h"
#include "resources.h"
#include "pugi/pugixml.hpp"

#include <sstream>

extern "C" {
    extern unsigned char verovio_data_zip[];
    extern unsigned char verovio_data_zip_end[];
}

using namespace vrv;

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

// Map SMuFL metronome PUA codepoints to standard Unicode musical symbols.
// Returns 0 for unmapped codepoints.
static const char *smuflToUnicode(char32_t code)
{
    switch (code) {
        case 0xECA2: return "\xF0\x9D\x85\x9D"; // metNoteWhole → U+1D15D 𝅝
        case 0xECA3: return "\xF0\x9D\x85\x9E"; // metNoteHalfUp → U+1D15E 𝅗𝅥
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

        // Replace PUA char with Unicode equivalent and use the text font
        tspan.text().set(replacement);
        tspan.remove_attribute("font-family");

        // Scale down: SMuFL glyph font-size is inflated by the music-to-lyric ratio;
        // the Unicode symbol in a text font needs the same size as surrounding text.
        // Find sibling tspan with font-size to match.
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

extern "C" {

void *vrvToolkit_constructorFromEmbeddedZip()
{
    EnableLog(false);

    std::vector<unsigned char> bytes(verovio_data_zip, verovio_data_zip_end);
    ZipFileReader zip;
    if (!zip.LoadBytes(bytes)) return nullptr;

    Toolkit *tk = new Toolkit(false);
    Resources &res = tk->GetDoc().GetResourcesForModification();
    if (!res.InitFontsFromZip(zip)) {
        delete tk;
        return nullptr;
    }

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
