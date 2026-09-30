#import "../errors.typ"

#let tokenize(src) = {
  let tokens = ()
  let s = str(src)
  let n = s.len()
  let i = 0
  while i < n {
    let c = s.at(i)
    if c == " " or c == "\t" or c == "\n" or c == "\r" {
      let whitespace-count = 0
      while i < n {
        let peek-char = s.at(i)
        if peek-char == " " or peek-char == "\t" or peek-char == "\n" or peek-char == "\r" { whitespace-count += 1; i += 1 } else { break }
      }
      if tokens.len() > 0 and i < n {
        if whitespace-count == 1 { tokens.push(("sp",)) }
        else { tokens.push(("text", " " * (whitespace-count - 1))) }
      }
      continue
    }

    if c == "\\" and i + 1 < n and (s.at(i + 1) == "{" or s.at(i + 1) == "}") {
      tokens.push(("text", s.at(i + 1)))
      i += 2
      continue
    }
    if c == "{" {
      let j = i + 1
      let buffer = ""
      while j < n {
        let ch = s.at(j)
        if ch == "\\" and j + 1 < n and (s.at(j + 1) == "{" or s.at(j + 1) == "}") {
          buffer += s.at(j + 1)
          j += 2
          continue
        }
        if ch == "}" { break }
        buffer += ch

        j += ch.len()
      }
      if j >= n { errors.raise("template.unclosed-literal", src: s) }
      tokens.push(("text", buffer))
      i = j + 1
      continue
    }

    if c == "=" and i + 1 < n and s.at(i + 1) == ">" { tokens.push(("arrow",)); i += 2; continue }
    if c == "?" and i + 1 < n and s.at(i + 1) == "<" { tokens.push(("group-open", "any")); i += 2; continue }
    if c == "&" and i + 1 < n and s.at(i + 1) == "<" { tokens.push(("group-open", "all")); i += 2; continue }
    if c == "<" { tokens.push(("group-open", "any")); i += 1; continue }
    if c == ">" { tokens.push(("group-close",)); i += 1; continue }
    if c == "|" { tokens.push(("alias",)); i += 1; continue }
    let char-codepoint = str.to-unicode(c)
    let is-id-start = char-codepoint >= 0x61 and char-codepoint <= 0x7A
    if is-id-start {
      let j = i + 1
      while j < n {
        let peek-char = s.at(j)
        let codepoint = str.to-unicode(peek-char)
        let ok = (codepoint >= 0x61 and codepoint <= 0x7A) or (codepoint >= 0x30 and codepoint <= 0x39) or peek-char == "-" or peek-char == "_"
        if not ok { break }
        j += 1
      }
      let name = s.slice(i, j)
      tokens.push(("ident", name))
      i = j
      continue
    }
    let clusters = s.slice(i).clusters()
    if clusters.len() > 0 {
      let first-cluster = clusters.first()
      tokens.push(("punct", first-cluster))
      i += first-cluster.len()
      continue
    }
    i += 1
  }
  tokens
}

#let _g-skip(nodes, i) = {
  while i < nodes.len() and nodes.at(i).at(0) == "sp" { i += 1 }
  i
}

#let _g-read-value(nodes, i) = {
  let v = ""
  while i < nodes.len() {
    let nd = nodes.at(i)
    let k = nd.at(0)
    if k == "ident" or k == "text" { v += nd.at(1); i += 1 }
    else if k == "punct" {
      let c = nd.at(1)
      if c == "&" or c == "?" or c == "!" or c == "=" { break }
      v += c; i += 1
    } else { break }
  }
  (v, i)
}

#let _g-is-field-start(nodes, i) = {
  i = _g-skip(nodes, i)
  if i >= nodes.len() or nodes.at(i).at(0) != "ident" { return false }
  let j = _g-skip(nodes, i + 1)
  if j >= nodes.len() { return false }
  nodes.at(j) == ("punct", "=") or nodes.at(j) == ("punct", "!")
}

#let _g-atom(nodes, i, token-names) = {
  i = _g-skip(nodes, i)
  if i >= nodes.len() or nodes.at(i).at(0) != "ident" { errors.raise("template.guard-expected-field") }
  let fname = nodes.at(i).at(1)
  i = _g-skip(nodes, i + 1)
  let op = none
  if i < nodes.len() and nodes.at(i) == ("punct", "=") { op = "eq"; i += 1 }
  else if i + 1 < nodes.len() and nodes.at(i) == ("punct", "!") and nodes.at(i + 1) == ("punct", "=") { op = "neq"; i += 2 }
  else { return (("present", fname), i) }
  i = _g-skip(nodes, i)
  let (v0, ni) = _g-read-value(nodes, i)
  if v0 == "" { errors.raise("template.guard-expected-value", field: fname) }
  i = ni
  let values = (v0,)
  while true {
    let p = _g-skip(nodes, i)
    if p < nodes.len() and nodes.at(p) == ("punct", "?") and not _g-is-field-start(nodes, p + 1) {
      let q = _g-skip(nodes, p + 1)
      if q < nodes.len() and nodes.at(q).at(0) == "ident" and nodes.at(q).at(1) in token-names {
        errors.raise("template.guard-ambiguous-or", field: fname, token: nodes.at(q).at(1))
      }
      let (vk, nk) = _g-read-value(nodes, q)
      if vk == "" { break }
      values.push(vk); i = nk
    } else { break }
  }
  (("cmp", fname, op, values), i)
}

#let _g-parse(nodes, i, min-prec, token-names) = {
  i = _g-skip(nodes, i)
  let left = none
  if i < nodes.len() and nodes.at(i) == ("punct", "!") {
    let (sub, ni) = _g-parse(nodes, i + 1, 3, token-names)
    left = ("not", sub); i = ni
  } else if i < nodes.len() and nodes.at(i).at(0) == "group" {
    let g = nodes.at(i)
    if g.len() > 3 and g.at(3) != none { errors.raise("template.guard-nested-arrow") }
    let (sub, _ig) = _g-parse(g.at(2), 0, 0, token-names)
    left = sub; i += 1
  } else {
    let (atom, ni) = _g-atom(nodes, i, token-names); left = atom; i = ni
  }
  while true {
    let j = _g-skip(nodes, i)
    if j >= nodes.len() { i = j; break }
    let nd = nodes.at(j)
    let prec = if nd == ("punct", "&") { 2 } else if nd == ("punct", "?") { 1 } else { 0 }
    if prec == 0 or prec < min-prec { i = j; break }
    let (right, nk) = _g-parse(nodes, j + 1, prec + 1, token-names)
    if nd == ("punct", "&") {
      left = if left.at(0) == "and" { ("and", left.at(1) + (right,)) } else { ("and", (left, right)) }
    } else {
      left = if left.at(0) == "or" { ("or", left.at(1) + (right,)) } else { ("or", (left, right)) }
    }
    i = nk
  }
  (left, i)
}

#let parse-guard-expr(nodes, token-names: ()) = {
  let (ast, i) = _g-parse(nodes, 0, 0, token-names)
  if _g-skip(nodes, i) < nodes.len() { errors.raise("template.guard-trailing") }
  ast
}
