#import "../pkg/scoryst.typ": score, pages
#set page(width: 210mm, height: 297mm, margin: 15mm)
#set text(size: 9pt)

#let long-abc = "X:1\nT:Test Score\nM:4/4\nK:C\nL:1/8\nw:do re mi fa sol la si do re mi fa sol la si do re\nCDEF GABc|cBAG FEDC|CDEF GABc|cBAG FEDC|\nw:do re mi fa sol la si do re mi fa sol la si do re\nEFGA Bcde|edcB AGFE|EFGA Bcde|edcB AGFE|"
#let lyric-abc = "X:1\nM:4/4\nK:C\nw:a~le~lu~ia do~mi~nus\nCDEF GABc|"
#let rest-abc = "X:1\nM:4/4\nK:C\nz4|z4|z4|z4|CDEF|"
#let test-scope = (score: score, pages: pages, read: read, long-abc: long-abc, lyric-abc: lyric-abc, rest-abc: rest-abc)
#show raw.where(lang: "test"): it => {
  let code = it.text
  raw(block: true, lang: "typst", code)
  v(-0.5em)
  block(clip: true, height: 10em,
    eval(code, mode: "markup", scope: test-scope)
  )
}

== `breaks`
````test
#score(long-abc, options: (breaks: "none"), width: 100%)
````
````test
#score(long-abc, options: (breaks: "auto"), width: 100%)
````
````test
#score(long-abc, options: (breaks: "line"), width: 100%)
````
````test
#score(long-abc, options: (breaks: "encoded"), width: 100%)
````

== `scale`
````test
#score(long-abc, options: (scale: 50), width: 100%)
````
````test
#score(long-abc, options: (scale: 100), width: 100%)
````
````test
#score(long-abc, options: (scale: 150), width: 100%)
````

== `font`
````test
#score(long-abc, options: (font: "Leipzig"), width: 100%)
````
````test
#score(long-abc, options: (font: "Bravura"), width: 100%)
````
````test
#score(long-abc, options: (font: "Petaluma"), width: 100%)
````

== `page-width`
````test
#score(long-abc, options: (page-width: 1000), width: 100%)
````
````test
#score(long-abc, options: (page-width: 3000), width: 100%)
````

== `adjust-page-width`
````test
#score(long-abc, options: (adjust-page-width: true), width: 100%)
````

== `landscape`
````test
#score(long-abc, options: (landscape: true), width: 100%)
````

== `spacing-staff`
````test
#score(long-abc, options: (spacing-staff: 4), width: 100%)
````
````test
#score(long-abc, options: (spacing-staff: 24), width: 100%)
````

== `spacing-linear`
````test
#score(long-abc, options: (spacing-linear: 0.1), width: 100%)
````
````test
#score(long-abc, options: (spacing-linear: 0.5), width: 100%)
````

== `header`
````test
#score(long-abc, options: (header: "none"), width: 100%)
````
````test
#score(long-abc, options: (header: "auto"), width: 100%)
````

== `footer`
````test
#score(long-abc, options: (footer: "none"), width: 100%)
````
````test
#score(long-abc, options: (footer: "auto"), width: 100%)
````

== `condense`
````test
#score(long-abc, options: (condense: "none"), width: 100%)
````
````test
#score(long-abc, options: (condense: "auto"), width: 100%)
````

== `stem-width`
````test
#score(long-abc, options: (stem-width: 0.1), width: 100%)
````
````test
#score(long-abc, options: (stem-width: 0.5), width: 100%)
````

== `bar-line-width`
````test
#score(long-abc, options: (bar-line-width: 0.1), width: 100%)
````
````test
#score(long-abc, options: (bar-line-width: 0.8), width: 100%)
````

== `staff-line-width`
````test
#score(long-abc, options: (staff-line-width: 0.05), width: 100%)
````
````test
#score(long-abc, options: (staff-line-width: 0.4), width: 100%)
````

== `lyric-elision`
````test
#score(lyric-abc, options: (lyric-elision: "regular"), width: 100%)
````
````test
#score(lyric-abc, options: (lyric-elision: "narrow"), width: 100%)
````
````test
#score(lyric-abc, options: (lyric-elision: "wide"), width: 100%)
````

== `lyric-size`
````test
#score(lyric-abc, options: (lyric-size: 3.0), width: 100%)
````
````test
#score(lyric-abc, options: (lyric-size: 6.0), width: 100%)
````

== `svg-view-box`
````test
#score(long-abc, options: (svg-view-box: true), width: 100%)
````
````test
#score(long-abc, options: (svg-view-box: false), width: 100%)
````

== `remove-ids`
````test
#score(long-abc, options: (remove-ids: true), width: 100%)
````

== `transpose`
````test
#score(long-abc, options: (transpose: "M2"), width: 100%)
````
````test
#score(long-abc, options: (transpose: "-P5"), width: 100%)
````

== `system-divider`
````test
#score(long-abc, options: (system-divider: "none"), width: 100%)
````
````test
#score(long-abc, options: (system-divider: "auto"), width: 100%)
````
````test
#score(long-abc, options: (system-divider: "left"), width: 100%)
````

== `pedal-style`
````test
#score(long-abc, options: (pedal-style: "auto"), width: 100%)
````
````test
#score(long-abc, options: (pedal-style: "line"), width: 100%)
````

== `multi-rest-style`
````test
#score(rest-abc, options: (multi-rest-style: "auto"), width: 100%)
````
````test
#score(rest-abc, options: (multi-rest-style: "default"), width: 100%)
````
````test
#score(rest-abc, options: (multi-rest-style: "block"), width: 100%)
````
````test
#score(rest-abc, options: (multi-rest-style: "symbols"), width: 100%)
````

== `font-fallback`
````test
#score(long-abc, options: (font-fallback: "Leipzig"), width: 100%)
````
````test
#score(long-abc, options: (font-fallback: "Bravura"), width: 100%)
````

== `smufl-text-font`
````test
#score(long-abc, options: (smufl-text-font: "embedded"), width: 100%)
````
````test
#score(long-abc, options: (smufl-text-font: "linked"), width: 100%)
````
````test
#score(long-abc, options: (smufl-text-font: "none"), width: 100%)
````

== `hairpin-size`
````test
#score(long-abc, options: (hairpin-size: 2.0), width: 100%)
````
````test
#score(long-abc, options: (hairpin-size: 5.0), width: 100%)
````

== `unit`
````test
#score(long-abc, options: (unit: 6), width: 100%)
````
````test
#score(long-abc, options: (unit: 12), width: 100%)
````

== Combined options
````test
#score(long-abc, options: (breaks: "auto", scale: 70, font: "Leland", header: "none", footer: "none"), width: 100%)
````
