#let plugin = plugin("mozart.wasm")

/// Render music notation to an SVG image.
///
/// - data: Music data as a string (MusicXML, MEI, ABC, Humdrum, etc.)
/// - options: Verovio options as a dictionary (optional)
/// - page: Page number to render (default: 1)
/// - ..args: Additional arguments forwarded to Typst's `image` function
///           (e.g., `width`, `height`, `fit`, `alt`)
#let render-music(data, options: none, page: 1, ..args) = {
  let data-bytes = bytes(data)
  let options-str = if options != none {
    // Convert Typst dict to JSON string for Verovio
    let pairs = options.pairs().map(((k, v)) => {
      let val = if type(v) == str { "\"" + v + "\"" } else { str(v) }
      "\"" + k + "\":" + val
    })
    "{" + pairs.join(",") + "}"
  } else {
    ""
  }
  let options-bytes = bytes(options-str)

  let svg-bytes = if page == 1 {
    plugin.render(data-bytes, options-bytes)
  } else {
    plugin.render_page(data-bytes, options-bytes, bytes(str(page)))
  }

  image(svg-bytes, format: "svg", ..args.named())
}

/// Get the number of pages for a music document.
///
/// - data: Music data as a string
/// - options: Verovio options as a dictionary (optional)
#let music-page-count(data, options: none) = {
  let data-bytes = bytes(data)
  let options-str = if options != none {
    let pairs = options.pairs().map(((k, v)) => {
      let val = if type(v) == str { "\"" + v + "\"" } else { str(v) }
      "\"" + k + "\":" + val
    })
    "{" + pairs.join(",") + "}"
  } else {
    ""
  }
  int(str(plugin.page_count(data-bytes, bytes(options-str))))
}
