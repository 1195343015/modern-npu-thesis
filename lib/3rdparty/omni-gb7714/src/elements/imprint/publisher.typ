#import "../../punct/built-in.typ" as punct
#import "../mark-medium/built-in.typ" as mark-medium

#let publisher(entry) = {
  let _mark = mark-medium.mark(entry)
  let chain = if entry.entry_type == "periodical" or _mark in ("A", "D") {
    ("institution", "publisher", "school", "organization")
  } else {
    ("publisher", "school", "organization", "institution")
  }
  for field-name in chain {
    let value = punct.field-text(entry, field-name); if value != none { return value }
  }
  none
}

#let platform(entry, mark) = {
  if mark == "DS" { publisher(entry) }
  else if mark == "PP" {
    let value = punct.field-text(entry, "archiveprefix")
    if value == none { value = punct.field-text(entry, "eprinttype") }
    if value == none { value = publisher(entry) }
    value
  } else { none }
}
