#import "../sentinel.typ": *
#import "../elements/mark-medium/built-in.typ" as mark-medium
#import "../field.typ"
#import "../detect/lang.typ" as language
#import "../terms/built-in.typ" as terms
#import "../punct/built-in.typ" as punct
#import "../elements/creators.typ" as creators
#import "../elements/titles.typ" as titles
#import "../elements/emphasis.typ" as emphasis
#import "../parse/latex.typ"
#import "../elements/access.typ": access, has-visible-path
#import "../elements/date.typ"
#import "../elements/imprint/general.typ" as imprint
#import "../elements/imprint/date.typ" as publication-date
#import "../elements/edition.typ"
#import "../elements/pages.typ"
#import "../category.typ"

#let _join(parts, separator) = {
  let filtered = parts.filter(p => p != none and p != "" and p != [])
  let separator-is-period = type(separator) == str and separator.trim(at: start).starts-with(".")
  let result = []
  let previous-trailing = ""
  for (i, p) in filtered.enumerate() {
    if i > 0 {
      let s = separator
      if separator-is-period and previous-trailing.trim().ends-with(".") {
        s = separator.trim(".", at: start, repeat: false)
      }
      result += s
    }
    result += p
    if separator-is-period { previous-trailing = punct.trailing-text(p) }
  }
  result
}
#let _join-creator(creator, rest, period-separator, period-after: true) = {
  if creator == none or creator == "" or creator == [] {
    _join(rest, period-separator)
  } else if period-after {
    _join((creator,) + rest, period-separator)
  } else {
    let body = _join(rest, period-separator)
    if body == none or body == "" or body == [] { creator } else { [#creator #body] }
  }
}

#let _pages-separator(entry, punct-style, custom-punct, space-before-pages) = {
  let use-full-pages-separator = punct.resolve-dir(punct-style, punct.is-cj-entry(entry)) == "full"
  if use-full-pages-separator or punct.has-override(custom-punct, "colon") { punct.get("colon", entry, punct-style, custom-punct) }
  else { ":" + (if space-before-pages { " " } else { "" }) }
}

#let _other-creators(entry, opts) = {
  let (dedup-author-editor, et-al-min, et-al-use-first, et-al-use-last, show-et-al, name-style, punct-style, custom-punct, name-suffix-separator, ..) = opts
  let raw-author = entry.parsed_names.at("author", default: ())
  let raw-editor = entry.parsed_names.at("editor", default: ())
  let has-real-author = raw-author.len() > 0
  let _mark = mark-medium.mark(entry)

  let editor-other = if _mark != "D" and has-real-author and not (dedup-author-editor and raw-author == raw-editor) {
    creators.other-editor(entry, et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-et-al: show-et-al, name-style: name-style, punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)), name-suffix-separator: name-suffix-separator, prefix-last: opts.at("prefix-last", default: false), version: opts.at("version", default: 2025))
  } else { none }
  let translator = if _mark != "D" and (has-real-author or raw-editor.len() > 0) {
    creators.other-translator(entry, et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-et-al: show-et-al, name-style: name-style, punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)), name-suffix-separator: name-suffix-separator, prefix-last: opts.at("prefix-last", default: false), et-al-translator-separator: opts.at("et-al-translator-separator", default: auto), version: opts.at("version", default: 2025))
  } else { none }
  (editor: editor-other, translator: translator)
}

#let _creator(entry, opts, roles: auto) = {
  let (skip-creator, et-al-min, et-al-use-first, et-al-use-last, show-anon, show-et-al, name-style, punct-style, custom-punct, name-suffix-separator, ..) = opts
  let raw = if skip-creator { none }
    else if opts.at("creator-override", default: none) != none { opts.creator-override }
    else { creators.principal(entry, et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-anon: show-anon, show-et-al: show-et-al, name-style: name-style, punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)), name-suffix-separator: name-suffix-separator, roles: roles, prefix-last: opts.at("prefix-last", default: false), version: opts.at("version", default: 2025)) }
  emphasis.decorate(raw, opts.at("emphasis", default: (:)), "creator", entry)
}
#let _access(entry, opts) = {
  let (show-url, hyperlink, show-pid, pid-priority, dedup-url-pid, custom-pids, punct-style, custom-punct, url-break-every, url-break-hyphen, url-break-hyphen-at-delimiters, version, ..) = opts
  access(entry, show-url: show-url, hyperlink: hyperlink, show-pid: show-pid, pid-priority: pid-priority, dedup-url-pid: dedup-url-pid, custom-pids: custom-pids, punct-style: punct-style, custom-punct: custom-punct, pid-colon-style: opts.at("pid-colon-style", default: auto), url-break-every: url-break-every, url-break-hyphen: url-break-hyphen, url-break-hyphen-at-delimiters: url-break-hyphen-at-delimiters, version: version)
}

