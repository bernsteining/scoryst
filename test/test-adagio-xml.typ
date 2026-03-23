#import "@local/mozart:0.1.0": render-music
#set page(width: 210mm, height: 297mm)

// Vivaldi/Bach Adagio in C minor - MusicXML format
#render-music(read("adagio.xml"), width: 100%)
