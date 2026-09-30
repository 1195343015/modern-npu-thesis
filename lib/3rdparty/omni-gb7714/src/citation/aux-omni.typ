#import "../entryset.typ"

#let bib-anchor-map() = {
  let anchor-map = (:)
  for e in query(metadata) {
    let value = e.value
    if type(value) == dictionary and value.at("kind", default: none) == "gb7714-bib" {
      let lbl = value.at("lbl", default: none)
      if lbl != none and lbl not in anchor-map { anchor-map.insert(lbl, e.location()) }
    }
  }
  anchor-map
}

#let cited-keys(bib-data, target-list) = {
  let active-list = state("gb7714-active-list", none)

  let named-lists = state("gb7714-list-ids", (:)).final().len() > 0

  if target-list == none and not named-lists and not state("gb7714-has-note", false).final() {
    return state("gb7714-cite-counter", (order: (), map: (:))).final().order
  }
  let redirect = entryset.redirect(bib-data)

  let keys = ()
  for it in query(selector(std.cite).or(selector(metadata))) {
    let k = if it.func() == std.cite {
      if str(it.key) in bib-data and ((not named-lists and target-list == none) or active-list.at(it.location()) == target-list) {
        redirect.at(str(it.key), default: str(it.key))
      } else { none }
    } else {
      let value = it.value
      if type(value) == dictionary and value.at("kind", default: none) == "gb7714-note" {
        let anchor-key = str(value.at("key", default: ""))
        if anchor-key in bib-data and ((not named-lists and target-list == none) or active-list.at(it.location()) == target-list) {
          redirect.at(anchor-key, default: anchor-key)
        } else { none }
      } else { none }
    }
    if k != none and k not in keys { keys.push(k) }
  }
  keys
}

#let cite-context(bib-data, target-list) = {
  let seen = cited-keys(bib-data, target-list)
  let number-of = (:)
  for (i, k) in seen.enumerate() { if k not in number-of { number-of.insert(k, i + 1) } }
  let named-lists = state("gb7714-list-ids", (:)).final().len() > 0
  let active-list = state("gb7714-active-list", none)

  let all-refs = query(std.cite).filter(r => r.at("form", default: auto) != none and str(r.key) in bib-data and (not named-lists or active-list.at(r.location()) == target-list))
  (seen: seen, all-refs: all-refs, number-of: number-of)
}