#let _online(entry, opts) = has-visible-path(
  entry,
  show-url: opts.show-url,
  show-pid: opts.at("show-pid", default: (:)),
  custom-pids: opts.at("custom-pids", default: (:)),
  dedup-url-pid: opts.at("dedup-url-pid", default: true),
  version: opts.version,
)

#let _title(entry, opts, is-component-part: false, title-spec: none, preprint: false) = titles.format(
  entry, is-component-part: is-component-part, preprint: preprint, online: _online(entry, opts),
  show-mark: opts.show-mark, show-medium: opts.show-medium, show-url: opts.show-url,
  space-before-mark: opts.space-before-mark, mark-medium-bracket-style: opts.at("mark-medium-bracket-style", default: "half"), show-patent-country: opts.at("show-patent-country", default: false), hyperlink-title: opts.hyperlink-title,
  correct-punct: opts.correct-punct, punct-style: opts.punct-style, custom-punct: opts.custom-punct,
  custom-terms: opts.at("custom-terms", default: (:)),
  version: opts.version, title-spec: title-spec,
  volume-title-gutter: opts.at("volume-title-gutter", default: auto),
)

#let degree(entry, show-degree: false, custom-terms: (:)) = {
  if not show-degree { return none }
  let entry-type = entry.entry_type
  let degree = if entry-type == "mastersthesis" { "MA" }
    else if entry-type == "phdthesis" { "PhD" }
    else if entry-type == "thesis" {
      let type-value = field.get(entry, "type")
      let type-value-str = if type-value != none { str(type-value) } else { "" }
      let type-value = lower(type-value-str)

      if type-value.contains("phd") or type-value.contains("doctor") or type-value-str.contains("博士") or type-value-str.contains("박사") { "PhD" }
      else if type-value.contains("master") or type-value == "mathesis" or type-value-str.contains("硕士") or type-value-str.contains("修士") or type-value-str.contains("석사") { "MA" }
      else { return none }
    }
    else { return none }
  terms.degree(entry, degree, custom-terms: custom-terms)
}

