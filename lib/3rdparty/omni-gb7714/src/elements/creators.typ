#import "../sentinel.typ": *
#import "../errors.typ"
#import "../detect/lang.typ" as language
#import "../detect/pinyin.typ" as pinyin
#import "../terms/built-in.typ" as terms
#import "../punct/built-in.typ" as punct
#import "mark-medium/built-in.typ" as mark-medium
#import "../parse/latex.typ"
#import "../field.typ"

#let _TEX-DROP-PATTERNS = latex.TEX-DROP-ARG.map(sort-command => regex("\\\\" + sort-command + "\\s*\\{[^{}]*\\}"))

#let _is-org(name) = {
  name.at("given", default: "") == "" and name.at("family", default: "").contains(" ")
}

#let _CORP-DESIGNATORS = ("ltd", "inc", "llc", "plc", "corp", "gmbh", "ag", "pty", "co", "company", "llp", "lp", "srl", "sarl", "nv", "bv", "sa")

#let _written-with-comma(name, entry) = {
  if entry == none { return false }
  let family = name.at("family", default: "")
  if family == "" { return false }
  let fields = entry.at("fields", default: (:))
  for (role, _) in entry.at("parsed_names", default: (:)) {
    let raw = fields.at(role, default: none)
    if type(raw) != str { continue }
    for segment in raw.split(regex("\\s+and\\s+")) {
      if segment.replace("{", "").replace("}", "").trim().starts-with(family + ",") { return true }
    }
  }
  false
}

#let is-corp-name(name, entry: none) = {
  let given = name.at("given", default: "")
  if given == "" { return false }
  let family = name.at("family", default: "")
  if family == "" { return false }
  if _written-with-comma(name, entry) { return false }
  lower(family.split(" ").last().replace(".", "").trim()) in _CORP-DESIGNATORS
}

#let name-style-keys = ("order", "family-case", "given-form", "given-initial-separator", "given-separator", "given-case", "family-given-separator", "given-family-separator")
#let _ORDER-VALUES = ("family-ahead", "given-ahead")
#let _FAMILY-CASE-VALUES = (auto, "uppercase", "lowercase", "capitalize-first", "capitalize-each", none)
#let _GIVEN-FORM-VALUES = (auto, none, "initials", "full", "pinyin-initials")
#let _GIVEN-CASE-VALUES = (none, "uppercase", "lowercase", "capitalize-first", "capitalize-each")

#let validate-name-style(value, param: "name-style") = {
  if value == auto { return }
  if std.type(value) != dictionary { errors.raise("name-style.not-dictionary", param: param, got: repr(value)) }
  for (key, v) in value {
    if key not in name-style-keys { errors.raise("name-style.unknown-key", param: param, key: key, keys: name-style-keys.join(" / ")) }

    if key == "order" and std.type(v) == dictionary {
      for (order-key, order-value) in v {
        if order-key not in ("first", "rest") { errors.raise("name-style.order-dict", param: param, got: repr(v)) }
        if order-value not in _ORDER-VALUES { errors.raise("name-style.bad-value", param: param, key: "order." + order-key, got: repr(order-value)) }
      }
      if "first" not in v or "rest" not in v { errors.raise("name-style.order-dict", param: param, got: repr(v)) }
      continue
    }
    if key == "given-form" and std.type(v) == dictionary {
      for (form-key, form-value) in v {
        if form-key not in ("pinyin", "rest") or form-value not in (none, "initials", "full", "pinyin-initials") {
          errors.raise("name-style.bad-value", param: param, key: "given-form." + form-key, got: repr(form-value))
        }
      }
      continue
    }
    let bad = if key == "order" { v not in _ORDER-VALUES }
      else if key == "family-case" { v not in _FAMILY-CASE-VALUES }
      else if key == "given-form" { v not in _GIVEN-FORM-VALUES }
      else if key == "given-case" { v not in _GIVEN-CASE-VALUES }
      else if key == "given-separator" { not (v == auto or v == none or std.type(v) == str or std.type(v) == dictionary) }
      else { not (v == auto or std.type(v) == str or std.type(v) == dictionary) }
    if bad { errors.raise("name-style.bad-value", param: param, key: key, got: repr(v)) }
  }
}

