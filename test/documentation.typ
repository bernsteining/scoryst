#import "../pkg/scoryst.typ": score, pages
#import "@preview/zebraw:0.6.1": *
#set page(width: 210mm, height: 297mm, margin: 15mm)
#set text(size: 11pt)
#show link: it => underline(text(fill: rgb("#1a5fb4"), it))

// Example helper: shows code then rendered output with minimal spacing
#let doc-scope = (score: score, pages: pages, read: read)
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
  #text(size: 32pt, weight: "bold", "Scoryst")

  #v(1.5em)
  #text(size: 16pt, fill: gray)[Music engraving in Typst]

  #box(score(
    "X:1\nM:\nK:C\nG1B|",
    options:(font:"Leipzig", adjust-page-width: true),
    width: 70%,
  ))
  #v(1.5em)

 #link("https://github.com/bernsteining/scoryst")[#text(size: 16pt, fill: blue)[github.com/bernsteining/scoryst]] · #link("https://typst.app/universe/package/scoryst")[#text(size: 16pt, fill: blue)[typst.app/universe/package/scoryst]]

  #v(1em)
  #text(size: 12pt, fill: gray)[v0.1.3 — 2026-06-21]
]
  
#v(1fr)

#pagebreak()
#outline(indent: auto)
#pagebreak()
#set page(numbering: "1", number-align: right + bottom)
#counter(page).update(1)

#align(center)[
  #text(size: 20pt, weight: "bold")[Scoryst — Music Engraving Plugin for Typst]
]

#v(1em)

Scoryst is a music notation engraving plugin for Typst. It
wraps #link("https://www.verovio.org/index.xhtml")[Verovio] as a WebAssembly module, rendering music from multiple
input formats directly into SVG embedded in your document.

= Quick Start

Render inline ABC notation:

````example
#import "../pkg/scoryst.typ": score
#score("X:1\nM:4/4\nK:C\nCDEF|GABc|")
````

Or define a show rule to render ABC code blocks automatically:

````example
#import "../pkg/scoryst.typ": score
#show raw.where(lang: "abc"): it => score(it.text)

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

== `score`

```typst
#score(
  data,             // string: music (ABC, MusicXML, MEI, Humdrum, EsAC, PAE, Volpiano, CMME)
  options: none,    // dictionary: verovio options
  page: 1,          // int: page number to render
  ..args,           // forwarded to Typst's image() (width, height, fit, alt)
)
```

== `pages`

```typst
#let n = pages(data, options: none)
```

Returns the number of pages for the given music data and options.
Useful to loop over pages of a multi-page score.

#pagebreak()

= Verovio Options

Options are passed as a Typst dictionary. They map directly to
#link("https://book.verovio.org/toolkit-reference/toolkit-options.html")[Verovio's toolkit options].
Both kebab-case and camelCase keys are accepted (e.g. `adjust-page-height` or `adjustPageHeight`).

#set text(size: 10.5pt)

#align(center, table(
  columns: (auto, auto, auto),
  align: (left, left, left),
  [`adjust-page-height`], [`true`], [Crop SVG height to content],
  [`adjust-page-width`], [`false`], [Crop SVG width to content],
  [`scale`], [`100`], [Scale factor (percent)],
  [`font`], [`"Leipzig"`], [Music font: Leipzig, Bravura, Gootville, Leland, Petaluma],
  [`input-from`], [`"auto"`], [Format: auto, mei, musicxml, abc, humdrum, esac, pae, volpiano, cmme],
  [`page-width`], [`2100`], [Page width (MEI units)],
  [`page-height`], [`2970`], [Page height (MEI units)],
  [`page-margin-top`], [`50`], [Top margin],
  [`page-margin-bottom`], [`50`], [Bottom margin],
  [`page-margin-left`], [`50`], [Left margin],
  [`page-margin-right`], [`50`], [Right margin],
  [`landscape`], [`false`], [Landscape orientation],
  [`breaks`], [`"auto"`], [Line breaks: auto, line, encoded, none],
  [`condense`], [`"auto"`], [Condense: auto, none, encoded],
  [`transpose`], [`""`], [Transpose (e.g. "M2" for major second up)],
  [`header`], [`"auto"`], [Header: auto, none, encoded],
  [`footer`], [`"auto"`], [Footer: auto, none, encoded],
  [`spacing-staff`], [`12`], [Spacing between staves],
  [`spacing-system`], [`12`], [Spacing between systems],
  [`spacing-linear`], [`0.25`], [Linear spacing factor],
  [`spacing-non-linear`], [`0.6`], [Non-linear spacing factor],
  [`unit`], [`9`], [Base unit size (half staff space)],
  [`stem-width`], [`0.2`], [Stem width],
  [`bar-line-width`], [`0.3`], [Bar line width],
  [`staff-line-width`], [`0.15`], [Staff line width],
  [`lyric-size`], [`4.5`], [Lyrics font size],
  [`hairpin-size`], [`3.0`], [Hairpin height],
  [`svg-view-box`], [`false`], [Use viewBox instead of width/height],
  [`svg-remove-xlink`], [`false`], [Use href instead of xlink:href],
  [`svg-bounding-boxes`], [`false`], [Add bounding box rects (debug)],
  [`remove-ids`], [`false`], [Strip element IDs from SVG],
  [`smufl-text-font`], [`"embedded"`], [SMuFL text font: embedded, linked, none],
  [`pedal-style`], [`"auto"`], [Pedal marking style: auto, line, pedstar, altpedstar],
  [`font-fallback`], [`"Leipzig"`], [Music font fallback for missing glyphs: Leipzig, Bravura],
  [`lyric-elision`], [`"regular"`], [Lyric elision width: regular, narrow, wide, unicode],
  [`multi-rest-style`], [`"auto"`], [Multi-measure rest style: auto, default, block, symbols],
  [`system-divider`], [`"none"`], [System divider display: none, auto, left, left-right],
  [`duration-equivalence`], [`"brevis"`], [Mensural duration equivalence: brevis, semibrevis, minima],
  [`ligature-oblique`], [`"auto"`], [Ligature oblique shape: auto, straight, curved],
  [`mensural-responsive-view`], [`"none"`], [Mensural responsive view: none, auto, selection],
)
)

