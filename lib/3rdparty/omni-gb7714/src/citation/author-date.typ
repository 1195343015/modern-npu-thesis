#import "../sentinel.typ": *
#import "../errors.typ"
#import "../detect/lang.typ" as language
#import "../terms/built-in.typ" as terms
#import "../elements/creators.typ" as creators
#import "../punct/built-in.typ" as punct
#import "../elements/imprint/date.typ" as publication-date
#import "../field.typ"

#let author-short(entry, cite-et-al-min: 2, cite-et-al-use-first: 1, cite-et-al-use-last: 0, name-style: (:), first-name-style: none, no-etal: false, terms-lang: "by-entry", document-lang: "en", sort-use-prefix: false, name-separator: ", ", name-suffix-separator: auto, custom-terms: (:), punct-style: "half-with-space", version: 2025) = {
  let name-list = creators.principal-names(entry).names
  if name-list.len() == 0 { return none }
  let (min: cite-et-al-min, use-first: cite-et-al-use-first, use-last: cite-et-al-use-last) = creators.resolve-et-al-triple(cite-et-al-min, cite-et-al-use-first, cite-et-al-use-last, "principal", entry)
  let (real-names, show-count, last-count, needs-etal, bare-etal) = creators.truncate(name-list, cite-et-al-min, cite-et-al-use-first, not no-etal, et-al-use-last: cite-et-al-use-last)

  let entry-use-prefix = field.use-prefix-entry(entry)

  let _one(name-index) = {
    let n = real-names.at(name-index)
    let style-for = if name-index == 0 and first-name-style != none { first-name-style } else { name-style }
    if creators.is-corp-name(n, entry: entry) {
      return creators.format-one(n, name-style: style-for, name-suffix-separator: name-suffix-separator, entry: entry, punct-style: punct-style, name-index: name-index)
    }
    if style-for.at("given-form", default: none) == none {
      let family = n.at("family", default: "")
      if language.is-cjk(family) { creators.format-one(n, name-style: style-for, name-suffix-separator: name-suffix-separator, entry: entry, punct-style: punct-style, name-index: name-index) } else {
        let prefix = if field.use-prefix-eff(n, entry-use-prefix, sort-use-prefix) { str(n.at("prefix", default: "")) } else { "" }
        let assembled = if prefix != "" { prefix + " " + family } else { family }
        let family-case = style-for.at("family-case", default: none)
        if family-case == "uppercase" { upper(assembled) } else if family-case == "lowercase" { lower(assembled) } else { assembled }
      }
    } else { creators.format-one(n, name-style: style-for, name-suffix-separator: name-suffix-separator, entry: entry, punct-style: punct-style, name-index: name-index) }
  }
  let formatted = range(show-count).map(_one)
  let result = formatted.join(name-separator)
  if last-count > 0 {
    let tail-start = real-names.len() - last-count
    return result + name-separator + punct.get("ellipsis", entry, punct-style, (:)) + range(tail-start, real-names.len()).map(_one).join(name-separator)
  }
  if needs-etal {
    let lang = terms.cite-term-lang(terms-lang, "et-al", entry, document-lang)
    let et-al-word = terms.etal-for(lang, custom-terms: custom-terms, version: version)

    let etal = if bare-etal { et-al-word }
      else if lang == "ru" { " " + et-al-word }
      else if lang in ("zh", "ja", "ko") { et-al-word }
      else if name-style.at("given-form", default: none) == none { " " + et-al-word }
      else { name-separator + et-al-word }
    result += etal
  }
  result
}

#let normalize-disambiguate(value) = {
  if value == auto { return (date: auto, given-name: auto, names: auto) }
  if value == true { return (date: true, given-name: true, names: true) }
  if value == false { return (date: false, given-name: false, names: false) }
  if std.type(value) != dictionary { errors.raise("disambiguate.bad-form", got: repr(value)) }
  let normalized = (date: auto, given-name: auto, names: auto)
  for (key, v) in value {
    if key not in ("date", "given-name", "names") { errors.raise("disambiguate.unknown-key", key: key) }
    if v != auto and v != true and v != false { errors.raise("disambiguate.bad-value", key: key, got: repr(v)) }
    normalized.insert(key, v)
  }
  normalized
}

