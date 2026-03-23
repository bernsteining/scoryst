#import "@local/mozart:0.1.0": render-music
#set page(width: 210mm, height: 297mm)

// Minimal Humdrum file — C major scale
#render-music("**kern\n*clefG2\n*M4/4\n4c\n4d\n4e\n4f\n*-\n", width: 100%)
