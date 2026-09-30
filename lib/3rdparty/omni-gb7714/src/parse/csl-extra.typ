#import "csl-map.typ"
#import "../sentinel.typ": _SUND

#let _TEX-NAME-FIELDS = ("author", "editor", "translator", "bookauthor", "holder", "editora", "editorb", "editorc")

#let _normalize-label(label) = {
  let t = lower(label.trim()).replace(" ", "-")
  if t == "archive-location" { return "archive_location" }
  if t in ("doi", "isbn", "issn", "pmid", "pmcid", "url") { return upper(t) }
  t
}

#let _STANDARD-NUMBER-RE = regex("[A-Z]{2,}(?:/[A-Z]+)?\s+\S+[—:\-](?:19|20)\d{2}")

#let _looks-like-standard(fields) = {
  let ty = fields.at("type", default: none)
  if type(ty) == str and (ty.contains("标准") or lower(ty).contains("standard")) { return true }
  let num = fields.at("number", default: none)
  if type(num) == str and num.contains(_STANDARD-NUMBER-RE) { return true }
  false
}

#let _split-line(line, pid-map: (:), entry-type: none) = {
  let bounds = ()
  let _known(v) = csl-map.classify(v, entry-type: entry-type).kind != "unknown" or v in pid-map
  for m in line.matches(regex("(?:^|\\s)([A-Za-z][A-Za-z _-]*?)\\s*:")) {
    let raw = m.captures.at(0)
    let norm = _normalize-label(raw)
    if _known(norm) {
      bounds.push((mstart: m.start, vstart: m.end, var: norm))
    } else {

      let words = raw.split(" ")
      for tl in range(1, words.len()) {
        let tail = words.slice(words.len() - tl).join(" ")
        let tnorm = _normalize-label(tail)
        if _known(tnorm) {
          bounds.push((mstart: m.end - 1 - tail.len(), vstart: m.end, var: tnorm))
          break
        }
      }
    }
  }

  bounds += line.matches(regex("10\\.\\d{4,}/\\S+")).map(m => (mstart: m.start, vstart: m.start, var: "__bare-doi-drop"))
  if bounds.len() == 0 { return (prefix: line, recognized: ()) }
  bounds = bounds.sorted(key: b => b.mstart)
  let recognized = ()
  for (i, b) in bounds.enumerate() {
    if b.var == "__bare-doi-drop" { continue }
    let vend = if i + 1 < bounds.len() { bounds.at(i + 1).mstart } else { line.len() }
    recognized.push((b.var, line.slice(b.vstart, vend).trim()))
  }
  (prefix: line.slice(0, bounds.first().mstart), recognized: recognized)
}

#let enrich(entry, pid-labels: ()) = {
  let pid-map = (:)
  for (label, field-name) in pid-labels { pid-map.insert(_normalize-label(label), field-name) }
  let fields = entry.fields
  let names = entry.parsed_names
  let dates = entry.parsed_dates
  let real-fields = fields.keys()
  let real-name-roles = names.keys()
  let real-date-keys = dates.keys()

  let note-raw = fields.at("_omni-note-raw", default: false)
  let esc(v) = if note-raw { csl-map.escape-text(v) } else { v }

  let override-type = none
  for src-key in ("note", "annotation") {
    let src = fields.at(src-key, default: none)
    if type(src) != str { continue }

    let tbounds = ()
    for m in src.matches(regex("(?i)\\btex\\.([a-z0-9_\\x{E000}-\\x{F8FF}]+)\\s*:")) {
      tbounds.push((mstart: m.start, vstart: m.end, field: lower(m.captures.at(0)).replace(_SUND, "_")))
    }
    for (i, b) in tbounds.enumerate() {
      let vend = if i + 1 < tbounds.len() { tbounds.at(i + 1).mstart } else { src.len() }
      let v = src.slice(b.vstart, vend).trim()
      if b.field == "entrytype" { override-type = lower(v); continue }
      if v == "" or b.field in real-fields { continue }
      if b.field in _TEX-NAME-FIELDS {
        let arr = names.at(b.field, default: ())
        arr.push(csl-map.parse-name-string(v))
        names.insert(b.field, arr)
        fields.insert(b.field, csl-map.name-string(arr))
      } else {
        fields.insert(b.field, esc(v))
      }
    }
    fields.insert(src-key, src.replace(regex("(?is)\\s*\\btex\\.[a-z0-9_\\x{E000}-\\x{F8FF}]+\\s*:.*"), ""))
  }

  let effective-type = if override-type != none { override-type } else { entry.entry_type }

  for src-key in ("note", "annotation") {
    let src = fields.at(src-key, default: none)
    if src == none or type(src) != str { continue }
    let kept = ()
    for line in src.split("\n") {
      let (prefix, recognized) = _split-line(line, pid-map: pid-map, entry-type: effective-type)
      if recognized.len() == 0 { kept.push(line); continue }
      if prefix.trim() != "" { kept.push(prefix) }
      for (var, value) in recognized {
        if value == "" { continue }
        if var in pid-map {
          let target = pid-map.at(var)
          if target not in real-fields { fields.insert(target, value) }
          continue
        }
        let route = csl-map.classify(var, entry-type: effective-type)

        if route.kind == "drop" { continue }
        let target = if route.kind == "lang" { "langid" } else if route.kind == "pmid" { "eprint" } else if route.kind == "container" { csl-map.container-field(effective-type) } else { route.key }
        let occupied = if route.kind == "name" { target in real-name-roles } else if route.kind == "date" { target in real-date-keys or target in real-fields } else { target in real-fields }
        if occupied { continue }

        if route.kind == "name" {
          let arr = names.at(target, default: ())
          arr.push(csl-map.parse-name-string(value))
          names.insert(target, arr)
          fields.insert(target, csl-map.name-string(arr))
        } else if route.kind == "date" {
          let (parsed, raw) = csl-map.parse-date-string(value)
          if parsed != none { dates.insert(target, parsed) } else { let _ = dates.remove(target, default: none) }
          fields.insert(target, raw)
        } else if route.kind == "pmid" {
          fields.insert("eprint", value)
          if "eprinttype" not in real-fields { fields.insert("eprinttype", "pmid") }
        } else if route.kind == "lang" {
          fields.insert("langid", csl-map.map-lang(value))
        } else if route.kind == "raw" {
          fields.insert(target, value)
        } else {
          fields.insert(target, esc(value))
        }
      }
    }
    let leftover = kept.join("\n", default: "").trim()
    if leftover == "" { let _ = fields.remove(src-key, default: none) } else { fields.insert(src-key, esc(leftover)) }
  }
  let _ = fields.remove("_omni-note-raw", default: none)
  fields = csl-map.swap-volume-title(fields)

  let e = entry
  if override-type != none {
    e.entry_type = override-type
  } else if e.entry_type == "misc" and ("scale" in fields or "dimensions" in fields) {

    e.entry_type = "map"
  } else if e.entry_type == "misc" and _looks-like-standard(fields) {

    e.entry_type = "standard"
  }
  e.fields = fields
  e.parsed_names = names
  e.parsed_dates = dates
  e
}
