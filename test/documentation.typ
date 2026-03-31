#import "@local/verovio:0.1.0": render-music, music-page-count
#set page(width: 210mm, height: 297mm, margin: 15mm)
#set text(size: 11pt)

// Front page
#v(1fr)
#align(center)[
  #box(render-music(
    "X:1\nK:C\nGABc|",
    options:(font:"Leipzig", adjustPageWidth: true),
  ))
  #v(1em)
  #text(size: 28pt, weight: "bold")[Verovio]
  #v(0.3em)
  #text(size: 14pt, fill: luma(100))[Music Engraving Plugin for Typst]
]
#v(1fr)

#pagebreak()
#outline(indent: auto)
#pagebreak()

#align(center)[
  #text(size: 20pt, weight: "bold")[Verovio — Music Engraving Plugin for Typst]
]

#v(1em)

Verovio is a fast, lightweight music notation engraving library. This Typst
plugin wraps Verovio as a WebAssembly module, rendering music from multiple
input formats directly into SVG images embedded in your document.

= Quick Start

```typst
#import "@local/verovio:0.1.0": render-music

#render-music("X:1\nT:Scale\nM:4/4\nK:C\nCDEF|GABc|")
```

#render-music("X:1\nT:Scale\nM:4/4\nK:C\nCDEF|GABc|", width: 100%)

= Supported Input Formats

Verovio auto-detects the input format for ABC, MusicXML, MEI, and Humdrum.
For Volpiano and DARMS, pass `inputFrom` explicitly.

== ABC Notation

ABC is a compact text-based format popular for folk and classical melodies.
Chord symbols are supported.

#raw(read("scarborough-fair.abc"), lang: "abc")

#render-music(read("scarborough-fair.abc"), width: 100%)

More complex pieces with fast arpeggiated patterns:

#render-music(read("bach-prelude-cmaj.abc"), width: 100%)

#pagebreak()

== MusicXML

MusicXML is the standard interchange format for notation software.
It supports grand staff, multiple voices, dynamics, and full score layout.

```typst
#render-music(read("score.musicxml"), width: 100%)
```

#render-music(read("adagio.xml"), width: 100%)

#pagebreak()

== MEI (Music Encoding Initiative)

MEI is a rich XML-based format used in musicology, supporting lyrics,
polyphonic textures, fermatas, and detailed editorial markup.

#render-music(read("sample-mei.mei"), width: 100%)

#pagebreak()

== Humdrum

Humdrum uses a tab-separated spine structure with `**kern` encoding
for pitches and durations. Widely used in computational musicology.

#render-music(read("sample-humdrum.krn"), width: 100%)

#pagebreak()

== Volpiano

Volpiano is a text encoding for medieval chant notation, used extensively
by the CANTUS database. Requires `inputFrom: "volpiano"`.

#raw(read("sample-volpiano.txt"), lang: "txt")

```typst
#render-music(read("chant.txt"), options: (inputFrom: "volpiano"))
```

#render-music(read("sample-volpiano.txt"), options: (inputFrom: "volpiano"), width: 100%)

#pagebreak()

= Music Fonts

Five SMuFL-compliant music fonts are available. Set the font with the
`font` option:

```typst
#render-music(data, options: (font: "Petaluma"))
```

#let sample = read("scarborough-fair.abc")

#for name in ("Leipzig", "Bravura", "Gootville", "Leland", "Petaluma") {
  [== #name]
  render-music(sample, options: (font: name), width: 100%)
}

#pagebreak()

= Verovio Options

Options are passed as a Typst dictionary. They map directly to
#link("https://book.verovio.org/toolkit-reference/toolkit-options.html")[Verovio's toolkit options].

```typst
#render-music(data, options: (
  scale: 50,
  font: "Bravura",
  adjustPageHeight: true,
))
```

== Common Options