#let monograph(entry, opts) = {
  let (show-sine-loco, show-sine-nomine, show-sine-anno, et-al-min, et-al-use-first, et-al-use-last, show-url, show-mark, show-medium, short-journal, show-urldate, hyperlink, space-before-mark, space-before-pages, page-range-separator, period-after-creator, show-anon, show-et-al, name-style, hyperlink-title, dedup-author-editor, skip-date, skip-creator, show-degree, correct-punct, punct-style, custom-punct, url-break-every, url-break-hyphen, name-suffix-separator, version, show-pid, pid-priority, dedup-url-pid, custom-pids, ..) = opts
  let p = name => punct.get(name, entry, punct-style, custom-punct)

  let _mark = mark-medium.mark(entry)

  if version == 2025 and _mark == "S" {

    let head = _title(entry, opts)
    let access = _access(entry, opts)
    return _join((head, access), p("period"))
  }
  let creator = _creator(entry, opts)
  let title = _title(entry, opts, title-spec: emphasis.resolve-spec(opts.at("emphasis", default: (:)), "titles", entry))
  let other-creators = _other-creators(entry, opts)
  let editor-other = other-creators.editor
  let translator = other-creators.translator
  let edition-part = if _mark != "D" { edition.edition(entry, version: version, custom-terms: opts.at("custom-terms", default: (:))) } else { none }

  let _archival = entry.entry_type in ("archive", "letter", "legislation")
  let imprint-block = imprint.format(entry, show-sine-loco: show-sine-loco, show-sine-nomine: show-sine-nomine, show-sine-anno: show-sine-anno, skip-date: skip-date, use-full-date: _archival and version == 2025, date-suffix: opts.at("date-suffix", default: ""), punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)), version: version)
  let pages-part = pages.pages(entry, page-range-separator: page-range-separator, page-range-style: opts.at("page-range-style", default: none), override: opts.at("pages-override", default: none), punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)))
  let urldate = date.urldate(entry, show-urldate: show-urldate, version: version)
  let access = _access(entry, opts)
  if imprint-block != none and pages-part != none {
    let pages-separator = _pages-separator(entry, punct-style, custom-punct, space-before-pages)
    imprint-block = imprint-block + pages-separator + pages-part
  }
  if imprint-block != none and urldate != none { imprint-block = imprint-block + urldate }

  let _show-series = opts.at("show-series", default: false)
  let series-part = {
    let series = if _show-series { punct.field-text(entry, "series", correct-punct: correct-punct, punct-style: punct-style) } else { none }

    series = emphasis.decorate(series, opts.at("emphasis", default: (:)), "series", entry)
    let _mark = mark-medium.mark(entry)

    if series == none or _mark in ("S", "D", "R", "P", "N", "J") { none } else {
      let series-number = punct.number-field-text(entry, "number", correct-punct: correct-punct, punct-style: punct-style)
      if series-number != none {
        p("lparen") + series + p("comma") + series-number + p("rparen")
      } else {
        p("lparen") + series + p("rparen")
      }
    }
  }
  let degree-annotation = degree(entry, show-degree: show-degree, custom-terms: opts.at("custom-terms", default: (:)))
  let dimensions-part = if version == 2025 and _mark == "CM" { punct.field-text(entry, "dimensions") } else { none }
  let version-part = edition.resolve-version(entry, punct-style, custom-punct)
  _join-creator(creator, (title, degree-annotation, editor-other, translator, edition-part, version-part, imprint-block, series-part, dimensions-part, access), p("period"), period-after: period-after-creator)
}

