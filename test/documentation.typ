#import "@local/verovio:0.1.0": render-music, music-page-count
#import "@preview/zebraw:0.6.1": *
#set page(width: 210mm, height: 297mm, margin: 15mm)
#set text(size: 11pt)
#show link: it => underline(text(fill: rgb("#1a5fb4"), it))

// Example helper: shows code then rendered output with minimal spacing
#let doc-scope = (render-music: render-music, music-page-count: music-page-count, read: read)
#show raw.where(lang: "example"): it => {
  let code = it.text
  zebraw(numbering: false, raw(block: true, lang: "typst", code))
  v(-0.5em)
  eval(code, mode: "markup", scope: doc-scope)
}
#show raw.where(block: true, lang: "typst"): it => zebraw(numbering: false, it)

// Front page
#set page(numbering: none)
#align(center + horizon)[
  #text(size: 32pt, weight: "bold", "Verovio")

  #v(1.5em)
  #text(size: 16pt, fill: gray)[Music engraving in Typst]

  #box(render-music(
    "X:1\nM:\nK:C\nG1B|",
    options:(font:"Leipzig", adjustPageWidth: true),
    width: 70%,
  ))
  #v(1.5em)

 #link("https://github.com/bernsteining/verovio")[#text(size: 16pt, fill: blue)[github.com/bernsteining/verovio]] · #link("https://typst.app/universe/package/verovio")[#text(size: 16pt, fill: blue)[typst.app/universe/package/verovio]]
] 
  
#v(1fr)

#pagebreak()
#outline(indent: auto)
#pagebreak()
#set page(numbering: "1", number-align: right + bottom)
#counter(page).update(1)

#align(center)[
  #text(size: 20pt, weight: "bold")[Verovio — Music Engraving Plugin for Typst]
]

#v(1em)

Verovio is a music notation engraving library. This Typst
plugin wraps #link("https://www.verovio.org/index.xhtml")[Verovio] as a WebAssembly module, rendering music from multiple
input formats directly into SVG embedded in your document.

= Quick Start

Render inline ABC notation:

````example
#import "@local/verovio:0.1.0": render-music
#render-music("X:1\nM:4/4\nK:C\nCDEF|GABc|")
````

Or define a show rule to render ABC code blocks automatically:

````example
#import "@local/verovio:0.1.0": render-music
#show raw.where(lang: "abc"): it => render-music(it.text)

```abc
X:1
T:Ode to Joy
M:4/4
K:C
EEFG|GFED|CCDE|E2D2|
EEFG|GFED|CCDE|D2C2|
```
````

= API Reference

== `render-music`

