#!/usr/bin/env python3
"""MEI fuzzer: generate MEI variants and check for WASM crashes."""

import itertools
import subprocess
import sys
import tempfile
import os

DURATIONS = ["long", "breve", "1", "2", "4", "8", "16", "32", "64", "128"]
ACCIDENTALS = [None, "s", "f", "n", "x", "ss", "ff"]
ELEMENT_TYPES = ["note", "rest", "mRest", "space"]
OCTAVES = ["3", "4", "5"]
PITCHES = ["c", "d", "e", "f", "g", "a", "b"]
CLEFS = [("G", "2"), ("F", "4"), ("C", "3")]
METERS = [("4", "4"), ("3", "4"), ("6", "8"), ("2", "2")]

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TYP_TEMPLATE = '#import "../pkg/scoryst.typ": score\n#score(read("{mei_file}"))\n'

def make_element(etype, dur="4", pname="c", oct="4", accid=None, stem_dir=None):
    if etype == "rest":
        return f'<rest dur="{dur}"/>'
    if etype == "mRest":
        return '<mRest/>'
    if etype == "space":
        return f'<space dur="{dur}"/>'
    attrs = f'dur="{dur}" pname="{pname}" oct="{oct}"'
    if accid:
        attrs += f' accid="{accid}"'
    if stem_dir:
        attrs += f' stem.dir="{stem_dir}"'
    return f'<note {attrs}/>'

def make_layer(elements, n=1):
    inner = "\n".join(elements)
    return f'<layer n="{n}">\n{inner}\n</layer>'

def make_mei(layers, clef=("G", "2"), meter=("4", "4")):
    layers_xml = "\n".join(layers)
    return f"""<mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.1">
<music><body><mdiv><score>
<scoreDef meter.count="{meter[0]}" meter.unit="{meter[1]}">
<staffGrp><staffDef n="1" lines="5" clef.shape="{clef[0]}" clef.line="{clef[1]}"/></staffGrp>
</scoreDef>
<section>
<measure>
<staff>
{layers_xml}
</staff>
</measure>
</section>
</score></mdiv></body></music>
</mei>"""

def run_test(mei_xml, label):
    mei_path = os.path.join(ROOT, "test", "_fuzz.xml")
    typ_path = os.path.join(ROOT, "test", "_fuzz.typ")
    pdf_path = os.path.join(ROOT, "test", "_fuzz.pdf")

    with open(mei_path, "w") as f:
        f.write(mei_xml)
    with open(typ_path, "w") as f:
        f.write(TYP_TEMPLATE.format(mei_file="_fuzz.xml"))

    result = subprocess.run(
        ["typst", "compile", "--root", ROOT, typ_path, pdf_path],
        capture_output=True, text=True, timeout=30
    )

    if result.returncode != 0:
        if "unreachable" in result.stderr:
            return "CRASH"
        return "ERROR"
    return "OK"

def test_durations_multilayer():
    """Test all durations in multi-layer with rests."""
    print("\n=== Durations in multi-layer (rest in layer 2) ===")
    for dur in DURATIONS:
        layer1 = make_layer([make_element("note", dur=dur)] * 2, n=1)
        layer2 = make_layer([make_element("note", dur=dur), make_element("rest", dur=dur)], n=2)
        mei = make_mei([layer1, layer2])
        label = f"dur={dur}"
        status = run_test(mei, label)
        print(f"  {status:5s}  {label}")

def test_accidentals_multilayer():
    """Test accidentals on notes adjacent to rests in other layers."""
    print("\n=== Accidentals adjacent to rest (2 layers) ===")
    for accid in ACCIDENTALS:
        layer1 = make_layer([
            make_element("note", accid=accid, pname="f", oct="4"),
            make_element("note", accid=accid, pname="f", oct="4"),
        ], n=1)
        layer2 = make_layer([
            make_element("rest"),
            make_element("note", pname="c", oct="4"),
        ], n=2)
        mei = make_mei([layer1, layer2])
        label = f"accid={accid}"
        status = run_test(mei, label)
        print(f"  {status:5s}  {label}")

def test_element_types_multilayer():
    """Test different element types in multi-layer."""
    print("\n=== Element types in layer 2 (with note in layer 1) ===")
    for etype in ELEMENT_TYPES:
        layer1 = make_layer([make_element("note")] * 4, n=1)
        if etype == "mRest":
            layer2 = make_layer([make_element(etype)], n=2)
        else:
            layer2 = make_layer([make_element(etype)] * 4, n=2)
        mei = make_mei([layer1, layer2])
        label = f"type={etype}"
        status = run_test(mei, label)
        print(f"  {status:5s}  {label}")

def test_three_layers():
    """Test 3 layers with rests."""
    print("\n=== Three layers with rests ===")
    for rest_layer in [1, 2, 3]:
        layers = []
        for n in range(1, 4):
            if n == rest_layer:
                elems = [make_element("note"), make_element("rest"), make_element("note"), make_element("rest")]
            else:
                elems = [make_element("note", pname=["c","e","g"][n-1], oct="4")] * 4
            layers.append(make_layer(elems, n=n))
        mei = make_mei(layers)
        label = f"rest_in_layer={rest_layer}"
        status = run_test(mei, label)
        print(f"  {status:5s}  {label}")