#set text(size: 11pt)

#align(center, [Full reference: #link("https://book.verovio.org/toolkit-reference/toolkit-options.html")])


#pagebreak()

= Music Fonts

Five #link("https://www.smufl.org/")[SMuFL]-compliant music fonts are available. Set the font with the
`font` option:

```typst
#score(data, options: (font: "Petaluma"))
```

#let font-sample = "X:1\nM:4/4\nL:1/8\nK:Bb\n(D2 EF) G>A|_B2 ^c2 d2 z2|{/A}G6 !trill!F2|]"

#block[
  #let cells = ()
  #for name in ("Petaluma", "Leland", "Gootville", "Bravura", "Leipzig") {
    cells.push(align(left + horizon, strong(name)))
    cells.push(score(font-sample, options: (font: name, adjust-page-width: true), height: 10em))
  }
  #grid(columns: (auto, 1fr), row-gutter: 0.5em, column-gutter: 1em, ..cells)
]

#pagebreak()

= Supported Input Formats

Verovio auto-detects the input format for ABC, MusicXML, MEI, Humdrum, and EsAC.
For PAE, Volpiano, and CMME, pass `input-from` explicitly.

All the files used in the examples are available in the project's #link("https://github.com/bernsteining/scoryst")[Github].

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
#score(read("examples/bach-prelude-cmaj.abc"))
````

#pagebreak()

== MusicXML

#link("https://www.w3.org/2021/06/musicxml40/")[MusicXML 4.0 specification]
· #link("https://www.musicxml.com/music-in-musicxml/")[Download MusicXML files]

MusicXML is the standard interchange format for notation software.
It supports grand staff, multiple voices, dynamics, and full score layout.

```example
#score(read("examples/adagio.xml"))
```

#pagebreak()

== MEI (Music Encoding Initiative)

#link("https://music-encoding.org/guidelines/v4/content/")[MEI Guidelines]
· #link("https://github.com/music-encoding/sample-encodings")[Sample MEI encodings]

MEI is a rich XML-based format used in musicology, supporting lyrics,
polyphonic textures, fermatas, and detailed editorial markup.

```example
#score(read("examples/schubert.mei"))
```

#pagebreak()

== Humdrum

#link("https://www.humdrum.org/guide/")[Humdrum User Guide]
· #link("https://kern.ccarh.org/")[Download kern files]

Humdrum uses a tab-separated spine structure with `**kern` encoding
for pitches and durations. Widely used in computational musicology.

```example
#score(read("examples/sample-humdrum.krn"))
```

#pagebreak()

== EsAC (Essen Associative Code)

#link("https://www.esac-data.org/")[EsAC data]
· #link("https://kern.ccarh.org/cgi-bin/browse?l=/essen")[Essen Folksong Collection]

EsAC is a text format used by the Essen Folksong Collection to encode
melodies as scale degrees relative to a tonic. It stores metadata (title,
region, key) and melody data in labeled fields. Here is _Das Hildebrandslied_,
a German folk ballad. EsAC is auto-detected by Verovio.

```example
#score(read("examples/hildebrandslied.esac"))
```

== Plaine & Easie Code (PAE)

#link("https://www.iaml.info/plaine-easie-code")[Plaine & Easie specification]
· #link("https://rism.info")[RISM catalogue]

Plaine & Easie Code is a compact text notation used by #link("https://rism.info")[RISM] to catalogue
musical incipits — the opening bars of a piece. It encodes clef, key signature,
time signature, and note data as key-value pairs.
Requires `input-from: "pae"`.

````example
#score(
  "@clef:G-2\n@keysig:xF\n@timesig:3/8\n@data:=25//$xFCG @c 2-4.-'8E/{6AGFE}{8A''C}'B''4D{6C'B}/{''DC'BA}{''8EA}",
  options: (input-from: "pae"),
)
````

#pagebreak()

== Volpiano

#link("https://cantus.uwaterloo.ca/description#volpiano")[Volpiano specification]
· #link("https://cantus.uwaterloo.ca/")[CANTUS database]

Volpiano is a text encoding for medieval chant notation, used by the
CANTUS database. Here is _Veni Creator Spiritus_, the famous Pentecost hymn.
Requires `input-from: "volpiano"`.

```example
#score("1---g--h-ij---hgf--g--hg---k--lk--k7---hG--f---h--k--lk---l--m--l---k--lm---kj7--hg--kl---g--gh--k---jk---h---gf--h--hjh7---g--f--g7---3", options: (input-from: "volpiano"))
```

== CMME

#link("https://www.cmme.org")[CMME project]
· #link("https://github.com/tdumitrescu/cmme-music")[Download CMME files]

CMME is an XML format for mensural notation (medieval and Renaissance music).
Requires `input-from: "cmme"`.

```example
#score(read("examples/cmme.xml"), options: (input-from: "cmme"))
```

