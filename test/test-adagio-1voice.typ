#import "@local/mozart:0.1.0": render-music
#set page(width: 210mm, height: 297mm)

// Single voice, single measure from Adagio
#render-music(read("adagio-1voice.abc"), width: 100%)
