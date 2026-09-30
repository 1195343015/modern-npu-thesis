#import "../sentinel.typ": *
#import "latex.typ"

#let TYPE-MAP = (
  "article-journal": "article",
  "article-magazine": "article",
  "article-newspaper": "newspaper",
  "article": "article",
  "review": "article",
  "review-book": "article",
  "book": "book",

  "chapter": "inbook",
  "paper-conference": "inproceedings",
  "thesis": "thesis",
  "report": "report",
  "patent": "patent",
  "webpage": "online",
  "post": "online",
  "post-weblog": "online",
  "dataset": "dataset",
  "software": "software",
  "standard": "standard",

  "manuscript": "archive",
  "entry": "inreference",
  "entry-dictionary": "inreference",
  "entry-encyclopedia": "inreference",
  "map": "map",
  "legislation": "legislation",
  "bill": "legislation",
  "legal_case": "misc",
  "personal_communication": "letter",
  "speech": "misc",
  "figure": "image",
  "graphic": "image",
  "motion_picture": "video",
  "broadcast": "video",
  "song": "music",
  "musical_score": "misc",
  "pamphlet": "booklet",
  "periodical": "periodical",

  "collection": "archive",
  "document": "misc",
)
#let map-type(csl-type) = TYPE-MAP.at(lower(str(csl-type)), default: "misc")

#let CONTAINER-AS-BOOKTITLE = ("incollection", "inproceedings", "inbook", "inreference", "map")
#let container-field(entry-type) = if entry-type in CONTAINER-AS-BOOKTITLE { "booktitle" } else { "journaltitle" }

#let LANG-MAP = (
  "en": "english", "en-us": "english", "en-gb": "english",
  "zh": "chinese", "zh-cn": "chinese", "zh-tw": "chinese", "zh-hans": "chinese", "zh-hant": "chinese",
  "fr": "french", "fr-fr": "french",
  "de": "german", "de-de": "german",
  "ja": "japanese", "ko": "korean",
  "ru": "russian", "es": "spanish", "it": "italian", "pt": "portuguese",
  "nl": "dutch", "la": "latin",
)
#let map-lang(code) = LANG-MAP.at(lower(str(code)), default: str(code))

#let escape-text(s) = {
  let t = str(s)

  t = t.replace("---", "\u{2014}").replace("--", "\u{2013}")
  t = t.replace("\\", _SBS)
  t = t.replace("$", _SD).replace("~", _ST)
  t = t.replace("&", _SAMP).replace("_", _SUND).replace("#", _SHSH).replace("%", _SPCT).replace("^", _SCIRC)
  t = t.replace("{", _SLBR).replace("}", _SRBR)
  latex.normalize-html(t)
}

#let parse-name(csl-name) = {
  if type(csl-name) != dictionary { return (family: str(csl-name), given: "", prefix: "", suffix: "") }
  let lit = csl-name.at("literal", default: none)
  if lit != none and str(lit).trim() != "" { return (family: str(lit), given: "", prefix: "", suffix: "") }
  let ndp = str(csl-name.at("non-dropping-particle", default: ""))
  let ddp = str(csl-name.at("dropping-particle", default: ""))
  (
    family: str(csl-name.at("family", default: "")),
    given: str(csl-name.at("given", default: "")),
    prefix: if ndp.trim() != "" { ndp } else { ddp },
    suffix: str(csl-name.at("suffix", default: "")),
  )
}

#let parse-name-string(s) = {
  let t = str(s).trim()
  if t.contains(",") {
    let i = t.position(",")
    (family: t.slice(0, i).trim(), given: t.slice(i + 1).trim(), prefix: "", suffix: "")
  } else {
    (family: t, given: "", prefix: "", suffix: "")
  }
}

#let name-string(names) = names.map(n => {
  let head = (n.prefix + " " + n.family).trim()
  if n.given.trim() != "" { head + ", " + n.given } else { head }
}).join(" and ")

#let NAME-ROLES = (
  "author": "author",
  "editor": "editor",
  "translator": "translator",
  "container-author": "bookauthor",
  "collection-editor": "editor",
)

