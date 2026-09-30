#import "../sentinel.typ": *
#import "../field.typ"
#import "../punct/built-in.typ" as punct
#import "../entryset.typ"
#import "../elements/mark-medium/built-in.typ" as mark-medium
#import "../elements/creators.typ" as creators
#import "../detect/lang.typ" as language
#import "../drivers/custom.typ" as custom-driver

#let emit-label(key, list-label: none) = {
  let lbl = if list-label == none { "gb7714" + _LSEP + key }
            else { "gb7714" + _LSEP + list-label + _LSEP + key }
  metadata((kind: "gb7714-bib", lbl: lbl))

  if _IS-HTML { html.elem("span", attrs: (id: _anchor-id(lbl))) }
}

#let annotation-tail(entry, show-annotation: false) = {
  if show-annotation {
    let annotation-value = field.alias(entry, "annotation", "annote")
    annotation-value != none and annotation-value != ""
  } else { false }
}

#let select-entries(source-keys, opts) = {
  let (bib-data, mark, entry-type, keyword, filter, eff-show-related, get-related-key) = opts
  let filtered = source-keys.map(k => (k, bib-data.at(k))).filter(pair => {
    let entry = pair.at(1)

    if entry == none or (entry.entry_type in _SPECIAL-ENTRY-TYPES and entry.entry_type != "set") { return false }
    if mark != none {
      let marks = (mark,).flatten()
      let entry-mark = mark-medium.mark(entry)
      let matched = marks.any(m => {
        entry-mark == m or entry-mark.starts-with(m + "/")
      })
      if not matched { return false }
    }
    if entry-type != none {
      let entry-types = (entry-type,).flatten()
      if entry.entry_type not in entry-types { return false }
    }
    if keyword != none {
      let keyword-field = entry.fields.at("keywords", default: none)
      if keyword-field == none or not str(keyword-field).contains(keyword) { return false }
    }
    if filter != none and not filter(entry) { return false }
    true
  })

  if eff-show-related {
    let related-keys = ()
    for k in source-keys {
      let redirect-key = get-related-key(bib-data.at(k))
      if redirect-key != none { related-keys.push(redirect-key) }
    }
    filtered = filtered.filter(pair => pair.at(0) not in related-keys)
  }

  {
    let _set-members = ()
    for kv-pair in filtered {
      let e = kv-pair.at(1)
      if e != none and e.entry_type == "set" {
        for m in entryset.members(e) { _set-members.push(m) }
        for m in entryset.leaves(bib-data, kv-pair.at(0)) { _set-members.push(m) }
      }
    }
    filtered = filtered.filter(kv-pair => kv-pair.at(0) not in _set-members)
  }
  filtered
}

#let assemble-list(rows, grid-cells, opts) = {
  let (title-heading, is-html, html-section-class, number-width, number-gutter, entry-spacing, lbl-align, ambient-spacing) = opts
  if is-html and rows.len() > 0 {
    let _ul = html.elem("ul", attrs: (style: "list-style-type: none"), rows.map(r => html.elem("li", r)).sum(default: []))
    let _sec-attrs = (role: "doc-bibliography")
    if html-section-class != none { _sec-attrs.insert("class", html-section-class) }
    html.elem("section", attrs: _sec-attrs, { title-heading; _ul })
  } else if grid-cells.len() > 0 {
    title-heading
    let _row-gutter = if entry-spacing != auto { entry-spacing } else { ambient-spacing }
    grid(
      columns: (number-width, 1fr),
      column-gutter: number-gutter,
      row-gutter: _row-gutter,
      align: (lbl-align + top, left + top),
      ..grid-cells,
    )
  } else if rows.len() > 0 {
    title-heading
    let _body = rows.sum(default: [])
    if entry-spacing != auto {
      block[#{ set par(spacing: entry-spacing); _body }]
    } else {
      block(_body)
    }
  }
}

