#import "@local/mozart:0.1.0": render-music
#set page(width: 210mm, height: 297mm)

// PAE with explicit inputFrom option
#render-music(
  read("sample-pae.pae"),
  options: (inputFrom: "pae"),
  width: 100%
)
