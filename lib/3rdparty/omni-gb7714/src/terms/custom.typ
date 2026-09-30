#import "../detect/lang.typ" as language
#import "../errors.typ"
#import "./built-in.typ": built-in-term-keys

#let reserved-bib-fields = (
  "author", "creator", "editor", "translator", "bookauthor", "holder",
  "title", "titles", "subtitle", "titleaddon",
  "booktitle", "booktitles", "booksubtitle", "booktitleaddon",
  "journal", "journaltitles", "journaltitle", "shortjournal", "journalsubtitle", "journaltitleaddon",
  "series", "edition", "version", "volume", "number", "pages", "eid",
  "year", "date", "urldate", "month", "day",
  "publisher", "school", "organization", "institution",
  "address", "location",
  "url", "doi", "isbn", "issn", "eprint", "eprinttype", "archiveprefix",
  "type", "note", "keywords",
  "langid", "language",
  "related", "relatedtype",
  "sortkey", "key", "mark", "usera", "entrysubtype", "medium",

  "scale", "dimensions", "eventtitle", "eventdate", "eventyear", "cstr", "entrytypeid", "entrymediumid",
)

#let reserved-term-names = (
  "author", "editor", "editor-other", "translator", "bookauthor", "holder",
  "title", "subtitle", "titleaddon",
  "title-block", "component-part-title-block",
  "mark", "mark-medium",
  "booktitle", "booksubtitle", "booktitleaddon",
  "journal", "journaltitle", "shortjournal", "journalsubtitle", "journaltitleaddon",
  "series", "series-block",
  "edition", "version", "volume", "number", "pages",
  "year", "date", "urldate", "month", "day",
  "address", "location", "publisher", "imprint-block",
  "school", "organization", "institution",
  "url", "doi", "isbn", "issn", "eprint", "eprinttype", "archiveprefix", "medium",
  "type", "keywords",
  "access", "degree-annotation", "country", "note",

  "scale", "dimensions", "eventtitle", "eventdate", "cstr",
)

#let _structural-keys = ("field", "bib-field", "prefix", "suffix", "pid", "resolver")

#let _number-branches(v, unwrap) = {
  let is-pair = type(v) == dictionary and ("singular" in v or "plural" in v)
  if unwrap {
    if not is-pair { return (("", v),) }
    return v.pairs().filter(pair => pair.first() in ("singular", "plural"))
  }
  if type(v) != dictionary { return (("", v),) }
  if is-pair { return v.pairs().filter(pair => pair.first() in ("singular", "plural")) }
  v.pairs()
}

#let validate-terms(custom-terms) = {
  if custom-terms == none or custom-terms == (:) { return }
  for (name, definition) in custom-terms {
    let is-built-in-word = str(name) in built-in-term-keys
    if not is-built-in-word and str(name) in reserved-term-names {
      errors.raise("custom-terms.structural-name", name: str(name), allowed: built-in-term-keys.join("、"))
    }
    if str(name) in ("edition", "volume", "pages", "footnote-number") {
      let allowed = if str(name) == "footnote-number" { ("prefix", "suffix", "supplement-separator") } else { ("prefix", "suffix") }
      if type(definition) != dictionary { errors.raise("custom-terms.bad-value", name: str(name)) }
      for (k, v) in _number-branches(definition, false) {
        if type(v) != dictionary { errors.raise("custom-terms.wrap-value-not-pair", name: str(name), key: str(k)) }
        for (_, branch) in _number-branches(v, true) {
          if type(branch) != dictionary { errors.raise("custom-terms.wrap-value-not-pair", name: str(name), key: str(k)) }
          for (wrap-key, _) in branch {
            if wrap-key not in allowed { errors.raise("custom-terms.wrap-bad-key", name: str(name), key: str(wrap-key), allowed: allowed.map(a => "`" + a + "`").join(" / ")) }
          }
        }
      }
      continue
    }
    if str(name) == "ibid" {
      let _check-ibid-parts(v, lang-key) = {
        for (part-key, part-value) in v {
          if part-key not in ("text", "supplement-separator") { errors.raise("custom-terms.ibid-bad-key", key: str(part-key)) }
          if part-value != none and type(part-value) != str { errors.raise("custom-terms.lang-value-not-str", name: "ibid", key: lang-key) }
        }
      }
      if type(definition) == str { continue }
      if type(definition) != dictionary { errors.raise("custom-terms.bad-value", name: "ibid") }
      if "text" in definition or "supplement-separator" in definition { _check-ibid-parts(definition, "ibid") }
      else {
        for (k, v) in definition {
          if type(v) == dictionary { _check-ibid-parts(v, str(k)) }
          else if v != none and type(v) != str { errors.raise("custom-terms.lang-value-not-str", name: "ibid", key: str(k)) }
        }
      }
      continue
    }
    if type(definition) == str { continue }
    if type(definition) != dictionary {
      errors.raise("custom-terms.bad-value", name: str(name))
    }
    for structural in _structural-keys {
      if structural in definition {
        errors.raise("custom-terms.structural-key", name: str(name), key: structural)
      }
    }
    for (k, v) in _number-branches(definition, false) {

      for (_, branch) in _number-branches(v, true) {
        if branch != none and type(branch) != str {
          errors.raise("custom-terms.lang-value-not-str", name: str(name), key: str(k))
        }
      }
    }
  }
}

#let resolve-term(name, definition, entry) = {
  if type(definition) == str { return definition }
  if type(definition) != dictionary { return none }
  let lang = language.get(entry)
  if lang in definition {
    let v = definition.at(lang)
    if v != none and v != "" { return v }
  }
  for (k, v) in definition {
    if v != none and v != "" { return v }
  }
  none
}