#let resolve-name-style(value, version: 2025, side: "bib") = {
  let dict = if value == auto or value == none { (:) } else { value }
  let family-case = dict.at("family-case", default: auto)
  if family-case == auto {
    family-case = if side == "cite" { none } else if version == 2025 { none } else { "uppercase" }
  }
  let given-form = dict.at("given-form", default: auto)
  if given-form == auto {
    given-form = if side == "cite" { none }
      else if version == 2025 { (pinyin: "full", rest: "initials") }
      else { (pinyin: "pinyin-initials", rest: "initials") }
  }
  let given-separator = dict.at("given-separator", default: auto)
  if given-separator == auto { given-separator = if version == 2025 { none } else { " " } }

  let given-initial-separator = dict.at("given-initial-separator", default: auto)
  if given-initial-separator == auto { given-initial-separator = "" }
  let family-given-separator = dict.at("family-given-separator", default: auto)
  if family-given-separator == auto { family-given-separator = " " }
  let given-family-separator = dict.at("given-family-separator", default: auto)
  if given-family-separator == auto { given-family-separator = " " }
  let order = dict.at("order", default: "family-ahead")
  let order = if std.type(order) == dictionary { order } else { (first: order, rest: order) }
  (
    order: order,
    family-case: family-case,
    given-form: given-form,
    given-initial-separator: given-initial-separator,
    given-separator: given-separator,
    given-case: dict.at("given-case", default: none),
    family-given-separator: family-given-separator,
    given-family-separator: given-family-separator,
  )
}

