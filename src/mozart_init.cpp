/**
 * mozart_init.cpp — Initialize Verovio toolkit from embedded zip data.
 *
 * Since Typst's WASM runtime has no filesystem, we embed the Verovio resource
 * data as a zip archive compiled directly into the binary, and initialize
 * the toolkit by loading fonts from the zip via ZipFileReader::LoadBytes().
 */

#include "toolkit.h"
#include "vrv.h"
#include "toolkitdef.h"
#include "filereader.h"
#include "resources.h"

#include "verovio_data.h"

using namespace vrv;

extern "C" {

/**
 * Create a Verovio toolkit initialized from the embedded zip resource data.
 * This avoids any filesystem access.
 */
void *vrvToolkit_constructorFromEmbeddedZip()
{
    // Redirect all logging to buffer (avoid stderr/EM_ASM in WASM)
    EnableLogToBuffer(true);

    // Create toolkit without initializing fonts from filesystem
    Toolkit *tk = new Toolkit(false);

    // Load the embedded zip data
    std::vector<unsigned char> bytes(verovio_data_zip, verovio_data_zip + verovio_data_zip_len);
    ZipFileReader zipFile;
    if (!zipFile.LoadBytes(bytes)) {
        delete tk;
        return nullptr;
    }

    // Initialize all fonts from the zip archive
    Resources &resources = tk->GetDoc().GetResourcesForModification();
    if (!resources.InitFontsFromZip(zipFile)) {
        delete tk;
        return nullptr;
    }

    return tk;
}

/* No-op stubs for Emscripten runtime functions that would otherwise trap */
void emscripten_notify_memory_growth(int) {}
int emscripten_asm_const_int(int, ...) { return 0; }
long __syscall_getdents64(long, long, long) { return 0; }

} // extern "C"
