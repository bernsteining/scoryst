#let wasm = plugin("../mozart/mozart.wasm")

#let svg-bytes = wasm.hello()
#image.decode(svg-bytes, format: "svg")
