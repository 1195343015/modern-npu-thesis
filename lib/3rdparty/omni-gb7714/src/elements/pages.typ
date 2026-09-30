#import "../errors.typ"
#import "../punct/built-in.typ" as punct
#import "../terms/built-in.typ" as terms

#let page-range-style-values = ("expanded", "minimal", "minimal-two", "chicago-15", "chicago-16")

#let normalize-page-range-style(value) = {
  if value == none { return none }
  if value == "chicago" { return "chicago-15" }
  if type(value) == str and value in page-range-style-values { return value }
  errors.raise("page-range-style.bad-value", value: repr(value))
}

#let _split-digit-suffix(s) = {
  let chars = s.clusters()
  let i = chars.len()
  while i > 0 and "0123456789".contains(chars.at(i - 1)) { i -= 1 }
  (chars.slice(0, i).join(""), chars.slice(i).join(""))
}

#let _changed-digits(x, y) = {
  let xc = x.clusters()
  let yc = y.clusters()
  while xc.len() < yc.len() { xc.insert(0, " ") }
  let n = yc.len()
  let i = 0
  while i < n {
    if xc.at(xc.len() - 1 - i) == yc.at(n - 1 - i) { return i }
    i += 1
  }
  n
}

#let _minimal(thresh, x, y) = {
  let xc = x.clusters()
  let yc = y.clusters()
  if yc.len() > xc.len() { return y }
  let i = 0
  while i < yc.len() and xc.at(i) == yc.at(i) { i += 1 }
  let tail = yc.slice(i).join("")
  if tail.clusters().len() < thresh and yc.len() >= thresh {
    yc.slice(yc.len() - thresh).join("")
  } else {
    tail
  }
}

#let _format-range(style, start, end, separator) = {
  let start = start.trim()
  let end = end.trim()
  let (start-prefix, x) = _split-digit-suffix(start)
  let (end-prefix, y-raw) = _split-digit-suffix(end)
  if start-prefix != end-prefix { return start + separator + end }
  if x == "" or y-raw == "" { return start + separator + end }

  let x-len = x.clusters().len()
  let y-len = y-raw.clusters().len()
  let y = if x-len <= y-len { y-raw } else { x.clusters().slice(0, x-len - y-len).join("") + y-raw }

  let tail = if style == "expanded" {
    start-prefix + y
  } else if style == "minimal" {
    _minimal(1, x, y)
  } else if style == "minimal-two" {
    _minimal(2, x, y)
  } else {

    if x-len < 3 or x.ends-with("00") { y }
    else if x.clusters().at(x-len - 2) == "0" { _minimal(1, x, y) }
    else if style == "chicago-15" and x-len == 4 and _changed-digits(x, y) >= 3 { y }
    else { _minimal(2, x, y) }
  }
  start-prefix + x + separator + tail
}

#let _RANGE-RE = regex("([^\\s,，]+?)(--|\u{2013}|-)([^\\s,，]+)")

#let _apply-page-range(page-text, style, separator) = {
  page-text.replace(_RANGE-RE, m => {
    let (start, _, end) = m.captures
    _format-range(style, start, end, separator)
  })
}

#let is-plural(page-text) = {
  if page-text == none or type(page-text) != str { return false }
  let segments = page-text.split(regex("[,，]")).map(s => s.trim()).filter(s => s != "")
  let countable = 0
  for segment in segments {
    let m = segment.match(_RANGE-RE)
    if m != none and m.start == 0 and m.end == segment.len() {
      if m.captures.first() != m.captures.last() { return true }
      countable += 1
    } else if segment.matches(regex("[0-9]")).len() > 0 { countable += 1 }
  }
  countable > 1
}

#let pages(entry, page-range-separator: "-", page-range-style: none, override: none, punct-style: "half-with-space", custom-punct: (:), custom-terms: (:)) = {

  if override != none { return override }
  let page-text = punct.field-text(entry, "pages")
  let is-pages = page-text != none
  if page-text == none { page-text = punct.field-text(entry, "eid") }
  if page-text == none { return none }
  let page-range-separator = punct.resolve-separator(page-range-separator, entry, punct-style, custom-punct, "-")
  if type(page-text) != str { return page-text }
  let label(text-out) = if is-pages {
    terms.pages-label(entry, text-out, is-plural(page-text), custom-terms: custom-terms)
  } else { text-out }
  if page-range-style != none and is-pages {
    return label(_apply-page-range(page-text, page-range-style, page-range-separator))
  }

  label(page-text.replace(regex("--|\u{2013}|-"), page-range-separator))
}
