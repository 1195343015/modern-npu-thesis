#import "../sentinel.typ": *
#import "../errors.typ"
#import "../elements/mark-medium/built-in.typ" as mark-medium
#import "../field.typ"
#import "../detect/lang.typ" as language
#import "../punct/built-in.typ" as punct
#import "../parse/latex.typ"
#import "../fields/built-in.typ" as fields
#import "../fields/custom.typ": resolve-field
#import "../terms/custom.typ": resolve-term
#import "../parse/guard.typ" as guard

#let _parse(tokens) = {
  let stack = ()
  let nodes = ()
  let pending-alias = none
  let i = 0
  let n = tokens.len()
  while i < n {
    let token = tokens.at(i)
    let kind = token.at(0)
    if kind == "group-open" {
      stack.push((token.at(1), nodes))
      nodes = ()
      i += 1
    } else if kind == "group-close" {
      if stack.len() == 0 { errors.raise("template.unmatched-close") }
      let frame = stack.pop()
      let group-type = frame.at(0)
      let parent = frame.at(1)

      let arrows = nodes.enumerate().filter(((node-index, nd)) => nd.at(0) == "arrow")
      if arrows.len() > 1 { errors.raise("template.guard-multiple-arrows") }
      let arrow-idx = if arrows.len() == 1 { arrows.first().at(0) } else { none }
      let _trim-sp(body) = {
        let a = 0
        while a < body.len() and body.at(a).at(0) == "sp" { a += 1 }
        let b = body.len()
        while b > a and body.at(b - 1).at(0) == "sp" { b -= 1 }
        body.slice(a, b)
      }
      let group-node = if arrow-idx != none {
        let guard-toks = nodes.slice(0, arrow-idx)
        let guard-ast = if guard-toks.any(tk => tk.at(0) != "sp") {
          guard.parse-guard-expr(guard-toks, token-names: fields.built-in-token-names)
        } else { ("otherwise",) }
        ("group", group-type, _trim-sp(nodes.slice(arrow-idx + 1)), guard-ast)
      } else {
        ("group", group-type, nodes, none)
      }
      nodes = parent
      if pending-alias != none and pending-alias.at(0) == stack.len() {
        nodes.push(("alias", pending-alias.at(1), group-node))
        for lit in pending-alias.at(2) { nodes.push(lit) }
        pending-alias = none
      } else {
        nodes.push(group-node)
      }
      i += 1
    } else if kind == "arrow" {
      if stack.len() == 0 { errors.raise("template.guard-arrow-outside-group") }
      nodes.push(("arrow",))
      i += 1
    } else if kind == "alias" {
      while nodes.len() > 0 and (nodes.last().at(0) == "sp" or (nodes.last().at(0) == "text" and nodes.last().at(1).trim() == "")) {
        nodes = nodes.slice(0, -1)
      }
      let alias-literals = ()
      while nodes.len() > 0 and (nodes.last().at(0) == "text" or nodes.last().at(0) == "punct") {
        alias-literals.insert(0, nodes.last())
        nodes = nodes.slice(0, -1)
      }
      if nodes.len() == 0 { errors.raise("template.alias-no-left") }
      let left = nodes.last()
      nodes = nodes.slice(0, -1)
      i += 1
      while i < n {
        let next-token = tokens.at(i)
        if next-token.at(0) == "sp" or (next-token.at(0) == "text" and next-token.at(1) == " ") { i += 1 } else { break }
      }
      if i >= n { errors.raise("template.alias-no-right") }
      pending-alias = (stack.len(), left, alias-literals)
    } else {
      let atom = if kind == "ident" { ("ident", token.at(1)) }
        else if kind == "text" { ("text", token.at(1)) }
        else if kind == "sp" { ("sp",) }
        else { ("punct", token.at(1)) }
      if pending-alias != none and kind != "sp" and pending-alias.at(0) == stack.len() {
        nodes.push(("alias", pending-alias.at(1), atom))
        for lit in pending-alias.at(2) { nodes.push(lit) }
        pending-alias = none
      } else {
        nodes.push(atom)
      }
      i += 1
    }
  }
  if stack.len() > 0 { errors.raise("template.unclosed-group") }
  if pending-alias != none { errors.raise("template.alias-no-right") }
  nodes
}

#let _is-empty(v) = {
  v == none or v == "" or v == []
}

