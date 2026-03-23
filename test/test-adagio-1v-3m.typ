#import "@local/mozart:0.1.0": render-music
#set page(width: 210mm, height: 297mm)

// Voice 1 only, 3 measures
#render-music(read("adagio-1v-3m.abc"), width: 100%)