#let format-one(name, name-style: (:), name-suffix-separator: auto, prefix-last: false, entry: none, punct-style: "half-with-space", custom-punct: (:), name-index: 0) = {

  let _norm-name(fragment) = {
    if type(fragment) != str { return fragment }
    fragment = fragment.replace(_SD, "$")
    fragment = fragment.replace("~", "\u{00A0}")
    if "\\" in fragment {
      for pattern in _TEX-DROP-PATTERNS {
        while fragment.match(pattern) != none { fragment = fragment.replace(pattern, "") }
      }
    }
    fragment = fragment.replace("``", "\u{201C}").replace("''", "\u{201D}")
    fragment = fragment.replace("`", "\u{2018}").replace("'", "\u{2019}")
    fragment
  }
  let family = _norm-name(name.at("family", default: ""))
  let given = _norm-name(name.at("given", default: ""))
  let prefix = _norm-name(name.at("prefix", default: ""))
  let suffix = _norm-name(name.at("suffix", default: ""))

  let _up-explicit = field.use-prefix-explicit(name, if entry != none { field.use-prefix-entry(entry) } else { none })
  let prefix-last = if _up-explicit != none { not _up-explicit } else { prefix-last }
  if family == "" and given == "" { return "" }
  if _is-org(name) { return family }
  if is-corp-name(name, entry: entry) { return given + " " + family }

  if language.is-cjk(given) or (given == "" and language.is-cjk(family)) { family + given }
  else {
    let style = name-style
    let family-case = style.at("family-case", default: none)
    let _cap-seg(s) = {
      let cl = s.clusters()
      if cl.len() == 0 { s } else { upper(cl.first()) + lower(cl.slice(1).join("")) }
    }
    let _apply-family-case(text-value) = {
      if family-case == "uppercase" { upper(text-value) }
      else if family-case == "lowercase" { lower(text-value) }
      else if family-case == "capitalize-first" {
        let segs = text-value.split(" ")
        segs.enumerate().map(((i, s)) => if i == 0 { _cap-seg(s) } else { lower(s) }).join(" ")
      }
      else if family-case == "capitalize-each" {
        text-value.split(" ").map(_cap-seg).join(" ")
      }
      else { text-value }
    }
    let formatted-family = _apply-family-case(family)
    let formatted-prefix = if prefix != "" { _apply-family-case(prefix).replace(" ", "\u{00A0}") + "\u{00A0}" } else { "" }
    let given-form = style.at("given-form", default: "initials")
    if type(given-form) == dictionary {
      given-form = if pinyin.is-name-pinyin(name) { given-form.at("pinyin", default: "full") }
        else { given-form.at("rest", default: "initials") }
    }
    let given-case = style.at("given-case", default: none)
    let _entry-lang = if entry != none { language.get(entry) } else { none }
    let _pick(value, fallback) = if type(value) == dictionary { punct.pick-separator-by-lang(value, _entry-lang, fallback) } else { value }
    let _dim(key, fallback) = _pick(style.at(key, default: fallback), fallback)
    let _sep(value) = {
      let resolved = punct.resolve-separator(value, entry, punct-style, custom-punct, value)
      if type(resolved) == str { resolved } else { value }
    }

    let given-initial-separator = {
      let value = _dim("given-initial-separator", "")
      if type(value) == str and value in punct.separator-char-set { _sep(value).trim(regex("\\s+"), at: end) } else { value }
    }
    let given-separator = {
      let value = _dim("given-separator", none)
      if value == none { none } else { _sep(value) }
    }
    let family-given-separator = _sep(_dim("family-given-separator", " "))
    let given-family-separator = _sep(_dim("given-family-separator", " "))
    let formatted-given = if given == "" or given-form == none { "" } else {
      let segments = ()
      let connectors = ()
      let _forced-space = ()
      let parts = given.split(regex("\\s+")).filter(p => p.len() > 0)
      for (part-index, part) in parts.enumerate() {
        let subsegments = part.split("-").filter(s => s.len() > 0)
        for (sub-index, subsegment) in subsegments.enumerate() {
          segments.push(subsegment)
          if sub-index < subsegments.len() - 1 { connectors.push("-") }
        }
        if part-index < parts.len() - 1 { connectors.push(" ") }
      }
      if given-form == "pinyin-initials" {
        let expanded = ()
        let expanded-connectors = ()
        let forced = ()
        for (segment-index, s) in segments.enumerate() {
          let split = pinyin.split-syllables(lower(s))
          if split != none {
            let head-len = split.first().clusters().len()
            let tail = s.clusters().slice(head-len)
            expanded.push(s.clusters().slice(0, head-len).join(""))
            expanded.push(upper(tail.first()) + tail.slice(1).join(""))
            expanded-connectors.push(" "); forced.push(true)
          } else { expanded.push(s) }
          if segment-index < connectors.len() { expanded-connectors.push(connectors.at(segment-index)); forced.push(false) }
        }
        segments = expanded
        connectors = expanded-connectors
        _forced-space = forced
      }
      let shaped = if given-form == "initials" or given-form == "pinyin-initials" {

        segments.map(s => s.clusters().first() + given-initial-separator)
      } else {
        let _capitalize(s) = { let cl = s.clusters(); upper(cl.first()) + lower(cl.slice(1).join("")) }
        segments.enumerate().map(((segment-index, s)) => {
          if given-case == "uppercase" { upper(s) }
          else if given-case == "lowercase" { lower(s) }
          else if given-case == "capitalize-first" { if segment-index == 0 { _capitalize(s) } else { lower(s) } }
          else if given-case == "capitalize-each" { _capitalize(s) }
          else { s }
        })
      }
      let _tie(separator) = if given-form in ("initials", "pinyin-initials") and separator == " " { "\u{00A0}" } else { separator }
      if given-separator == none {
        let rejoined = ""
        for (segment-index, s) in shaped.enumerate() {
          rejoined += s
          if segment-index < connectors.len() { rejoined += _tie(connectors.at(segment-index)) }
        }
        rejoined
      } else {
        let rejoined = ""
        for (segment-index, s) in shaped.enumerate() {
          rejoined += s
          if segment-index < connectors.len() {
            let forced = _forced-space.len() > segment-index and _forced-space.at(segment-index)
            rejoined += _tie(if forced { " " } else { given-separator })
          }
        }
        rejoined
      }
    }

    let formatted-given = if type(formatted-given) == str { formatted-given.trim(regex("\\s+"), at: end) } else { formatted-given }
    let order = style.at("order", default: "family-ahead")
    let order = if std.type(order) == dictionary { order.at(if name-index == 0 { "first" } else { "rest" }, default: "family-ahead") } else { order }
    let result = if order == "given-ahead" {
      if formatted-given != "" { formatted-given + given-family-separator + formatted-prefix + formatted-family }
      else { formatted-prefix + formatted-family }
    } else if prefix-last and prefix != "" {

      let end-prefix = prefix.replace(" ", "\u{00A0}")
      let assembled = formatted-family
      if formatted-given != "" { assembled += family-given-separator + formatted-given }
      assembled + " " + end-prefix
    } else {
      let assembled = formatted-prefix + formatted-family
      if formatted-given != "" { assembled += family-given-separator + formatted-given }
      assembled
    }
    if suffix != "" {
      let suffix-separator = if name-suffix-separator != auto { _sep(_pick(name-suffix-separator, ", ")) } else { ", " }
      result += suffix-separator + suffix.trim(".", at: end)
    }
    result
  }
}