#let component-part(entry, opts) = {
  let (show-sine-loco, show-sine-nomine, show-sine-anno, et-al-min, et-al-use-first, et-al-use-last, show-url, show-mark, show-medium, show-patent-country, short-journal, show-urldate, hyperlink, space-before-mark, space-before-pages, page-range-separator, period-after-creator, show-anon, show-et-al, name-style, hyperlink-title, dedup-author-editor, skip-date, skip-creator, show-degree, correct-punct, punct-style, custom-punct, url-break-every, url-break-hyphen, name-suffix-separator, version, show-pid, pid-priority, dedup-url-pid, custom-pids, ..) = opts
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let creator = _creator(entry, opts, roles: creators.default-roles(entry, component-part: true))
  let title = _title(entry, opts, is-component-part: true)
  let translator = creators.other-translator(entry, et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-et-al: show-et-al, name-style: name-style, punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)), name-suffix-separator: name-suffix-separator, prefix-last: opts.at("prefix-last", default: false), et-al-translator-separator: opts.at("et-al-translator-separator", default: auto), version: opts.at("version", default: 2025))

  let host-bookauthor = creators.format(entry.parsed_names, role: "bookauthor", et-al-role: "host", entry: entry, et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-et-al: show-et-al, name-style: name-style, punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)), name-suffix-separator: name-suffix-separator, prefix-last: opts.at("prefix-last", default: false), version: version)
  let host-editor = creators.format(entry.parsed_names, role: "editor", et-al-role: "host", entry: entry, et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last, show-et-al: show-et-al, name-style: name-style, punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)), name-suffix-separator: name-suffix-separator, prefix-last: opts.at("prefix-last", default: false), version: version)
  let host-creator = if host-bookauthor != none { host-bookauthor } else { host-editor }
  if dedup-author-editor and host-creator != none and creator != none and host-creator == creator { host-creator = none }
  let booktitle = punct.field-text(entry, "booktitle", correct-punct: correct-punct, punct-style: punct-style)

  if booktitle == none { booktitle = punct.field-text(entry, "eventtitle", correct-punct: correct-punct, punct-style: punct-style) }
  if booktitle == none { booktitle = punct.field-text(entry, "journaltitle", correct-punct: correct-punct, punct-style: punct-style) }
  if booktitle == none { booktitle = punct.field-text(entry, "journal", correct-punct: correct-punct, punct-style: punct-style) }
  booktitle = titles.addons(booktitle, entry, subtitle-key: "booksubtitle", titleaddon-key: "booktitleaddon", correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct)
  booktitle = emphasis.decorate(booktitle, opts.at("emphasis", default: (:)), "booktitles", entry)
  let number = punct.number-field-text(entry, "number", correct-punct: correct-punct, punct-style: punct-style); let _mark = mark-medium.mark(entry)

  let _has-host-imprint = field.get(entry, "publisher") != none or field.get(entry, "location") != none or field.get(entry, "address") != none
  if _mark == "C" and host-creator == none and not _has-host-imprint {
    let pages-part = pages.pages(entry, page-range-separator: page-range-separator, page-range-style: opts.at("page-range-style", default: none), override: opts.at("pages-override", default: none), punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)))
    let urldate = date.urldate(entry, show-urldate: show-urldate, version: version)
    let access = _access(entry, opts)
    let event = punct.field-text(entry, "eventtitle", correct-punct: correct-punct, punct-style: punct-style)
    if event == none { event = booktitle }
    let year = if skip-date { none } else { publication-date.year(entry) }
    let event-and-year = if event != none and year != none { [#event#p("comma")#year] }
      else if event != none { event } else { year }
    let body = title
    if event-and-year != none { body = [#body#(punct.resolve-separator(opts.at("component-part-separator", default: "//"), entry, punct-style, custom-punct, "//"))#event-and-year] }
    if pages-part != none {
      let pages-separator = _pages-separator(entry, punct-style, custom-punct, space-before-pages)
      body = [#body#pages-separator#pages-part]
    }
    if urldate != none { body = [#body#urldate] }
    return _join-creator(creator, (body, access), p("period"), period-after: period-after-creator)
  }
  let edition-part = edition.edition(entry, version: version, custom-terms: opts.at("custom-terms", default: (:)))
  let _conf-component-part = _mark == "C"

  let off-when-component-part = show-value => if _conf-component-part { false } else { show-value }
  let sine-loco = off-when-component-part(show-sine-loco)
  let sine-nomine = off-when-component-part(show-sine-nomine)
  let sine-anno = off-when-component-part(show-sine-anno)
  let imprint-block = imprint.format(entry, show-sine-loco: sine-loco, show-sine-nomine: sine-nomine, show-sine-anno: sine-anno, skip-date: skip-date, punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)), version: version)
  let pages-part = pages.pages(entry, page-range-separator: page-range-separator, page-range-style: opts.at("page-range-style", default: none), override: opts.at("pages-override", default: none), punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:))); let urldate = date.urldate(entry, show-urldate: show-urldate, version: version)
  let access = _access(entry, opts)
  let host-title = booktitle
  if host-title != none and number != none and _mark in ("S", "R") { host-title = host-title + p("colon") + number }

  let host-volume = titles.volume(entry, version: version, custom-terms: opts.at("custom-terms", default: (:)))
  if host-title != none and host-volume != none and not (number != none and _mark in ("S", "R")) {
    host-title = host-title + p("colon") + host-volume
  }
  let container = if host-creator == none and host-title == none { "" } else { _join((host-creator, host-title), p("period")) }
  let title-with-translator = if translator != none { title + p("period") + translator } else { title }
  let component-part-body = if container != "" { title-with-translator + punct.resolve-separator(opts.at("component-part-separator", default: "//"), entry, punct-style, custom-punct, "//") + container } else { title-with-translator }
  if imprint-block != none {
    if pages-part != none {
      let pages-separator = _pages-separator(entry, punct-style, custom-punct, space-before-pages)
      imprint-block = imprint-block + pages-separator + pages-part
    }
  } else if pages-part != none {
    let year-value = if skip-date { none } else { publication-date.year(entry) }
    imprint-block = if year-value != none { year-value + p("colon") + pages-part } else { pages-part }
  }
  if imprint-block != none and urldate != none { imprint-block = imprint-block + urldate }

  let series-part = {
    let series = if opts.at("show-series", default: false) { punct.field-text(entry, "series", correct-punct: correct-punct, punct-style: punct-style) } else { none }
    if series == none { none } else {
      let series-number = punct.number-field-text(entry, "number", correct-punct: correct-punct, punct-style: punct-style)
      let consumed-by-host-title = series-number != none and _mark in ("S", "R")
      if series-number != none and not consumed-by-host-title and _mark not in ("P", "J", "N") {
        p("lparen") + series + p("comma") + series-number + p("rparen")
      } else {
        p("lparen") + series + p("rparen")
      }
    }
  }
  let dimensions-part = if version == 2025 and _mark == "CM" { punct.field-text(entry, "dimensions") } else { none }
  _join-creator(creator, (component-part-body, edition-part, imprint-block, series-part, dimensions-part, access), p("period"), period-after: period-after-creator)
}

#let serial-article(entry, opts) = {
  let (show-sine-loco, show-sine-nomine, show-sine-anno, et-al-min, et-al-use-first, et-al-use-last, show-url, show-mark, show-medium, show-patent-country, short-journal, show-urldate, hyperlink, space-before-mark, space-before-pages, page-range-separator, period-after-creator, show-anon, show-et-al, name-style, hyperlink-title, dedup-author-editor, skip-date, skip-creator, show-degree, correct-punct, punct-style, custom-punct, url-break-every, url-break-hyphen, name-suffix-separator, version, show-pid, pid-priority, dedup-url-pid, custom-pids, ..) = opts
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let creator = _creator(entry, opts)
  let title = _title(entry, opts)
  let journal = titles.journal(entry, correct-punct, punct-style, custom-punct, short-journal)
  let volume = punct.field-text(entry, "volume")

  let number = punct.field-text(entry, "number"); if number == none { number = punct.field-text(entry, "issue") }
  let pages-part = pages.pages(entry, page-range-separator: page-range-separator, page-range-style: opts.at("page-range-style", default: none), override: opts.at("pages-override", default: none), punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)))

  let year = if skip-date { none } else if volume == none and number == none { publication-date.date(entry) } else { publication-date.year(entry) }
  let urldate = date.urldate(entry, show-urldate: show-urldate, version: version); let access = _access(entry, opts)
  let other-creators = _other-creators(entry, opts)
  let editor-other = other-creators.editor
  let translator = other-creators.translator
  let source = []
  let source-empty = true
  let _emph = opts.at("emphasis", default: (:))
  if journal != none {
    source += emphasis.decorate(journal, _emph, "journaltitles", entry)
    source-empty = false
  }
  if year != none {
    let year-dec = emphasis.decorate(year, _emph, "date", entry)
    source += if source-empty { year-dec } else { p("comma") + year-dec }
    source-empty = false
  }
  if volume != none {
    let volume-dec = emphasis.decorate(volume, _emph, "volume", entry)
    source += if source-empty { volume-dec } else { p("comma") + volume-dec }
    source-empty = false
  }
  if number != none { source += p("lparen") + emphasis.decorate(number, _emph, "issue", entry) + p("rparen") }
  if pages-part != none {
    let pages-separator = _pages-separator(entry, punct-style, custom-punct, space-before-pages)
    source += pages-separator + pages-part
  }
  if urldate != none { source += urldate }
  _join-creator(creator, (title, editor-other, translator, source, access), p("period"), period-after: period-after-creator)
}

