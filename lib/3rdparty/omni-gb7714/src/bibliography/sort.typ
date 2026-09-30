#import "@preview/auto-pinyin:0.1.0" as _auto-pinyin
#import "@preview/auto-bihua:0.2.0": bihua-count as _bihua-count, bihua-order as _bihua-order
#import "../sentinel.typ": *
#import "../errors.typ"
#import "../field.typ"
#import "../elements/creators.typ" as creators
#import "../terms/built-in.typ" as terms
#import "../detect/lang.typ" as language
#import "../elements/imprint/date.typ" as publication-date

#let lang-key(entry, entry-lang-order: ("zh", "ja", "ko", "en", "fr", "ru")) = {
  if entry-lang-order.len() == 0 { return "01" }
  let lang = language.get(entry)
  let index = entry-lang-order.position(l => l == lang)
  let rank = if index != none { index + 1 } else { entry-lang-order.len() + 1 }
  let text-value = str(rank)
  "0" * calc.max(0, 2 - text-value.len()) + text-value
}

#let _normalize(s) = {
  lower(str(s)).replace(regex("[^a-z0-9]"), "")
}

#let _pinyin(s) = {
  if s == none or s == "" { return "" }
  let text = str(s)

  if not language.is-cjk(text) { return _normalize(text) }
  let parts = _auto-pinyin.to-pinyin(text, style: "tone-num-end")
  _normalize(parts.join(""))
}

#let _bihua(s) = {
  if s == none or s == "" { return "" }
  let key = ""
  for c in str(s).clusters() {
    let count = _bihua-count(c)
    let stroke-count = if type(count) == int { count } else { 0 }
    let stroke-order = _bihua-order(c)
    let order-str = if type(stroke-order) == str { stroke-order } else { "" }
    let count-str = str(stroke-count)
    key += "0" * calc.max(0, 3 - count-str.len()) + count-str + order-str
  }
  key
}

#let collate(s, lang, sort-zh-by) = {
  if sort-zh-by == "bihua" and lang == "zh" { _bihua(s) } else { _pinyin(s) }
}

#let _names-str(names, sort-use-prefix: false, entry-use-prefix: none) = {
  let parts = ()
  for n in names {
    let family = str(n.at("family", default: ""))
    let given = str(n.at("given", default: ""))
    let prefix = if field.use-prefix-eff(n, entry-use-prefix, sort-use-prefix) { str(n.at("prefix", default: "")) } else { "" }
    if family != "" or given != "" {
      parts.push((if prefix != "" { prefix + " " } else { "" }) + family + " " + given)
    }
  }
  parts.join(" ")
}

#let _noopsort(v) = {
  if v == none { return none }
  let sort-match = str(v).match(regex("\\\\noopsort\\s*\\{([^{}]*)\\}"))
  if sort-match != none { sort-match.captures.at(0) } else { none }
}

#let _name-key(entry, sort-zh-by: "pinyin", sort-use-prefix: false, show-anon: false, custom-terms: (:)) = {
  let sort-key = field.get(entry, "sortkey")
  if sort-key != none { return _normalize(sort-key) }
  let key-value = field.get(entry, "key")
  if key-value != none { return _normalize(key-value) }

  let _collate = if sort-zh-by == "bihua" and language.get(entry) == "zh" { _bihua } else { _pinyin }
  let entry-use-prefix = field.use-prefix-entry(entry)
  let authors = entry.parsed_names.at("author", default: ())
  if authors.len() > 0 {
    let noop-name = _noopsort(field.get(entry, "author"))
    return if noop-name != none { _normalize(noop-name) } else { _collate(_names-str(authors, sort-use-prefix: sort-use-prefix, entry-use-prefix: entry-use-prefix)) }
  }
  let editors = entry.parsed_names.at("editor", default: ())
  if editors.len() > 0 {
    let noop-name = _noopsort(field.get(entry, "editor"))
    return if noop-name != none { _normalize(noop-name) } else { _collate(_names-str(editors, sort-use-prefix: sort-use-prefix, entry-use-prefix: entry-use-prefix)) }
  }

  if show-anon and creators.principal-names(entry).names.len() == 0 {
    return _collate(str(terms.anon(entry, custom-terms: custom-terms)))
  }
  let title-value = field.get(entry, "title")
  if title-value == none { return "" }
  let noop-name = _noopsort(title-value)
  if noop-name != none { _normalize(noop-name) } else { _collate(str(title-value)) }
}

#let date-key(entry) = {
  let raw = publication-date.year(entry)
  let head = if raw != none { raw.split("/").first() } else { "9999" }
  let digits = head.find(regex("\\d+"))
  let value = if digits != none { int(digits) } else { 999999 }
  let text-value = str(value)
  "0" * calc.max(0, 6 - text-value.len()) + text-value
}

#let sort-by-keys = ("name", "date", "title")
#let cite-sort-by-keys = ("name", "date")
#let sort-by-orders = ("ascending", "descending")

#let normalize-sort-by(value, keys: sort-by-keys, param: "sort-by") = {
  if value == none { return none }
  if type(value) != array { errors.raise("sort-by.not-array", param: param, got: repr(value)) }
  let specs = ()
  for element in value {
    if type(element) == str {
      if element not in keys { errors.raise("sort-by.unknown-key", param: param, key: element, keys: keys.join(" / ")) }
      specs.push((element, "ascending"))
    } else if type(element) == dictionary {
      if element.len() != 1 { errors.raise("sort-by.dict-size", param: param, got: repr(element)) }
      let name = element.keys().first()
      let order = element.values().first()
      if name not in keys { errors.raise("sort-by.unknown-key", param: param, key: name, keys: keys.join(" / ")) }
      if type(order) != str or order not in sort-by-orders {
        errors.raise("sort-by.bad-order", param: param, key: name, order: repr(order), orders: sort-by-orders.join(" / "))
      }
      specs.push((name, order))
    } else {
      errors.raise("sort-by.bad-element", param: param, got: repr(element))
    }
  }
  specs
}

#let apply(filtered, opts) = {
  let (sort-by, eff-entry-lang-order, sort-zh-by, eff-sort-use-prefix, sort-keys, show-anon, custom-terms) = opts
  if sort-by != none and sort-by.len() > 0 {
    for (name, order) in sort-by.rev() {
      let key-of = if name == "name" {
        pair => _name-key(pair.at(1), sort-zh-by: sort-zh-by, sort-use-prefix: eff-sort-use-prefix, show-anon: show-anon, custom-terms: custom-terms)
      } else if name == "date" {
        pair => date-key(pair.at(1))
      } else {

        pair => collate(str(pair.at(1).fields.at("title", default: "")), language.get(pair.at(1)), sort-zh-by)
      }
      filtered = if order == "descending" { filtered.rev().sorted(key: key-of).rev() } else { filtered.sorted(key: key-of) }
    }

    filtered = filtered.sorted(key: pair => lang-key(pair.at(1), entry-lang-order: eff-entry-lang-order))
  }

  if sort-keys != none {
    let sort-key-seen = ()
    let sort-key-dedup = ()
    for k in sort-keys {
      if k not in sort-key-seen { sort-key-seen.push(k); sort-key-dedup.push(k) }
    }
    let in-order = sort-key-dedup.filter(k => filtered.map(p => p.at(0)).contains(k))
    let rest = filtered.filter(p => p.at(0) not in sort-key-dedup)
    filtered = in-order.map(k => filtered.find(p => p.at(0) == k)) + rest
  }
  filtered
}
