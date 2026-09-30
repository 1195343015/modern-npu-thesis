#import "../detect/lang.typ" as language
#import "../errors.typ"

#let _spec-keys = ("italic", "bold", "prefix", "suffix")

#let _valid-slots = ("titles", "journaltitles", "booktitles", "series", "creator", "volume", "issue", "date")

#let _validate-spec(spec, slot) = {
  for (k, val) in spec {
    if k not in _spec-keys { errors.raise("emphasis.bad-key", slot: slot, key: str(k), keys: _spec-keys.join(" / ")) }
    if k in ("italic", "bold") and type(val) != bool { errors.raise("emphasis.bad-key", slot: slot, key: str(k), keys: "布尔值") }
  }
}

#let validate(emphasis) = {
  if emphasis == auto { return }
  if type(emphasis) != dictionary { errors.raise("emphasis.not-dict") }
  for (slot, v) in emphasis {
    if str(slot) not in _valid-slots { errors.raise("emphasis.bad-slot", slot: str(slot), slots: _valid-slots.join(" / ")) }
    if v == none { continue }
    if type(v) != dictionary { errors.raise("emphasis.bad-value", slot: str(slot)) }

    if v.keys().any(k => k not in _spec-keys) {
      for (_, atom) in v {
        if atom == none { continue }
        if type(atom) != dictionary { errors.raise("emphasis.bad-value", slot: str(slot)) }
        _validate-spec(atom, str(slot))
      }
    } else {
      _validate-spec(v, str(slot))
    }
  }
}

#let resolve-spec(emphasis, slot, entry) = {
  if type(emphasis) != dictionary { return none }
  let v = emphasis.at(slot, default: none)
  if v == none or v == () { return none }
  if type(v) != dictionary { return none }
  let is-lang-split = v.keys().any(k => k not in _spec-keys)
  if is-lang-split {
    let lang = language.get(entry)
    let atom = v.at(lang, default: v.at("rest", default: none))
    if type(atom) != dictionary { return none }
    return atom
  }
  v
}

#let apply(content, spec) = {
  if spec == none or content == none { return content }
  let out = content
  if spec.at("italic", default: false) { out = emph(out) }
  if spec.at("bold", default: false) { out = strong(out) }
  let prefix = spec.at("prefix", default: none)
  let suffix = spec.at("suffix", default: none)
  if prefix != none { out = [#prefix#out] }
  if suffix != none { out = [#out#suffix] }
  out
}

#let decorate(content, emphasis, slot, entry) = apply(content, resolve-spec(emphasis, slot, entry))