#let serial-newspaper(entry, opts) = {
  let (show-sine-loco, show-sine-nomine, show-sine-anno, et-al-min, et-al-use-first, et-al-use-last, show-url, show-mark, show-medium, show-patent-country, short-journal, show-urldate, hyperlink, space-before-mark, space-before-pages, page-range-separator, period-after-creator, show-anon, show-et-al, name-style, hyperlink-title, dedup-author-editor, skip-date, skip-creator, show-degree, correct-punct, punct-style, custom-punct, url-break-every, url-break-hyphen, name-suffix-separator, version, show-pid, pid-priority, dedup-url-pid, custom-pids, ..) = opts
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let creator = _creator(entry, opts)
  let title = _title(entry, opts)
  let journal = titles.journal(entry, correct-punct, punct-style, custom-punct, false)
  let pub-date = if skip-date { none } else { publication-date.date(entry) }

  let number = punct.number-field-text(entry, "number", correct-punct: correct-punct, punct-style: punct-style)
  if number == none { number = punct.number-field-text(entry, "pages", correct-punct: correct-punct, punct-style: punct-style) }
  let urldate = date.urldate(entry, show-urldate: show-urldate, version: version)
  let access = _access(entry, opts)
  let other-creators = _other-creators(entry, opts)
  let editor-other = other-creators.editor
  let translator = other-creators.translator
  let source = []
  let _emph = opts.at("emphasis", default: (:))
  let has-journal = journal != none
  if has-journal {
    source += emphasis.decorate(journal, _emph, "journaltitles", entry)
  }
  if pub-date != none {
    if has-journal { source += p("comma") }
    source += emphasis.decorate(pub-date, _emph, "date", entry)
  }
  if number != none { source += p("lparen") + emphasis.decorate(number, _emph, "issue", entry) + p("rparen") }
  if urldate != none { source += urldate }
  _join-creator(creator, (title, editor-other, translator, source, access), p("period"), period-after: period-after-creator)
}

