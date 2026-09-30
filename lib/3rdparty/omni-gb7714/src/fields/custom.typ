#import "../punct/built-in.typ" as punct
#import "../errors.typ"
#import "../terms/built-in.typ" as terms
#import "../terms/custom.typ": reserved-term-names, reserved-bib-fields

#let validate-fields(custom-fields) = {
  if custom-fields == none or custom-fields == (:) { return }
  for (name, definition) in custom-fields {
    if str(name) in reserved-term-names {
      errors.raise("custom-fields.built-in-name", name: str(name))
    }
    if definition == auto { continue }
    if type(definition) != dictionary {
      errors.raise("custom-fields.bad-value", name: str(name))
    }
    let field-name = definition.at("field", default: none)
    if field-name == none {
      errors.raise("custom-fields.missing-field", name: str(name))
    }
    if str(field-name) in reserved-bib-fields {
      errors.raise("custom-fields.field-conflict", name: str(name), field: str(field-name))
    }
    for key in ("prefix", "suffix") {
      let v = definition.at(key, default: none)
      if v != none and type(v) != str and type(v) != dictionary {
        errors.raise("custom-fields.affix-not-str", name: str(name), key: key)
      }
    }
  }
}

#let resolve-field(name, definition, entry, correct-punct: false, punct-style: "half-with-space", custom-punct: (:)) = {
  let field-name = if definition == auto { name } else if type(definition) == dictionary { definition.at("field", default: none) } else { none }
  if field-name == none { return none }
  let value = punct.field-text(entry, str(field-name), correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct, force-correct: true)
  if value == none or value == "" { return none }
  if definition == auto { return value }
  let prefix = terms.localized(definition.at("prefix", default: none), entry)
  let suffix = terms.localized(definition.at("suffix", default: none), entry)
  if prefix != none or suffix != none {
    let prefix-text = if prefix != none { prefix } else { "" }
    let suffix-text = if suffix != none { suffix } else { "" }
    return [#prefix-text#value#suffix-text]
  }
  value
}