#let _suffix(i) = {
  let n = i + 1
  let result = ""
  while n > 0 {
    let remainder = calc.rem(n - 1, 26)
    result = str.from-unicode(97 + remainder) + result
    n = calc.quo(n - 1, 26)
  }
  result
}

#let disambiguation(bib-data, cite-et-al-min: 2, cite-et-al-use-first: 1, name-style: (:), sort-keys: none, scope-keys: none, escalate-given-name: false, expand-names: false) = {

  let active-keys = if scope-keys != none { scope-keys.filter(k => k in bib-data) } else { bib-data.keys() }
  let related-targets = ()
  let related-pairs = (:)
  for key in active-keys {
    let entry = bib-data.at(key)
    let related = entry.fields.at("related", default: none)
    let related-type = entry.fields.at("relatedtype", default: none)
    if related != none and related-type != none and lower(str(related-type)) == "lanversion" {
      let related-key = str(related)
      related-targets.push(related-key)
      related-pairs.insert(key, related-key)
    }
  }

  let escalations = (:)
  let _blank-escalation = (use-first: none, given-form: none)
  let _first-person(entry) = { let ns = creators.principal-names(entry).names; if ns.len() > 0 { ns.first() } else { none } }

  let _person-key = creators.person-key
  let _roster-key(entry) = creators.principal-names(entry).names.map(_person-key).join("\u{1E}")
  let _escalated-style(form) = { let d = name-style; d.insert("given-form", form); d }

  let _escalated-label(current-escalations, key) = {
    let entry = bib-data.at(key)
    let esc = current-escalations.at(key, default: _blank-escalation)
    let label = author-short(entry,
      cite-et-al-min: cite-et-al-min,
      cite-et-al-use-first: if esc.use-first != none { esc.use-first } else { cite-et-al-use-first },
      name-style: name-style,
      first-name-style: if esc.given-form != none { _escalated-style(esc.given-form) } else { none })
    let year = publication-date.year(entry)
    if year == none { year = "" }

    if label == none {
      if field.get(entry, "label") != none { return none }
      if entry.entry_type == "set" { return none }
      if year == "" { return none }
      return terms.anon(entry) + "|" + year
    }
    (if std.type(label) == str { label } else { repr(label) }) + "|" + year
  }
  let _collision-groups(current-escalations) = {
    let groups = (:)
    for key in active-keys {
      if key in related-targets { continue }
      let group-key = _escalated-label(current-escalations, key)
      if group-key == none { continue }
      if group-key not in groups { groups.insert(group-key, ()) }
      groups.at(group-key).push(key)
    }
    groups.values().filter(g => g.len() > 1)
  }
  if escalate-given-name {
    for group in _collision-groups(escalations) {
      let persons = group.map(k => _person-key(_first-person(bib-data.at(k))))
      if persons.dedup().len() <= 1 { continue }
      for key in group {
        let esc = escalations.at(key, default: _blank-escalation)
        esc.given-form = (pinyin: "pinyin-initials", rest: "initials")
        escalations.insert(key, esc)
      }
      let still-colliding = (:)
      for key in group {
        let group-key = _escalated-label(escalations, key)
        if group-key not in still-colliding { still-colliding.insert(group-key, ()) }
        still-colliding.at(group-key).push(key)
      }
      for (_, keys) in still-colliding {
        if keys.len() <= 1 { continue }
        let givens = keys.map(k => { let person = _first-person(bib-data.at(k)); str(person.at("given", default: "")) })
        if givens.dedup().len() <= 1 { continue }
        for key in keys {
          let esc = escalations.at(key, default: _blank-escalation)
          esc.given-form = "full"
          escalations.insert(key, esc)
        }
      }
    }
  }
  if expand-names {
    let expanding = true
    let rounds = 0
    while expanding and rounds < 8 {
      expanding = false
      rounds += 1
      for group in _collision-groups(escalations) {
        let rosters = group.map(k => _roster-key(bib-data.at(k)))
        if rosters.dedup().len() <= 1 { continue }
        for key in group {
          let total = creators.principal-names(bib-data.at(key)).names.len()
          let esc = escalations.at(key, default: _blank-escalation)
          let current = if esc.use-first != none { esc.use-first } else { cite-et-al-use-first }
          if current < total {
            esc.use-first = current + 1
            escalations.insert(key, esc)
            expanding = true
          }
        }
      }
    }
  }

  let cite-labels = (:)
  let keys-by-disambiguation = (:)
  for key in active-keys {
    if key in related-targets { continue }
    let entry = bib-data.at(key)
    let esc = escalations.at(key, default: _blank-escalation)
    let _first-style = if esc.given-form != none { _escalated-style(esc.given-form) } else { none }
    let author = author-short(entry, cite-et-al-min: cite-et-al-min, cite-et-al-use-first: if esc.use-first != none { esc.use-first } else { cite-et-al-use-first }, name-style: name-style, first-name-style: _first-style)
    if author == none { author = "" }
    let year = publication-date.year(entry)
    if year == none { year = "" }
    cite-labels.insert(key, author + ", " + year)
    let disambiguation-key = _escalated-label(escalations, key)
    if disambiguation-key == none { continue }
    if disambiguation-key not in keys-by-disambiguation { keys-by-disambiguation.insert(disambiguation-key, ()) }
    keys-by-disambiguation.at(disambiguation-key).push(key)
  }
  let cite-suffixes = (:)
  for (_, keys) in keys-by-disambiguation {
    if keys.len() > 1 {

      let sorted-keys = if sort-keys != none {
        keys.enumerate().sorted(key: ((i, k)) => {
          let position = sort-keys.position(sort-key => sort-key == k)
          if position != none { (0, position, i) } else { (1, 0, i) }
        }).map(((i, k)) => k)
      } else { keys }
      for (i, key) in sorted-keys.enumerate() {
        let suffix-str = _suffix(i)
        cite-suffixes.insert(key, suffix-str)
        if key in related-pairs {
          cite-suffixes.insert(related-pairs.at(key), suffix-str)
        }
      }
    }
  }
  (cite-labels: cite-labels, cite-suffixes: cite-suffixes, escalations: escalations)
}