#let _entryset-block(anchor, lbl, member-blocks, author-date-or-none: false, is-html: false, not-hanging: false, hanging-indent: 1.5em, first-line-indent: 0pt, number-align: right, number-width: 0pt, gutter: 0.5em) = {
  let _members(cont-prefix) = { for (i, mb) in member-blocks.enumerate() { if i > 0 { linebreak(); cont-prefix }; mb } }
  if author-date-or-none {

    par(hanging-indent: hanging-indent, first-line-indent: (amount: first-line-indent, all: true))[#anchor#_members([])]
  } else if is-html {
    {
      anchor
      html.elem("span", attrs: (class: "prefix"), lbl)
      " "
      for (i, mb) in member-blocks.enumerate() { if i > 0 { linebreak() }; mb }
    }
  } else if not-hanging {

    par(first-line-indent: (amount: first-line-indent, all: true))[#anchor#lbl#h(gutter)#_members(h(measure(lbl).width + gutter))]
  } else {

    let _num-cell = if number-align == left { box(width: number-width)[#lbl#h(1fr)] }
      else if number-align == center { box(width: number-width)[#h(1fr)#lbl#h(1fr)] }
      else { box(width: number-width)[#h(1fr)#lbl] }
    par(
      hanging-indent: number-width + gutter + hanging-indent,
      first-line-indent: (amount: first-line-indent, all: true),
    )[#anchor#_num-cell#h(gutter)#_members([])]
  }
}

#let render-entries(filtered, opts) = {
  let (bib-data, _emit-entry, _emit-entry-author-date, _plabel, _get-related, _disambiguation, _active-list, eff-bib-style, eff-suffixes, eff-numeric-date-suffix, eff-bib-numbering-style, eff-show-related, eff-show-url, eff-show-annotation, eff-show-end-period, eff-custom-drivers, eff-version, eff-punct-style, eff-custom-punct, eff-hyphenate, eff-entry-hanging-indent, eff-entry-first-line-indent, eff-number-gutter, eff-number-width, eff-back-ref, eff-number-placement, _column-mode, _margin-mode, list-label, number-offset, lbl-align, related-indent, eff-creator-idem, eff-entry-localized-glyphs) = opts

  let _wrap-lang(lang, body) = {
    let on = if eff-entry-localized-glyphs == false { false }
      else if eff-entry-localized-glyphs == true { true }
      else if lang not in ("zh", "ja", "ko") { true }
      else { eff-version != 2005 }
    if not on { body }
    else if lang not in ("zh", "ja", "ko") { text(lang: lang, hyphenate: eff-hyphenate, body) }
    else { text(lang: lang, body) }
  }

  let _period-on(single-block) = if eff-show-end-period == auto { not single-block } else { eff-show-end-period }

  let _rows = ()
  let _backref-label(label, key) = {
    let cites = query(std.cite).filter(c => str(c.key) == key and _active-list.at(c.location()) == list-label)
    if cites.len() == 0 { return label }
    if _IS-HTML {
      let lbl-anchor = if list-label == none { "gb7714" + _LSEP + key } else { "gb7714" + _LSEP + list-label + _LSEP + key }
      html.elem("a", attrs: (href: "#" + _anchor-id(lbl-anchor) + "-ref", role: "doc-backlink"), label)
    } else {

      link(cites.first().location(), box(label))
    }
  }
  let _html-li-content(anchor, lbl, body, related) = {
    anchor
    if lbl != none { html.elem("span", attrs: (class: "prefix"), lbl); " " }
    body
    if related != none { linebreak(); related }
  }
  let _grid-cells = ()

  let _grid-mode = (not _IS-HTML) and _column-mode

  for (i, pair) in filtered.enumerate() {
    let key = pair.at(0)
    let entry = pair.at(1)

    if entry != none and entry.entry_type == "set" {
      let member-keys = entryset.leaves(bib-data, key)
      let members = member-keys.map(m => bib-data.at(m, default: none)).filter(e => e != none and e.entry_type not in _SPECIAL-ENTRY-TYPES)
      if members.len() == 0 { continue }
      let _member-lang = language.get(members.first())
      let _wrap-member(b) = _wrap-lang(_member-lang, b)
      let _render-member(member-entry) = {
        let annotation-tail-flag = annotation-tail(member-entry, show-annotation: eff-show-annotation)
        let (member-body, member-single) = if eff-bib-style == "author-date" {
          _emit-entry-author-date(member-entry, suffix-key: str(member-keys.at(members.position(x => x == member-entry), default: 0)), suffixes: eff-suffixes)
        } else { _emit-entry(member-entry) }
        let tail-sep = if _period-on(member-single) and not annotation-tail-flag and not custom-driver.uses-override(member-entry, eff-custom-drivers, version: eff-version) { [#punct.end-period(member-entry, eff-punct-style, eff-custom-punct)] } else { [] }
        punct.append-end-period(member-body, tail-sep)
      }
      let member-block = members.map(_render-member)
      let element = emit-label(key, list-label: list-label)
      let number-label = _plabel(str(i + 1 + number-offset))
      if eff-back-ref and eff-bib-numbering-style != none { number-label = _backref-label(number-label, key) }
      if _grid-mode {
        _grid-cells.push(number-label)
        _grid-cells.push(_wrap-member(par(
          hanging-indent: eff-entry-hanging-indent,
          first-line-indent: (amount: eff-entry-first-line-indent, all: true),
        )[#element#{ for (j, member-body) in member-block.enumerate() { if j > 0 { linebreak() }; member-body } }]))
      } else {
        let inner-block = _entryset-block(
          element, number-label, member-block,
          author-date-or-none: eff-bib-numbering-style == none,
          is-html: _IS-HTML,
          not-hanging: false,
          hanging-indent: eff-entry-hanging-indent, first-line-indent: eff-entry-first-line-indent,
          number-align: lbl-align,
          number-width: eff-number-width,
          gutter: eff-number-gutter,
        )
        _rows.push(_wrap-member(inner-block))
      }
      continue
    }

    let _creator-override = if eff-creator-idem != none and i > 0 and entry != none {
      let previous-entry = filtered.at(i - 1).at(1)
      let roster = creators.roster-key(entry)
      if previous-entry != none and roster != "" and roster == creators.roster-key(previous-entry) { eff-creator-idem } else { none }
    } else { none }
    let related = if eff-show-related { _get-related(entry) } else { none }
    let skip-date = eff-bib-style == "author-date"
    let annotation-tail-v = annotation-tail(entry, show-annotation: eff-show-annotation)

    let entry-label-tag = emit-label(key, list-label: list-label)

    let _entry-lang = language.get(entry)
    let _wrap(body) = _wrap-lang(_entry-lang, body)

    let _is-author-date-entry = eff-bib-style == "author-date"
    let _emit(target-entry, suffix-key, creator-override: none) = if _is-author-date-entry {
      _emit-entry-author-date(target-entry, suffix-key: suffix-key, suffixes: eff-suffixes, creator-override: creator-override)
    } else {

      _emit-entry(target-entry, date-suffix: if eff-numeric-date-suffix { eff-suffixes.at(suffix-key, default: "") } else { "" }, creator-override: creator-override)
    }
    let (formatted, entry-single) = _emit(entry, key, creator-override: _creator-override)
    let suffix = if _period-on(entry-single) and not annotation-tail-v and not custom-driver.uses-override(entry, eff-custom-drivers, version: eff-version) { punct.end-period(entry, eff-punct-style, eff-custom-punct) } else { "" }
    let related-annotation-tail = if related != none { annotation-tail(related, show-annotation: eff-show-annotation) } else { false }
    let related-formatted = if related != none {
      let related-key = str(entry.fields.at("related", default: ""))
      let (related-body, related-single) = _emit(related, related-key)
      let related-suffix = if _period-on(related-single) and not related-annotation-tail and not custom-driver.uses-override(related, eff-custom-drivers, version: eff-version) { punct.end-period(related, eff-punct-style, eff-custom-punct) } else { "" }
      punct.append-end-period(related-body, related-suffix)
    } else { none }

    if eff-bib-numbering-style == none {

      let related-indent-value = if related-indent != none { related-indent } else { [] }
      let _hanging-indent = eff-entry-hanging-indent
      let _first-line-indent = eff-entry-first-line-indent
      let _inner = if _IS-HTML {
        _html-li-content(entry-label-tag, none, punct.append-end-period(formatted, suffix), related-formatted)
      } else {
        par(hanging-indent: _hanging-indent, first-line-indent: (amount: _first-line-indent, all: true))[#entry-label-tag#punct.append-end-period(formatted, suffix)]
        if related-formatted != none {
          par(hanging-indent: _hanging-indent, first-line-indent: (amount: _first-line-indent, all: true))[#related-indent-value#related-formatted]
        }
      }
      _rows.push(_wrap(_inner))
    } else if _column-mode {

      let lbl = _plabel(str(i + 1 + number-offset))
      if eff-back-ref { lbl = _backref-label(lbl, key) }
      let related-indent-value = if related-indent != none { related-indent } else { [] }
      let related-content = if related-formatted != none { [#related-indent-value#related-formatted] } else { none }
      if _IS-HTML {
        _rows.push(_wrap(_html-li-content(entry-label-tag, lbl, punct.append-end-period(formatted, suffix), related-content)))
      } else {
        _grid-cells.push(lbl)
        _grid-cells.push(_wrap(par(
          hanging-indent: eff-entry-hanging-indent,
          first-line-indent: (amount: eff-entry-first-line-indent, all: true),
        )[#entry-label-tag#punct.append-end-period(formatted, suffix)#if related-content != none [#linebreak()#related-content]]))
      }
    } else {

      let lbl = _plabel(str(i + 1 + number-offset))
      if eff-back-ref { lbl = _backref-label(lbl, key) }
      let _lead = if _margin-mode { context box(width: 0pt)[#h(-(measure(lbl).width + eff-number-gutter))#lbl] }
        else { [#lbl#h(eff-number-gutter)] }
      let related-indent-value = if related-indent != none { related-indent }
        else if _margin-mode { [] }
        else { h(measure(lbl).width + eff-number-gutter) }
      let _inner = if _IS-HTML {
        _html-li-content(entry-label-tag, lbl, punct.append-end-period(formatted, suffix), related-formatted)
      } else {
        par(hanging-indent: eff-entry-hanging-indent, first-line-indent: (amount: eff-entry-first-line-indent, all: true))[#entry-label-tag#_lead#punct.append-end-period(formatted, suffix)#if related-formatted != none [#linebreak()#related-indent-value#related-formatted]]
      }
      _rows.push(_wrap(_inner))
    }
  }
  (rows: _rows, grid-cells: _grid-cells)
}

#let _circled-number-table = (
  "①","②","③","④","⑤","⑥","⑦","⑧","⑨","⑩",
  "⑪","⑫","⑬","⑭","⑮","⑯","⑰","⑱","⑲","⑳",
  "㉑","㉒","㉓","㉔","㉕","㉖","㉗","㉘","㉙","㉚",
  "㉛","㉜","㉝","㉞","㉟","㊱","㊲","㊳","㊴","㊵",
  "㊶","㊷","㊸","㊹","㊺","㊻","㊼","㊽","㊾","㊿",
)
#let circled-number(n) = {
  if n >= 1 and n <= 50 { _circled-number-table.at(n - 1) }
  else { "(" + str(n) + ")" }
}