#let et-al-role-keys = ("principal", "host", "editor", "translator", "rest")

#let et-al-role-of-field = (
  author: "principal", holder: "principal", editora: "principal",
  bookauthor: "host",
  editor: "editor", translator: "translator",
)

#let _pick-et-al-by-lang(value, entry, param) = {
  if type(value) != dictionary { return value }
  for key in value.keys() {
    if key not in punct.separator-lang-keys {
      errors.raise("et-al.unknown-lang-key", param: param, key: key, keys: punct.separator-lang-keys.join(" / "))
    }
  }
  let lang = if entry != none { language.get(entry) } else { none }
  if lang != none and lang in value { return value.at(lang) }
  if "rest" in value { return value.at("rest") }
  errors.raise("et-al.no-lang-fallback", param: param, lang: if lang == none { "未能判定" } else { lang })
}

#let resolve-et-al(value, role, entry, param: "et-al-min") = {
  if type(value) != dictionary { return value }
  let keys = value.keys()
  for key in keys {
    if key not in et-al-role-keys and key not in punct.separator-lang-keys {
      errors.raise("et-al.unknown-key", param: param, key: key,
        roles: et-al-role-keys.filter(k => k != "rest").join(" / "),
        langs: punct.separator-lang-keys.filter(k => k != "rest").join(" / "))
    }
  }
  let role-keys = keys.filter(k => k in et-al-role-keys and k != "rest")
  let lang-keys = keys.filter(k => k in punct.separator-lang-keys and k != "rest")
  if role-keys.len() > 0 and lang-keys.len() > 0 {
    errors.raise("et-al.mixed-keys", param: param, roles: role-keys.join(" / "), langs: lang-keys.join(" / "))
  }
  if role-keys.len() == 0 { return _pick-et-al-by-lang(value, entry, param) }
  let picked = if role in value { value.at(role) } else if "rest" in value { value.at("rest") } else {
    errors.raise("et-al.no-role-fallback", param: param, role: role)
  }
  _pick-et-al-by-lang(picked, entry, param)
}

#let resolve-et-al-triple(et-al-min, et-al-use-first, et-al-use-last, role, entry) = {
  let min = resolve-et-al(et-al-min, role, entry, param: "et-al-min")
  let use-first = resolve-et-al(et-al-use-first, role, entry, param: "et-al-use-first")
  let use-last = resolve-et-al(et-al-use-last, role, entry, param: "et-al-use-last")
  if use-last > 0 and use-first + use-last > min - 1 {
    errors.raise("et-al.use-last-too-few-omitted", min: min, first: use-first, last: use-last,
      role: role, lang: if entry != none { language.get(entry) } else { "未能判定" })
  }
  (min: min, use-first: use-first, use-last: use-last)
}