#let _point(part) = {
  let p = (year: int(part.at(0)))
  if part.len() >= 2 and str(part.at(1)).trim() not in ("", "0") { p.insert("month", int(part.at(1))) }
  if part.len() >= 3 and str(part.at(2)).trim() not in ("", "0") { p.insert("day", int(part.at(2))) }
  p
}
#let _point-str(p) = {
  let pad(n) = if n < 10 { "0" + str(n) } else { str(n) }
  let s = str(p.year)
  if "month" in p { s += "-" + pad(p.month) }
  if "day" in p { s += "-" + pad(p.day) }
  s
}
#let parse-date(csl-date) = {
  if type(csl-date) == str { return (parsed: none, raw: csl-date) }
  if type(csl-date) != dictionary { return (parsed: none, raw: none) }
  let circa = csl-date.at("circa", default: false)
  let approximate = (circa == true or circa == "true" or circa == 1)
  let dp = csl-date.at("date-parts", default: none)
  if type(dp) != array or dp.len() == 0 or type(dp.at(0)) != array or dp.at(0).len() == 0 {
    let lit = csl-date.at("literal", default: csl-date.at("raw", default: none))
    return (parsed: none, raw: if lit != none { str(lit) } else { none })
  }
  let start = _point(dp.at(0))
  if dp.len() >= 2 and type(dp.at(1)) == array and dp.at(1).len() > 0 {
    let end = _point(dp.at(1))
    return (
      parsed: (kind: "between", uncertain: false, approximate: approximate, start: start, end: end),
      raw: _point-str(start) + "/" + _point-str(end),
    )
  }
  (parsed: (kind: "at", uncertain: false, approximate: approximate, start: start), raw: _point-str(start))
}

#let parse-date-string(s) = {
  let t = str(s).trim()
  let point-from(m) = {
    let p = (year: int(m.captures.at(0)))
    if m.captures.at(1) != none { p.insert("month", int(m.captures.at(1))) }
    if m.captures.at(2) != none { p.insert("day", int(m.captures.at(2))) }
    p
  }
  let single = regex("^(\\d{4})(?:-(\\d{1,2}))?(?:-(\\d{1,2}))?$")
  if t.contains("/") {
    let ends = t.split("/")
    let sm = ends.at(0).trim().match(single)
    let em = ends.at(1).trim().match(single)
    if sm != none and em != none {
      let start = point-from(sm)
      let end = point-from(em)
      return (parsed: (kind: "between", uncertain: false, approximate: false, start: start, end: end), raw: _point-str(start) + "/" + _point-str(end))
    }
    return (parsed: none, raw: t)
  }
  let m = t.match(single)
  if m != none {
    let start = point-from(m)
    return (parsed: (kind: "at", uncertain: false, approximate: false, start: start), raw: _point-str(start))
  }
  (parsed: none, raw: t)
}

#let DATE-KEYS = (
  "issued": "date",
  "accessed": "urldate",
  "event-date": "eventdate",
  "original-date": "origdate",
  "submitted": "date",
)

#let TEXT-FIELDS = (
  "title": "title",
  "title-short": "shorttitle",
  "publisher": "publisher",
  "publisher-place": "location",
  "collection-title": "series",
  "genre": "type",
  "event": "eventtitle",
  "event-title": "eventtitle",
  "event-place": "venue",
  "note": "note",
  "abstract": "abstract",
  "status": "pubstate",

  "scale": "scale",
  "dimensions": "dimensions",
)
#let RAW-FIELDS = (
  "volume": "volume",
  "edition": "edition",
  "version": "version",
  "page": "pages",
  "DOI": "doi",
  "URL": "url",
  "ISBN": "isbn",
  "ISSN": "issn",
  "call-number": "callnumber",
)