#let patent(entry, opts) = {
  let (show-sine-loco, show-sine-nomine, show-sine-anno, et-al-min, et-al-use-first, et-al-use-last, show-url, show-mark, show-medium, show-patent-country, short-journal, show-urldate, hyperlink, space-before-mark, space-before-pages, page-range-separator, period-after-creator, show-anon, show-et-al, name-style, hyperlink-title, dedup-author-editor, skip-date, skip-creator, show-degree, correct-punct, punct-style, custom-punct, url-break-every, url-break-hyphen, name-suffix-separator, version, show-pid, pid-priority, dedup-url-pid, custom-pids, ..) = opts
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let creator = _creator(entry, opts)

  let title = _title(entry, opts)

  let pub-date = publication-date.date(entry); let urldate = date.urldate(entry, show-urldate: show-urldate, version: version)
  let access = _access(entry, opts)
  let date-block = ""; if pub-date != none { date-block += pub-date }

  if version == 2025 and date-block != "" {
    let pages-part = pages.pages(entry, page-range-separator: page-range-separator, page-range-style: opts.at("page-range-style", default: none), override: opts.at("pages-override", default: none), punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)))
    if pages-part != none { date-block += _pages-separator(entry, punct-style, custom-punct, space-before-pages) + pages-part }
  }
  if urldate != none { date-block += urldate }
  if date-block == "" { date-block = none }
  _join-creator(creator, (title, date-block, access), p("period"), period-after: period-after-creator)
}

