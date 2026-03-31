#import "@local/verovio:0.1.0": render-music, music-page-count
#set page(width: 210mm, height: 297mm, margin: 15mm)
#set text(size: 11pt)

#align(center)[
  #text(size: 20pt, weight: "bold")[Verovio — Music Notation Plugin for Typst]
]

#v(1em)

Verovio renders music notation from multiple formats directly in Typst documents.

= Supported Formats

== 1. ABC Notation

ABC is a compact text-based format popular for folk and classical melodies.
Chord symbols are supported.

#render-music(read("scarborough-fair.abc"), width: 100%)

More complex pieces with fast arpeggiated patterns:

#render-music(read("bach-prelude-cmaj.abc"), width: 100%)

#pagebreak()

== 2. MusicXML

MusicXML is the standard interchange format for music notation software.
It supports grand staff, multiple voices, and full score layout.

#render-music(read("adagio.xml"), width: 100%)

#pagebreak()

== 3. MEI (Music Encoding Initiative)

MEI is a rich XML-based format used in musicology. It supports lyrics,
polyphonic textures, fermatas, and detailed editorial markup.

#render-music(read("sample-mei.mei"), width: 100%)

#pagebreak()

== 4. Humdrum

Humdrum is a toolkit and format for music analysis. It uses a tab-separated
spine structure with `**kern` encoding for pitches and durations.

#render-music(read("sample-humdrum.krn"), width: 100%)

#pagebreak()

= Music Fonts

Five SMuFL-compliant music fonts are available.

#let sample = read("scarborough-fair.abc")

#for font in ("Leipzig", "Bravura", "Gootville", "Leland", "Petaluma") {
  [== #font]
  render-music(sample, options: (font: font, scale: 40), width: 100%)
}

#pagebreak()

= Verovio Options

Options can be passed as a dictionary. For example, scaling:

#render-music(read("scarborough-fair.abc"), options: (scale: 50), width: 100%)

Page height is automatically adjusted to fit content (`adjustPageHeight: true`
is the default). You can override it:

#render-music(read("scarborough-fair.abc"), options: (adjustPageHeight: false), width: 100%)

= Multi-page Documents

For longer scores, use `music-page-count` and the `page` parameter:

#let data = read("adagio.xml")
#let pages = music-page-count(data)
This score has #pages page(s).
