![logo](test/logo.svg)

# Scoryst - Music Engraving Plugin for Typst

A Typst plugin to render music notation from multiple formats using
[Verovio](https://www.verovio.org/), compiled to WASM.

## Features

- **8 input formats**: [ABC](https://en.wikipedia.org/wiki/ABC_notation), [MusicXML](https://en.wikipedia.org/wiki/MusicXML), [MEI](https://music-encoding.org/), [Humdrum](https://wiki.ccarh.org/images/6/6e/Humdrum-File-Format.pdf), [EsAC](https://wiki.ccarh.org/wiki/EsAC), [PAE](https://www.iaml.info/plaine-easie-code/), [Volpiano](https://cantusdatabase.org/static/documents/2.%20Volpiano%20Protocols.pdf), [CMME](https://www.cmme.org/)
- **Automatic format detection**: all 8 formats are detected from the data — `input-from` is only needed to override
- **Format conversion**: transcode any input to MEI or Plaine & Easie with `convert`
- **Code-block rendering**: `#show: scoryst.render-blocks` auto-renders fenced ` ```abc `, ` ```musicxml `, … blocks
- **5 [SMuFL](https://www.smufl.org/)-compliant music fonts**: Leipzig (default), Bravura, Gootville, Leland, Petaluma
- **Full Verovio options**: scale, font, page layout, and all
  [toolkit options](https://book.verovio.org/toolkit-reference/toolkit-options.html); introspect them at compile time with `available-options`
- **Multi-page support**: render individual pages of long scores
- **Binary font loading**: fonts pre-compiled to binary for instant init

Check the [documentation](https://github.com/bernsteining/scoryst/blob/master/test/documentation.pdf) for a full demonstration with examples.

## Usage

Some formats are too verbose to write inline here, so only compact formats are written inline here.

```typst
#import "@preview/scoryst:0.2.0": score, pages

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

// PAE - Plaine & Easie Code (auto-detected)
#score("@clef:G-2\n@keysig:\n@timesig:4/4\n@data:''4CDEF/GABc")

// Volpiano (auto-detected)
#score("1---g--h-ij---hgf--g--hg---k--lk--k7")

// CMME (auto-detected)
#score(read("cmme.xml"))

// Change font
#score(data, options: (font: "Petaluma"))

// Multi-page
#let data = read("adagio.xml")
#let n = pages(data)
#for p in range(1, n + 1) {
  score(data, page: p)
}

// Transcode to another format (input is auto-detected)
#import "@preview/scoryst:0.2.0": convert
#let mei = convert("X:1\nK:C\nCDEF|", to: "mei")  // -> canonical MEI
#let pae = convert(read("adagio.xml"), to: "pae") // -> Plaine & Easie
```

### API

**`score(data, options: none, page: 1, ..args)`**

Renders music notation to an SVG image. `data` is a string in any supported
format. `..args` are forwarded to Typst's `image()` function (`width`,
`height`, `fit`, `alt`).

**`pages(data, options: none)`**

Returns the number of pages for the given music data.

**`convert(data, to: "mei", options: none)`**

Transcodes music notation to another format. The input format is auto-detected;
`to` is `"mei"` (canonical MEI) or `"pae"` (Plaine & Easie). Returns a string.

**`available-options()`**

Returns Verovio's full option catalogue as a nested dictionary (grouped by
category, each option carrying its `title`, `description`, `type`, and
`default`). Used to generate the options reference in the
[documentation](https://github.com/bernsteining/scoryst/blob/master/test/documentation.pdf).

**`version()`**

Returns the bundled Verovio version string (e.g. `"6.3.0"`).

**`render-blocks(options: none, body)`** (show rule)

Auto-renders fenced code blocks whose language is a supported format
(`abc`, `musicxml`, `mei`, `humdrum`/`kern`, `esac`, `pae`, `volpiano`, `cmme`).
Enable it with `#show: scoryst.render-blocks` (or, with defaults,
`#show: scoryst.render-blocks.with(options: (font: "Bravura"))`); after that a
` ```abc ` or ` ```musicxml ` block renders directly as a score.

Unknown option keys are reported at compile time with a suggestion
(e.g. *unknown option "spacng-staff", did you mean "spacing-staff"?*).

### Verovio Options

Options are passed as a Typst dictionary and map directly to
[Verovio's toolkit options](https://book.verovio.org/toolkit-reference/toolkit-options.html).
Both kebab-case and camelCase keys are accepted (e.g. `adjust-page-height` or `adjustPageHeight`).

| Option | Default | Description |
|--------|---------|-------------|
| `adjust-page-height` | `true` | Crop SVG height to content |
| `adjust-page-width` | `false` | Crop SVG width to content |
| `scale` | `100` | Scale factor (percent) |
| `font` | `"Leipzig"` | Music font: Leipzig, Bravura, Gootville, Leland, Petaluma |
| `input-from` | `"auto"` | Format: auto, mei, musicxml, abc, humdrum, esac, pae, volpiano, cmme |
| `page-width` | `2100` | Page width (MEI units) |
| `page-height` | `2970` | Page height (MEI units) |
| `page-margin-top` | `50` | Top margin |
| `page-margin-bottom` | `50` | Bottom margin |
| `page-margin-left` | `50` | Left margin |
| `page-margin-right` | `50` | Right margin |
| `landscape` | `false` | Landscape orientation |
| `breaks` | `"auto"` | Line breaks: auto, line, encoded, none |
| `condense` | `"auto"` | Condense: auto, none, encoded |
| `transpose` | `""` | Transpose (e.g. "M2" for major second up) |
| `header` | `"auto"` | Header: auto, none, encoded |
| `footer` | `"auto"` | Footer: auto, none, encoded |
| `spacing-staff` | `12` | Spacing between staves |
| `spacing-system` | `12` | Spacing between systems |
| `spacing-linear` | `0.25` | Linear spacing factor |
| `spacing-non-linear` | `0.6` | Non-linear spacing factor |
| `unit` | `9` | Base unit size (half staff space) |
| `stem-width` | `0.2` | Stem width |
| `bar-line-width` | `0.3` | Bar line width |
| `staff-line-width` | `0.15` | Staff line width |
| `lyric-size` | `4.5` | Lyrics font size |
| `hairpin-size` | `3.0` | Hairpin height |
| `svg-view-box` | `false` | Use viewBox instead of width/height |
| `svg-remove-xlink` | `false` | Use href instead of xlink:href |
| `svg-bounding-boxes` | `false` | Add bounding box rects (debug) |
| `remove-ids` | `false` | Strip element IDs from SVG |
| `smufl-text-font` | `"embedded"` | SMuFL text font: embedded, linked, none |
| `pedal-style` | `"auto"` | Pedal marking style: auto, line, pedstar, altpedstar |
| `font-fallback` | `"Leipzig"` | Music font fallback for missing glyphs: Leipzig, Bravura |
| `lyric-elision` | `"regular"` | Lyric elision width: regular, narrow, wide, unicode |
| `multi-rest-style` | `"auto"` | Multi-measure rest style: auto, default, block, symbols |
| `system-divider` | `"none"` | System divider display: none, auto, left, left-right |
| `duration-equivalence` | `"brevis"` | Mensural duration equivalence: brevis, semibrevis, minima |
| `ligature-oblique` | `"auto"` | Ligature oblique shape: auto, straight, curved |
| `mensural-responsive-view` | `"none"` | Mensural responsive view: none, auto, selection |

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

- **Binary font loading**: embed font data directly in the WASM binary, avoiding parsing ~2600 XML glyph files at init time
- **PAE support**: rewrite the Plaine & Easie parser to avoid WASI syscalls incompatible with Typst's WASM environment
- **Text font**: use Liberation Serif instead of Times, which Typst's SVG renderer can't resolve
- **Performance**: `std::bitset` for attribute class lookups, `unordered_map` for glyph dedup and font tables
- **Slim build**: strip unused data to reduce WASM size

## Known limitations

- **DARMS unsupported**: It worked but it looks like nobody uses this format so we dropped it.

## License

LGPLv3 - [Verovio's licensing](https://book.verovio.org/introduction/licensing.html)
