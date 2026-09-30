#import "../elements/creators.typ" as creators
#import "../elements/titles.typ" as titles
#import "../elements/emphasis.typ" as emphasis
#import "../elements/mark-medium/built-in.typ" as mark-medium
#import "../punct/built-in.typ" as punct
#import "../elements/imprint/general.typ" as imprint
#import "../elements/imprint/date.typ" as publication-date
#import "../elements/edition.typ"
#import "../elements/pages.typ"
#import "../category.typ"
#import "../elements/date.typ"
#import "../field.typ"
#import "../elements/access.typ": access, has-visible-path
#import "../drivers/built-in.typ" as built-in-driver

#let built-in-token-names = (
  "built-in",
  "author", "creator", "editor-other", "translator", "editor", "bookauthor",
  "title", "titles", "subtitle", "titleaddon", "title-block", "component-part-title-block",
  "booktitle", "booktitles", "booksubtitle", "booktitleaddon",
  "journal", "journaltitles", "journaltitle", "journalsubtitle", "journaltitleaddon", "shortjournal",
  "series", "series-block", "serial-block", "edition", "version", "volume", "number",
  "pages", "date", "year", "month", "day", "urldate", "eventdate",
  "publisher", "address", "location", "country", "institution", "school", "organization", "holder",
  "imprint-block", "mark", "mark-medium", "medium", "note", "access",
  "doi", "cstr", "isbn", "issn", "eprint", "eprinttype", "archiveprefix", "url",
  "type", "keywords", "scale", "dimensions", "eventtitle", "degree-annotation",
)

#let online(entry, opts) = has-visible-path(
  entry,
  show-url: opts.show-url,
  show-pid: opts.at("show-pid", default: (:)),
  custom-pids: opts.at("custom-pids", default: (:)),
  dedup-url-pid: opts.at("dedup-url-pid", default: true),
  version: opts.version,
)