def test_rest_durations_all():
    """Test every rest duration in a 2-layer context."""
    print("\n=== All rest durations in layer 2 (note in layer 1) ===")
    for dur in DURATIONS:
        layer1 = make_layer([make_element("note", dur=dur, pname="g", oct="5")] * 2, n=1)
        layer2 = make_layer([make_element("rest", dur=dur)] * 2, n=2)
        mei = make_mei([layer1, layer2])
        label = f"rest_dur={dur}"
        status = run_test(mei, label)
        print(f"  {status:5s}  {label}")

def test_mixed_durations():
    """Test mixing different durations between layers."""
    print("\n=== Mixed durations between layers ===")
    combos = [("4", "8"), ("2", "16"), ("1", "4"), ("breve", "4"), ("long", "4"),
              ("8", "32"), ("4", "128"), ("2", "long")]
    for d1, d2 in combos:
        layer1 = make_layer([make_element("note", dur=d1, pname="g", oct="5")], n=1)
        layer2 = make_layer([make_element("rest", dur=d2)], n=2)
        mei = make_mei([layer1, layer2])
        label = f"layer1={d1} layer2_rest={d2}"
        status = run_test(mei, label)
        print(f"  {status:5s}  {label}")

def test_clefs():
    """Test different clefs with multi-layer rests."""
    print("\n=== Clefs with multi-layer rests ===")
    for shape, line in CLEFS:
        layer1 = make_layer([make_element("note")] * 4, n=1)
        layer2 = make_layer([make_element("note"), make_element("rest"), make_element("rest"), make_element("note")], n=2)
        mei = make_mei([layer1, layer2], clef=(shape, line))
        label = f"clef={shape}{line}"
        status = run_test(mei, label)
        print(f"  {status:5s}  {label}")

def test_noteheads():
    """Test special noteheads (like x from the original issue)."""
    print("\n=== Special noteheads with multi-layer rests ===")
    shapes = [None, "x", "+", "diamond", "triangle", "slash"]
    for shape in shapes:
        head_attr = f' head.shape="{shape}"' if shape else ""
        note_xml = f'<note dur="4" pname="f" oct="5"{head_attr}/>'
        layer1 = make_layer([note_xml] * 4, n=1)
        layer2 = make_layer([make_element("note"), make_element("rest"), make_element("note"), make_element("rest")], n=2)
        mei = make_mei([layer1, layer2])
        label = f"head.shape={shape}"
        status = run_test(mei, label)
        print(f"  {status:5s}  {label}")

def test_extreme_octaves():
    """Test extreme octaves in multi-layer."""
    print("\n=== Extreme octaves with rests ===")
    for oct in ["1", "2", "3", "4", "5", "6", "7", "8"]:
        layer1 = make_layer([make_element("note", pname="c", oct=oct)] * 2, n=1)
        layer2 = make_layer([make_element("rest"), make_element("note", pname="c", oct=oct)], n=2)
        mei = make_mei([layer1, layer2])
        label = f"oct={oct}"
        status = run_test(mei, label)
        print(f"  {status:5s}  {label}")

def test_beams_with_rests():
    """Test beamed notes with rests in another layer."""
    print("\n=== Beams with rests in other layer ===")
    beam_xml = '<beam><note dur="8" pname="c" oct="5"/><note dur="8" pname="d" oct="5"/></beam>'
    layer1 = make_layer([beam_xml, beam_xml], n=1)
    layer2 = make_layer([make_element("rest", dur="8")] * 4, n=2)
    mei = make_mei([layer1, layer2])
    status = run_test(mei, "beams+rests")
    print(f"  {status:5s}  beams+rests")

def test_chords_with_rests():
    """Test chords with rests in another layer."""
    print("\n=== Chords with rests in other layer ===")
    chord_xml = '<chord dur="4"><note pname="c" oct="4"/><note pname="e" oct="4"/><note pname="g" oct="4"/></chord>'
    layer1 = make_layer([chord_xml] * 4, n=1)
    layer2 = make_layer([make_element("rest")] * 4, n=2)
    mei = make_mei([layer1, layer2])
    status = run_test(mei, "chords+rests")
    print(f"  {status:5s}  chords+rests")

