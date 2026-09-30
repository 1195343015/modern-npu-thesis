#let _is-native-mode(bibs) = (
  sys.version >= std.version(0, 15, 0)
  and bibs.all(b => b.label == none)
  and (bibs.len() > 1 or bibs.any(b => b.target != auto) or bibs.any(b => b.native-style))
  and (
    (
      not state("gb7714-config", (:)).final().at("note", default: none) != none
      and not bibs.any(b => b.at("footnote", default: auto) == true)
    )
    or bibs.any(b => b.target != auto)
    or bibs.any(b => b.native-style)
  )
)

#let _native-route-table(bibs, set-redirect) = {
  let timeline = query(selector(std.cite).or(std.bibliography))
  let cite-infos = ()
  let bibs-seen = 0
  for e in timeline {
    if e.func() == std.bibliography { bibs-seen += 1 }
    else {
      let k = set-redirect.at(str(e.key), default: str(e.key))
      cite-infos.push((key: k, loc: e.location(), before: bibs-seen))
    }
  }
  let t-hits = bibs.map(b => if b.target == auto { none } else { query(b.target) })
  let per-bib = bibs.map(_ => ())
  let routes = ()
  for c in cite-infos {
    let routed = none
    for i in range(bibs.len()) {
      let target-hits = t-hits.at(i)
      if target-hits != none and target-hits.any(hit-cite => hit-cite.location() == c.loc) { routed = i; break }
    }
    if routed == none {
      for i in range(c.before, bibs.len()) {
        let b = bibs.at(i)
        if b.target == auto and c.key in b.source-keys { routed = i; break }
      }
    }
    if routed == none {
      let i = c.before - 1
      while i >= 0 {
        let b = bibs.at(i)
        if b.target == auto and c.key in b.source-keys { break }
        i -= 1
      }
      if i >= 0 { routed = i }
    }
    if routed != none {
      let array = per-bib.at(routed)
      let rank = array.position(existing => existing == c.key)
      if rank == none { array.push(c.key); per-bib.at(routed) = array; rank = array.len() - 1 }
      routes.push((loc: c.loc, bib-index: routed, rank: rank))
    }
  }
  let _bib-count(bib-index) = {
    let bib-at-index = bibs.at(bib-index)
    if bib-at-index.full {
      let bib-keys = per-bib.at(bib-index)
      for k in bib-at-index.source-keys { if k not in bib-keys { bib-keys.push(k) } }
      bib-keys.len()
    } else { per-bib.at(bib-index).len() }
  }
  let offsets = bibs.map(_ => 0)
  for i in range(bibs.len()) {
    let entry-group = bibs.at(i).group
    let offset = 0
    if entry-group != none {
      for j in range(i) {
        if bibs.at(j).group == entry-group and bibs.at(j).at("counts-number", default: true) { offset += _bib-count(j) }
      }
    }
    offsets.at(i) = offset
  }
  let numbered = routes.map(route => (loc: route.loc, number: offsets.at(route.bib-index) + route.rank + 1, bib-index: route.bib-index))
  let seen = bibs.map(_ => ())
  for i in range(bibs.len()) {
    let off = offsets.at(i)
    let keys = per-bib.at(i)
    if bibs.at(i).full { for k in bibs.at(i).source-keys { if k not in keys { keys.push(k) } } }
    let array = range(off).map(_ => "")
    for k in keys { array.push(k) }
    seen.at(i) = array
  }
  (numbered: numbered, seen: seen)
}
#let _native-route-number(table, loc) = {
  let hit = table.numbered.find(r => r.loc == loc)
  if hit == none { none } else { (number: hit.number, bib-index: hit.bib-index) }
}
