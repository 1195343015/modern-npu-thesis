#let members(entry) = {
  let entryset-field = entry.fields.at("entryset", default: none)
  if entryset-field == none { return () }
  str(entryset-field).split(regex("[,\\s]+")).map(s => s.trim()).filter(s => s != "")
}

#let leaves(bib-data, key, visited: ()) = {
  if key in visited { return () }
  let entry = bib-data.at(key, default: none)
  if entry == none or entry.entry_type != "set" { return (key,) }
  let visited = visited + (key,)
  let out = ()
  for member in members(entry) {
    for leaf in leaves(bib-data, member, visited: visited) {
      if leaf not in out { out.push(leaf) }
    }
  }
  out
}

#let redirect(bib-data) = {
  let nested = ()
  for (k, e) in bib-data {
    if e.entry_type == "set" {
      for member in members(e) { nested.push(member) }
    }
  }
  let _contained-sets(key, visited: ()) = {
    if key in visited { return () }
    let e = bib-data.at(key, default: none)
    if e == none or e.entry_type != "set" { return () }
    let visited = visited + (key,)
    let out = ()
    for member in members(e) {
      let member-entry = bib-data.at(member, default: none)
      if member-entry != none and member-entry.entry_type == "set" {
        out.push(member)
        for s in _contained-sets(member, visited: visited) { if s not in out { out.push(s) } }
      }
    }
    out
  }
  let redirect-map = (:)
  for (k, e) in bib-data {
    if e.entry_type == "set" and k not in nested {
      for leaf in leaves(bib-data, k) {
        if leaf not in redirect-map { redirect-map.insert(leaf, k) }
      }
      for s in _contained-sets(k) {
        if s not in redirect-map { redirect-map.insert(s, k) }
      }
    }
  }
  for (k, e) in bib-data {
    if e.entry_type == "set" {
      for leaf in leaves(bib-data, k) {
        if leaf not in redirect-map { redirect-map.insert(leaf, k) }
      }
    }
  }
  redirect-map
}
