![logo](test/logo.svg)

# Scoryst - Music Engraving Plugin for Typst

A Typst plugin to render music notation from multiple formats using
[Verovio](https://www.verovio.org/), compiled to WASM.

## Features

- **8 input formats**: [ABC](https://en.wikipedia.org/wiki/ABC_notation), [MusicXML](https://en.wikipedia.org/wiki/MusicXML), [MEI](https://music-encoding.org/), [Humdrum](https://wiki.ccarh.org/images/6/6e/Humdrum-File-Format.pdf), [EsAC](https://wiki.ccarh.org/wiki/EsAC), [PAE](https://www.iaml.info/plaine-easie-code/), [Volpiano](https://cantusdatabase.org/static/documents/2.%20Volpiano%20Protocols.pdf), [CMME](https://www.cmme.org/)
- **Automatic format detection**: all 8 formats are detected from the data
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

// Auto-render fenced code blocks of any supported format
#import "@preview/scoryst:0.2.0": render-blocks
#show: render-blocks
```

Once `render-blocks` is enabled, a fenced block in a supported language
renders directly as a score:

````typ
```abc
X:1
K:C
CDEF|GABc|
```
````

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

The full option catalogue from the bundled Verovio follows (command-line-only options omitted). Keys are shown in camelCase; the kebab-case form works too.

#### Base short options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `inputFrom` | string | `"mei"` | Select input format from: "abc", "cmme.xml", "darms", "esac", "gabc", "humdrum", "mei", "pae", "volpiano", "xml" (musicxml), "musicxml-hum" (musicxml via humdrum) or "mei-pb-serialized" |
| `scale` | int | `100` | Scale of the output in percent (100 is normal size) |
| `xmlIdSeed` | int | `0` | Seed the random number generator for XML IDs (default is random) |

#### Input and page configuration options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `adjustPageHeight` | bool | false | Adjust the page height to the height of the content |
| `adjustPageWidth` | bool | false | Adjust the page width to the width of the content |
| `breaks` | enum | `""` | Define page and system breaks layout |
| `breaksSmartSb` | double | `0.66` | In smart breaks mode, the portion of system width usage at which an encoded sb will be used |
| `condense` | enum | `""` | Control condensed score layout |
| `condenseFirstPage` | bool | false | When condensing a score also condense the first page |
| `condenseNotLastSystem` | bool | false | When condensing a score never condense the last system |
| `condenseTempoPages` | bool | false | When condensing a score also condense pages with a tempo change |
| `evenNoteSpacing` | bool | false | Align notes and rests without adding duration based space |
| `footer` | enum | `""` | Control footer layout |
| `header` | enum | `""` | Control header layout |
| `humType` | bool | false | Include type attributes when importing from Humdrum |
| `incip` | bool | false | Read <incip> elements as data input |
| `justifyVertically` | bool | false | Justify spacing vertically to fill the page |
| `landscape` | bool | false | Swap the values for page height and page width |
| `minLastJustification` | double | `0.8` | The last system is only justified if the unjustified width is greater than this percent |
| `mmOutput` | bool | false | Specify that the output in the SVG is given in mm (default is px) |
| `moveScoreDefinitionToStaff` | bool | false | Move score definition (clef, keySig, meterSig, etc.) from scoreDef to staffDef |
| `neumeAsNote` | bool | false | Render neumes as note heads instead of original notation |
| `noJustification` | bool | false | Do not justify the system |
| `openControlEvents` | bool | false | Render open control events |
| `outputFormatRaw` | bool | false | Writes MEI out with no line indenting or non-content newlines. |
| `outputIndent` | int | `3` | Output indentation value for MEI and SVG |
| `outputIndentTab` | bool | false | Output indentation with tabulation for MEI and SVG |
| `outputSmuflXmlEntities` | bool | false | Output SMuFL characters as XML entities instead of hex byte codes |
| `pageHeight` | int | `2970` | The page height |
| `pageMarginBottom` | int | `50` | The page bottom margin |
| `pageMarginLeft` | int | `50` | The page left margin |
| `pageMarginRight` | int | `50` | The page right margin |
| `pageMarginTop` | int | `50` | The page top margin |
| `pageWidth` | int | `2100` | The page width |
| `pedalStyle` | enum | `""` | The global pedal style |
| `preserveAnalyticalMarkup` | bool | false | Preserves the analytical markup in MEI |
| `removeIds` | bool | false | Remove XML IDs in the MEI output that are not referenced |
| `scaleToPageSize` | bool | false | Scale the content within the page instead of scaling the page itself |
| `setLocale` | bool | false | Changes the global locale to C (this is not thread-safe) |
| `showHidden` | bool | false | Display <space>, <mSpace> and invisible or gestural elements |
| `showRuntime` | bool | false | Display the total runtime on command-line |
| `shrinkToFit` | bool | false | Scale down page content to fit the page height if needed |
| `smuflTextFont` | enum | `""` | Specify if the smufl text font is embedded, linked, or ignored |
| `staccatoCenter` | bool | false | Align staccato and staccatissimo articulations with center of the note |
| `svgAdditionalAttribute` | array | `[]` | Add additional attribute for graphical elements in SVG as "data-*", for example, "note@pname" would add a "data-pname" to all note elements |
| `svgBoundingBoxes` | bool | false | Include bounding boxes in SVG output |
| `svgContentBoundingBoxes` | bool | false | Include content bounding boxes in SVG output |
| `svgCss` | string | `""` | CSS (as a string) to be added to the SVG output |
| `svgFormatRaw` | bool | false | Writes SVG out with no line indenting or non-content newlines |
| `svgHtml5` | bool | false | Write data-id and data-class attributes for JS usage and id clash avoidance |
| `svgRemoveXlink` | bool | false | Removes the xlink: prefix on href attributes for compatibility with some newer browsers |
| `svgViewBox` | bool | false | Use viewBox on svg root element for easy scaling of document |
| `unit` | double | `9.0` | The MEI unit (1⁄2 of the distance between the staff lines) |
| `useBraceGlyph` | bool | false | Use brace glyph from current font |
| `useFacsimile` | bool | false | Use information in the <facsimile> element to control the layout |
| `usePgFooterForAll` | bool | false | Use the pgFooter for all pages |
| `usePgHeaderForAll` | bool | false | Use the pgHeader for all pages |
| `xmlIdChecksum` | bool | false | Seed the generator for XML IDs using the checksum of the input data |

#### General layout options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `barLineSeparation` | double | `0.8` | The default distance between multiple barlines when locked together |
| `barLineWidth` | double | `0.3` | The barline width |
| `beamFrenchStyle` | bool | false | For notes in beams, stems will stop at first outermost sub-beam without crossing it |
| `beamMaxSlope` | int | `10` | The maximum beam slope |
| `beamMixedPreserve` | bool | false | Mixed beams will be drawn even if there is not enough space |
| `beamMixedStemMin` | double | `3.5` | The minimal stem length in MEI units used to draw mixed beams |
| `bracketThickness` | double | `1.0` | The thickness of the system bracket |
| `breaksNoWidow` | bool | false | Prevent single measures on the last page by fitting it into previous system |
| `dashedBarLineDashLength` | double | `1.14` | The dash length of dashed barlines |
| `dashedBarLineGapLength` | double | `1.14` | The gap length of dashed barlines |
| `dynamDist` | double | `1.0` | The default distance from the staff for dynamic marks |
| `dynamSingleGlyphs` | bool | false | Don't use SMuFL's predefined dynamics glyph combinations |
| `engravingDefaults` |  | `""` | Json describing defaults for engraving SMuFL elements |
| `extenderLineMinSpace` | double | `1.5` | Minimum space required for extender line to be drawn |
| `fingeringScale` | double | `0.75` | The scale of fingering font compared to default font size |
| `font` | string | `"Leipzig"` | Set the music font |
| `fontAddCustom` | array | `[]` | Add a custom music font as zip file |
| `fontFallback` | enum | `""` | The music font fallback for missing glyphs |
| `fontLoadAll` | bool | false | Load all music fonts |
| `fontTextLiberation` | bool | false | Use the Liberation text font |
| `graceFactor` | double | `0.75` | The grace size ratio numerator |
| `graceRhythmAlign` | bool | false | Align grace notes rhythmically with all staves |
| `graceRightAlign` | bool | false | Align the right position of a grace group with all staves |
| `hairpinSize` | double | `3.0` | The hairpin size in MEI units |
| `hairpinThickness` | double | `0.2` | The thickness of the hairpin |
| `handwrittenFont` | array | `[]` | Fonts that emulate hand writing and require special handling |
| `harmDist` | double | `1.0` | The default distance from the staff of harmonic indications |
| `justificationBraceGroup` | double | `1.0` | Space between staves inside a braced group justification |
| `justificationBracketGroup` | double | `1.0` | Space between staves inside a bracketed group justification |
| `justificationMaxVertical` | double | `0.2` | Maximum ratio of justifiable height to page height that can be used for the vertical justification |
| `justificationStaff` | double | `1.0` | The staff justification |
| `justificationSystem` | double | `1.0` | The system spacing justification |
| `ledgerLineExtension` | double | `0.54` | The amount by which a ledger line should extend either side of a notehead |
| `ledgerLineThickness` | double | `0.25` | The thickness of the ledger lines |
| `lyricElision` | enum | `""` | The lyric elision width |
| `lyricHeightFactor` | double | `1.0` | The lyric verse line height factor |
| `lyricLineThickness` | double | `0.25` | The lyric extender line thickness |
| `lyricNoStartHyphen` | bool | false | Do not show hyphens at the beginning of a system |
| `lyricSize` | double | `4.5` | The lyrics size in MEI units |
| `lyricTopMinMargin` | double | `2.0` | The minmal margin above the lyrics in MEI units |
| `lyricVerseCollapse` | bool | false | Collapse empty verse lines in lyrics |
| `lyricWordSpace` | double | `1.2` | The lyric word space length |
| `measureMinWidth` | int | `15` | The minimal measure width in MEI units |
| `mnumInterval` | int | `0` | How frequently to place measure numbers |
| `multiRestStyle` | enum | `""` | Rendering style of multiple measure rests |
| `multiRestThickness` | double | `2.0` | The thickness of the multi rest in MEI units |
| `octaveAlternativeSymbols` | bool | false | Use alternative symbols for displaying octaves |
| `octaveLineThickness` | double | `0.2` | The thickness of the line used for an octave line |
| `octaveNoSpanningParentheses` | bool | false | Do not enclose octaves that are spanning over systems with parentheses. |
| `ossiaStaffSize` | double | `0.75` | The ossia staff size in relation to the staff size |
| `pedalLineThickness` | double | `0.2` | The thickness of the line used for piano pedaling |
| `repeatBarLineDotSeparation` | double | `0.36` | The default horizontal distance between the dots and the inner barline of a repeat barline |
| `repeatEndingLineThickness` | double | `0.15` | Repeat and ending line thickness |
| `slurCurveFactor` | double | `1.0` | Slur curve factor - high value means rounder slurs |
| `slurEndpointFlexibility` | double | `0.0` | Slur endpoint flexibility - allow more endpoint movement during adjustment |
| `slurEndpointThickness` | double | `0.1` | The endpoint slur thickness in MEI units |
| `slurMargin` | double | `1.0` | Slur safety distance in MEI units to obstacles |
| `slurMaxSlope` | int | `60` | The maximum slur slope in degrees |
| `slurMidpointThickness` | double | `0.6` | The midpoint slur thickness in MEI units |
| `slurSymmetry` | double | `0.0` | Slur symmetry - high value means more symmetric slurs |
| `spacingBraceGroup` | int | `12` | Minimum space between staves inside a braced group in MEI units |
| `spacingBracketGroup` | int | `12` | Minimum space between staves inside a bracketed group in MEI units |
| `spacingDurDetection` | bool | false | Detect long duration for adjusting spacing |
| `spacingLinear` | double | `0.25` | Specify the linear spacing factor |
| `spacingNonLinear` | double | `0.6` | Specify the non-linear spacing factor |
| `spacingOssia` | double | `0.35` | Specify the factor of an ossia spacing in relation to staff spacing |
| `spacingStaff` | int | `12` | The staff minimal spacing in MEI units |
| `spacingSystem` | int | `4` | The system minimal spacing in MEI units |
| `staffLineWidth` | double | `0.15` | The staff line width in MEI units |
| `stemWidth` | double | `0.2` | The stem width |
| `subBracketThickness` | double | `0.2` | The thickness of system sub-bracket |
| `systemDivider` | enum | `""` | The display of system dividers |
| `systemMaxPerPage` | int | `0` | Maximum number of systems per page |
| `textEnclosureThickness` | double | `0.2` | The thickness of the line text enclosing box |
| `thickBarlineThickness` | double | `1.0` | The thickness of the thick barline |
| `tieEndpointThickness` | double | `0.1` | The Endpoint tie thickness in MEI units |
| `tieMidpointThickness` | double | `0.5` | The midpoint tie thickness in MEI units |
| `tieMinLength` | double | `2.0` | The minimum length of tie in MEI units |
| `tupletAngledOnBeams` | bool | false | Tuplet brackets angled on beams only |
| `tupletBracketThickness` | double | `0.2` | The thickness of the tuplet bracket |
| `tupletNumHead` | bool | false | Placement of tuplet number on the side of the note head |

#### Loading selectors and processing

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `appXPathQuery` | array | `[]` | Set the xPath query for selecting <app> child elements, for example: "./rdg[contains(@source, 'source-id')]"; by default the <lem> or the first <rdg> is selected |
| `choiceXPathQuery` | array | `[]` | Set the xPath query for selecting <choice> child elements, for example: "./orig"; by default the first child is selected |
| `expand` | string | `""` | Expand all referenced elements in the expansion <xml:id> |
| `expandAlways` | bool | false | Expand for all outputs, using selected, first, or generated expansion |
| `expandNever` | bool | false | Expand for no output, including MIDI and timemap |
| `loadSelectedMdivOnly` | bool | false | Load only the selected mdiv; the content of the other is skipped |
| `mdivAll` | bool | false | Load and render all <mdiv> elements in the MEI files |
| `mdivXPathQuery` | string | `""` | Set the xPath query for selecting the <mdiv> to be rendered; only one <mdiv> can be rendered |
| `ossiaHidden` | bool | false | Hide ossias when rendering |
| `substXPathQuery` | array | `[]` | Set the xPath query for selecting <subst> child elements, for example: "./del"; by default the first child is selected |
| `transpose` | string | `""` | Transpose the entire content |
| `transposeMdiv` |  | `""` | Json mapping the mdiv ids to the corresponding transposition |
| `transposeSelectedOnly` | bool | false | Transpose only the selected content and ignore unselected editorial content |
| `transposeToSoundingPitch` | bool | false | Transpose to sounding pitch by evaluating @trans.semi |

#### Element margins

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `bottomMarginArtic` | double | `0.75` | The margin for artic in MEI units |
| `bottomMarginHarm` | double | `1.0` | The margin for harm in MEI units |
| `bottomMarginHeader` | double | `2.0` | The margin for header in MEI units |
| `bottomMarginOctave` | double | `1.0` | The margin for octave in MEI units |
| `defaultBottomMargin` | double | `0.5` | The default bottom margin |
| `defaultLeftMargin` | double | `0.0` | The default left margin |
| `defaultRightMargin` | double | `0.0` | The default right margin |
| `defaultTopMargin` | double | `0.5` | The default top margin |
| `leftMarginAccid` | double | `1.0` | The margin for accid in MEI units |
| `leftMarginBarLine` | double | `0.0` | The margin for barLine in MEI units |
| `leftMarginBeatRpt` | double | `2.0` | The margin for beatRpt in MEI units |
| `leftMarginChord` | double | `1.0` | The margin for chord in MEI units |
| `leftMarginClef` | double | `1.0` | The margin for clef in MEI units |
| `leftMarginKeySig` | double | `1.0` | The margin for keySig in MEI units |
| `leftMarginLeftBarLine` | double | `1.0` | The margin for left barLine in MEI units |
| `leftMarginMRest` | double | `0.0` | The margin for mRest in MEI units |
| `leftMarginMRpt2` | double | `0.0` | The margin for mRpt2 in MEI units |
| `leftMarginMensur` | double | `1.0` | The margin for mensur in MEI units |
| `leftMarginMeterSig` | double | `1.0` | The margin for meterSig in MEI units |
| `leftMarginMultiRest` | double | `0.0` | The margin for multiRest in MEI units |
| `leftMarginMultiRpt` | double | `0.0` | The margin for multiRpt in MEI units |
| `leftMarginNote` | double | `1.0` | The margin for note in MEI units |
| `leftMarginRest` | double | `1.0` | The margin for rest in MEI units |
| `leftMarginRightBarLine` | double | `1.0` | The margin for right barLine in MEI units |
| `leftMarginTabDurSym` | double | `1.0` | The margin for tabDurSym in MEI units |
| `rightMarginAccid` | double | `0.5` | The right margin for accid in MEI units |
| `rightMarginBarLine` | double | `0.0` | The right margin for barLine in MEI units |
| `rightMarginBeatRpt` | double | `0.0` | The right margin for beatRpt in MEI units |
| `rightMarginChord` | double | `0.0` | The right margin for chord in MEI units |
| `rightMarginClef` | double | `1.0` | The right margin for clef in MEI units |
| `rightMarginKeySig` | double | `1.0` | The right margin for keySig in MEI units |
| `rightMarginLeftBarLine` | double | `1.0` | The right margin for left barLine in MEI units |
| `rightMarginMRest` | double | `0.0` | The right margin for mRest in MEI units |
| `rightMarginMRpt2` | double | `0.0` | The right margin for mRpt2 in MEI units |
| `rightMarginMensur` | double | `1.0` | The right margin for mensur in MEI units |
| `rightMarginMeterSig` | double | `1.0` | The right margin for meterSig in MEI units |
| `rightMarginMultiRest` | double | `0.0` | The right margin for multiRest in MEI units |
| `rightMarginMultiRpt` | double | `0.0` | The right margin for multiRpt in MEI units |
| `rightMarginNote` | double | `0.0` | The right margin for note in MEI units |
| `rightMarginRest` | double | `0.0` | The right margin for rest in MEI units |
| `rightMarginRightBarLine` | double | `0.0` | The right margin for right barLine in MEI units |
| `rightMarginTabDurSym` | double | `0.0` | The right margin for tabDurSym in MEI units |
| `topMarginArtic` | double | `0.75` | The margin for artic in MEI units |
| `topMarginHarm` | double | `1.0` | The margin for harm in MEI units |
| `topMarginPgFooter` | double | `2.0` | The margin for footer in MEI units |

#### Midi options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `midiNoCue` | bool | false | Skip cue notes in MIDI output |
| `midiTempoAdjustment` | double | `1.0` | The MIDI tempo adjustment factor |
| `tuningFile` | string | `""` | A custom tuning definition or filepath to apply to the MIDI output |

#### Mensural notation options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `durationEquivalence` | enum | `""` | The mensural duration equivalence |
| `ligatureAsBracket` | bool | false | Render ligatures as bracket instead of original notation |
| `ligatureOblique` | enum | `""` | Ligature oblique shape |
| `mensuralResponsiveView` | enum | `""` | Make mensural content responsive (selection discards ligatures and editorial markup) |
| `mensuralScoreUp` | bool | false | Score up the mensural voices by providing a dur.quality to the notes |
| `mensuralToCmn` | bool | false | Convert mensural sections to CMN measure-based MEI |

#### Method JSON options for the command-line

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `timemapOptions` | string | `"{}"` | The JSON options to be passed when producing the timemap |

#### Neumatic notation options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `gabcAquitanianContext` | bool | false | Render the GABC `V` left-stem (grule virga_left) using tilt="ne" instead of the default tilt="n" used for square notation. |
| `gabcExtendedSymbols` | bool | false | Enable the S-GABC proposed symbols: `r` for uncertain reading and `"` for clarifying lines |
| `gabcStaffLines` | int | `4` | Number of staff lines for GABC import (the GABC `staff-lines:` header value) |
| `liquescentWithoutTails` | bool | false | Render liquescent head without tails |

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
