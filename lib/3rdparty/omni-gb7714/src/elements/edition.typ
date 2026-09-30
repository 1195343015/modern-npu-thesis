#import "../field.typ"
#import "../terms/built-in.typ" as terms
#import "../punct/built-in.typ" as punct
#import "mark-medium/built-in.typ" as mark-medium

#let edition(entry, version: 2015, custom-terms: (:)) = {
  let _mark = mark-medium.mark(entry)
  let edition-value = if _mark == "R" {
    let version-value = punct.field-text(entry, "version")
    if version-value != none { version-value } else { punct.field-text(entry, "edition") }
  } else { punct.field-text(entry, "edition") }
  if edition-value == none { return none }
  if type(edition-value) != str { return edition-value }
  let edition-str = edition-value.trim()
  let m = edition-str.match(regex("^(\\d+)$"))
  if m != none {
    let n = int(m.captures.first()); if n <= 1 { return none }
    terms.edition(entry, n, version: version, custom-terms: custom-terms)
  } else {

    edition-str
  }
}

#let resolve-version(entry, punct-style, custom-punct) = {
  let raw-version = field.get(entry, "version")
  if raw-version == none { return none }
  let version-text = punct.field-text(entry, "version", correct-punct: false, punct-style: punct-style)
  if lower(str(raw-version)).starts-with("v") { version-text } else { [V#version-text] }
}