#let truncate(names, et-al-min, et-al-use-first, show-et-al, et-al-use-last: 0) = {
  let has-others = names.last().at("family", default: "") == "others" and names.last().at("given", default: "") == ""
  let real-names = if has-others { names.slice(0, -1) } else { names }

  let should-truncate = has-others or real-names.len() >= et-al-min
  let show-count = if should-truncate { calc.min(real-names.len(), et-al-use-first) } else { real-names.len() }
  let needs-etal = (has-others or show-count < real-names.len()) and show-et-al
  let last-count = if et-al-use-last > 0 and needs-etal and not has-others {
    calc.min(et-al-use-last, real-names.len() - show-count)
  } else { 0 }
  if last-count > 0 { needs-etal = false }

  (real-names: real-names, show-count: show-count, last-count: last-count,
   needs-etal: needs-etal, bare-etal: needs-etal and show-count == 0)
}

#let _NAMEFORMAT-FIELD-STYLES = (
  uppercase: (family-case: "uppercase", given-form: "initials"),
  lowercase: (family-case: none, given-form: "initials"),
  givenahead: (order: "given-ahead", family-case: "uppercase", given-form: "initials"),
  familyahead: (family-case: "uppercase", given-form: "initials"),
  fullname: (order: "given-ahead", family-case: none, given-form: "full", given-separator: "", given-case: "capitalize-each"),
  pinyin: (family-case: "uppercase", given-form: "full", given-separator: "-", given-case: "capitalize-first"),
  quanpin: (family-case: none, given-form: "full", given-separator: "", given-case: "capitalize-first"),
)

#let format(parsed-names, role: "author", et-al-role: "principal", entry: none, et-al-min: 4, et-al-use-first: 3, et-al-use-last: 0, show-et-al: true, name-style: (:), first-name-style: none, punct-style: "half-with-space", custom-punct: (:), custom-terms: (:), name-suffix-separator: auto, prefix-last: false, version: 2025) = {
  let names = parsed-names.at(role, default: ())
  if names == () or names.len() == 0 { return none }
  let (min: et-al-min, use-first: et-al-use-first, use-last: et-al-use-last) = resolve-et-al-triple(et-al-min, et-al-use-first, et-al-use-last, et-al-role, entry)

  if entry != none {
    let _name-format = entry.fields.at("nameformat", default: none)
    if _name-format != none and type(_name-format) == str and _name-format.trim() != "" {
      let format-key = _name-format.trim().replace("-", "")
      if format-key in _NAMEFORMAT-FIELD-STYLES {
        name-style = _NAMEFORMAT-FIELD-STYLES.at(format-key)
      }
    }
  }
  let (real-names, show-count, last-count, needs-etal, bare-etal) = truncate(names, et-al-min, et-al-use-first, show-et-al, et-al-use-last: et-al-use-last)
  let _one(name-index) = format-one(real-names.at(name-index), name-style: if name-index == 0 and first-name-style != none { first-name-style } else { name-style }, name-suffix-separator: name-suffix-separator, prefix-last: prefix-last, entry: entry, punct-style: punct-style, custom-punct: custom-punct, name-index: name-index)
  let comma = if entry != none { punct.get("comma", entry, punct-style, custom-punct) } else { ", " }
  let result = range(show-count).map(_one).join(comma)
  if last-count > 0 {
    let tail-start = real-names.len() - last-count
    result += comma + punct.get("ellipsis", entry, punct-style, custom-punct) + range(tail-start, real-names.len()).map(_one).join(comma)
  } else if needs-etal {
    result += (if bare-etal { "" } else { comma }) + terms.etal(entry, custom-terms: custom-terms, version: version)
  }
  result
}

#let default-roles(entry, component-part: false) = if component-part {
  ("author", "translator", "holder")
} else if mark-medium.mark(entry) == "P" {
  ("holder", "author", "editor", "translator", "editora")
} else {
  ("author", "editor", "translator", "holder", "editora")
}

#let principal-names(entry, roles: auto) = {
  let roles = if roles == auto { default-roles(entry) } else { roles }
  for role in roles {
    let role-names = entry.parsed_names.at(role, default: ())
    if role-names.len() > 0 { return (role: role, names: role-names) }
  }
  (role: none, names: ())
}

#let person-key(person) = if person == none { "" } else {
  str(person.at("family", default: "")) + "\u{1F}" + str(person.at("given", default: "")) + "\u{1F}" + str(person.at("prefix", default: "")) + "\u{1F}" + str(person.at("suffix", default: ""))
}

