#import "../field.typ"
#import "mark-medium/built-in.typ" as mark-medium
#import "imprint/date.typ" as publication-date

#let modified(entry) = {
  let date-field = field.get(entry, "date")
  if date-field == none { return none }
  let parsed-date = publication-date.parsed(entry, "date")
  if parsed-date == none { return none }
  publication-date.format-parsed-date(parsed-date)
}

#let _URLDATE-TYPES = ("EB", "DB", "CP", "DS", "PP")

#let urldate(entry, show-urldate: true, version: 2015) = {
  if not show-urldate { return none }
  let urldate-value = field.get(entry, "urldate")
  if urldate-value == none { return none }
  if version == 2025 and mark-medium.mark(entry) not in _URLDATE-TYPES { return none }
  let parsed-date = publication-date.parsed(entry, "urldate")
  if parsed-date == none { return none }
  "[" + publication-date.format-date-point(if "start" in parsed-date { parsed-date.start } else { parsed-date.end }) + "]"
}
