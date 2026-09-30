#import "csl-map.typ"
#import "../errors.typ"

#let _convert-item(item, position) = {
  if type(item) != dictionary { errors.raise("csl-json.item-not-object", value: repr(item)) }
  let entry-key = str(item.at("id", default: "csl-" + str(position)))
  let entry-type = csl-map.map-type(item.at("type", default: "document"))

  let _has-archive-field = item.at("archive", default: none) != none or item.at("archive_location", default: none) != none
  if _has-archive-field and entry-type in ("booklet", "misc", "image", "video", "music") {
    entry-type = "archive"
  }

  let fields = (:)
  let parsed-names = (:)
  let parsed-dates = (:)

  for (csl-key, bib-key) in csl-map.TEXT-FIELDS {
    if csl-key == "note" { continue }
    let v = item.at(csl-key, default: none)
    if v != none and str(v).trim() != "" and bib-key not in fields { fields.insert(bib-key, csl-map.escape-text(v)) }
  }
  let note = item.at("note", default: none)
  if note != none and str(note).trim() != "" {
    fields.insert("note", str(note))
    fields.insert("_omni-note-raw", true)
  }

  let volume-title = item.at("volume-title", default: none)
  if volume-title != none and str(volume-title).trim() != "" {
    fields.insert("volume-title", csl-map.escape-text(volume-title))
    fields = csl-map.swap-volume-title(fields)
  }
  for (csl-key, bib-key) in csl-map.RAW-FIELDS {
    let v = item.at(csl-key, default: none)
    if v != none and str(v).trim() != "" { fields.insert(bib-key, str(v)) }
  }

  let container = item.at("container-title", default: none)
  if container != none and str(container).trim() != "" {
    fields.insert(csl-map.container-field(entry-type), csl-map.escape-text(container))
  }

  let _archival = entry-type in ("archive", "letter", "legislation")
  let archive = item.at("archive", default: none)
  if archive != none and str(archive).trim() != "" and _archival and "institution" not in fields {
    fields.insert("institution", csl-map.escape-text(archive))
  }
  let archive-place = item.at("archive-place", default: none)
  if archive-place != none and str(archive-place).trim() != "" and _archival and "location" not in fields {
    fields.insert("location", csl-map.escape-text(archive-place))
  }

  let archive-location = item.at("archive_location", default: none)
  if archive-location != none and str(archive-location).trim() != "" and _archival and "number" not in fields {
    fields.insert("number", str(archive-location))
  }

  let issue = item.at("issue", default: none)
  if issue != none and str(issue).trim() != "" { fields.insert("issue", str(issue)) }
  let number = item.at("number", default: none)
  if number != none and str(number).trim() != "" {
    fields.insert(csl-map.classify("number", entry-type: entry-type).key, str(number))
  }

  let lang = item.at("language", default: none)
  if lang != none and str(lang).trim() != "" { fields.insert("langid", csl-map.map-lang(lang)) }

  let pmid = item.at("PMID", default: none)
  if pmid != none and str(pmid).trim() != "" {
    fields.insert("eprint", str(pmid))
    fields.insert("eprinttype", "pmid")
  }

  for (csl-role, bib-role) in csl-map.NAME-ROLES {
    let arr = item.at(csl-role, default: none)
    if type(arr) == array and arr.len() > 0 {
      let names = arr.map(csl-map.parse-name).filter(n => n.family != "" or n.given != "")
      if names.len() > 0 {
        parsed-names.insert(bib-role, names)
        if bib-role not in fields { fields.insert(bib-role, csl-map.name-string(names)) }
      }
    }
  }

  for (csl-key, bib-key) in csl-map.DATE-KEYS {
    let cd = item.at(csl-key, default: none)
    if cd == none { continue }
    let (parsed, raw) = csl-map.parse-date(cd)
    if raw != none and raw.trim() != "" and bib-key not in fields { fields.insert(bib-key, raw) }
    if parsed != none and bib-key not in parsed-dates { parsed-dates.insert(bib-key, parsed) }
  }

  (
    entry_type: entry-type,
    entry_key: entry-key,
    position: position,
    fields: fields,
    parsed_names: parsed-names,
    parsed_dates: parsed-dates,
  )
}

#let looks-like-json(content) = {
  let t = str(content).trim()
  t.starts-with("[") or t.starts-with("{")
}

