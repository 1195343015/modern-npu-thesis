#import "../sentinel.typ": *
#import "../elements/mark-medium/built-in.typ" as mark-medium
#import "../detect/lang.typ" as language
#import "../errors.typ"
#import "../parse/latex.typ"
#import "custom.typ"

#let _default-half = (
  comma: ", ", colon: ": ", lparen: "(", rparen: ")",
  semicolon: "; ", question: "?", exclam: "!",
  period: ". ", slash: "/", ellipsis: "… ",
)
#let _default-half-nospace = (
  comma: ",", colon: ":", lparen: "(", rparen: ")",
  semicolon: ";", question: "?", exclam: "!",
  period: ".", slash: "/", ellipsis: "…",
)

#let _default-full = (
  comma: "，", colon: "：", lparen: "（", rparen: "）",
  semicolon: "；", question: "？", exclam: "！",
  period: ". ", slash: "/", ellipsis: "…",
)

#let _style-affected = ("comma", "colon", "lparen", "rparen", "semicolon", "question", "exclam", "period", "ellipsis")

#let _cite-half       = (comma: ",", colon: ":", semicolon: ";", lparen: "(", rparen: ")")
#let _cite-half-space = (comma: ", ", colon: ": ", semicolon: "; ", lparen: "(", rparen: ")")
#let _cite-full       = (comma: "，", colon: "：", semicolon: "；", lparen: "（", rparen: "）")

#let cite-direction(eff-cite-punct-style, document-lang, entry-lang, eff-style) = {
  let mode = eff-cite-punct-style
  if type(mode) == dictionary { mode = mode.at(eff-style, default: "by-doc-and-style") }
  if mode == auto { mode = "by-doc-and-style" }
  let cj-document = document-lang == "zh" or document-lang == "ja"
  let cj-entry = entry-lang == "zh" or entry-lang == "ja"
  let is-author-date = eff-style == "author-date"
  if mode == "by-doc-and-style" {
    if is-author-date { if cj-document { "full" } else { "half-with-space" } } else { "half" }
  } else if mode == "by-doc-no-space" {
    if is-author-date and cj-document { "full" } else { "half" }
  } else if mode == "by-doc-with-space" {
    if is-author-date and cj-document { "full" } else { "half-with-space" }
  } else if mode == "by-entry-and-style" {
    if cj-entry { "full" } else if is-author-date { "half-with-space" } else { "half" }
  } else if mode == "by-entry-no-space" {
    if cj-entry { "full" } else { "half" }
  } else if mode == "by-entry-with-space" {
    if cj-entry { "full" } else { "half-with-space" }
  } else { mode }

}

#let cite(name, eff-cite-punct-style, document-lang, entry-lang, eff-style) = {
  let mode = cite-direction(eff-cite-punct-style, document-lang, entry-lang, eff-style)
  let table = if mode == "full" { _cite-full }
    else if mode == "half-with-space" { _cite-half-space }
    else { _cite-half }
  table.at(name, default: "")
}

#let supplement-style(eff-supplement-style, eff-style) = {
  if eff-supplement-style == "compact" or eff-supplement-style == "split" { eff-supplement-style }
  else { "split" }
}

#let is-cj-entry(entry) = {
  let lang = language.get(entry)
  lang == "zh" or lang == "ja"
}

#let _slot-char = (comma: ",", colon: ":", semicolon: ";", period: ".", question: "?", exclam: "!", slash: "/", lparen: "(", rparen: ")")
#let char-to-slot = { let m = (:); for (slot, c) in _slot-char { m.insert(c, slot) }; m }
#let separator-char-set = custom.separator-char-set
#let _slot-override-chars = custom.slot-chars
#let _char-to-slot-any = custom.char-to-slot-any
#let has-override = custom.has-override
#let get-override = custom.get-override
#let resolve-value = custom.resolve-value
#let _text-only = custom.text-only