```typst
#render-music(
  data,             // string: music data (ABC, MusicXML, MEI, Humdrum, Volpiano, CMME)
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
Useful to loop over pages of a multi-page score:

#pagebreak()

= Verovio Options

Options are passed as a Typst dictionary. They map directly to
#link("https://book.verovio.org/toolkit-reference/toolkit-options.html")[Verovio's toolkit options].

#set text(size: 13pt)

#align(center, table(
  columns: (auto, auto, auto),
  align: (left, left, left),
  table.header(
    table.cell(colspan: 3, align: left, strong[Common]),
  ),
  [`adjustPageHeight`], [`true`], [Crop SVG height to content],
  [`adjustPageWidth`], [`false`], [Crop SVG width to content],
  [`scale`], [`100`], [Scale factor (percent)],
  [`font`], [`"Leipzig"`], [Music font: Leipzig, Bravura, Gootville, Leland, Petaluma],
  [`inputFrom`], [`"auto"`], [Format: auto, mei, musicxml, abc, humdrum, volpiano, cmme],
  [`pageWidth`], [`2100`], [Page width (MEI units)],
  [`pageHeight`], [`2970`], [Page height (MEI units)],
  [`pageMarginTop`], [`50`], [Top margin],
  [`pageMarginBottom`], [`50`], [Bottom margin],
  [`pageMarginLeft`], [`50`], [Left margin],
  [`pageMarginRight`], [`50`], [Right margin],
  [`landscape`], [`false`], [Landscape orientation],
  [`breaks`], [`"auto"`], [Line breaks: auto, line, encoded, none],
  [`condense`], [`"auto"`], [Condense: auto, none, encoded],
  [`transpose`], [`""`], [Transpose (e.g. "M2" for major second up)],
  [`header`], [`"auto"`], [Header: auto, none, encoded],
  [`footer`], [`"auto"`], [Footer: auto, none, encoded],
  table.cell(colspan: 3, align: left, strong[Layout]),
  [`spacingStaff`], [`12`], [Spacing between staves],
  [`spacingSystem`], [`12`], [Spacing between systems],
  [`spacingLinear`], [`0.25`], [Linear spacing factor],
  [`spacingNonLinear`], [`0.6`], [Non-linear spacing factor],
  [`unit`], [`9`], [Base unit size (half staff space)],
  [`stemWidth`], [`0.2`], [Stem width],
  [`barLineWidth`], [`0.3`], [Bar line width],
  [`staffLineWidth`], [`0.15`], [Staff line width],
  [`lyricSize`], [`4.5`], [Lyrics font size],
  [`hairpinSize`], [`3.0`], [Hairpin height],
  table.cell(colspan: 3, align: left, strong[SVG Output]),
  [`svgViewBox`], [`false`], [Use viewBox instead of width/height],
  [`svgRemoveXlink`], [`false`], [Use href instead of xlink:href],
  [`svgBoundingBoxes`], [`false`], [Add bounding box rects (debug)],
  [`removeIds`], [`false`], [Strip element IDs from SVG],
  [`smuflTextFont`], [`"embedded"`], [SMuFL text font: embedded, linked, none],
)
)

#set text(size: 11pt)

#align(center, [Full reference: #link("https://book.verovio.org/toolkit-reference/toolkit-options.html")])


#pagebreak()

= Music Fonts

Five #link("https://www.smufl.org/")[SMuFL]-compliant music fonts are available. Set the font with the
`font` option:

```typst
#render-music(data, options: (font: "Petaluma"))
```

#let font-sample = "X:1\nM:4/4\nL:1/8\nK:Bb\n(D2 EF) G>A|_B2 ^c2 d2 z2|{/A}G6 !trill!F2|]"

#block[
  #let cells = ()
  #for name in ("Petaluma", "Leland", "Gootville", "Bravura", "Leipzig") {
    cells.push(align(left + horizon, strong(name)))
    cells.push(render-music(font-sample, options: (font: name, adjustPageWidth: true), height: 10em))
  }
  #grid(columns: (auto, 1fr), row-gutter: 0.5em, column-gutter: 1em, ..cells)
]

#pagebreak()

= Supported Input Formats

Verovio auto-detects the input format for ABC, MusicXML, MEI, and Humdrum.
For Volpiano and CMME, pass `inputFrom` explicitly.

All the files used in the examples are available in the project's #link("https://github.com/bernsteining/verovio")[Github].

=== Exporting from notation software

If you're working with any of these scoring software this table sums up each supported export format with their documentation linked.

#set text(size: 9pt)
#table(
  columns: (auto, auto, auto, auto, auto),
  align: (left, center, center, center, center),
  table.header([*Software*], [*MusicXML*], [*MEI*], [*ABC*], [*Humdrum*]),
  [#link("https://musescore.org/en/handbook/4/file-export")[MuseScore]], [✓], [✓], [], [],
  [#link("https://usermanuals.finalemusic.com/FinaleMac/Content/Finale/menu-file.htm")[Finale]], [✓], [], [], [],
  [#link("https://resources.avid.com/SupportFiles/Sibelius/2024.12/en-US/Content/Sibelius/Exporting_MusicXML.htm")[Sibelius]], [✓], [], [], [],
  [#link("https://www.steinberg.help/r/dorico-pro/5.1/en/dorico/topics/project_file_handling/project_file_handling_musicxml_unpitched_percussion_r.html")[Dorico]], [✓], [], [], [],
  [#link("https://lilypond.org/doc/v2.24/Documentation/usage/invoking-musicxml2ly")[LilyPond]], [✓], [], [], [],
  [#link("https://help.flat.io/en/music-notation-software/print-export/")[Flat.io]], [✓], [], [], [],
  [#link("https://www.noteflight.com/guide#exportScore")[Noteflight]], [✓], [], [], [],
  [#link("https://abcnotation.com/wiki/abc:standard:v2.1")[ABC tools]], [✓], [], [✓], [],
  [#link("https://extras.humdrum.org/man/")[Humdrum tools]], [✓], [✓], [✓], [✓],
  [#link("https://music-encoding.org/resources/tools.html")[MEI tools]], [✓], [✓], [], [],
)
#set text(size: 11pt)

MusicXML is the universal interchange format — virtually all notation software can export it. For the best results, export as uncompressed MusicXML (`.musicxml` or `.xml`, not `.mxl`).

== ABC Notation

#link("https://abcnotation.com/wiki/abc:standard:v2.1")[ABC specification]
· #link("https://abcnotation.com/tunes")[Download ABC files]

ABC is a compact text-based format popular for folk and classical melodies.
Chord symbols are supported.

````example
#render-music(read("bach-prelude-cmaj.abc"))
````

#pagebreak()

== MusicXML

#link("https://www.w3.org/2021/06/musicxml40/")[MusicXML 4.0 specification]
· #link("https://www.musicxml.com/music-in-musicxml/")[Download MusicXML files]

MusicXML is the standard interchange format for notation software.
It supports grand staff, multiple voices, dynamics, and full score layout.

```example
#render-music(read("adagio.xml"))
```

#pagebreak()

== MEI (Music Encoding Initiative)

#link("https://music-encoding.org/guidelines/v4/content/")[MEI Guidelines]
· #link("https://github.com/music-encoding/sample-encodings")[Sample MEI encodings]

MEI is a rich XML-based format used in musicology, supporting lyrics,
polyphonic textures, fermatas, and detailed editorial markup.

```example
#render-music(read("schubert.mei"))
```

#pagebreak()

== Humdrum

#link("https://www.humdrum.org/guide/")[Humdrum User Guide]
· #link("https://kern.ccarh.org/")[Download kern files]

Humdrum uses a tab-separated spine structure with `**kern` encoding
for pitches and durations. Widely used in computational musicology.

```example
#render-music(read("sample-humdrum.krn"))
```

#pagebreak()

== Volpiano

#link("https://cantus.uwaterloo.ca/description#volpiano")[Volpiano specification]
· #link("https://cantus.uwaterloo.ca/")[CANTUS database]

Volpiano is a text encoding for medieval chant notation, used by the
CANTUS database. Here is _Veni Creator Spiritus_, the famous Pentecost hymn.
Requires `inputFrom: "volpiano"`.

```example
#render-music("1---g--hij---hgf--g--hg---k--lk--k7---hG--f---h--k--lk---l--m--l---k--lm---kj7--hg--kl---g--gh--k---jk---h---gf--h--hjh7---g--f--g7---3", options: (inputFrom: "volpiano"))
```

== CMME

#link("https://www.cmme.org")[CMME project]
· #link("https://github.com/tdumitrescu/cmme-music")[Download CMME files]

CMME is an XML format for mensural notation (medieval and Renaissance music).
Requires `inputFrom: "cmme"`.

```example
#render-music(read("cmme.xml"), options: (inputFrom: "cmme"))
```