#let resolve-built-in-token(name, entry, opts) = {

  if name == "built-in" {
    let render-built-in = opts.at("render-built-in", default: none)
    return if render-built-in == none { none } else { render-built-in(opts) }
  }
  let name-options = (
    et-al-min: opts.et-al-min, et-al-use-first: opts.et-al-use-first,
    et-al-use-last: opts.at("et-al-use-last", default: 0),
    show-et-al: opts.show-et-al, name-style: opts.name-style,
    punct-style: opts.punct-style, custom-punct: opts.custom-punct,
    custom-terms: opts.at("custom-terms", default: (:)),
    name-suffix-separator: opts.at("name-suffix-separator", default: auto), prefix-last: opts.at("prefix-last", default: false),
  )
  if name == "creator" {
    if opts.skip-creator { return none }
    let creator-override = opts.at("creator-override", default: none)
    if creator-override != none { return creator-override }
    let roles = creators.default-roles(entry, component-part: category.get(entry, version: opts.version) == "component-part")
    return creators.principal(entry, show-anon: opts.show-anon, roles: roles, version: opts.version, ..name-options)
  }
  if name == "editor-other" {
    let raw-author = entry.parsed_names.at("author", default: ())
    let raw-editor = entry.parsed_names.at("editor", default: ())
    if raw-author.len() == 0 { return none }
    if opts.dedup-author-editor and raw-author == raw-editor { return none }
    return creators.other-editor(entry, ..name-options, version: opts.version)
  }
  if name == "translator" {
    let raw-author = entry.parsed_names.at("author", default: ())
    let raw-editor = entry.parsed_names.at("editor", default: ())
    if raw-author.len() == 0 and raw-editor.len() == 0 { return none }
    return creators.other-translator(entry, ..name-options, et-al-translator-separator: opts.at("et-al-translator-separator", default: auto), version: opts.at("version", default: 2025))
  }
  if name in ("author", "editor", "bookauthor", "holder") {
    return creators.format(entry.parsed_names, role: name, et-al-role: creators.et-al-role-of-field.at(name, default: "principal"), entry: entry, version: opts.version, ..name-options)
  }
  if name == "title" { return punct.field-text(entry, "title", correct-punct: opts.correct-punct, punct-style: opts.punct-style) }
  if name == "titles" {
    let title-text = punct.field-text(entry, "title", correct-punct: opts.correct-punct, punct-style: opts.punct-style)
    if title-text == none { return none }
    return titles.addons(title-text, entry, correct-punct: opts.correct-punct, punct-style: opts.punct-style, custom-punct: opts.custom-punct)
  }
  if name == "subtitle" { return punct.field-text(entry, "subtitle", correct-punct: opts.correct-punct, punct-style: opts.punct-style) }
  if name == "titleaddon" { return punct.field-text(entry, "titleaddon", correct-punct: opts.correct-punct, punct-style: opts.punct-style) }
  if name == "title-block" {
    return titles.format(entry, online: online(entry, opts), show-mark: opts.show-mark, show-medium: opts.show-medium, show-url: opts.show-url, space-before-mark: opts.space-before-mark, hyperlink-title: opts.hyperlink-title, correct-punct: opts.correct-punct, punct-style: opts.punct-style, custom-punct: opts.custom-punct, custom-terms: opts.at("custom-terms", default: (:)), version: opts.version, volume-title-gutter: opts.at("volume-title-gutter", default: auto))
  }
  if name == "component-part-title-block" {
    return titles.format(entry, is-component-part: true, online: online(entry, opts), show-mark: opts.show-mark, show-medium: opts.show-medium, show-url: opts.show-url, space-before-mark: opts.space-before-mark, hyperlink-title: opts.hyperlink-title, correct-punct: opts.correct-punct, punct-style: opts.punct-style, custom-punct: opts.custom-punct, custom-terms: opts.at("custom-terms", default: (:)), version: opts.version, volume-title-gutter: opts.at("volume-title-gutter", default: auto))
  }
  if name == "mark" {
    if not mark-medium.gate(opts.show-mark, entry, version: opts.version, allow-online-only: false) { return none }
    let code = mark-medium.mark(entry)
    if code == "" { return none }
    return code
  }
  if name == "medium" {
    if not opts.show-medium { return none }
    return mark-medium.medium(entry, show-url: mark-medium.gate(opts.show-url, entry, version: opts.version), version: opts.version, online: online(entry, opts))
  }
  if name == "mark-medium" {
    let mark-text = mark-medium.render(entry, show-mark: opts.show-mark, show-medium: opts.show-medium, show-url: opts.show-url, space-before-mark: opts.space-before-mark, version: opts.version, online: online(entry, opts), bracket-style: opts.at("mark-medium-bracket-style", default: "half"))
    if mark-text == "" { return none }
    return mark-text
  }
  if name == "booktitle" { return punct.field-text(entry, "booktitle", correct-punct: opts.correct-punct, punct-style: opts.punct-style) }
  if name == "booktitles" {
    let book-title = punct.field-text(entry, "booktitle", correct-punct: opts.correct-punct, punct-style: opts.punct-style)
    if book-title == none { return none }
    return titles.addons(book-title, entry, subtitle-key: "booksubtitle", titleaddon-key: "booktitleaddon", correct-punct: opts.correct-punct, punct-style: opts.punct-style, custom-punct: opts.custom-punct)
  }

  if name == "journaltitles" {
    let journal-value = titles.journal(entry, opts.correct-punct, opts.punct-style, opts.custom-punct, opts.short-journal)
    if journal-value == none { return none }
    return emphasis.decorate(journal-value, opts.at("emphasis", default: (:)), "journaltitles", entry)
  }
  if name == "series" { return punct.field-text(entry, "series", correct-punct: opts.correct-punct, punct-style: opts.punct-style) }
  if name == "series-block" {
    let series = punct.field-text(entry, "series", correct-punct: opts.correct-punct, punct-style: opts.punct-style)
    if series == none { return none }
    let series-number = punct.field-text(entry, "number")
    let punct-of = name => punct.get(name, entry, opts.punct-style, opts.custom-punct)
    if series-number != none { return punct-of("lparen") + series + punct-of("comma") + (if type(series-number) == str { series-number } else { str(series-number) }) + punct-of("rparen") }
    return punct-of("lparen") + series + punct-of("rparen")
  }
  if name == "edition" { return edition.edition(entry, custom-terms: opts.at("custom-terms", default: (:))) }
  if name == "volume" {
    if category.get(entry, version: opts.version) in ("serial-article", "serial", "serial-newspaper") {
      return punct.field-text(entry, "volume")
    }
    return titles.volume(entry, version: opts.version, custom-terms: opts.at("custom-terms", default: (:)))
  }
  if name == "version" {

    return edition.resolve-version(entry, opts.punct-style, opts.custom-punct)
  }
  if name == "number" {
    let number-value = punct.field-text(entry, "number")
    if number-value == none { return none }
    if type(number-value) != str { return str(number-value) }
    return number-value
  }
  if name == "pages" { return pages.pages(entry, page-range-separator: opts.page-range-separator, page-range-style: opts.at("page-range-style", default: none), override: opts.at("pages-override", default: none), punct-style: opts.punct-style, custom-punct: opts.custom-punct, custom-terms: opts.at("custom-terms", default: (:))) }
  if name == "year" {
    if opts.skip-date { return none }
    return publication-date.year(entry)
  }
  if name == "date" {
    if opts.skip-date { return none }
    let drs = opts.at("date-range-separator", default: auto)
    return publication-date.date(entry, range-separator: if drs == auto or drs == none { "—" } else { drs })
  }
  if name == "urldate" { return date.urldate(entry, show-urldate: opts.show-urldate, version: opts.version) }
  if name == "address" or name == "location" { return imprint.location(entry) }
  if name == "publisher" { return imprint.publisher(entry) }
  if name == "imprint-block" {
    return imprint.format(entry, show-sine-loco: opts.show-sine-loco, show-sine-nomine: opts.show-sine-nomine, show-sine-anno: opts.at("show-sine-anno", default: false), skip-date: opts.skip-date, date-suffix: opts.at("date-suffix", default: ""), punct-style: opts.punct-style, custom-punct: opts.custom-punct, custom-terms: opts.at("custom-terms", default: (:)), version: opts.version)
  }
  if name == "serial-block" { return built-in-driver.serial-year-volume(entry, opts).block }
  if name == "access" {
    return access(entry, show-url: opts.show-url, hyperlink: opts.hyperlink, show-pid: opts.show-pid, pid-priority: opts.pid-priority, dedup-url-pid: opts.dedup-url-pid, custom-pids: opts.at("custom-pids", default: (:)), punct-style: opts.punct-style, custom-punct: opts.custom-punct, pid-colon-style: opts.at("pid-colon-style", default: auto), url-break-every: opts.url-break-every, url-break-hyphen: opts.url-break-hyphen, url-break-hyphen-at-delimiters: opts.url-break-hyphen-at-delimiters, version: opts.version)
  }
  if name == "degree-annotation" { return built-in-driver.degree(entry, show-degree: opts.show-degree, custom-terms: opts.at("custom-terms", default: (:))) }
  if name == "country" {
    if not (opts.show-patent-country or opts.version == 2005) { return none }
    let location-value = imprint.location(entry)
    return location-value
  }
  if name == "note" { return punct.field-text(entry, "note", correct-punct: opts.correct-punct, punct-style: opts.punct-style) }
  if name in ("booksubtitle", "booktitleaddon", "journal", "journaltitle", "shortjournal", "journalsubtitle", "journaltitleaddon", "school", "organization", "institution", "keywords", "eventtitle") {
    return punct.field-text(entry, name, correct-punct: opts.correct-punct, punct-style: opts.punct-style)
  }

  if name in ("type", "scale", "dimensions", "isbn", "issn", "eprinttype", "archiveprefix") { return punct.field-text(entry, name) }
  if name in ("url", "doi", "eprint", "cstr", "month", "day", "eventdate") { return field.get(entry, name) }
  none
}