#let resolve-dir(punct-style, is-cjk) = {
  if punct-style == "full" { "full" }
  else if punct-style == "by-entry-with-space" or punct-style == "by-doc-with-space" { if is-cjk { "full" } else { "half-with-space" } }
  else if punct-style == "by-entry-no-space" or punct-style == "by-doc-no-space" { if is-cjk { "full" } else { "half" } }
  else if punct-style == "half" or punct-style == "half-no-space" { "half" }
  else { "half-with-space" }
}

#let resolve-bib-document(punct-style, document-lang) = {
  let cj-document = document-lang == "zh" or document-lang == "ja"
  if punct-style == "by-doc-with-space" { if cj-document { "full" } else { "half-with-space" } }
  else if punct-style == "by-doc-no-space" { if cj-document { "full" } else { "half" } }
  else { punct-style }
}

#let get(name, entry, punct-style, custom-punct) = {
  if has-override(custom-punct, name) {
    return resolve-value(get-override(custom-punct, name))
  }
  if name not in _style-affected {
    return _default-half.at(name)
  }
  let dir = resolve-dir(punct-style, is-cj-entry(entry))
  if dir == "full" { _default-full.at(name) }
  else if dir == "half-with-space" { _default-half.at(name) }
  else { _default-half-nospace.at(name) }
}

#let unwrap-separator(value) = {
  let unescape(s) = s.replace("\\{", "{").replace("\\}", "}")
  if value.len() >= 2 and value.starts-with("{") and value.ends-with("}") {
    (verbatim: true, text: unescape(value.slice(1, value.len() - 1)))
  } else {
    (verbatim: false, text: unescape(value))
  }
}

#let separator-lang-keys = ("zh", "en", "ja", "ko", "ru", "fr", "rest")

#let pick-separator-by-lang(dict, lang, fallback) = {
  for key in dict.keys() {
    if key not in separator-lang-keys {
      errors.raise("separator.unknown-lang-key", key: key, keys: separator-lang-keys.join(" / "))
    }
  }
  if lang != none and lang in dict {
    let v = dict.at(lang)
    if v != none and v != "" { return v }
  }
  let rest = dict.at("rest", default: none)
  if rest != none and rest != "" { return rest }
  fallback
}

#let resolve-separator(value, entry, punct-style, custom-punct, fallback) = {
  let value = if type(value) == dictionary {
    pick-separator-by-lang(value, if entry != none { language.get(entry) } else { none }, fallback)
  } else { value }
  if type(value) != str { return value }
  let (verbatim, text) = unwrap-separator(value)
  if verbatim { return text }
  if text in _char-to-slot-any {
    get(_char-to-slot-any.at(text), entry, punct-style, custom-punct)
  } else { text }
}

#let resolve-cite-separator(value, eff-cite-punct-style, document-lang, entry-lang, eff-style, fallback) = {
  let value = if type(value) == dictionary { pick-separator-by-lang(value, entry-lang, fallback) } else { value }
  if type(value) != str { return value }
  let (verbatim, text) = unwrap-separator(value)
  if verbatim { return text }
  if text in _char-to-slot-any {
    cite(_char-to-slot-any.at(text), eff-cite-punct-style, document-lang, entry-lang, eff-style)
  } else { text }
}

#let end-period(entry, punct-style, custom-punct) = {
  let period-char = get("period", entry, punct-style, custom-punct)
  if type(period-char) == str { period-char.trim() } else { period-char }
}

#let _strip-breaks(text-value) = text-value.replace("\u{200b}", "").replace("\u{00ad}", "")

#let leading-text(value) = {
  if type(value) == str { return value }
  if type(value) != content { return "" }
  if value.has("text") { return value.text }
  if value.func() == [].func() and value.has("children") and value.children.len() > 0 {
    for kid in value.children {
      let t = leading-text(kid)
      if _strip-breaks(t).trim() != "" { return t }
    }
    return ""
  }
  if value.has("child") { return leading-text(value.child) }
  if value.has("body") { return leading-text(value.body) }
  ""
}