def test_tuplets_with_rests():
    """Test tuplets with rests."""
    print("\n=== Tuplets with rests ===")
    tuplet_xml = '<tuplet num="3" numbase="2"><note dur="8" pname="c" oct="4"/><note dur="8" pname="d" oct="4"/><note dur="8" pname="e" oct="4"/></tuplet>'
    layer1 = make_layer([tuplet_xml, tuplet_xml], n=1)
    layer2 = make_layer([make_element("rest", dur="4"), make_element("rest", dur="4")], n=2)
    mei = make_mei([layer1, layer2])
    status = run_test(mei, "tuplets+rests")
    print(f"  {status:5s}  tuplets+rests")

    tuplet_rest = '<tuplet num="3" numbase="2"><note dur="8" pname="c" oct="4"/><rest dur="8"/><note dur="8" pname="e" oct="4"/></tuplet>'
    layer1 = make_layer([make_element("note")] * 4, n=1)
    layer2 = make_layer([tuplet_rest, tuplet_rest], n=2)
    mei = make_mei([layer1, layer2])
    status = run_test(mei, "rest_inside_tuplet")
    print(f"  {status:5s}  rest_inside_tuplet")

def test_grace_notes_with_rests():
    """Test grace notes with rests in other layer."""
    print("\n=== Grace notes with rests ===")
    grace_xml = '<note dur="8" pname="d" oct="4" grace="acc"/><note dur="4" pname="c" oct="4"/>'
    layer1 = make_layer([grace_xml] * 2, n=1)
    layer2 = make_layer([make_element("rest")] * 2, n=2)
    mei = make_mei([layer1, layer2])
    status = run_test(mei, "grace+rests")
    print(f"  {status:5s}  grace+rests")

def test_dots_with_rests():
    """Test dotted notes/rests in multi-layer."""
    print("\n=== Dotted elements in multi-layer ===")
    for dots in ["1", "2"]:
        dotted_note = f'<note dur="4" dots="{dots}" pname="g" oct="5"/>'
        dotted_rest = f'<rest dur="4" dots="{dots}"/>'
        layer1 = make_layer([dotted_note] * 2, n=1)
        layer2 = make_layer([dotted_rest] * 2, n=2)
        mei = make_mei([layer1, layer2])
        label = f"dots={dots}"
        status = run_test(mei, label)
        print(f"  {status:5s}  {label}")

def test_ties_with_rests():
    """Test tied notes with rests in other layer."""
    print("\n=== Ties with rests ===")
    mei_xml = """<mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.1">
<music><body><mdiv><score>
<scoreDef meter.count="4" meter.unit="4">
<staffGrp><staffDef n="1" lines="5"/></staffGrp>
</scoreDef>
<section>
<measure>
<staff>
<layer n="1">
<note dur="2" pname="g" oct="5" tie="i"/>
<note dur="2" pname="g" oct="5" tie="t"/>
</layer>
<layer n="2">
<rest dur="4"/>
<note dur="4" pname="c" oct="4"/>
<rest dur="4"/>
<note dur="4" pname="c" oct="4"/>
</layer>
</staff>
</measure>
</section>
</score></mdiv></body></music>
</mei>"""
    status = run_test(mei_xml, "ties+rests")
    print(f"  {status:5s}  ties+rests")

def test_multiple_staves():
    """Test multiple staves with rests."""
    print("\n=== Multiple staves with multi-layer rests ===")
    mei_xml = """<mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.1">
<music><body><mdiv><score>
<scoreDef meter.count="4" meter.unit="4">
<staffGrp>
<staffDef n="1" lines="5" clef.shape="G" clef.line="2"/>
<staffDef n="2" lines="5" clef.shape="F" clef.line="4"/>
</staffGrp>
</scoreDef>
<section>
<measure>
<staff n="1">
<layer n="1"><note dur="4" pname="g" oct="5"/><note dur="4" pname="g" oct="5"/><note dur="4" pname="g" oct="5"/><note dur="4" pname="g" oct="5"/></layer>
<layer n="2"><rest dur="4"/><note dur="4" pname="c" oct="4"/><rest dur="4"/><note dur="4" pname="c" oct="4"/></layer>
</staff>
<staff n="2">
<layer n="1"><note dur="2" pname="c" oct="3"/><rest dur="2"/></layer>
<layer n="2"><rest dur="4"/><rest dur="4"/><note dur="2" pname="g" oct="2"/></layer>
</staff>
</measure>
</section>
</score></mdiv></body></music>
</mei>"""
    status = run_test(mei_xml, "multi-staff+rests")
    print(f"  {status:5s}  multi-staff+rests")

def cleanup():
    for f in ["_fuzz.xml", "_fuzz.typ", "_fuzz.pdf"]:
        path = os.path.join(ROOT, "test", f)
        if os.path.exists(path):
            os.remove(path)

if __name__ == "__main__":
    print("MEI Fuzzer — testing for WASM crashes")
    print("=" * 50)

    crashes = 0
    errors = 0

    tests = [
        test_durations_multilayer,
        test_rest_durations_all,
        test_accidentals_multilayer,
        test_element_types_multilayer,
        test_three_layers,
        test_mixed_durations,
        test_clefs,
        test_noteheads,
        test_extreme_octaves,
        test_beams_with_rests,
        test_chords_with_rests,
        test_tuplets_with_rests,
        test_grace_notes_with_rests,
        test_dots_with_rests,
        test_ties_with_rests,
        test_multiple_staves,
    ]

    for test_fn in tests:
        test_fn()

    cleanup()
    print("\n" + "=" * 50)
    print("Done.")
