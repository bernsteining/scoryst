#import "@local/mozart:0.1.0": render-music

#set page(width: 210mm, height: 297mm, margin: 15mm)
#set text(size: 11pt)

= Mozart — Format Tests

== 1. MusicXML (C-D-E-F scale)
#render-music(```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="4.0">
  <part-list>
    <score-part id="P1"><part-name>Piano</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>1</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>D</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>E</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>F</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
    </measure>
  </part>
</score-partwise>
```.text, width: 100%)

== 2. MEI (Bach — Ein feste Burg)
#render-music(read("sample-mei.mei"), width: 100%)

== 3. Humdrum (Beethoven — Moonlight Sonata)
#render-music(read("sample-humdrum.krn"), width: 100%)

#pagebreak()

== 4. ABC (Greensleeves)
#render-music(read("sample-abc.abc"), width: 100%)

== 5. Plaine & Easie
#render-music(read("sample-pae.pae"), width: 100%)