#let trailing-text(value) = {
  if type(value) == str { return value }
  if type(value) != content { return "" }
  if value.has("text") { return value.text }
  if value.func() == [].func() and value.has("children") and value.children.len() > 0 {
    let kids = value.children
    let i = kids.len() - 1
    while i >= 0 {
      let t = trailing-text(kids.at(i))
      if _strip-breaks(t).trim() != "" { return t }
      i -= 1
    }
    return ""
  }
  if value.has("child") { return trailing-text(value.child) }
  if value.has("body") { return trailing-text(value.body) }
  ""
}

#let ends-with-period(value, period: ".") = {
  let t = _strip-breaks(trailing-text(value)).trim(at: end)
  let p = _strip-breaks(trailing-text(period)).trim()
  if p == "" { return false }
  if p == "." or p == "．" {
    return (t.ends-with(".") or t.ends-with("．")) and not t.ends-with("..")
  }
  t.ends-with(p)
}

#let append-end-period(body, period) = {
  if period == none or period == "" or period == [] { return body }
  if ends-with-period(body, period: period) { body } else { [#body#period] }
}

#let long-text-fields = (
  "title", "subtitle", "titleaddon", "maintitle",
  "booktitle", "booksubtitle", "booktitleaddon",
  "journal", "journaltitle", "journalsubtitle", "journaltitleaddon", "shortjournal",
  "eventtitle", "series", "note",
)

#let _correct-map-full = (",": "，", ";": "；", "!": "！", "?": "？", "(": "（", ")": "）", ":": "：")
#let _correct-map-half = ("，": ",", "；": ";", "！": "!", "？": "?", "（": "(", "）": ")", "：": ":")

#let _colon-keep(c, previous, next) = {
  let digits = ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")
  (c == ":" or c == "：") and previous in digits and next in digits
}

#let _correct(s, entry, punct-style, custom-punct: (:)) = {
  if s == none or type(s) != str { return s }
  let dir = resolve-dir(punct-style, is-cj-entry(entry))
  let use-full = dir == "full"
  let add-space = dir == "half-with-space"
  let target = if use-full { _correct-map-full } else { _correct-map-half }
  let override-keys = ()
  for (slot, chars) in _slot-override-chars {
    if slot in ("period", "slash") { continue }
    if has-override(custom-punct, slot) {
      let override-text = _text-only(get-override(custom-punct, slot))
      for c in chars { target.insert(c, override-text); override-keys.push(c) }
    }
  }
  let characters = s.clusters()
  let n = characters.len()
  let i = 0
  let result = ""
  while i < n {
    let c = characters.at(i)
    let previous = if i > 0 { characters.at(i - 1) } else { "" }
    let next = if i + 1 < n { characters.at(i + 1) } else { "" }
    if c in target and not _colon-keep(c, previous, next) {
      result += target.at(c)
      if c in override-keys or use-full {
        if i + 1 < n and characters.at(i + 1) == " " { i += 2 } else { i += 1 }
      } else if add-space {
        if i + 1 < n and characters.at(i + 1) == " " { i += 1 }
        else { result += " "; i += 1 }
      } else {
        i += 1
      }
      continue
    }
    result += c
    i += 1
  }
  result
}

#let _block-lang(block) = {
  let lang-match = block.match(regex("\\b(?:langid|language)\\s*=\\s*\\{?([^{}\\n,]+?)\\}?\\s*[,}\\n]"))
  if lang-match != none {
    let lang-text = lower(lang-match.captures.first().trim())
    if lang-text == "chinese" or lang-text.starts-with("zh") { return "zh" }
    if lang-text == "japanese" or lang-text.starts-with("ja") { return "ja" }
    if lang-text == "korean" or lang-text.starts-with("ko") { return "ko" }
    if lang-text == "russian" or lang-text.starts-with("ru") { return "ru" }
    if lang-text in ("english", "american", "british") or lang-text.starts-with("en") { return "en" }
    if lang-text == "french" or lang-text.starts-with("fr") { return "fr" }
  }
  let has-cjk = false
  for c in block.clusters() {
    let codepoint = str.to-unicode(c)
    if (codepoint >= 0x3040 and codepoint <= 0x309F) or (codepoint >= 0x30A0 and codepoint <= 0x30FF) { return "ja" }
    if (codepoint >= 0xAC00 and codepoint <= 0xD7AF) or (codepoint >= 0x1100 and codepoint <= 0x11FF) or (codepoint >= 0x3130 and codepoint <= 0x318F) { return "ko" }
    if (codepoint >= 0x4E00 and codepoint <= 0x9FFF) or (codepoint >= 0x3400 and codepoint <= 0x4DBF) { has-cjk = true }
  }
  if has-cjk { "zh" } else { "en" }
}

