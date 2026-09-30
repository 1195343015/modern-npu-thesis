#import "../category.typ"
#import "../sentinel.typ": _CJK-ADJ
#import "../elements/mark-medium/built-in.typ" as mark-medium
#import "../punct/built-in.typ" as punct
#import "../field.typ"
#import "built-in.typ" as built-in-driver
#import "custom.typ" as custom-driver

#let count-data-groups(entry) = {
  let has(..names) = names.pos().any(n => field.get(entry, n) != none)
  let mark = mark-medium.mark(entry)
  let groups = (
    has("author", "editor", "translator"),
    has("title", "journaltitle", "maintitle", "booktitle", "issuetitle") or (mark == "S" and field.get(entry, "number") != none),
    has("edition", "version"),
    has("location", "address", "publisher", "date", "year", "institution", "organization", "school", "pages"),
    field.get(entry, "series") != none,
    field.get(entry, "url") != none,
    has("doi", "isbn", "issn", "cstr", "eprint"),
  )
  groups.filter(g => g).len()
}

#let _maybe-annotation(rendered, entry, show-annotation, space-before-annotation) = {
  if not show-annotation { return rendered }
  let a = punct.field-text(entry, "annotation"); if a == none { a = punct.field-text(entry, "annote") }
  if a == none or a == "" { return rendered }
  let lead = if space-before-annotation == true { " " }
    else if space-before-annotation == false { "" }
    else if type(a) == str and a.match(regex("^" + _CJK-ADJ)) != none { "" }
    else { " " }
  [#rendered.#lead#a]
}

#let entry(entry, registered-marks: (), show-sine-loco: true, show-sine-nomine: true, show-sine-anno: false, et-al-min: 4, et-al-use-first: 3, et-al-use-last: 0, show-url: true, show-mark: true, show-medium: true, show-patent-country: false, short-journal: false, show-urldate: true, show-end-period: true, hyperlink: true, emphasis: (:), space-before-mark: false, mark-medium-bracket-style: "half", space-before-pages: true, page-range-separator: "-", page-range-style: none, period-after-creator: true, show-anon: false, show-et-al: true, name-style: (:), hyperlink-title: false, dedup-author-editor: false, skip-date: false, date-suffix: "", pages-override: none, skip-creator: false, creator-override: none, show-degree: false, show-series: false, prefix-last: false, custom-drivers: (:), custom-terms: (:), custom-fields: (:), custom-pids: (:), correct-punct: false, punct-style: "half-with-space", custom-punct: (:), pid-colon-style: auto, url-break-every: 1, url-break-hyphen: true, url-break-hyphen-at-delimiters: true, version: 2015, name-suffix-separator: auto, et-al-translator-separator: auto, component-part-separator: "//", show-pid: (:), pid-priority: (), dedup-url-pid: true, show-annotation: false, space-before-annotation: auto, volume-title-gutter: auto, date-range-separator: auto) = {
  let entry-category = category.get(entry, version: version)
  let show-urldate = show-urldate and not mark-medium.online-suppressed(show-url, entry, version: version)
  let mark-is-auto = (mark-medium.applied-value(show-mark, entry) == auto)

  let _format-args = (
    show-sine-loco: show-sine-loco, show-sine-nomine: show-sine-nomine, show-sine-anno: show-sine-anno,
    et-al-min: et-al-min, et-al-use-first: et-al-use-first, et-al-use-last: et-al-use-last,
    show-url: show-url,
    show-mark: show-mark, show-medium: show-medium,
    show-patent-country: show-patent-country,
    short-journal: short-journal, show-urldate: show-urldate,
    hyperlink: hyperlink,
    emphasis: emphasis,
    space-before-mark: space-before-mark, mark-medium-bracket-style: mark-medium-bracket-style, space-before-pages: space-before-pages,
    page-range-separator: page-range-separator, page-range-style: page-range-style, period-after-creator: period-after-creator,
    show-anon: show-anon, show-et-al: show-et-al, name-style: name-style, name-suffix-separator: name-suffix-separator, et-al-translator-separator: et-al-translator-separator, component-part-separator: component-part-separator,
    hyperlink-title: hyperlink-title, dedup-author-editor: dedup-author-editor,
    skip-date: skip-date, date-suffix: date-suffix, pages-override: pages-override, skip-creator: skip-creator, creator-override: creator-override, show-degree: show-degree, show-series: show-series, prefix-last: prefix-last,
    correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct, pid-colon-style: pid-colon-style,
    url-break-every: url-break-every, url-break-hyphen: url-break-hyphen, url-break-hyphen-at-delimiters: url-break-hyphen-at-delimiters,
    version: version, show-pid: show-pid, pid-priority: pid-priority, dedup-url-pid: dedup-url-pid,
    custom-terms: custom-terms, custom-fields: custom-fields, custom-pids: custom-pids,
    volume-title-gutter: volume-title-gutter, date-range-separator: date-range-separator,
  )
  let run-built-in(args) = if entry-category == "component-part" { built-in-driver.component-part(entry, args) }
    else if entry-category == "preprint" { built-in-driver.preprint(entry, args) }
    else if entry-category == "serial-article" { built-in-driver.serial-article(entry, args) }
    else if entry-category == "serial-newspaper" { built-in-driver.serial-newspaper(entry, args) }
    else if entry-category == "patent" { built-in-driver.patent(entry, args) }
    else if entry-category == "electronic" { built-in-driver.electronic(entry, args) }
    else if entry-category == "serial" { built-in-driver.serial(entry, args) }
    else { built-in-driver.monograph(entry, args) }
  let _format-args = (
    .._format-args,
    render-built-in: run-built-in,
    built-in-single-block: count-data-groups(entry) <= 1,
  )
  let strip-mark(render, args, body, single-block) = {
    if mark-is-auto and single-block and mark-medium.mark(entry) != none {
      let re = render((..args, show-mark: false))
      if type(re) == array { re.first() } else { re }
    } else { body }
  }

  if custom-drivers != none and custom-drivers != (:) {
    custom-driver.validate-driver-keys(custom-drivers, extra-marks: registered-marks)
    let template = custom-drivers.at(entry.entry_type, default: none)
    if template == none { template = custom-drivers.at(mark-medium.base-mark(entry), default: none) }
    if template != none {
      let render-custom(args) = custom-driver.render(entry, template, args, custom-terms, show-end-period: show-end-period)
      let (body, single-block) = render-custom(_format-args)
      body = strip-mark(render-custom, _format-args, body, single-block)
      return (_maybe-annotation(body, entry, show-annotation, space-before-annotation), single-block)
    }
  }

  let single-block = count-data-groups(entry) <= 1
  let body = strip-mark(run-built-in, _format-args, run-built-in(_format-args), single-block)
  (_maybe-annotation(body, entry, show-annotation, space-before-annotation), single-block)
}
