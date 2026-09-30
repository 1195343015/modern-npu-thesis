#import "../errors.typ"

#let slot-chars = (
  comma: (",", "，"), colon: (":", "："), semicolon: (";", "；"),
  period: (".", "。", "．"), question: ("?", "？"), exclam: ("!", "！"),
  slash: ("/", "／"), lparen: ("(", "（"), rparen: (")", "）"),

  ellipsis: ("…",),
)

#let char-to-slot-any = { let m = (:); for (slot, chars) in slot-chars { for c in chars { m.insert(c, slot) } }; m }

#let separator-char-set = char-to-slot-any.keys()

#let validate-punct(custom-punct) = {
  if custom-punct == none or custom-punct == auto { return }
  for (k, _) in custom-punct {
    if k not in char-to-slot-any {
      errors.raise("custom-punct.unknown-key", key: k, keys: separator-char-set.join(" "))
    }
  }
}

#let _override-key(custom-punct, slot) = {
  if custom-punct == none { return none }
  for c in slot-chars.at(slot, default: ()) {
    if c in custom-punct { return c }
  }
  none
}

#let has-override(custom-punct, slot) = _override-key(custom-punct, slot) != none

#let get-override(custom-punct, slot) = custom-punct.at(_override-key(custom-punct, slot))

#let resolve-value(v) = {
  if type(v) == str { return v }
  if type(v) == dictionary {
    let body = v.at("text", default: v.at("val", default: ""))
    let kwargs = v
    let _ = kwargs.remove("text", default: none)
    let _ = kwargs.remove("val", default: none)
    if kwargs.len() == 0 { return body }
    return text(..kwargs, body)
  }
  v
}

#let text-only(v) = {
  if type(v) == str { return v }
  if type(v) == dictionary { return v.at("text", default: v.at("val", default: "")) }
  ""
}
