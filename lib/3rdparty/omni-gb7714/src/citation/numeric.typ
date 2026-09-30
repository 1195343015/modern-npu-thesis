#let _compress-runs(items) = {
  let segments = ()
  let segment-start = none
  let segment-end = none
  for item in items {
    if item.supplement != none {
      if segment-start != none { segments.push((segment-start, segment-end, none)); segment-start = none; segment-end = none }
      segments.push((item.number, item.number, item.supplement))
    } else {
      if segment-start == none { segment-start = item.number; segment-end = item.number }
      else if item.number == segment-end + 1 { segment-end = item.number }
      else { segments.push((segment-start, segment-end, none)); segment-start = item.number; segment-end = item.number }
    }
  }
  if segment-start != none { segments.push((segment-start, segment-end, none)) }
  segments
}

#let render-run(items, _group-merge, opts) = {
  let (eff-form, _key-of, _cite-author, _cite-year, _order-items, _name-punct-direction, bib-data, publication-date, p, _num-link, supplement-mode, document-comma, document-semi, block-sep, seen, eff-compress-min, eff-cite-range-separator, cite-numbering-style, cite-circled-render) = opts

  let is-circled = cite-numbering-style == "circled"
  let (cite-lb, cite-rb) = (
    "paren": ("(", ")"),
    "fullwidth-bracket": ("［", "］"),
    "shell": ("〔", "〕"),
    "fullwidth-paren": ("（", "）"),
  ).at(cite-numbering-style, default: ("[", "]"))
  let br(inner) = if is-circled { inner } else { [#cite-lb#inner#cite-rb] }
  let items = _order-items(items)
  if items.len() == 1 and eff-form == "prose" {
    let item = items.first()
    let k = _key-of(item)
    let entry = bib-data.at(k, default: none)
    let author = _cite-author(entry)
    let lbl = _num-link(k, item.number)
    let gap = if _name-punct-direction(entry) == "full" { "" } else { " " }
    if item.supplement != none { [#author#gap#br(lbl)#item.supplement] }
    else { [#author#gap#br(lbl)] }
  } else if items.len() == 1 and eff-form in ("author", "year") {
    let item = items.first()
    let k = _key-of(item)
    let entry = bib-data.at(k, default: none)
    let display = if eff-form == "author" {
      _cite-author(entry)
    } else {
      _cite-year(entry, "")
    }
    let lbl = _num-link(k, item.number, display: display)
    if item.supplement != none { [#lbl#item.supplement] } else { lbl }
  } else if items.len() > 1 and eff-form in ("author", "year") {
    let parts = items.map(item => {
      let k = _key-of(item)
      let entry = bib-data.at(k, default: none)
      let display = if eff-form == "author" {
        _cite-author(entry)
      } else {
        _cite-year(entry, "")
      }
      _num-link(k, item.number, display: display)
    })
    let result = []
    for (i, part) in parts.enumerate() {
      if i > 0 and _group-merge { result += document-semi }
      result += part
    }
    result
  } else if not _group-merge or is-circled {
    let use-super = eff-form == "super" or eff-form == "normal"
    let parts = items.map(item => {
      let k = _key-of(item)
      let lbl = if is-circled { _num-link(k, item.number, display: cite-circled-render(item.number)) } else { _num-link(k, item.number) }
      let inner = if item.supplement != none { [#lbl#item.supplement] } else { lbl }
      if use-super { super[#br(inner)] } else { br(inner) }
    })
    parts.join()
  } else {
    let use-super = eff-form == "super" or eff-form == "normal"
    let segments = _compress-runs(items)

    if supplement-mode == "split" {

      let any-supplement = segments.any(segment => segment.at(2) != none)
      if not any-supplement {
        let parts = segments.map(segment => {
          let (start, end, _) = segment
          let k = seen.at(start - 1, default: "")
          if start == end {
            _num-link(k, start)
          } else if end - start + 1 >= eff-compress-min {
            _num-link(k, start, display: str(start) + eff-cite-range-separator + str(end))
          } else {
            let result = []
            for (index, n) in range(start, end + 1).enumerate() {
              if index > 0 { result += p("comma") }
              result += _num-link(seen.at(n - 1, default: ""), n)
            }
            result
          }
        })
        let inner = []
        for (i, part) in parts.enumerate() {
          if i > 0 { inner += p("comma") }
          inner += part
        }
        if use-super { super[#br(inner)] } else { br(inner) }
      } else {
        let parts = segments.map(segment => {
          let (start, end, supplement) = segment
          let k = seen.at(start - 1, default: "")
          let bracketed = if start == end {
            br(_num-link(k, start))
          } else if end - start + 1 >= eff-compress-min {
            br(_num-link(k, start, display: str(start) + eff-cite-range-separator + str(end)))
          } else {
            let inner = []
            for (index, n) in range(start, end + 1).enumerate() {
              if index > 0 { inner += p("comma") }
              inner += _num-link(seen.at(n - 1, default: ""), n)
            }
            br(inner)
          }
          if supplement != none { [#bracketed#(if use-super { supplement } else { super[#supplement] })] } else { bracketed }
        })
        let result = []
        for (i, part) in parts.enumerate() {

          if i > 0 { result += block-sep }
          result += part
        }
        if use-super { super[#result] } else { result }
      }
    } else {
      let parts = segments.map(segment => {
        let (start, end, supplement) = segment
        let k = seen.at(start - 1, default: "")
        if supplement != none {
          _num-link(k, start) + p("colon") + supplement
        } else if start == end {
          _num-link(k, start)
        } else if end - start + 1 >= eff-compress-min {
          _num-link(k, start, display: str(start) + eff-cite-range-separator + str(end))
        } else {
          let result = []
          for (index, n) in range(start, end + 1).enumerate() {
            if index > 0 { result += p("comma") }
            result += _num-link(seen.at(n - 1, default: ""), n)
          }
          result
        }
      })
      let inner = []
      for (i, part) in parts.enumerate() {
        if i > 0 { inner += p("comma") }
        inner += part
      }
      if use-super { super[#br(inner)] }
      else { br(inner) }
    }
  }
}