#let electronic(entry, opts) = {
  let (show-sine-loco, show-sine-nomine, show-sine-anno, et-al-min, et-al-use-first, et-al-use-last, show-url, show-mark, show-medium, show-patent-country, short-journal, show-urldate, hyperlink, space-before-mark, space-before-pages, page-range-separator, period-after-creator, show-anon, show-et-al, name-style, hyperlink-title, dedup-author-editor, skip-date, skip-creator, show-degree, correct-punct, punct-style, custom-punct, url-break-every, url-break-hyphen, name-suffix-separator, version, show-pid, pid-priority, dedup-url-pid, custom-pids, ..) = opts
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let creator = _creator(entry, opts)
  let title = _title(entry, opts)
  let other-creators = _other-creators(entry, opts)
  let editor-other = other-creators.editor
  let translator = other-creators.translator

  let publication-year = if skip-date { none } else {
    let year-field = field.get(entry, "year")
    if year-field != none { publication-date.edtf-year(str(year-field)) } else { none }
  }

  let modify-date = date.modified(entry)

  let pages-part = pages.pages(entry, page-range-separator: page-range-separator, page-range-style: opts.at("page-range-style", default: none), override: opts.at("pages-override", default: none), punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)))
  let urldate = date.urldate(entry, show-urldate: show-urldate, version: version)
  let access = _access(entry, opts)

  let mark-2025 = if version == 2025 { mark-medium.mark(entry) } else { "" }
  let _is-2025-platform-form = category.is-platform-form(entry, version: version)
  let has-real-publisher = if _is-2025-platform-form { false }
    else { imprint.publisher(entry) != none or field.get(entry, "address") != none or field.get(entry, "location") != none or field.get(entry, "year") != none }

  if has-real-publisher {
    let imprint-block = imprint.format(entry,
      show-sine-loco: false, show-sine-nomine: false, show-sine-anno: false,
      date-override: publication-year,
      punct-style: punct-style, custom-punct: custom-punct,
      custom-terms: opts.at("custom-terms", default: (:)), version: version)
    if pages-part != none {
      let pages-separator = _pages-separator(entry, punct-style, custom-punct, space-before-pages)
      imprint-block = if imprint-block != none { imprint-block + pages-separator + pages-part } else { pages-part }
    }
    let resource-dates = ""
    if modify-date != none { resource-dates += p("lparen") + modify-date + p("rparen") }
    if urldate != none { resource-dates += urldate }
    if resource-dates != "" {
      imprint-block = if imprint-block != none { imprint-block + resource-dates } else { resource-dates }
    }
    _join-creator(creator, (title, editor-other, translator, imprint-block, access), p("period"), period-after: period-after-creator)
  } else {
    let _2025-version-field = edition.resolve-version(entry, punct-style, custom-punct)
    let _2025-platform = imprint.platform(entry, mark-2025)
    let date-block = ""
    if not _is-2025-platform-form and publication-year != none { date-block += publication-year }
    if _2025-platform != none { date-block += _2025-platform }

    if version == 2025 and entry.entry_type in ("archive", "letter", "legislation") and modify-date != none {
      date-block += modify-date
    } else {
      let _platform-issued = if modify-date != none { modify-date } else if _is-2025-platform-form and publication-year != none { publication-year } else { none }
      if _platform-issued != none { date-block += p("lparen") + _platform-issued + p("rparen") }
    }

    if pages-part != none and date-block != "" and not _is-2025-platform-form { date-block += p("colon") + pages-part }
    if urldate != none { date-block += urldate }
    if date-block == "" { date-block = none }

    let parts = (creator, title, editor-other, translator)
    if _2025-version-field != none and mark-2025 not in ("EB", "CP") { parts.push(_2025-version-field) }
    parts.push(date-block)
    parts.push(access)
    _join(parts, p("period"))
  }
}

#let preprint(entry, opts) = {
  let (show-sine-loco, show-sine-nomine, show-sine-anno, et-al-min, et-al-use-first, et-al-use-last, show-url, show-mark, show-medium, show-patent-country, short-journal, show-urldate, hyperlink, space-before-mark, space-before-pages, page-range-separator, period-after-creator, show-anon, show-et-al, name-style, hyperlink-title, dedup-author-editor, skip-date, skip-creator, show-degree, correct-punct, punct-style, custom-punct, url-break-every, url-break-hyphen, name-suffix-separator, version, show-pid, pid-priority, dedup-url-pid, custom-pids, ..) = opts
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let creator = _creator(entry, opts)

  let title-mark = _title(entry, opts, preprint: true)

  let eprint = field.get(entry, "eprint")
  let journal = field.alias(entry, "journaltitle", "journal")

  let arxiv-id = if eprint != none {
    none
  } else if journal != none and lower(str(journal)).starts-with("arxiv") {
    let j = str(journal)
    let m = j.match(regex("(?i)arxiv[: ]*(?:preprint[: ]*)?(?:arxiv[: ]*)?(.+)"))
    if m != none { "arXiv:" + m.captures.first().trim() } else { j }
  } else { none }

  let pages-part = pages.pages(entry, page-range-separator: page-range-separator, page-range-style: opts.at("page-range-style", default: none), override: opts.at("pages-override", default: none), punct-style: punct-style, custom-punct: custom-punct, custom-terms: opts.at("custom-terms", default: (:)))
  let urldate = date.urldate(entry, show-urldate: show-urldate, version: version)
  let access = _access(entry, opts)

  let source = arxiv-id
  let imprint-block = imprint.format(entry,
    show-sine-loco: false, show-sine-nomine: false, show-sine-anno: false, skip-date: skip-date,
    punct-style: punct-style, custom-punct: custom-punct,
    custom-terms: opts.at("custom-terms", default: (:)), version: version)
  if pages-part != none {
    let pages-separator = _pages-separator(entry, punct-style, custom-punct, space-before-pages)
    imprint-block = if imprint-block != none { imprint-block + pages-separator + pages-part } else { pages-part }
  }
  if urldate != none { imprint-block = if imprint-block != none { imprint-block + urldate } else { urldate } }

  _join-creator(creator, (title-mark, source, imprint-block, access), p("period"), period-after: period-after-creator)
}

