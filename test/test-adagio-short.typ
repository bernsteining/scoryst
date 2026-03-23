#import "@local/mozart:0.1.0": render-music
#set page(width: 210mm, height: 297mm)

// Vivaldi/Bach Adagio - first 3 measures only
#render-music(read("adagio-short.abc"), width: 100%)
