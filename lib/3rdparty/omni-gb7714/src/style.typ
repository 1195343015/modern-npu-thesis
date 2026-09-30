#import "errors.typ"

#let axis-values = ("numeric", "author-date")

#let csl-name-map = (
  "gb-7714-2005-numeric": ("numeric", 2005, auto),
  "gb-7714-2005-author-date": ("author-date", 2005, auto),
  "gb-7714-2005-note": ("numeric", 2005, "foot"),
  "gb-7714-2015-numeric": ("numeric", 2015, auto),
  "gb-7714-2015-author-date": ("author-date", 2015, auto),
  "gb-7714-2015-note": ("numeric", 2015, "foot"),
  "gb-7714-2025-numeric": ("numeric", 2025, auto),
  "gb-7714-2025-author-date": ("author-date", 2025, auto),
  "gb-7714-2025-note": ("numeric", 2025, "foot"),
)

#let normalize(style) = {
  if style == none or style == auto {
    return (cite: none, bib: none, version: auto, note: auto, native: false)
  }
  if type(style) == dictionary {
    for (key, _) in style {
      if key not in ("cite", "bib") { errors.raise("style.unknown-axis", key: key) }
    }
    if "cite" not in style or "bib" not in style {
      errors.raise("style.missing-axis", got: repr(style))
    }
    let pick(key) = {
      let value = style.at(key, default: auto)
      if value == auto or value == none { none }
      else if type(value) == str and value in axis-values { value }
      else { errors.raise("style.bad-axis-value", key: key, value: repr(value), values: axis-values.join(" / ")) }
    }
    return (cite: pick("cite"), bib: pick("bib"), version: auto, note: auto, native: false)
  }
  if type(style) == str and style in axis-values {
    return (cite: style, bib: style, version: auto, note: auto, native: false)
  }
  if type(style) == str and style in csl-name-map {
    let (name, version, note) = csl-name-map.at(style)
    return (cite: name, bib: name, version: version, note: note, native: false)
  }
  (cite: none, bib: none, version: auto, note: auto, native: true)
}

#let resolve(list-style, global-style, fallback: "numeric") = {
  let cite = if list-style.cite != none { list-style.cite }
    else if global-style.cite != none { global-style.cite }
    else { fallback }
  let bib = if list-style.bib != none { list-style.bib }
    else if global-style.bib != none { global-style.bib }
    else { cite }
  (cite: cite, bib: bib)
}