#let serial-year-volume(entry, opts) = {
  let punct-style = opts.punct-style
  let custom-punct = opts.custom-punct
  let skip-date = opts.skip-date
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let volume = punct.field-text(entry, "volume")

  let number = punct.field-text(entry, "number"); if number == none { number = punct.field-text(entry, "issue") }

  let start-year = none
  let end-year = none
  if not skip-date {
    let date-field = field.get(entry, "date")
    if date-field != none {
      let parsed-date = publication-date.parsed(entry, "date")
      if parsed-date != none {
        if "start" in parsed-date { start-year = str(parsed-date.start.year) }
        if "end" in parsed-date { end-year = str(parsed-date.end.year) }
      }
    } else {
      let year-field = field.get(entry, "year")
      if year-field != none {
        let year-string = str(year-field)
        if year-string.contains("/") {
          let parts = year-string.split("/")
          start-year = parts.first().trim()
          end-year = parts.last().trim()
          if end-year == "" { end-year = none }
        } else { start-year = year-string.split("-").first() }
      }
    }
  }

  let _composite-volume = type(volume) == str and volume.contains(regex("\\d{4}")) and (volume.contains("，") or volume.contains(",") or volume.contains("（") or volume.contains("("))

  let block = if _composite-volume {
    volume.replace(regex("[-–—]+"), "—")
  } else {
    let start-volume = none
    let end-volume = none
    if volume != none {
      if type(volume) == str {
        if volume.contains("-") {
          let parts = volume.split("-")
          start-volume = parts.first().trim()
          end-volume = parts.last().trim()
        } else { start-volume = volume }
      } else { start-volume = volume }
    }
    let start-number = none
    let end-number = none
    if number != none {
      if type(number) == str {
        if number.contains("-") {
          let parts = number.split("-")
          start-number = parts.first().trim()
          end-number = parts.last().trim()
        } else { start-number = number }
      } else { start-number = number }
    }

    let _year-volume-number(year, volume, number) = {
      let s = ""
      if year != none { s += year }
      if volume != none { s += (if s != "" { p("comma") } else { "" }) + volume }
      if number != none { s += p("lparen") + number + p("rparen") }
      s
    }
    let start-segment = _year-volume-number(start-year, start-volume, start-number)
    let end-segment = _year-volume-number(end-year, end-volume, end-number)

    if start-segment == "" { "" }
    else if end-segment != "" { start-segment + "—" + end-segment }
    else { start-segment + "—" }
  }
  (block: block, start-year: start-year, end-year: end-year)
}

#let serial(entry, opts) = {
  let (show-sine-loco, show-sine-nomine, show-sine-anno, et-al-min, et-al-use-first, et-al-use-last, show-url, show-mark, show-medium, show-patent-country, short-journal, show-urldate, hyperlink, space-before-mark, space-before-pages, page-range-separator, period-after-creator, show-anon, show-et-al, name-style, hyperlink-title, dedup-author-editor, skip-date, skip-creator, show-degree, correct-punct, punct-style, custom-punct, url-break-every, url-break-hyphen, name-suffix-separator, version, show-pid, pid-priority, dedup-url-pid, custom-pids, ..) = opts
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let creator = _creator(entry, opts)
  let title = _title(entry, opts)
  let location = imprint.location(entry)
  let publisher = imprint.publisher(entry)
  let urldate = date.urldate(entry, show-urldate: show-urldate, version: version)
  let access = _access(entry, opts)

  let _yv = serial-year-volume(entry, opts)
  let year-volume-number = _yv.block
  let start-year = _yv.start-year
  let end-year = _yv.end-year

  let location-publisher = imprint.location-publisher(location, publisher, p)

  let parts = (creator, title)
  if year-volume-number != "" { parts.push(year-volume-number) }
  if location-publisher != none {
    let publication-year = if start-year != none and end-year != none {
      start-year + "—" + end-year
    } else if start-year != none {
      start-year + "—"
    } else { none }
    if publication-year != none { parts.push(location-publisher + p("comma") + publication-year) }
    else { parts.push(location-publisher) }
  }
  if urldate != none { parts.push(urldate) }
  if access != none { parts.push(access) }

  _join(parts, p("period"))
}
