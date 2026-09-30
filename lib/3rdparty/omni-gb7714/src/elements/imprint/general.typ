#import "../../field.typ"
#import "../../terms/built-in.typ" as terms
#import "../../punct/built-in.typ" as punct
#import "../mark-medium/built-in.typ" as mark-medium
#import "../../category.typ"
#import "location.typ": location
#import "publisher.typ": publisher, platform
#import "date.typ" as publication-date

#let _missing-set = (
  "[S.l.]", "[s.l.]", "[S. l.]", "[S.L.]",
  "S.l.",   "s.l.",   "S. l.",   "S.L.",
  "[s.n.]", "[S.n.]", "[S.N.]",
  "s.n.",   "S.n.",   "S.N.",
  "[出版地不详]", "[出版者不详]",
  "出版地不详", "出版者不详",
  "[不详]", "不详",
)

#let is-missing(v) = {
  if v == none { return true }
  if type(v) != str { return false }
  let s = v.trim()
  s == "" or s in _missing-set
}

#let location-publisher(location-value, publisher-value, p) = {
  if location-value != none and publisher-value != none { location-value + p("colon") + publisher-value }
  else if publisher-value != none { publisher-value }
  else if location-value != none { location-value }
  else { none }
}

#let _imprint-fragment(entry) = {
  let empty(..names) = names.pos().all(n => field.get(entry, n) == none)
  (empty("author", "editor", "translator")
    and empty("title", "journaltitle", "maintitle", "booktitle", "issuetitle", "number"))
}

#let format(entry, show-sine-loco: auto, show-sine-nomine: auto, show-sine-anno: false, skip-date: false, date-suffix: "", use-full-date: false, date-override: auto, punct-style: "half-with-space", custom-punct: (:), custom-terms: (:), version: 2015) = {
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let _mark-early = mark-medium.mark(entry)

  {
    let _report-has-location = (not is-missing(punct.field-text(entry, "location"))) or (not is-missing(punct.field-text(entry, "address")))
    if version == 2025 and _mark-early == "R" and not _report-has-location {
      let date-value = publication-date.date(entry)
      if date-value != none { return date-value }
      let year-value = publication-date.year(entry)
      if year-value != none { return year-value }
      return none
    }
  }
  let location-value = location(entry)
  let publisher-value = publisher(entry)
  if type(location-value) == str and location-value.trim() == "" { location-value = none }
  if type(publisher-value) == str and publisher-value.trim() == "" { publisher-value = none }

  let year = if date-override != auto { date-override }
    else if skip-date { none }
    else if use-full-date { publication-date.date(entry) }
    else { publication-date.year(entry) }
  if year != none and date-suffix != "" { year = publication-date.with-suffix(year, date-suffix) }

  let _mark = _mark-early
  let skip-placeholder-by-type = category.lacks-imprint-slot(entry) or (_mark == "Z" and field.has-online(entry))

  if not skip-placeholder-by-type {
    let _sine-loco = terms.sine-loco(entry, custom-terms: custom-terms)
    let _sine-nomine = terms.sine-nomine(entry, custom-terms: custom-terms)
    let _date-supplied = show-sine-anno and year == none and not skip-date
    let _sine-anno-word = if _date-supplied { terms.sine-anno(entry, custom-terms: custom-terms) } else { none }
    let _has-date = field.get(entry, "date") != none or field.get(entry, "year") != none
    let _fragment-no-fill = _imprint-fragment(entry) and (field.has-online(entry) or not _has-date)
    let need = (missing, show-value, other) => missing == none and (show-value == true or (show-value == auto and other != none and not _fragment-no-fill))
    let need-sine-loco = need(location-value, show-sine-loco, publisher-value)
    let need-sine-nomine = need(publisher-value, show-sine-nomine, location-value)
    if need-sine-loco and need-sine-nomine {

      if _date-supplied {
        return "[" + _sine-loco + p("colon") + _sine-nomine + p("comma") + _sine-anno-word + "]"
      } else if year != none {
        return "[" + _sine-loco + p("colon") + _sine-nomine + "]" + p("comma") + year
      }
    } else if need-sine-nomine and _date-supplied {

      publisher-value = "[" + _sine-nomine + p("comma") + _sine-anno-word + "]"
      year = none
    } else {
      if need-sine-loco { location-value = "[" + _sine-loco + "]" }
      if need-sine-nomine { publisher-value = "[" + _sine-nomine + "]" }
      if _date-supplied { year = "[" + _sine-anno-word + "]" }
    }
  }

  if location-value == none and publisher-value == none and year == none { return none }
  let location-publisher-value = location-publisher(location-value, publisher-value, p)
  if location-publisher-value != none and year != none { location-publisher-value + p("comma") + year }
  else if year != none { year } else { location-publisher-value }
}