#let _resolve-ident(name, entry, opts, custom-terms, strict: true) = {
  let custom-fields = opts.at("custom-fields", default: (:))
  let is-built-in = name in fields.built-in-token-names
  let is-field = custom-fields != none and name in custom-fields
  let is-term = custom-terms != none and name in custom-terms
  if not is-built-in and not is-field and not is-term {
    if strict { errors.raise("template.unknown-token", token: name) }
    return field.get(entry, name)
  }
  let v = if is-built-in { fields.resolve-built-in-token(name, entry, opts) } else { none }
  if v == none and is-field {
    v = resolve-field(name, custom-fields.at(name), entry, correct-punct: opts.correct-punct, punct-style: opts.punct-style, custom-punct: opts.custom-punct)
  }
  if v == none and is-term and not is-built-in {
    v = resolve-term(name, custom-terms.at(name), entry)
  }
  v
}

#let _eval-guard(ast, entry, opts, custom-terms) = {
  let k = ast.at(0)
  if k == "otherwise" { return true }
  if k == "and" { return ast.at(1).all(a => _eval-guard(a, entry, opts, custom-terms)) }
  if k == "or" { return ast.at(1).any(a => _eval-guard(a, entry, opts, custom-terms)) }
  if k == "not" { return not _eval-guard(ast.at(1), entry, opts, custom-terms) }
  if k == "present" {
    return not _is-empty(_resolve-ident(ast.at(1), entry, opts, custom-terms, strict: false))
  }
  let fname = ast.at(1)
  let op = ast.at(2)
  let values = ast.at(3)

  if fname == "type" and str(values.first()) in mark-medium.known-marks {
    errors.raise("template.guard-type-is-bib-field", value: str(values.first()))
  }
  let actual = if fname == "mark" { mark-medium.mark(entry) }
    else if fname == "medium" {
      let code = mark-medium.medium(entry, show-url: mark-medium.gate(opts.show-url, entry, version: opts.version), version: opts.version, online: fields.online(entry, opts))
      if code == none { "" } else { code }
    }
    else if fname == "entry-type" { entry.entry_type }
    else if fname == "entry-lang" { language.get(entry) }
    else { let v = field.get(entry, fname); if v == none { "" } else { str(v) } }
  let matches = str(actual) in values
  if op == "neq" { not matches } else { matches }
}

#let _is-otherwise(node) = {
  node.at(0) == "group" and node.len() > 3 and node.at(3) != none and node.at(3).at(0) == "otherwise"
}

#let _otherwise-suppressed(nodes, entry, opts, custom-terms) = {
  if not nodes.any(_is-otherwise) { return false }
  nodes.any(n => (
    n.at(0) == "group" and n.len() > 3 and n.at(3) != none and n.at(3).at(0) != "otherwise"
      and _eval-guard(n.at(3), entry, opts, custom-terms)
  ))
}

#let _CF-HUG-LEFT  = ".,:;?!)]}，。．、：；？！）】》」』（【《「『…·"
#let _CF-HUG-RIGHT = "([{，。．、：；？！（）【】《》「」『』…·"
#let _hug-left(ch)  = ch != none and _CF-HUG-LEFT.contains(ch)
#let _hug-right(ch) = ch != none and _CF-HUG-RIGHT.contains(ch)

#let _last-character(v) = {
  let t = if type(v) == str { v } else { punct.trailing-text(v) }
  if type(t) == str and t.len() > 0 { t.clusters().last() } else { none }
}

#let _first-character(v) = {
  let t = if type(v) == str { v } else { punct.leading-text(v) }
  if type(t) == str and t.len() > 0 { t.clusters().first() } else { none }
}

#let _resolve-separator(items, left-boundary, right-boundary) = {
  let out = ""
  let left-char = left-boundary
  for (index, it) in items.enumerate() {
    if it.at(0) == "hard" {
      let v = it.at(1)

      if left-char == "." and type(v) == str and v.starts-with(".") {
        v = v.slice(1)
      }
      out += v
      let last-char = _last-character(v)
      if last-char != none { left-char = last-char }
    } else {
      let next-char = none
      for j in range(index + 1, items.len()) {
        if items.at(j).at(0) == "hard" {
          let first-char = _first-character(items.at(j).at(1))
          if first-char != none { next-char = first-char; break }
        }
      }
      if next-char == none { next-char = right-boundary }
      if not (_hug-right(left-char) or _hug-left(next-char)) {
        out += " "
        left-char = " "
      }
    }
  }
  out
}

#let _has-text-literal(run) = {
  run.any(it => it.at(0) == "hard" and it.len() > 3 and it.at(3) == "text")
}

