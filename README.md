# Verovio for Typst

A Typst plugin that renders music notation via [Verovio](https://www.verovio.org).
Supports MusicXML, MEI, ABC, Humdrum, and Plaine & Easie.

## Building

The only dependency is Docker (or Podman).

```sh
git clone --recurse-submodules <repo-url>
cd verovio
make build
```

This will:
1. Initialize the verovio submodule (sparse checkout, ~19M)
2. Build the Docker image with emscripten + wasi-stub (cached after first run)
3. Compile `pkg/verovio.wasm` inside the container

### Building without Docker

If you have emscripten and [wasi-stub](https://crates.io/crates/wasi-stub) installed locally:

```sh
make submodule
make wasm
```

## Installation

Install the package to your local Typst packages directory:

```sh
make install
```

This copies `verovio.wasm`, `verovio.typ`, and `typst.toml` to
`~/.local/share/typst/packages/local/verovio/0.1.0/`.

## Usage

```typst
#import "@local/verovio:0.1.0": render-music, music-page-count

// Render ABC notation
#render-music("X:1\nT:Scale\nK:C\nCDEF GABc|", width: 100%)

// Render from a file
#render-music(read("score.musicxml"), width: 100%)

// Render a specific page
#render-music(read("score.mei"), page: 2, width: 100%)

// Get total page count
#let pages = music-page-count(read("score.mei"))
```

### Options

Pass Verovio options as a dictionary:

```typst
#render-music(
  read("score.abc"),
  options: (
    scale: 50,
    pageWidth: 2000,
    font: "Leipzig",
  ),
  width: 100%,
)
```

### Supported formats

| Format | Example |
|--------|---------|
| ABC | `read("tune.abc")` |
| MusicXML | `read("score.musicxml")` |
| MEI | `read("score.mei")` |
| Humdrum | `read("score.krn")` |
| Plaine & Easie | `read("incipit.pae")` |
| Volpiano | `read("chant.txt")` |
| CMME | `read("piece.xml")` |
| DARMS | `read("score.txt")` |
| EsAC | `read("melody.txt")` |

## License

MIT
