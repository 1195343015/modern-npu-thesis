#import "../sentinel.typ": *
#import "../errors.typ"
#import "../punct/built-in.typ" as punct
#import "../drivers/custom.typ" as custom-driver
#import "../bibliography/render.typ" as bib
#import "../terms/built-in.typ" as terms
#import "../entryset.typ"
#import "../elements/creators.typ" as creators
#import "../elements/titles.typ" as titles

#let note-repeat-style-values = ("full", "number", "shortened", "reuse")

#let _endnote-counter = counter("gb7714-endnote")

#let normalize-note-repeat-style(value) = {
  if value == auto { return "number" }
  if value not in note-repeat-style-values { errors.raise("note-repeat-style.bad-value", got: repr(value), values: note-repeat-style-values.join(" / ")) }
  value
}

#let normalize-note-ibid(value, version) = {
  if value == auto { return version != 2025 }
  if value == true or value == false { return value }
  errors.raise("note-ibid.bad-value", got: repr(value))
}

#let normalize-note-repeat-reset(value) = {
  if value == none { return none }
  if value == "per-page" { return "per-page" }
  if std.type(value) == selector { return value }
  if std.type(value) == label or std.type(value) == function { return selector(value) }
  errors.raise("note-repeat-reset.bad-value", got: repr(value))
}

#let _sidecar-list() = query(metadata).filter(m => {
  let value = m.value
  std.type(value) == dictionary and value.at("kind", default: none) == "gb7714-note-sidecar"
})