#let _LABEL-ALIAS = (
  "pages": "page",
  "place": "publisher-place",
  "series": "collection-title", "series-title": "collection-title", "seriestitle": "collection-title",
  "short-title": "title-short", "shorttitle": "title-short",
  "abstract-note": "abstract", "abstractnote": "abstract",
  "eventplace": "event-place",
  "meeting-name": "event-title", "meetingname": "event-title",
  "conference-name": "event-title", "conferencename": "event-title",
  "publication-title": "container-title", "publicationtitle": "container-title",
  "book-title": "container-title", "booktitle": "container-title",
  "version-number": "version", "versionnumber": "version",
  "callnumber": "call-number",
  "date": "issued",
  "access-date": "accessed", "accessdate": "accessed",
  "filing-date": "submitted", "filingdate": "submitted",
  "originaldate": "original-date",
  "book-author": "container-author", "bookauthor": "container-author",
  "series-editor": "collection-editor", "serieseditor": "collection-editor",
)

#let _ARTICLE-LIKE-TYPES = ("article", "newspaper")

#let _CSL-VARS = (
  "author", "chair", "collection-editor", "compiler", "composer", "container-author", "contributor",
  "curator", "director", "editor", "editor-translator", "editorial-director", "executive-producer",
  "guest", "host", "illustrator", "interviewer", "narrator", "organizer", "original-author",
  "performer", "producer", "recipient", "reviewed-author", "script-writer", "series-creator", "translator",
  "accessed", "available-date", "event-date", "issued", "original-date", "submitted",
  "abstract", "annote", "archive", "archive-collection", "archive-location", "archive-place",
  "authority", "call-number", "chapter-number", "citation-key", "citation-label", "citation-number",
  "collection-number", "collection-title", "collection-title-short", "container-title",
  "container-title-short", "dimensions", "division", "DOI", "edition", "event", "event-title",
  "event-place", "first-reference-note-number", "genre", "ISBN", "ISSN", "jurisdiction", "keyword",
  "language", "license", "medium", "note", "number", "number-of-pages", "number-of-volumes",
  "original-publisher", "original-publisher-place", "original-title", "page", "page-first",
  "part-number", "part-title", "PMCID", "PMID", "printing-number", "publisher", "publisher-place",
  "references", "reviewed-genre", "reviewed-title", "scale", "section", "source", "status",
  "supplement-number", "title", "title-short", "URL", "version", "volume", "volume-title",
  "volume-title-short", "year-suffix",
)

#let classify(raw-var, entry-type: none) = {
  let csl-var = _LABEL-ALIAS.at(raw-var, default: raw-var)
  if csl-var in NAME-ROLES { return (kind: "name", key: NAME-ROLES.at(csl-var)) }
  if csl-var in DATE-KEYS { return (kind: "date", key: DATE-KEYS.at(csl-var)) }
  if csl-var in TEXT-FIELDS { return (kind: "text", key: TEXT-FIELDS.at(csl-var)) }
  if csl-var in RAW-FIELDS { return (kind: "raw", key: RAW-FIELDS.at(csl-var)) }

  if csl-var == "issue" { return (kind: "raw", key: "issue") }
  if csl-var == "number" {
    return (kind: "raw", key: if entry-type in _ARTICLE-LIKE-TYPES { "eid" } else { "number" })
  }

  if csl-var == "jurisdiction" and entry-type == "patent" { return (kind: "text", key: "location") }

  if csl-var == "archive" and entry-type in ("archive", "letter", "legislation") { return (kind: "text", key: "institution") }
  if csl-var == "archive-place" and entry-type in ("archive", "letter", "legislation") { return (kind: "text", key: "location") }

  if csl-var in ("archive-location", "archive_location") and entry-type in ("archive", "letter", "legislation") { return (kind: "raw", key: "number") }
  if csl-var == "language" { return (kind: "lang", key: "langid") }
  if csl-var == "PMID" { return (kind: "pmid", key: "eprint") }
  if csl-var == "container-title" { return (kind: "container", key: none) }

  if csl-var == "volume-title" { return (kind: "text", key: "volume-title") }

  if csl-var in _CSL-VARS { return (kind: "drop", key: none) }
  (kind: "unknown", key: none)
}

#let swap-volume-title(fields) = {
  let volume-title = fields.at("volume-title", default: none)
  if volume-title == none or str(volume-title).trim() == "" { return fields }
  if "title" in fields and "maintitle" not in fields { fields.insert("maintitle", fields.at("title")) }
  fields.insert("title", volume-title)
  let _ = fields.remove("volume-title")
  fields
}