#let _collapse-around-empty(left, right, next-char) = {
  if next-char == "/" { return () }
  // 无 verbatim 字面量时保持原始折叠语义（内置 driver 路径逐字不变）
  if not (_has-text-literal(left) or _has-text-literal(right)) {
    for run in (left, right) {
      for item in run {
        if item.at(0) == "hard" and item.len() > 2 and item.at(2) { return (item,) }
      }
    }
    return right
  }
  // 有 verbatim 字面量时：折叠结构句点，但保留字面量及其前导软空格
  let collect(run) = {
    let literals = ()
    let period = none
    let pending-soft = none
    for item in run {
      if item.at(0) == "soft" { pending-soft = item; continue }
      if item.at(0) == "hard" and item.len() > 2 {
        if item.at(2) {
          if period == none { period = item }
          pending-soft = none
        } else if item.len() > 3 and item.at(3) == "text" {
          if pending-soft != none { literals.push(pending-soft); pending-soft = none }
          literals.push(item)
        } else {
          pending-soft = none
        }
      }
    }
    (literals, period)
  }
  let left-col = collect(left)
  let right-col = collect(right)
  let period-item = if left-col.at(1) != none { left-col.at(1) } else { right-col.at(1) }
  if period-item != none { return left-col.at(0) + right-col.at(0) + (period-item,) }
  left-col.at(0) + right
}

#let _drop-trailing-period(items) = {
  let last-hard = none
  for (index, item) in items.enumerate() {
    if item.at(0) == "hard" { last-hard = index }
  }
  if last-hard != none and items.at(last-hard).len() > 2 and items.at(last-hard).at(2) {
    items.slice(0, last-hard)
  } else { items }
}

#let _leads-with-structural-period(node) = {
  let kind = node.at(0)
  if kind == "punct" { return punct.char-to-slot.at(node.at(1), default: none) == "period" }
  if kind == "group" {
    for child in node.at(2) {
      if child.at(0) == "sp" { continue }
      return _leads-with-structural-period(child)
    }
    return false
  }
  false
}

#let _smart-join(nodes, parts, keep-trailing: false, active-group: false, always-emit: false) = {
  let phase = "preamble"
  let buffer = ()
  let prefix = ()
  let seen-data = false
  let result = []
  let emitted = false
  let last-character = none
  let held = ()
  let pending-empty = false
  for (i, cur-node) in nodes.enumerate() {
    let next-kind = cur-node.at(0)
    if next-kind == "sp" { buffer.push(("soft",)); continue }
    let p = parts.at(i)
    if next-kind == "punct" or next-kind == "text" {
      let is-period = next-kind == "punct" and punct.char-to-slot.at(cur-node.at(1), default: none) == "period"
      buffer.push(("hard", p, is-period, next-kind))
      continue
    }
    if not seen-data {
      seen-data = true
      if active-group { prefix = buffer; buffer = () }
    }
    if _is-empty(p) {
      held = if pending-empty { _collapse-around-empty(held, buffer, none) } else { buffer }
      pending-empty = true
      buffer = ()
      phase = "midstream"
      continue
    }
    if not emitted {

      let head = prefix + (if phase == "preamble" { buffer } else { () })
      if head.len() > 0 { result += _resolve-separator(head, none, _first-character(p)) }
      prefix = ()
      result += p
      emitted = true
      phase = "midstream"
    } else {
      let first-char = _first-character(p)
      let separator = if pending-empty { _collapse-around-empty(held, buffer, first-char) } else { buffer }

      if pending-empty and _leads-with-structural-period(cur-node) {
        separator = _drop-trailing-period(separator)
      }
      result += _resolve-separator(separator, last-character, first-char)
      result += p
    }
    last-character = _last-character(p)
    buffer = ()
    held = ()
    pending-empty = false
  }

  // 末尾被空组挂起的 held 仅当含 verbatim 字面量时才参与 flush，
  // 否则保持原始行为（内置 driver 路径逐字不变）
  let held-has-text = _has-text-literal(held)
  if keep-trailing and emitted and (buffer.len() > 0 or (pending-empty and held-has-text)) {
    let tail-sep = if pending-empty and held-has-text { _collapse-around-empty(held, buffer, none) } else { buffer }
    result += _resolve-separator(tail-sep, last-character, none)
  }
  if not emitted {

    if always-emit and buffer.len() > 0 { return _resolve-separator(buffer, none, none) }
    return none
  }
  result
}

