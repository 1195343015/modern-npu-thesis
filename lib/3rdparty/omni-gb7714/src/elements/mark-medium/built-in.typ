#import "../../sentinel.typ": *
#import "../../field.typ"
#import "../../errors.typ"
#import "../../parse/guard.typ" as guard

#let _eval-mark-guard(ast, entry) = {
  let k = ast.at(0)
  if k == "and" { return ast.at(1).all(a => _eval-mark-guard(a, entry)) }
  if k == "or" { return ast.at(1).any(a => _eval-mark-guard(a, entry)) }
  if k == "not" { return not _eval-mark-guard(ast.at(1), entry) }
  if k == "present" {
    let v = field.get(entry, ast.at(1))
    return v != none and str(v).trim() != ""
  }
  let fname = ast.at(1); let op = ast.at(2); let values = ast.at(3)
  let actual = if fname == "entry-type" { entry.entry_type }
    else { let v = field.get(entry, fname); if v == none { "" } else { str(v) } }
  let matches = str(actual) in values
  if op == "neq" { not matches } else { matches }
}

#let _mark-toks-to-str(toks) = {
  let s = ""
  for t in toks { if t.at(0) == "sp" { s += " " } else if t.len() > 1 { s += t.at(1) } }
  s.trim()
}

#let _resolve-mark-guard(value, entry) = {
  let tokens = guard.tokenize(value)
  let i = 0
  while i < tokens.len() {
    if tokens.at(i).at(0) == "group-open" {
      let depth = 1; let j = i + 1; let arrow = none
      let guard-toks = (); let code-toks = ()
      while j < tokens.len() {
        let tj = tokens.at(j); let kj = tj.at(0)
        if kj == "group-open" { depth += 1 }
        else if kj == "group-close" { depth -= 1; if depth == 0 { break } }
        if depth >= 1 {
          if kj == "arrow" and depth == 1 and arrow == none { arrow = j }
          else if arrow == none { guard-toks.push(tj) }
          else { code-toks.push(tj) }
        }
        j += 1
      }
      if arrow != none {

        let has-guard = guard-toks.any(t => t.at(0) != "sp")
        if not has-guard or _eval-mark-guard(guard.parse-guard-expr(guard-toks), entry) {
          return _mark-toks-to-str(code-toks)
        }
      }
      i = j + 1
    } else { i += 1 }
  }
  none
}

#let _auto-table = (
  article: "J",
  book: "M", mvbook: "M", inbook: "M", bookinbook: "M",
  inproceedings: "C", conference: "C",
  proceedings: "C", mvproceedings: "C",
  mastersthesis: "D", phdthesis: "D", thesis: "D",
  techreport: "R", report: "R",
  patent: "P",
  collection: "G", mvcollection: "G", incollection: "G",

  reference: "M", mvreference: "M", inreference: "M",
  online: "EB",
  software: "CP",
  dataset: "DS",
  database: "DB",
  manual: "A",

  archive: "A", letter: "A", legislation: "A",
  periodical: "J",
  booklet: "M",

  standard: "S", newspaper: "N", webpage: "EB",
  map: "CM",
  unpublished: "Z", misc: "Z",
  suppbook: "Z", suppperiodical: "Z", suppcollection: "Z",
)

#let _subtype-mark-table = (
  newspaper: "N", news: "N", inproceedings: "C", report: "R",
  techreport: "R", standard: "S", patent: "P", dataset: "DS",
)

#let _news-re = regex("(n|N)(e|E)(w|W)(s|S)")
#let _standard-re = regex("(s|S)(t|T)(a|A)(n|N)(d|D)(a|A)(r|R)(d|D)")

#let _note-hijack-mark(entry) = {
  let value = entry.fields.at("note", default: none)
  if value == none { return none }
  let text = str(value)
  if entry.entry_type == "article" and text.match(_news-re) != none { return "N" }
  if entry.entry_type in ("book", "inbook") and text.match(_standard-re) != none { return "S" }
  none
}

#let _raw-mark-medium(entry) = {
  let note-mark = _note-hijack-mark(entry)
  if note-mark != none { return note-mark }
  let usera = entry.fields.at("usera", default: none)
  if usera != none { return usera }
  let entrytypeid = entry.fields.at("entrytypeid", default: none)
  if entrytypeid != none { return entrytypeid }
  let subtype = entry.fields.at("entrysubtype", default: none)
  if subtype != none {
    let code = _subtype-mark-table.at(lower(str(subtype).trim()), default: none)
    if code != none { return code }
  }
  let mark-field = entry.fields.at("mark", default: none)
  if mark-field != none { return mark-field }
  let custom = entry.fields.at("_omni-mark-custom", default: none)
  if custom != none {
    if type(custom) == str and "=>" in custom {
      let resolved = _resolve-mark-guard(custom, entry)
      if resolved != none and resolved != "" { return resolved }
    } else { return custom }
  }
  let override = entry.fields.at("_omni-mark-override", default: none)
  if override != none { return override }
  _auto-table.at(entry.entry_type, default: "Z")
}