#let preprocess(bib-string, punct-style, custom-punct) = {
  let characters = bib-string.clusters()
  let n = characters.len()
  let out = ()
  let i = 0
  while i < n {
    let c = characters.at(i)
    if c != "@" { out.push(c); i += 1; continue }
    let start = i
    let brace-pos = i + 1
    while brace-pos < n and characters.at(brace-pos) != "{" { brace-pos += 1 }
    if brace-pos >= n { for k in range(i, n) { out.push(characters.at(k)) }; break }
    let depth = 0
    let end = brace-pos
    while end < n {
      let current-character = characters.at(end)
      if current-character == "{" { depth += 1 }
      else if current-character == "}" { depth -= 1; if depth == 0 { end += 1; break } }
      end += 1
    }
    let block-characters = characters.slice(start, end)
    let is-by-lang = punct-style == "by-entry-with-space" or punct-style == "by-entry-no-space" or punct-style == "by-doc-with-space" or punct-style == "by-doc-no-space"
    let lang = if is-by-lang { _block-lang(block-characters.join("")) } else { "" }
    let use-full = resolve-dir(punct-style, lang == "zh" or lang == "ja") == "full"
    let map-base = if use-full { _correct-map-full } else { _correct-map-half }
    let final-map = (:)
    let override-keys = ()
    for (src, tgt) in map-base { final-map.insert(src, tgt) }
    if has-override(custom-punct, "comma") {
      let override-text = _text-only(get-override(custom-punct, "comma"))
      final-map.insert(",", override-text); final-map.insert("，", override-text)
      override-keys.push(","); override-keys.push("，")
    }
    if has-override(custom-punct, "semicolon") {
      let override-text = _text-only(get-override(custom-punct, "semicolon"))
      final-map.insert(";", override-text); final-map.insert("；", override-text)
      override-keys.push(";"); override-keys.push("；")
    }
    if has-override(custom-punct, "exclam") {
      let override-text = _text-only(get-override(custom-punct, "exclam"))
      final-map.insert("!", override-text); final-map.insert("！", override-text)
      override-keys.push("!"); override-keys.push("！")
    }
    if has-override(custom-punct, "question") {
      let override-text = _text-only(get-override(custom-punct, "question"))
      final-map.insert("?", override-text); final-map.insert("？", override-text)
      override-keys.push("?"); override-keys.push("？")
    }

    if has-override(custom-punct, "colon") {
      let override-text = _text-only(get-override(custom-punct, "colon"))
      final-map.insert(":", override-text); final-map.insert("：", override-text)
      override-keys.push(":"); override-keys.push("：")
    }
    if has-override(custom-punct, "lparen") {
      let override-text = _text-only(get-override(custom-punct, "lparen"))
      final-map.insert("(", override-text); final-map.insert("（", override-text)
      override-keys.push("("); override-keys.push("（")
    }
    if has-override(custom-punct, "rparen") {
      let override-text = _text-only(get-override(custom-punct, "rparen"))
      final-map.insert(")", override-text); final-map.insert("）", override-text)
      override-keys.push(")"); override-keys.push("）")
    }
    let processed = ()
    let block-count = block-characters.len()
    let block-i = 0
    let depth = 0
    let last-name = ""
    let collecting = false
    let new-name-buffer = ""
    let in-quote = false

    let quote-base-depth = 0
    while block-i < block-count {
      let current-character = block-characters.at(block-i)
      if current-character == "\"" {
        if in-quote and depth == quote-base-depth + 1 {
          in-quote = false; depth -= 1; processed.push(current-character); block-i += 1; continue
        }
        if not in-quote and depth == 1 {
          if collecting { last-name = new-name-buffer; new-name-buffer = ""; collecting = false }
          quote-base-depth = depth; in-quote = true; depth += 1; processed.push(current-character); block-i += 1; continue
        }
        processed.push(current-character); block-i += 1; continue
      }
      if current-character == "{" {
        if collecting { last-name = new-name-buffer; new-name-buffer = ""; collecting = false }
        depth += 1
        processed.push(current-character); block-i += 1
        continue
      }
      if current-character == "}" {
        depth -= 1
        processed.push(current-character); block-i += 1
        if depth == 0 { break }
        continue
      }
      if depth == 1 {
        let codepoint = if current-character.len() == 1 { str.to-unicode(current-character) } else { 0 }
        let is-letter = (codepoint >= 0x41 and codepoint <= 0x5A) or (codepoint >= 0x61 and codepoint <= 0x7A)
        let is-continuation = is-letter or (codepoint >= 0x30 and codepoint <= 0x39) or current-character == "_" or current-character == "-"
        if collecting and is-continuation { new-name-buffer += lower(current-character); processed.push(current-character); block-i += 1; continue }
        if not collecting and is-letter { collecting = true; new-name-buffer = lower(current-character); processed.push(current-character); block-i += 1; continue }
        if collecting { last-name = new-name-buffer; new-name-buffer = ""; collecting = false }
        processed.push(current-character); block-i += 1
        continue
      }
      if depth == 2 {

        if last-name in long-text-fields and current-character == "\\" {
          let j = block-i + 1
          let word = ""
          while j < block-count {
            let ch = block-characters.at(j)
            let cp = if ch.len() == 1 { str.to-unicode(ch) } else { 0 }
            if (cp >= 0x41 and cp <= 0x5A) or (cp >= 0x61 and cp <= 0x7A) { word += ch; j += 1 } else { break }
          }
          if word in latex.PUNCT-MACROS {
            while j < block-count and block-characters.at(j) in (" ", "\t", "\n", "\r") { j += 1 }
            block-characters = block-characters.slice(0, block-i) + latex.PUNCT-MACROS.at(word).clusters() + block-characters.slice(j)
            block-count = block-characters.len()
            continue
          }
        }
        let char-previous = if block-i > 0 { block-characters.at(block-i - 1) } else { "" }
        let char-next = if block-i + 1 < block-count { block-characters.at(block-i + 1) } else { "" }
        if last-name in long-text-fields and current-character in final-map and not _colon-keep(current-character, char-previous, char-next) {
          processed.push(final-map.at(current-character))
          let next-is-space = block-i + 1 < block-count and block-characters.at(block-i + 1) == " "
          if current-character in override-keys {
            if next-is-space { block-i += 2 } else { block-i += 1 }
          } else if use-full {
            if next-is-space { block-i += 2 } else { block-i += 1 }
          } else {
            if next-is-space { block-i += 1 }
            else { processed.push(" "); block-i += 1 }
          }
          continue
        }
        processed.push(current-character)
        block-i += 1
        continue
      }
      processed.push(current-character); block-i += 1
    }
    while block-i < block-count { processed.push(block-characters.at(block-i)); block-i += 1 }
    for c in processed { out.push(c) }
    i = end
  }
  out.join("")
}

#let field-text(entry, key, correct-punct: false, punct-style: "half-with-space", custom-punct: (:), force-correct: false) = {
  let v = entry.fields.at(key, default: none)
  if v == none { return none }
  if type(v) == str and v.trim() == "" { return none }
  if type(v) != str { return v }
  let result = latex.to-typst(v)
  if correct-punct and type(result) == str and force-correct and (key not in long-text-fields) {
    result = _correct(result, entry, punct-style, custom-punct: custom-punct)
  }
  result
}

#let field-text-alias(entry, real, alias) = {
  let v = field-text(entry, real)
  if v == none { v = field-text(entry, alias) }
  v
}

#let number-field-text(entry, key, correct-punct: false, punct-style: "half-with-space") = {
  let v = field-text(entry, key, correct-punct: correct-punct, punct-style: punct-style)
  if type(v) == int or type(v) == float { str(v) } else { v }
}