#table(
  columns: (auto, auto, auto),
  align: (left, left, left),
  table.header([*Option*], [*Default*], [*Description*]),
  [`adjustPageHeight`], [`true`], [Crop SVG height to content],
  [`adjustPageWidth`], [`false`], [Crop SVG width to content],
  [`scale`], [`100`], [Scale factor (percent)],
  [`font`], [`"Leipzig"`], [Music font: Leipzig, Bravura, Gootville, Leland, Petaluma],
  [`inputFrom`], [`"auto"`], [Input format: auto, mei, musicxml, abc, humdrum, volpiano, darms],
  [`pageWidth`], [`2100`], [Page width in MEI units],
  [`pageHeight`], [`2970`], [Page height in MEI units],
  [`pageMarginTop`], [`50`], [Top margin],
  [`pageMarginBottom`], [`50`], [Bottom margin],
  [`pageMarginLeft`], [`50`], [Left margin],
  [`pageMarginRight`], [`50`], [Right margin],
  [`landscape`], [`false`], [Landscape orientation],
  [`breaks`], [`"auto"`], [Line breaks: auto, line, encoded, none],
  [`condense`], [`"auto"`], [Condense score: auto, none, encoded],
  [`transpose`], [`""`], [Transpose interval (e.g. "M2" for major second up)],
  [`header`], [`"auto"`], [Show header: auto, none, encoded],
  [`footer`], [`"auto"`], [Show footer: auto, none, encoded],
)

== Layout Options

#table(
  columns: (auto, auto, auto),
  align: (left, left, left),
  table.header([*Option*], [*Default*], [*Description*]),
  [`spacingStaff`], [`12`], [Spacing between staves],
  [`spacingSystem`], [`12`], [Spacing between systems],
  [`spacingLinear`], [`0.25`], [Linear spacing factor],
  [`spacingNonLinear`], [`0.6`], [Non-linear spacing factor],
  [`unit`], [`9`], [Base unit size (half staff space)],
  [`stemWidth`], [`0.2`], [Stem width],
  [`barLineWidth`], [`0.3`], [Bar line width],
  [`staffLineWidth`], [`0.15`], [Staff line width],
  [`beamMaxSlope`], [`10`], [Max beam slope (degrees)],
  [`lyricSize`], [`4.5`], [Lyrics font size],
  [`dynamDist`], [`3.0`], [Distance for dynamics placement],
  [`hairpinSize`], [`3.0`], [Hairpin height],
)

== SVG Output Options

#table(
  columns: (auto, auto, auto),
  align: (left, left, left),
  table.header([*Option*], [*Default*], [*Description*]),
  [`svgViewBox`], [`false`], [Use viewBox instead of width/height],
  [`svgRemoveXlink`], [`false`], [Use href instead of xlink:href],
  [`svgBoundingBoxes`], [`false`], [Add bounding box rects (debug)],
  [`removeIds`], [`false`], [Strip element IDs from SVG],
  [`smuflTextFont`], [`"embedded"`], [SMuFL text font: embedded, linked, none],
)

Full reference: #link("https://book.verovio.org/toolkit-reference/toolkit-options.html")

== Scaling Example

#render-music(read("scarborough-fair.abc"), options: (scale: 50), width: 100%)

== Page Height

`adjustPageHeight: true` (the default) crops the SVG to fit the content.
Set it to `false` for full-page layout:

#render-music(read("scarborough-fair.abc"), options: (adjustPageHeight: false), width: 100%)

= Multi-page Scores

For longer scores, use `music-page-count` and the `page` parameter:

```typst
#let data = read("score.musicxml")
#let pages = music-page-count(data)
#for p in range(1, pages + 1) {
  render-music(data, page: p, width: 100%)
}
```

#let data = read("adagio.xml")
#let pages = music-page-count(data)
This score has #pages page(s).

= API Reference

== `render-music`

```typst
#render-music(
  data,             // string: music data (ABC, MusicXML, MEI, etc.)
  options: none,    // dictionary: verovio options
  page: 1,          // int: page number to render
  ..args,           // forwarded to Typst's image() (width, height, fit, alt)
)
```

== `music-page-count`

```typst
#let n = music-page-count(data, options: none)
```

Returns the number of pages for the given music data and options.
