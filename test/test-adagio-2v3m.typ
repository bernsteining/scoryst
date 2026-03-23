#import "@local/mozart:0.1.0": render-music
#set page(width: 210mm, height: 297mm)

// Two voices, 3 measures
#render-music(read("adagio-2v3m.abc"), width: 100%)
