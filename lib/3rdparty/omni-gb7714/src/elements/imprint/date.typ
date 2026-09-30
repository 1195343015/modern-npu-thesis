#import "../../field.typ"
#import "../../parse/latex.typ"

#let edtf-year(s) = {
  if s.ends-with("~") or s.ends-with("?") or s.ends-with("%") {
    "[" + s.slice(0, -1) + "]"
  } else { s }
}

#let parsed(entry, key) = {
  let d = entry.at("parsed_dates", default: (:)).at(key, default: none)
  if d == none { return none }
  let start-ok = "start" in d and d.start.year != 0
  let end-ok = "end" in d and d.end.year != 0
  if "start" in d and not start-ok { let _ = d.remove("start") }
  if "end" in d and not end-ok { let _ = d.remove("end") }
  if not start-ok and not end-ok { return none }
  if d.kind == "between" {
    if start-ok and not end-ok { d.kind = "after" } else if end-ok and not start-ok { d.kind = "before" }
  }
  d
}

#let _parsed-date-year(parsed-date) = str((if "start" in parsed-date { parsed-date.start } else { parsed-date.end }).year)

#let zero-pad(number) = if number < 10 { "0" + str(number) } else { str(number) }

#let _literal-date(date-field) = latex.to-typst(edtf-year(str(date-field)))

#let format-date-point(point) = {
  let result = str(point.year)
  if "month" in point { result += "-" + zero-pad(point.month) }
  if "day" in point { result += "-" + zero-pad(point.day) }
  result
}

#let format-parsed-date(parsed-date, range-separator: "—") = {
  let body = if parsed-date.kind == "between" { format-date-point(parsed-date.start) + range-separator + format-date-point(parsed-date.end) } else if parsed-date.kind == "after" { format-date-point(parsed-date.start) + "—" } else if parsed-date.kind == "before" { "—" + format-date-point(parsed-date.end) } else { format-date-point(parsed-date.start) }
  if parsed-date.approximate or parsed-date.uncertain { "[" + body + "]" } else { body }
}

#let year(entry) = {
  let date-field = field.get(entry, "date")
  if date-field != none {
    let parsed-date = parsed(entry, "date")
    if parsed-date == none { return _literal-date(date-field) }
    let year-str = _parsed-date-year(parsed-date)
    if parsed-date.approximate or parsed-date.uncertain { "[" + year-str + "]" } else { year-str }
  } else {
    let year-field = field.get(entry, "year")
    if year-field != none { edtf-year(str(year-field)) } else { none }
  }
}

#let date(entry, range-separator: "—") = {
  let date-field = field.get(entry, "date")
  if date-field != none {
    let parsed-date = parsed(entry, "date")
    if parsed-date == none { return _literal-date(date-field) }
    format-parsed-date(parsed-date, range-separator: range-separator)
  } else {
    let year-field = field.get(entry, "year")
    if year-field != none { edtf-year(str(year-field)) } else { none }
  }
}

#let with-suffix(year, suffix) = {
  if year == none or suffix == "" { return year }
  if type(year) == str and year.starts-with("[") and year.ends-with("]") {
    year.slice(0, -1) + suffix + "]"
  } else { year + suffix }
}