#let _render-node(node, entry, opts, custom-terms) = {
  let kind = node.at(0)
  if kind == "text" { return node.at(1) }
  if kind == "punct" {
    let c = node.at(1)
    let overrides = opts.at("custom-punct", default: none)
    if c in punct.char-to-slot {
      let punct-name = punct.char-to-slot.at(c)

      if punct-name == "slash" {
        if overrides != none and punct.has-override(overrides, "slash") { return punct.resolve-value(punct.get-override(overrides, "slash")) }
        return c
      }
      return punct.get(punct-name, entry, opts.punct-style, overrides)
    }
    if overrides != none and c in overrides { return punct.resolve-value(overrides.at(c)) }
    return c
  }
  if kind == "ident" {

    return _resolve-ident(node.at(1), entry, opts, custom-terms)
  }
  if kind == "alias" {
    let left = _render-node(node.at(1), entry, opts, custom-terms)
    if not _is-empty(left) { return left }
    return _render-node(node.at(2), entry, opts, custom-terms)
  }
  if kind == "group" {
    let group-type = node.at(1)
    let body = node.at(2)
    let suppress = _otherwise-suppressed(body, entry, opts, custom-terms)
    let parts = ()
    for child in body {
      parts.push(if suppress and _is-otherwise(child) { none } else { _render-node(child, entry, opts, custom-terms) })
    }
    let guard = if node.len() > 3 { node.at(3) } else { none }
    if guard != none {
      if not _eval-guard(guard, entry, opts, custom-terms) { return none }
      return _smart-join(body, parts, keep-trailing: true, active-group: false, always-emit: true)
    }
    let data-parts = ()
    for (i, c) in body.enumerate() {
      if c.at(0) == "ident" or c.at(0) == "alias" or c.at(0) == "group" { data-parts.push(parts.at(i)) }
    }
    let pass = if group-type == "all" {
      data-parts.len() > 0 and data-parts.all(p => not _is-empty(p))
    } else {
      data-parts.any(p => not _is-empty(p))
    }
    if not pass { return none }
    return _smart-join(body, parts, keep-trailing: true, active-group: true)
  }
  none
}

#let _banned-driver-keys = (
  monograph: "改用 entry_type 点名（book / reference / techreport …）或大写码键（M / R / D …）",
  component-part: "改用 entry_type 点名（incollection / inbook …）",
  "serial-article": "改用 article: 或码键 J:",
  "serial-newspaper": "改用 newspaper: 点名 entry_type，或码键 N:",
  serial: "改用 periodical:",
  electronic: "改用 online:（@electronic/@www 解析期已归一为 online）或码键 EB:",
)
#let validate-driver-keys(custom-drivers, extra-marks: ()) = {
  for (k, _) in custom-drivers {
    if k in _banned-driver-keys {
      errors.raise("custom-drivers.banned-category-key", key: k, hint: _banned-driver-keys.at(k))
    }
    if k == upper(k) and k != lower(k) and k not in mark-medium.known-marks and k not in extra-marks {
      errors.raise("custom-drivers.key-not-mark", key: k, marks: (mark-medium.known-marks + extra-marks).join("/"))
    }
  }
}

#let uses-override(entry, custom-drivers, version: 2015) = {
  if custom-drivers == none or custom-drivers == (:) { return false }
  entry.entry_type in custom-drivers or mark-medium.base-mark(entry) in custom-drivers
}

#let render(entry, template, opts, custom-terms, show-end-period: false) = {
  let nodes = _parse(guard.tokenize(template))
  let suppress = _otherwise-suppressed(nodes, entry, opts, custom-terms)
  let parts = ()
  for node in nodes {
    parts.push(if suppress and _is-otherwise(node) { none } else { _render-node(node, entry, opts, custom-terms) })
  }
  let body = _smart-join(nodes, parts, keep-trailing: true)
  let data-blocks = 0
  for (i, node) in nodes.enumerate() {
    if node.at(0) not in ("sp", "punct", "text") and node.at(1, default: none) not in ("mark", "medium", "mark-medium") and not _is-empty(parts.at(i)) { data-blocks += 1 }
  }
  let single-block = if template.contains("built-in") {

    opts.at("built-in-single-block", default: data-blocks <= 1)
  } else { data-blocks <= 1 }
  let period-on = if show-end-period == auto { not single-block } else { show-end-period }
  if period-on and body != none {
    let dot = punct.get("period", entry, opts.punct-style, opts.custom-punct)
    if type(dot) == str { dot = dot.trim() }
    body = punct.append-end-period(body, dot)
  }
  (body, single-block)
}