#let render-run(items, _group-merge, opts) = {
  let (eff-form, _key-of, _cite-author, _cite-year, _order-items, bib-data, publication-date, p, _bib-link, _author-date-cite-label, lbl-prefix, current-list, suffix-table, escalation-table, supplement-mode, document-semi, eff-name-style, eff-cite-et-al-min, eff-cite-et-al-use-first, eff-cite-terms-lang, document-lang, eff-collapse-date, _name-punct-direction) = opts
  let items = _order-items(items)
  if items.len() == 1 and eff-form in ("author", "year") {
    let item = items.first()
    let k = _key-of(item)
    let entry = bib-data.at(k, default: none)
    let author = _cite-author(entry)
    let _suffix = suffix-table.at(k, default: "")
    let year = _cite-year(entry, _suffix)
    let display = if eff-form == "author" { author } else { year }
    let lbl = _bib-link(lbl-prefix + k, current-list, k, display)
    if item.supplement != none { [#lbl#super[#item.supplement]] } else { lbl }
  } else if items.len() > 1 and eff-form in ("author", "year") {
    let parts = items.map(item => {
      let k = _key-of(item)
      let entry = bib-data.at(k, default: none)
      let author = _cite-author(entry)
      let _suffix = suffix-table.at(k, default: "")
      let year = _cite-year(entry, _suffix)
      let display = if eff-form == "author" { author } else { year }
      _bib-link(lbl-prefix + k, current-list, k, display)
    })
    let result = []
    for (i, part) in parts.enumerate() {
      if i > 0 and _group-merge { result += document-semi }
      result += part
    }
    result
  } else if items.len() == 1 and eff-form == "prose" {
    let item = items.first()
    let k = _key-of(item)
    let entry = bib-data.at(k, default: none)
    let author = _cite-author(entry)
    let _suffix = suffix-table.at(k, default: "")
    let year = _cite-year(entry, _suffix)
    let lbl = _bib-link(lbl-prefix + k, current-list, k, year)
    let gap = if author == "" or _name-punct-direction(entry) == "full" { "" } else { " " }
    let no-year = (year == none or year == "") and item.supplement == none
    if no-year { author }
    else if item.supplement != none {
      if supplement-mode == "split" { [#author#gap#p("lparen", entry: entry)#lbl#p("rparen", entry: entry)#super(item.supplement)] }
      else { [#author#gap#p("lparen", entry: entry)#lbl#p("colon", entry: entry)#item.supplement#p("rparen", entry: entry)] }
    } else { [#author#gap#p("lparen", entry: entry)#lbl#p("rparen", entry: entry)] }
  } else {

    let do-collapse = eff-collapse-date and _group-merge
    let groups = {
      let built = ()
      for item in items {
        let k = _key-of(item)
        let entry = bib-data.at(k, default: none)
        let parts = _author-date-cite-label(k, name-format: eff-name-style, suffixes: suffix-table, escalations: escalation-table, name-separator: p("comma", entry: entry), et-al-min: eff-cite-et-al-min, et-al-use-first: eff-cite-et-al-use-first, terms-lang: eff-cite-terms-lang, document-lang: document-lang, parts: true, name-punct-style: _name-punct-direction(entry))
        let member = (item: item, key: k, parts: parts)
        let collapsible = item.supplement == none and parts.year != ""
        if do-collapse and collapsible and built.len() > 0 and built.last().collapsible and built.last().members.first().parts.author == parts.author {
          let g = built.pop(); g.members.push(member); built.push(g)
        } else {
          built.push((collapsible: collapsible, members: (member,)))
        }
      }
      built
    }

    let group-label(g) = {
      let first = g.members.first()
      let entry = bib-data.at(first.key, default: none)
      let full-text = if first.parts.year == "" { first.parts.author } else { first.parts.author + first.parts.delim + first.parts.year }
      let result = _bib-link(lbl-prefix + first.key, current-list, first.key, full-text)
      for m in g.members.slice(1) {
        result += p("comma", entry: entry) + _bib-link(lbl-prefix + m.key, current-list, m.key, m.parts.year)
      }
      result
    }
    let render-group(g) = {
      let punct-entry(n) = p(n, entry: bib-data.at(g.members.first().key, default: none))
      let lbl = group-label(g)
      let sup = g.members.first().item.supplement
      if sup != none {
        if supplement-mode == "split" { [#punct-entry("lparen")#lbl#punct-entry("rparen")#super(sup)] }
        else { [#punct-entry("lparen")#lbl#punct-entry("colon")#sup#punct-entry("rparen")] }
      } else { [#punct-entry("lparen")#lbl#punct-entry("rparen")] }
    }
    let body = if items.len() == 1 {
      render-group(groups.first())
    } else if not _group-merge {
      groups.map(render-group).join()
    } else {

      let has-any-supplement = items.any(item => item.supplement != none)
      if supplement-mode == "split" and has-any-supplement {
        let parts = groups.map(render-group)
        let result = []
        for (i, part) in parts.enumerate() {
          if i > 0 { result += document-semi }
          result += part
        }
        result
      } else {
        let labels = groups.map(g => {
          let punct-entry(n) = p(n, entry: bib-data.at(g.members.first().key, default: none))
          let lbl = group-label(g)
          let sup = g.members.first().item.supplement
          if sup != none { lbl + punct-entry("colon") + sup } else { lbl }
        })
        let inner = []
        for (i, l) in labels.enumerate() {
          if i > 0 { inner += p("semicolon") }
          inner += l
        }
        [#p("lparen")#inner#p("rparen")]
      }
    }
    if eff-form == "super" { super[#body] } else { body }
  }
}