#let _render-note(items, options-thunk, in-merged-group, note-mode) = {
  let _is-fncite(m) = { let v = m.value; std.type(v) == dictionary and v.at("kind", default: none) == "gb7714-note" }
  let anchors-all = query(selector(metadata).before(here(), inclusive: false)).filter(_is-fncite)
  let group-size = items.len()
  let base = calc.max(0, anchors-all.len() - group-size)
  let sidecars = _sidecar-list()
  let _sidecar-at(index) = sidecars.at(index, default: none)
  let _supplement-at(index) = {
    let sidecar = _sidecar-at(index)
    if sidecar == none { none } else { sidecar.value.at("supplement", default: none) }
  }
  let _supplement-of(anchor) = {
    let index = anchors-all.position(candidate => candidate.location() == anchor.location())
    if index == none { none } else { _supplement-at(index) }
  }
  let first-sidecar = _sidecar-at(base)
  let opts = options-thunk(if first-sidecar == none { (:) } else { first-sidecar.value.at("overrides", default: (:)) })
  let (indent, eff-style, bib-style, show-url, eff-show-annotation, show-end-period, eff-custom-drivers, version, eff-punct-style, eff-custom-punct, eff-pid-colon-style, _emit-entry-author-date, _emit-entry, eff-custom-terms, eff-custom-fields, eff-custom-pids, eff-correct-punct, eff-url-break-every, eff-show-pid, eff-pid-priority, eff-dedup-url-pid, _get-related, _set-redirect, bib-data, note-repeat-style, note-ibid, note-repeat-reset, cite-terms-lang, format-footnote-number, _active-list, _bib-link, show-anon, show-et-al, _global-config, show-mark, show-medium, space-before-mark, correct-punct) = opts
  let current-list = _active-list.at(here())
  let document-lang = text.lang

      let _period-on(single-block) = if show-end-period == auto { not single-block } else { show-end-period }
      let _footnote-full-body(entry, k, supplement, with-end-period: true) = {
        let skip-date = bib-style == "author-date"
        let annotation-tail = bib.annotation-tail(entry, show-annotation: eff-show-annotation)
        let (formatted, entry-single) = if skip-date { _emit-entry-author-date(entry, suffix-key: k, pages-override: supplement, custom-drivers: eff-custom-drivers, custom-terms: eff-custom-terms, custom-fields: eff-custom-fields, custom-pids: eff-custom-pids, correct-punct: eff-correct-punct, punct-style: eff-punct-style, custom-punct: eff-custom-punct, pid-colon-style: eff-pid-colon-style, url-break-every: eff-url-break-every, show-pid: eff-show-pid, pid-priority: eff-pid-priority, dedup-url-pid: eff-dedup-url-pid, show-annotation: eff-show-annotation) } else { _emit-entry(entry, pages-override: supplement, custom-drivers: eff-custom-drivers, custom-terms: eff-custom-terms, custom-fields: eff-custom-fields, custom-pids: eff-custom-pids, correct-punct: eff-correct-punct, punct-style: eff-punct-style, custom-punct: eff-custom-punct, pid-colon-style: eff-pid-colon-style, url-break-every: eff-url-break-every, show-pid: eff-show-pid, pid-priority: eff-pid-priority, dedup-url-pid: eff-dedup-url-pid, show-annotation: eff-show-annotation) }
        let end-suffix = if _period-on(entry-single) and not annotation-tail and not custom-driver.uses-override(entry, eff-custom-drivers, version: version) { punct.end-period(entry, eff-punct-style, eff-custom-punct) } else { "" }
        let related = _get-related(entry)
        if related != none {
          let related-key = str(entry.fields.at("related", default: ""))
          let related-annotation-tail = bib.annotation-tail(related, show-annotation: eff-show-annotation)
          let (related-formatted, related-single) = if skip-date { _emit-entry-author-date(related, suffix-key: related-key, custom-drivers: eff-custom-drivers, custom-terms: eff-custom-terms, custom-fields: eff-custom-fields, custom-pids: eff-custom-pids, correct-punct: eff-correct-punct, punct-style: eff-punct-style, custom-punct: eff-custom-punct, pid-colon-style: eff-pid-colon-style, url-break-every: eff-url-break-every, show-pid: eff-show-pid, pid-priority: eff-pid-priority, dedup-url-pid: eff-dedup-url-pid, show-annotation: eff-show-annotation) } else { _emit-entry(related, custom-drivers: eff-custom-drivers, custom-terms: eff-custom-terms, custom-fields: eff-custom-fields, custom-pids: eff-custom-pids, correct-punct: eff-correct-punct, punct-style: eff-punct-style, custom-punct: eff-custom-punct, pid-colon-style: eff-pid-colon-style, url-break-every: eff-url-break-every, show-pid: eff-show-pid, pid-priority: eff-pid-priority, dedup-url-pid: eff-dedup-url-pid, show-annotation: eff-show-annotation) }
          let related-end-suffix = if _period-on(related-single) and not related-annotation-tail and not custom-driver.uses-override(related, eff-custom-drivers, version: version) { punct.end-period(related, eff-punct-style, eff-custom-punct) } else { "" }
          [#punct.append-end-period(formatted, end-suffix)#linebreak()#indent#punct.append-end-period(related-formatted, if with-end-period { related-end-suffix } else { "" })]
        } else { punct.append-end-period(formatted, if with-end-period { end-suffix } else { "" }) }
      }
      let _footnote-full-body-by-key(k, supplement, with-end-period: true) = {
        let redirect-key = _set-redirect.at(k, default: k)
        let redirect-entry = bib-data.at(redirect-key, default: none)
        if redirect-entry != none and redirect-entry.entry_type == "set" {
          let leaf-keys = entryset.leaves(bib-data, redirect-key)
            .filter(leaf-key => bib-data.at(leaf-key, default: none) != none)
          let bodies = leaf-keys.enumerate().map(((leaf-index, leaf-key)) => _footnote-full-body(bib-data.at(leaf-key), leaf-key, none, with-end-period: leaf-index < leaf-keys.len() - 1 or supplement != none or with-end-period))
          let joined = bodies.join(linebreak() + indent)
          if supplement != none {

            [#joined #(if with-end-period { punct.append-end-period(supplement, punct.end-period(entry, eff-punct-style, eff-custom-punct)) } else { [#supplement] })]
          } else { joined }
        } else {
          _footnote-full-body(bib-data.at(k, default: none), k, supplement, with-end-period: with-end-period)
        }
      }

      let _short-body(entry, supplement, with-end-period: true) = {
        let author = creators.principal(entry, et-al-min: _global-config.et-al-min, et-al-use-first: _global-config.et-al-use-first, show-anon: show-anon, show-et-al: show-et-al, name-style: _global-config.name-style, punct-style: eff-punct-style, custom-punct: eff-custom-punct, custom-terms: _global-config.custom-terms, name-suffix-separator: _global-config.name-suffix-separator, prefix-last: _global-config.prefix-last, version: version)
        let short-title = titles.format(entry, show-mark: (if show-mark == auto { true } else { show-mark }), show-medium: show-medium, show-url: false, space-before-mark: space-before-mark, mark-medium-bracket-style: _global-config.at("mark-medium-bracket-style", default: "half"), hyperlink-title: false, correct-punct: correct-punct, punct-style: eff-punct-style, custom-punct: eff-custom-punct, version: _global-config.version, volume-title-gutter: _global-config.volume-title-gutter)

        let parts = if supplement != none { (author, short-title, supplement) } else { (author, short-title) }
        let segment-period = punct.end-period(entry, eff-punct-style, eff-custom-punct)
        let segments = parts.enumerate().map(((part-index, part)) => {
          if part-index < parts.len() - 1 or with-end-period { [#punct.append-end-period(part, segment-period)] } else { [#part] }
        })
        segments.join([ ])
      }
      let _slot-content(k, prior, current-list, document-lang, in-merged-group, slot-index, bare) = {
        let supplement = _supplement-at(base + slot-index)
        let redirect-key = _set-redirect.at(k, default: k)
        let entry = bib-data.at(k, default: none)
        let _redirect-of(anchor) = { let anchor-key = anchor.value.key; _set-redirect.at(anchor-key, default: anchor-key) }
        let prior-first = prior.find(m => _redirect-of(m) == redirect-key)
        let is-repeat = prior-first != none

        let previous-anchor-same = prior.len() > 0 and _redirect-of(prior.last()) == redirect-key
        let previous-in-same-group = in-merged-group and slot-index > 0
        let previous-merged = prior.len() > 0 and prior.last().value.at("merged", default: false)
        let adjacent-allowed = previous-in-same-group or not previous-merged
        let previous-supplement = if previous-anchor-same { _supplement-of(prior.last()) } else { none }
        let adjacent = previous-anchor-same and adjacent-allowed and not (supplement == none and previous-supplement != none)

        let same-locator-as-previous = adjacent and supplement != none and supplement == previous-supplement

        let content-kind = if not is-repeat { "full" }
          else if adjacent and note-ibid { "ibid" }
          else { note-repeat-style }
        if content-kind == "reuse" and is-repeat and (in-merged-group or prior-first.value.at("merged", default: false)) { content-kind = "number" }
        let entry-end-suffix = if show-end-period != false { punct.end-period(entry, eff-punct-style, eff-custom-punct) } else { "" }

        let _ibid-lang = terms.cite-term-lang(cite-terms-lang, "ibid", entry, document-lang)
        let _fnnum-lang = terms.cite-term-lang(cite-terms-lang, "footnote-number", entry, document-lang)

        let _note-supplement-default = if _ibid-lang in ("zh", "ja") { punct.get("colon", entry, eff-punct-style, eff-custom-punct) }
          else { punct.get("comma", entry, "half-with-space", eff-custom-punct) }
        let _note-supplement-separator(term-separator) = if term-separator == auto { _note-supplement-default }
          else { punct.resolve-separator(term-separator, entry, eff-punct-style, eff-custom-punct, _note-supplement-default) }
        let _with-locator(body, term-separator) = if supplement != none { [#body#_note-supplement-separator(term-separator)#supplement] } else { body }
        if content-kind == "reuse" and is-repeat {
          (kind: "reuse", body: none)
        } else if content-kind == "ibid" and is-repeat {
          let ibid-body = if same-locator-as-previous { terms.ibid-for(_ibid-lang, custom-terms: eff-custom-terms) }
            else { _with-locator(terms.ibid-for(_ibid-lang, custom-terms: eff-custom-terms), terms.ibid-supplement-separator(_ibid-lang, custom-terms: eff-custom-terms)) }
          (kind: "ibid", body: if bare { ibid-body } else { punct.append-end-period(ibid-body, entry-end-suffix) })
        } else if content-kind == "number" and is-repeat {

          let _note-counter = if note-mode == "end" { _endnote-counter } else { counter(std.footnote) }
          let note-number = _note-counter.at(prior-first.location()).first() + 1
          let reference-text = terms.footnote-number-wrap(_fnnum-lang, format-footnote-number(note-number), custom-terms: eff-custom-terms)
          let numbered-body = _with-locator(reference-text, terms.footnote-number-supplement-separator(_fnnum-lang, custom-terms: eff-custom-terms))
          (kind: "number", body: if bare { numbered-body } else { punct.append-end-period(numbered-body, entry-end-suffix) })
        } else if content-kind == "shortened" and is-repeat {
          (kind: "shortened", body: _short-body(entry, supplement, with-end-period: not bare))
        } else {

          (kind: "full", body: _footnote-full-body-by-key(k, supplement, with-end-period: not bare))
        }
      }

      let _prior-anchors(slot-index) = {
        let cut = base + slot-index
        let all = anchors-all.slice(0, cut)
        let domain = if note-repeat-reset == none { all } else if note-repeat-reset == "per-page" {
          let pg = here().page()
          all.filter(a => a.location().page() == pg)
        } else {
          let boundaries = query(note-repeat-reset.before(here(), inclusive: false))
          if boundaries.len() == 0 { all } else {
            let scoped = query(selector(metadata).after(boundaries.last().location()).before(here(), inclusive: false)).filter(_is-fncite)
            let drop = anchors-all.len() - cut
            if scoped.len() >= drop { scoped.slice(0, scoped.len() - drop) } else { () }
          }
        }
        (domain: domain, all: all)
      }
      let _redirect-of-anchor(anchor) = { let anchor-key = anchor.value.key; _set-redirect.at(anchor-key, default: anchor-key) }
      let _emit-endnote(body) = {

        _endnote-counter.step()
        super(context format-footnote-number(_endnote-counter.get().first()))
        metadata((kind: "gb7714-endnote", body: body, list: current-list))
      }
      if not in-merged-group {
        let item = items.first()
        let redirect-key = _set-redirect.at(item.key, default: item.key)
        let anchor-sets = _prior-anchors(0)
        let globally-first = anchor-sets.all.find(m => _redirect-of-anchor(m) == redirect-key) == none
        let slot = _slot-content(item.key, anchor-sets.domain, current-list, document-lang, false, 0, false)
        if note-mode == "end" {
          if slot.kind == "reuse" {
            let prior-first = anchor-sets.domain.find(m => _redirect-of-anchor(m) == redirect-key)
            let reuse-number = _endnote-counter.at(prior-first.location()).first() + 1
            [#super(format-footnote-number(reuse-number))]
          } else {
            _emit-endnote(slot.body)
          }
        } else if slot.kind == "reuse" {

          std.footnote(std.label("gb7714-note-" + redirect-key))
        } else if globally-first {

          [#std.footnote(slot.body)#std.label("gb7714-note-" + redirect-key)]
        } else {
          std.footnote(slot.body)
        }
      } else {

        let slots = items.enumerate().map(((slot-index, item)) => {
          let anchor-sets = _prior-anchors(slot-index)
          (item: item, resolved: _slot-content(item.key, anchor-sets.domain, current-list, document-lang, true, slot-index, true))
        })

        let joined = []
        for (slot-index, s) in slots.enumerate() {
          if slot-index > 0 {
            let left-entry = bib-data.at(slots.at(slot-index - 1).item.key, default: none)
            joined += [#punct.get("semicolon", left-entry, eff-punct-style, eff-custom-punct)]
          }
          joined += [#s.resolved.body]
        }
        let end-suffix = if show-end-period != false {
          punct.end-period(bib-data.at(slots.last().item.key, default: none), eff-punct-style, eff-custom-punct)
        } else { "" }
        if note-mode == "end" { _emit-endnote(punct.append-end-period(joined, end-suffix)) }
        else { std.footnote(punct.append-end-period(joined, end-suffix)) }
      }
}

#let render(items, options-thunk, merge-notes: true, note-mode: "foot") = {
  let will-merge = merge-notes and items.len() > 1
  for item in items {

    metadata((kind: "gb7714-note", key: item.key, merged: will-merge))

    state("gb7714-has-note", false).update(true)
    if not will-merge { context { _render-note((item,), options-thunk, false, note-mode) } }
  }
  if will-merge { context { _render-note(items, options-thunk, true, note-mode) } }
}
