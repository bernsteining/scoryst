![logo](test/logo.svg)

# Scoryst - Music Engraving Plugin for Typst

A Typst plugin that renders music notation from multiple formats using
[Verovio](https://www.verovio.org/), compiled to WebAssembly.

## Features

- **8 input formats**: ABC, MusicXML, MEI, Humdrum, EsAC, PAE, Volpiano, CMME
- **5 music fonts**: Leipzig (default), Bravura, Gootville, Leland, Petaluma
- **Full Verovio options**: scale, font, page layout, and all
  [toolkit options](https://book.verovio.org/toolkit-reference/toolkit-options.html)
- **Multi-page support**: render individual pages of long scores
- **Binary font loading**: fonts pre-compiled to binary for instant init

Check the [documentation](https://github.com/bernsteining/scoryst/blob/master/test/documentation.pdf?raw=1) for a full demonstration with examples.

## Usage

Some formats are too verbose to write inline here, so only compact formats are written inline here.

```typst
#import "@preview/scoryst:0.1.2": score, pages

// ABC notation (auto-detected)
#score("X:1\nM:4/4\nK:C\nCDEF|GABc|")

// MusicXML (auto-detected)
#score(read("adagio.xml"))

// MEI (auto-detected)
#score(read("schubert.mei"))

// Humdrum (auto-detected)
#score(read("sample-humdrum.krn"))

// EsAC - Essen Associative Code (auto-detected)
#score(read("hildebrandslied.esac"))

// PAE - Plaine & Easie Code (requires explicit format)
#score("@clef:G-2\n@keysig:\n@timesig:4/4\n@data:''4CDEF/GABc", options: (inputFrom: "pae"))

// Volpiano (requires explicit format)
#score("1---g--h-ij---hgf--g--hg---k--lk--k7", options: (inputFrom: "volpiano"))

// CMME (requires explicit format)
#score(read("cmme.xml"), options: (inputFrom: "cmme"))

// Change font
#score(data, options: (font: "Petaluma"))

// Multi-page
#let data = read("adagio.xml")
#let n = pages(data)
#for p in range(1, n + 1) {
  score(data, page: p)
}
```

### API

**`score(data, options: none, page: 1, ..args)`**

Renders music notation to an SVG image. `data` is a string in any supported
format. `..args` are forwarded to Typst's `image()` function (`width`,
`height`, `fit`, `alt`).

**`pages(data, options: none)`**

Returns the number of pages for the given music data.

## Building

Requires [Emscripten](https://emscripten.org/) and
[wasi-stub](https://crates.io/crates/wasi-stub).

```sh
make submodule       # init verovio submodule + apply patches
make -j$(nproc) wasm # compile to WASM
make install         # install to ~/.local/share/typst/packages/
```

### Docker build

```sh
make build    # submodule + docker image + compile + install
```

### Regenerating binary fonts

Fonts are pre-converted from Verovio's XML glyph data to a compact binary
format. To regenerate after updating the Verovio submodule:

```sh
python3 scripts/fonts_to_binary.py
```

## Architecture

### Verovio patches

The plugin applies minimal patches to the Verovio C++ source
(`scripts/verovio-typst.patch`), applied automatically by `make submodule`:

Mainly to strip data we don't need to make the wasm slimmer, to fit to Typst's specificities and also to embed the fonts in binary formats directly in order to avoid parsing XML of ~2600 glyph files at init time with direct
memory reads, making font loading instant.

## Known limitations

- **DARMS unsupported**: It worked but it looks like nobody uses this format so we dropped it.

## License

LGPLv3 - [Verovio's licensing](https://book.verovio.org/introduction/licensing.html)