#let mark(entry) = str(_raw-mark-medium(entry)).split("/").first()

#let _explicit-medium(entry) = {
  let raw = str(_raw-mark-medium(entry))
  if raw.contains("/") { raw.split("/").slice(1).join("/") } else { none }
}

#let known-marks = ("M", "C", "G", "N", "J", "D", "R", "S", "P", "DB", "CP", "EB", "A", "CM", "DS", "Z", "PP")

#let base-mark(entry) = {
  if entry.entry_type == "preprint" or str(entry.fields.at("entrysubtype", default: "")) == "preprint" { return "PP" }
  let stored = entry.fields.at("_omni-mark-base", default: none)
  let code = if stored != none { str(stored) } else { str(mark(entry)) }
  code.split("/").first()
}

#let ONLINE-TYPES = ("online", "webpage", "electronic", "www")

#let _born-digital = ("online", "webpage", "software", "dataset", "database", "preprint", "electronic", "www")

#let is-online(entry, version: 2015) = {
  let medium-field = entry.fields.at("medium", default: none)
  if medium-field != none { return upper(str(medium-field)).contains("OL") }
  for f in ("entrytypeid", "usera", "mark") {
    let v = entry.fields.at(f, default: none)
    if v != none and str(v).contains("/") { return upper(str(v)).contains("/OL") }
  }
  if entry.entry_type == "online" { return true }
  let subtype = str(entry.fields.at("entrysubtype", default: ""))
  if entry.entry_type in _born-digital or subtype == "preprint" or field.get(entry, "eprint") != none {
    return field.has-online(entry)
  }
  false
}

#let applied-value(setting, entry) = {
  if type(setting) == dictionary {
    if entry.entry_type in setting { setting.at(entry.entry_type) }
    else {
      let code = base-mark(entry)
      if code in setting { setting.at(code) }
      else { setting.at("rest", default: auto) }
    }
  } else { setting }
}

#let gate(setting, entry, version: 2015, default: true, allow-online-only: true) = {
  let v = applied-value(setting, entry)
  if v == auto { return default }
  if v == "online-only" {
    if not allow-online-only { errors.raise("mark-medium.show-mark-online-only") }
    return is-online(entry, version: version)
  }
  v == true
}

#let validate-setting-keys(setting, param-name, extra-marks: ()) = {
  if type(setting) != dictionary { return }
  for (k, _) in setting {
    if k == upper(k) and k != lower(k) and k not in known-marks and k not in extra-marks {
      errors.raise("mark-medium.setting-key-not-mark", param: param-name, key: k, marks: (known-marks + extra-marks).join("/"))
    }
  }
}

#let online-suppressed(setting, entry, version: 2015) = {
  applied-value(setting, entry) == "online-only" and not is-online(entry, version: version)
}

#let medium(entry, show-url: true, version: 2015, online: auto) = {
  let medium-field = entry.fields.at("medium", default: none)
  if medium-field != none { return medium-field }
  let explicit = _explicit-medium(entry)
  if explicit != none { return explicit }
  if entry.entry_type in ONLINE-TYPES { return "OL" }

  let online = if online != auto { online }
    else if version == 2005 { field.get(entry, "url") != none and show-url }
    else { field.has-online(entry) and show-url }
  if online { return "OL" }
  return none
}

#let render(entry, show-mark: true, show-medium: true, show-url: true, space-before-mark: false, version: 2015, online: auto, bracket-style: "half") = {
  if not gate(show-mark, entry, version: version, allow-online-only: false) { return "" }
  let show-url = gate(show-url, entry, version: version)
  let mark-code = mark(entry)
  if mark-code == "" { return "" }
  let medium-code = if show-medium { medium(entry, show-url: show-url, version: version, online: online) } else { none }
  let prefix = if space-before-mark { " " } else { "" }
  let (lb, rb) = if bracket-style == "full" { ("［", "］") } else { ("[", "]") }
  if medium-code != none { prefix + lb + mark-code + "/" + medium-code + rb } else { prefix + lb + mark-code + rb }
}
