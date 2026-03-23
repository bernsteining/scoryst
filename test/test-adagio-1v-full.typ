#import "@local/mozart:0.1.0": render-music
#set page(width: 210mm, height: 297mm)

// Voice 1 only, 15 measures
#render-music(read("adagio-1v-full.abc"), width: 100%)
