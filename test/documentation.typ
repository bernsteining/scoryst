#import "../pkg/scoryst.typ": score, pages, version, convert, available-options, render-blocks
#import "@preview/zebraw:0.6.1": *
#set page(width: 210mm, height: 297mm, margin: 15mm)
#set text(size: 11pt)
#show link: it => underline(text(fill: rgb("#1a5fb4"), it))

// Example helper: shows code then rendered output with minimal spacing
#let doc-scope = (score: score, pages: pages, read: read, convert: convert, version: version, render-blocks: render-blocks)
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
  #text(size: 12pt, fill: gray)[v0.2.0 — 2026-09-01]

  #text(size: 11pt, fill: gray)[Powered by Verovio #version()]
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

Or enable the `render-blocks` show rule and write music directly in fenced code
blocks (`abc`, `musicxml`, `mei`, `humdrum`/`kern`, `esac`, `pae`, `volpiano`,
`cmme`):

````example
#import "../pkg/scoryst.typ": render-blocks
#show: render-blocks

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

Options are passed as a Typst dictionary and map directly to
#link("https://book.verovio.org/toolkit-reference/toolkit-options.html")[Verovio's toolkit options].
Both kebab-case and camelCase keys are accepted (e.g. `adjust-page-height`
or `adjustPageHeight`).

// --- Helpers: option tables generated from available-options() ---------------
#let _fmt-default(v) = {
  if type(v) == bool { if v { "true" } else { "false" } }
  else if type(v) == str { if v == "" { "\"\"" } else { "\"" + v + "\"" } }
  else if type(v) == array { "[" + v.map(x => "\"" + str(x) + "\"").join(", ") + "]" }
  else { str(v) }
}
#let _fmt-type(t) = {
  if t == "std::string" { "string" } else if t == "std::string-list" { "enum" } else { t }
}
#let _opt-table(rows) = table(
  columns: (auto, auto, auto, 1fr),
  align: (left, left, left, left),
  inset: 4pt,
  table.header([*Option*], [*Type*], [*Default*], [*Description*]),
  ..rows.map(((k, o)) => (
    raw(k),
    _fmt-type(o.at("type", default: "")),
    raw(_fmt-default(o.at("default", default: ""))),
    o.at("description", default: ""),
  )).flatten()
)
// Flatten every option into a key -> option lookup.
#let _all-opts = {
  let m = (:)
  for (gid, grp) in available-options().at("groups") {
    for (k, o) in grp.at("options") { m.insert(k, o) }
  }
  m
}

The options below are the ones you'll reach for most often; the values are read
at compile time from `available-options()`, so they always match the bundled
Verovio #version(). The *complete* list of every option, grouped by category, is
in the #link(<appendix-options>)[appendix].

#let _common = (
  "adjustPageHeight", "adjustPageWidth", "scale", "font", "inputFrom", "breaks",
  "pageWidth", "pageHeight", "landscape", "header", "footer", "transpose",
  "spacingStaff", "spacingSystem", "unit",
)
#set text(size: 9.5pt)
#_opt-table(_common.map(k => (k, _all-opts.at(k, default: none))).filter(((k, o)) => o != none))
#set text(size: 11pt)

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

All eight input formats are auto-detected, so `#score(data)` just works. Pass
`options: (input-from: "…")` only to override detection.

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
time signature, and note data as key-value pairs. Auto-detected.

````example
#score(
  "@clef:G-2\n@keysig:xF\n@timesig:3/8\n@data:=25//$xFCG @c 2-4.-'8E/{6AGFE}{8A''C}'B''4D{6C'B}/{''DC'BA}{''8EA}",
)
````

#pagebreak()

== Volpiano

#link("https://cantus.uwaterloo.ca/description#volpiano")[Volpiano specification]
· #link("https://cantus.uwaterloo.ca/")[CANTUS database]

Volpiano is a text encoding for medieval chant notation, used by the
CANTUS database. Here is _Veni Creator Spiritus_, the famous Pentecost hymn.
Auto-detected from its clef-and-hyphen prefix (pass `input-from: "volpiano"` to force it).

```example
#score("1---g--h-ij---hgf--g--hg---k--lk--k7---hG--f---h--k--lk---l--m--l---k--lm---kj7--hg--kl---g--gh--k---jk---h---gf--h--hjh7---g--f--g7---3")
```

== CMME

#link("https://www.cmme.org")[CMME project]
· #link("https://github.com/tdumitrescu/cmme-music")[Download CMME files]

CMME is an XML format for mensural notation (medieval and Renaissance music).
Auto-detected.

```example
#score(read("examples/cmme.xml"))
```


#pagebreak()

= Format Conversion

Beyond rendering, scoryst can transcode notation between formats with
`convert(data, to: ...)`. The input format is auto-detected; the supported
output targets are `"mei"` (canonical MEI) and `"pae"` (#link("https://www.iaml.info/plaine-easie-code")[Plaine & Easie]).
This is useful for normalizing input, archiving a canonical MEI copy, or
inspecting how Verovio interprets a score.

Convert ABC to Plaine & Easie:

```typst
#let pae = convert("X:1\nL:1/4\nK:C\nCDEF|GABc|", to: "pae")
```

#let pae = convert("X:1\nL:1/4\nK:C\nCDEF|GABc|", to: "pae")
#zebraw(numbering: false, raw(block: true, pae))

Convert the same melody to MEI (the canonical, richly-structured encoding
Verovio renders from). MEI is verbose, so here are its first lines:

```typst
#let mei = convert("X:1\nL:1/4\nK:C\nCDEF|GABc|", to: "mei")
```

#let mei = convert("X:1\nL:1/4\nK:C\nCDEF|GABc|", to: "mei")
#zebraw(numbering: false, raw(block: true, lang: "xml", mei.split("\n").slice(0, 12).join("\n")))

= Changelog

*v0.2.0 — 2026-09-01*
- Upgraded to Verovio 6.3.0.
- New API: `version()`, `convert()` (to MEI or PAE), and `available-options()`.
- The Verovio options reference is now generated from `available-options()`.

*v0.1.3 — 2026-06-21*
- WASM-safety patches for exception-raising Verovio code paths (including the tuning library).

*v0.1.2 — 2026-05-31*
- Renamed the API to `score` / `pages`; both kebab-case and camelCase option keys accepted.
- Added Plaine & Easie (PAE) and EsAC input formats.
- Enum options passed as integers to avoid a WASM hang; Verovio logs forwarded to Typst.

*v0.1.1 — 2026-04-15*
- Renamed the package to scoryst; note-head position fix for upward stems.

*v0.1.0 — 2026-04-04*
- Initial release: Verovio-based engraving of MusicXML, MEI, ABC, Humdrum, and CMME.

#pagebreak()

= Appendix: Complete Verovio Options <appendix-options>

Every Verovio option, grouped by category, generated at compile time from
`available-options()` (Verovio #version()). Command-line-only options are
omitted. Enum options list their accepted values in the description.

#set text(size: 8.5pt)
#for (gid, grp) in available-options().at("groups").pairs().sorted(key: p => p.at(0)) {
  let opts = grp.at("options").pairs().filter(((k, o)) => not o.at("cmdOnly", default: false))
  if opts.len() == 0 { continue }
  heading(level: 2, grp.at("name"))
  _opt-table(opts)
}
#set text(size: 11pt)
