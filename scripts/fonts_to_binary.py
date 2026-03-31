#!/usr/bin/env python3
"""Convert verovio XML font data to a compact binary format.

Binary format per font file (FontName.bin):
  Header:
    uint32  magic         = 0x56524630 ("VRF0")
    uint32  units_per_em
    uint32  glyph_count
    uint32  string_pool_offset  (from start of file)
  Per glyph (glyph_count entries):
    uint32  codepoint
    int32   x, y, w, h          (bbox, 10x scaled)
    int32   horiz_adv_x          (10x scaled)
    int32   anchor_x[6], anchor_y[6]  (0 if absent; scaled by upm/4)
    uint32  path_offset           (into string pool)
    uint32  path_length
  String pool:
    concatenated SVG path strings (the <g>...</g> XML)

Text fonts (text/FontName.bin) omit path data (path_offset=0, path_length=0).
"""

import struct
import sys
import os
import xml.etree.ElementTree as ET

MAGIC = 0x56524630  # "VRF0"
ANCHOR_NAMES = ["stemDownNW", "stemUpSE", "cutOutNE", "cutOutNW", "cutOutSE", "cutOutSW"]

# Header: magic, upm, count, string_pool_offset
HEADER_FMT = "<IIII"
HEADER_SIZE = struct.calcsize(HEADER_FMT)

# Per glyph: codepoint, x, y, w, h, hax, 6 anchor x, 6 anchor y, path_offset, path_len
GLYPH_FMT = "<I5i6i6iII"
GLYPH_SIZE = struct.calcsize(GLYPH_FMT)


def convert_font(data_dir, font_name, output_path, is_text_font=False):
    meta_path = os.path.join(data_dir, f"{font_name}.xml")
    tree = ET.parse(meta_path)
    root = tree.getroot()
    upm = int(root.attrib.get("units-per-em", "1000"))

    glyphs = []
    string_pool = bytearray()

    for g in root.findall("g"):
        code_str = g.attrib.get("c", "")
        if not code_str:
            continue
        codepoint = int(code_str, 16)

        x = int(round(float(g.attrib.get("x", "0")) * 10))
        y = int(round(float(g.attrib.get("y", "0")) * 10))
        w = int(round(float(g.attrib.get("w", "0")) * 10))
        h = int(round(float(g.attrib.get("h", "0")) * 10))
        hax = int(round(float(g.attrib.get("h-a-x", "0")) * 10))

        # Anchors
        anchor_x = [0] * 6
        anchor_y = [0] * 6
        for a in g.findall("a"):
            name = a.attrib.get("n", "")
            if name in ANCHOR_NAMES:
                idx = ANCHOR_NAMES.index(name)
                ax = float(a.attrib.get("x", "0"))
                ay = float(a.attrib.get("y", "0"))
                anchor_x[idx] = int(round(ax * upm / 4))
                anchor_y[idx] = int(round(ay * upm / 4))

        # SVG path data
        path_offset = 0
        path_length = 0
        if not is_text_font:
            glyph_dir = os.path.join(data_dir, font_name)
            glyph_file = os.path.join(glyph_dir, f"{code_str}.xml")
            if os.path.exists(glyph_file):
                with open(glyph_file, "r") as f:
                    xml_content = f.read().strip()
                path_bytes = xml_content.encode("utf-8")
                path_offset = len(string_pool)
                path_length = len(path_bytes)
                string_pool.extend(path_bytes)

        glyphs.append((codepoint, x, y, w, h, hax,
                        *anchor_x, *anchor_y,
                        path_offset, path_length))

    # Build binary
    glyph_count = len(glyphs)
    string_pool_offset = HEADER_SIZE + glyph_count * GLYPH_SIZE

    with open(output_path, "wb") as f:
        f.write(struct.pack(HEADER_FMT, MAGIC, upm, glyph_count, string_pool_offset))
        for g in glyphs:
            f.write(struct.pack(GLYPH_FMT, *g))
        f.write(string_pool)

    total = os.path.getsize(output_path)
    print(f"  {font_name}: {glyph_count} glyphs, {total} bytes ({total//1024}KB)")


def main():
    data_dir = sys.argv[1] if len(sys.argv) > 1 else "verovio/data"
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "src/fonts"
    os.makedirs(out_dir, exist_ok=True)

    music_fonts = ["Bravura", "Gootville", "Leipzig", "Leland", "Petaluma"]
    text_fonts = ["Times", "Times-bold", "Times-bold-italic", "Times-italic"]

    print("Converting music fonts:")
    for font in music_fonts:
        meta = os.path.join(data_dir, f"{font}.xml")
        if os.path.exists(meta):
            convert_font(data_dir, font, os.path.join(out_dir, f"{font}.bin"))

    print("Converting text fonts:")
    text_data_dir = os.path.join(data_dir, "text")
    for font in text_fonts:
        meta = os.path.join(text_data_dir, f"{font}.xml")
        if os.path.exists(meta):
            # Text font metadata is in data/text/, referenced as text/Font.xml
            convert_text_font(text_data_dir, font, os.path.join(out_dir, f"text-{font}.bin"))


def convert_text_font(data_dir, font_name, output_path):
    """Text fonts have no path data, just bounding boxes."""
    meta_path = os.path.join(data_dir, f"{font_name}.xml")
    tree = ET.parse(meta_path)
    root = tree.getroot()
    upm = int(root.attrib.get("units-per-em", "1000"))

    glyphs = []
    for g in root.findall("g"):
        code_str = g.attrib.get("c", "")
        if not code_str:
            continue
        codepoint = int(code_str, 16)
        x = int(round(float(g.attrib.get("x", "0")) * 10))
        y = int(round(float(g.attrib.get("y", "0")) * 10))
        w = int(round(float(g.attrib.get("w", "0")) * 10))
        h = int(round(float(g.attrib.get("h", "0")) * 10))
        hax = int(round(float(g.attrib.get("h-a-x", "0")) * 10))

        glyphs.append((codepoint, x, y, w, h, hax,
                        *([0]*6), *([0]*6),  # no anchors
                        0, 0))  # no path data

    glyph_count = len(glyphs)
    string_pool_offset = HEADER_SIZE + glyph_count * GLYPH_SIZE

    with open(output_path, "wb") as f:
        f.write(struct.pack(HEADER_FMT, MAGIC, upm, glyph_count, string_pool_offset))
        for g in glyphs:
            f.write(struct.pack(GLYPH_FMT, *g))

    total = os.path.getsize(output_path)
    print(f"  {font_name}: {glyph_count} glyphs, {total} bytes ({total//1024}KB)")


if __name__ == "__main__":
    main()