#let _decode(content) = {
  let data = if type(content) == array or type(content) == dictionary { content } else { json(bytes(str(content))) }
  if type(data) == dictionary { (data,) } else { data }
}

#let keys(content) = _decode(content).enumerate().map(((i, item)) => {
  if type(item) == dictionary { str(item.at("id", default: "csl-" + str(i))) } else { "csl-" + str(i) }
})

#let load(content) = {
  let items = _decode(content)
  let bib-map = (:)
  for (i, item) in items.enumerate() {
    let entry = _convert-item(item, i)
    bib-map.insert(entry.entry_key, entry)
  }
  bib-map
}

#let _strip-html(s) = str(s).replace(regex("</?[^>]+>"), "")
#let _bibtex-escape(s) = {
  let t = _strip-html(s)
  t = t.replace("\\", "\\textbackslash ")
  t = t.replace("{", "").replace("}", "")
  t = t.replace("&", "\\&").replace("%", "\\%").replace("#", "\\#").replace("$", "\\$").replace("_", "\\_")
  t = t.replace("~", "\\textasciitilde ").replace("^", "\\textasciicircum ")
  t
}

#let _NATIVE-SAFE-TYPES = (
  "article", "book", "booklet", "inbook", "incollection", "inproceedings", "proceedings",
  "manual", "misc", "phdthesis", "mastersthesis", "thesis", "techreport", "report",
  "unpublished", "online", "patent", "periodical", "collection", "reference", "inreference",
  "dataset", "software", "letter",
)
#let _name-bibtex(csl-name) = {
  if type(csl-name) != dictionary { return _bibtex-escape(csl-name) }
  let lit = csl-name.at("literal", default: none)
  if lit != none and str(lit).trim() != "" { return "{" + _bibtex-escape(lit) + "}" }
  let ndp = str(csl-name.at("non-dropping-particle", default: ""))
  let family = (ndp + " " + str(csl-name.at("family", default: ""))).trim()
  let given = str(csl-name.at("given", default: ""))
  let suffix = str(csl-name.at("suffix", default: ""))
  let core = if given.trim() != "" { _bibtex-escape(family) + ", " + _bibtex-escape(given) } else { _bibtex-escape(family) }
  if suffix.trim() != "" { core + ", " + _bibtex-escape(suffix) } else { core }
}
#let _bib-line(k, v) = if v != none and str(v).trim() != "" { ("  " + k + " = {" + _bibtex-escape(v) + "}",) } else { () }

#let to-bibtex(content) = {
  let items = _decode(content)
  let out = ""
  for (i, item) in items.enumerate() {
    if type(item) != dictionary { continue }
    let key = str(item.at("id", default: "csl-" + str(i)))
    let csl-type = item.at("type", default: "document")
    let real-type = csl-map.map-type(csl-type)
    let etype = if real-type in _NATIVE-SAFE-TYPES { real-type } else { "misc" }
    let lines = ()
    for (csl-role, bib-role) in csl-map.NAME-ROLES {
      let arr = item.at(csl-role, default: none)
      if type(arr) == array and arr.len() > 0 { lines.push("  " + bib-role + " = {" + arr.map(_name-bibtex).join(" and ") + "}") }
    }
    let container = item.at("container-title", default: none)
    if container != none and str(container).trim() != "" {
      lines += _bib-line(csl-map.container-field(real-type), container)
    }
    for (csl-key, bib-key) in csl-map.TEXT-FIELDS { lines += _bib-line(bib-key, item.at(csl-key, default: none)) }
    for (csl-key, bib-key) in csl-map.RAW-FIELDS { lines += _bib-line(bib-key, item.at(csl-key, default: none)) }
    lines += _bib-line("issue", item.at("issue", default: none))
    lines += _bib-line(csl-map.classify("number", entry-type: real-type).key, item.at("number", default: none))
    let lang = item.at("language", default: none)
    if lang != none and str(lang).trim() != "" { lines.push("  langid = {" + csl-map.map-lang(lang) + "}") }
    let issued = item.at("issued", default: none)
    if issued != none { lines += _bib-line("date", csl-map.parse-date(issued).raw) }
    out += "@" + etype + "{" + key + ",\n" + lines.join(",\n") + ",\n}\n\n"
  }
  out
}