#let roster-key(entry) = {
  let principal = principal-names(entry)
  if principal.names.len() == 0 { return "" }
  principal.names.map(person-key).join("\u{1E}")
}

#let principal(entry, et-al-min: 4, et-al-use-first: 3, et-al-use-last: 0, show-anon: false, show-et-al: true, name-style: (:), first-name-style: none, punct-style: "half-with-space", custom-punct: (:), custom-terms: (:), name-suffix-separator: auto, roles: auto, prefix-last: false, version: 2025) = {
  let _principal-name = principal-names(entry, roles: roles)
  if _principal-name.role != none {
    return format(entry.parsed_names, role: _principal-name.role, entry: entry, et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-et-al: show-et-al, name-style: name-style, first-name-style: first-name-style, punct-style: punct-style, custom-punct: custom-punct, custom-terms: custom-terms, name-suffix-separator: name-suffix-separator, prefix-last: prefix-last, version: version)
  }
  if show-anon { terms.anon(entry, custom-terms: custom-terms) } else { none }
}

#let _other(entry, role, role-term, et-al-min: 4, et-al-use-first: 3, et-al-use-last: 0, show-et-al: true, name-style: (:), punct-style: "half-with-space", custom-punct: (:), custom-terms: (:), name-suffix-separator: auto, prefix-last: false, et-al-translator-separator: auto, version: 2025) = {
  let names = entry.parsed_names.at(role, default: ())
  if names.len() == 0 { return none }
  let comma = punct.get("comma", entry, punct-style, custom-punct)
  let (min: et-al-min, use-first: et-al-use-first, use-last: et-al-use-last) = resolve-et-al-triple(et-al-min, et-al-use-first, et-al-use-last, role, entry)

  let (real-names, show-count, last-count, needs-etal, bare-etal) = truncate(names, et-al-min, et-al-use-first, show-et-al, et-al-use-last: et-al-use-last)
  let _one(name-index) = format-one(real-names.at(name-index), name-style: name-style, name-suffix-separator: name-suffix-separator, prefix-last: prefix-last, entry: entry, punct-style: punct-style, custom-punct: custom-punct, name-index: name-index)
  let formatted = range(show-count).map(_one).join(comma)
  if last-count > 0 {
    let tail-start = real-names.len() - last-count
    formatted += comma + punct.get("ellipsis", entry, punct-style, custom-punct) + range(tail-start, real-names.len()).map(_one).join(comma)
  }
  let translator-separator = if et-al-translator-separator == auto { auto } else { punct.resolve-separator(et-al-translator-separator, entry, punct-style, custom-punct, auto) }
  formatted + terms.role(entry, role-term, needs-etal, comma, bare-etal: bare-etal, custom-terms: custom-terms, et-al-translator-separator: translator-separator, version: version, plural: names.len() > 1)
}
#let other-editor(entry, et-al-min: 4, et-al-use-first: 3, et-al-use-last: 0, show-et-al: true, name-style: (:), punct-style: "half-with-space", custom-punct: (:), custom-terms: (:), name-suffix-separator: auto, prefix-last: false, version: 2025) = _other(entry, "editor", "ed", et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-et-al: show-et-al, name-style: name-style, punct-style: punct-style, custom-punct: custom-punct, custom-terms: custom-terms, name-suffix-separator: name-suffix-separator, prefix-last: prefix-last, version: version)
#let other-translator(entry, et-al-min: 4, et-al-use-first: 3, et-al-use-last: 0, show-et-al: true, name-style: (:), punct-style: "half-with-space", custom-punct: (:), custom-terms: (:), name-suffix-separator: auto, prefix-last: false, et-al-translator-separator: auto, version: 2025) = _other(entry, "translator", "trans", et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-et-al: show-et-al, name-style: name-style, punct-style: punct-style, custom-punct: custom-punct, custom-terms: custom-terms, name-suffix-separator: name-suffix-separator, prefix-last: prefix-last, et-al-translator-separator: et-al-translator-separator, version: version)
