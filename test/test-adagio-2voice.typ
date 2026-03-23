#import "@local/mozart:0.1.0": render-music
#set page(width: 210mm, height: 297mm)

// Two voices, single measure from Adagio
#render-music(read("adagio-2voice.abc"), width: 100%)
