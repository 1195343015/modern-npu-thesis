#import "../../field.typ"
#import "../../errors.typ"
#import "../../terms/built-in.typ" as terms
#import "../../terms/custom.typ": reserved-term-names, reserved-bib-fields

#let _plain(v) = {
  if type(v) == str { v } else if type(v) == content and v.has("text") { v.text } else { repr(v) }
}

#let _resolve-label-base(definition, entry, fallback-name) = {
  let raw = definition.at("prefix", default: none)
  let resolved = if raw == none { fallback-name } else { terms.localized(raw, entry) }
  if resolved == none { resolved = fallback-name }
  let s = _plain(resolved).trim()
  while s.ends-with(":") or s.ends-with("：") { s = s.slice(0, -1).trim() }
  s
}

#let label-text(definition, entry, fallback-name) = _resolve-label-base(definition, entry, fallback-name)

#let strip-label-prefix(value, label) = {
  let value-str = str(value).trim()
  if label == none or str(label) == "" { return value-str }
  let head = lower(str(label)) + ":"
  if lower(value-str).starts-with(head) { return value-str.slice(head.len()).trim() }
  value-str
}

#let resolve-custom(definition, v) = {
  let value-str = str(v).trim()
  let value-lower = lower(value-str)
  if value-lower.starts-with("http://") or value-lower.starts-with("https://") or value-lower.starts-with("ftp://") { return value-str }
  let resolver = if type(definition) == dictionary { definition.at("resolver", default: none) } else { none }
  if resolver == none { return none }
  let resolver-str = str(resolver)
  if resolver-str.contains("{}") { resolver-str.replace("{}", value-str) } else { resolver-str + value-str }
}

#let _built-in-pid-names = ("doi", "cstr", "isbn", "issn", "eprint")

#let _is-pid(definition) = type(definition) == dictionary and definition.at("field", default: none) != none

#let order-names(custom-pids) = {
  let order = ()
  for (term-name, definition) in custom-pids {
    if str(term-name) in _built-in-pid-names { continue }
    if _is-pid(definition) and str(term-name) not in order { order.push(str(term-name)) }
  }
  order
}

#let note-label-candidates(custom-pids) = {
  let out = ()
  for name in _built-in-pid-names {
    if name == "eprint" { continue }
    out.push((upper(name), name))
  }
  if type(custom-pids) != dictionary { return out }
  for (name, definition) in custom-pids {
    if type(definition) != dictionary { continue }
    let field-name = str(definition.at("field", default: str(name)))
    out.push((str(name), field-name))
    let prefix = definition.at("prefix", default: none)
    if type(prefix) == str { out.push((prefix, field-name)) }
    else if type(prefix) == dictionary { for (_, v) in prefix { out.push((str(v), field-name)) } }
  }
  out
}

#let emit(term-name, custom-pids, entry, effective-fn, pcolon, brk, link) = {
  let definition = custom-pids.at(term-name, default: none)
  if not _is-pid(definition) { return none }
  let field-name = definition.at("field", default: none)
  let value = field.get(entry, str(field-name))
  if value == none or value == "" { return none }
  if not effective-fn(term-name, value) { return none }
  let label = upper(label-text(definition, entry, str(field-name)))
  let value = strip-label-prefix(value, label)
  link(resolve-custom(definition, value), [#label#pcolon#(brk(value))])
}

#let validate-pids(custom-pids) = {
  if custom-pids == none or custom-pids == (:) { return }
  for (name, definition) in custom-pids {
    let is-override = str(name) in _built-in-pid-names
    if not is-override and str(name) in reserved-term-names {
      errors.raise("custom-pids.structural-name", name: str(name), allowed: _built-in-pid-names.join("、"))
    }
    if type(definition) != dictionary {
      errors.raise("custom-pids.bad-value", name: str(name))
    }
    let field-name = definition.at("field", default: none)
    if field-name == none and not is-override {
      errors.raise("custom-pids.missing-field", name: str(name))
    }
    if field-name != none and str(field-name) in reserved-bib-fields and not is-override {
      errors.raise("custom-pids.field-conflict", name: str(name), field: str(field-name))
    }
    let prefix = definition.at("prefix", default: none)
    if prefix != none and type(prefix) != str and type(prefix) != dictionary {
      errors.raise("custom-pids.prefix-bad", name: str(name))
    }
    let resolver = definition.at("resolver", default: none)
    if resolver != none and type(resolver) != str {
      if str(name) != "eprint" or type(resolver) != dictionary {
        errors.raise("custom-pids.resolver-bad", name: str(name))
      }
      for (platform, url-template) in resolver {
        if type(url-template) != str {
          errors.raise("custom-pids.resolver-bad", name: str(name) + "." + str(platform))
        }
      }
    }
  }
}
