// BibTeX author 字段解析器
// 从原始 BibTeX 内容中提取 author 字段，保留花括号保护信息

/// 按 " and " / " AND " 分割作者列表（跳过花括号内的分隔符）
/// 返回分割后的作者名字符串数组
#let split-bib-authors(raw) = {
  let chars = raw.split("")
  let result = ()
  let current = ""
  let depth = 0
  let i = 0
  let total = chars.len()

  while i < total {
    let c = chars.at(i)
    if c == "{" { depth += 1 }
    if c == "}" { depth -= 1 }

    let is-sep = false
    if depth == 0 and i + 5 <= total {
      let seg = chars.slice(i, i + 5).join("")
      if seg == " and " or seg == " AND " {
        is-sep = true
      }
    }
    if is-sep {
      let trimmed = current.trim()
      if trimmed != "" { result.push(trimmed) }
      current = ""
      i += 5
    } else {
      current += c
      i += 1
    }
  }
  let trimmed = current.trim()
  if trimmed != "" { result.push(trimmed) }
  result
}

/// 检测作者名是否被花括号保护
#let is-brace-protected(name-text) = {
  let t = name-text.trim()
  t.starts-with("{") and t.ends-with("}")
}

/// 从原始 BibTeX 内容中解析所有 entry 的 author 字段
/// 返回 dict: entry-key -> 受保护的 family name 集合 (array of strings)
#let parse-bib-brace-protection(bib-content) = {
  let result = (:)
  let current-key = none
  let in-author = false
  let field-value = ""

  for line in bib-content.split("\n") {
    let trimmed = line.trim()
    // 检测 entry 开始: @type{key,
    if trimmed.starts-with("@") {
      let after-at = trimmed.slice(1)
      let brace-pos = after-at.position("{")
      if brace-pos != none {
        let after-brace = after-at.slice(brace-pos + 1)
        let comma-pos = after-brace.position(",")
        if comma-pos != none {
          current-key = after-brace.slice(0, comma-pos).trim()
        }
      }
    }
    if current-key != none {
      if not in-author {
        let eq-pos = trimmed.position("=")
        if eq-pos != none {
          let fname = trimmed.slice(0, eq-pos).trim()
          if fname == "author" {
            in-author = true
            field-value = trimmed.slice(eq-pos + 1)
          }
        }
      } else {
        field-value += " " + trimmed
      }
      if in-author {
        let d = 0
        for c in field-value.split("") {
          if c == "{" { d += 1 }
          if c == "}" { d -= 1 }
        }
        if d <= 0 and field-value.contains("}") {
          // 字段结束，清理值
          let cleaned = field-value.trim()
          if cleaned.ends-with(",") { cleaned = cleaned.slice(0, cleaned.len() - 1) }
          cleaned = cleaned.trim()
          if cleaned.starts-with("{") and cleaned.ends-with("}") {
            cleaned = cleaned.slice(1, cleaned.len() - 1)
          }
          // 分割作者并提取受保护的 family name
          let protected-families = ()
          let authors = split-bib-authors(cleaned)
          for a in authors {
            if is-brace-protected(a) {
              // 去掉外层花括号，作为受保护的 family name
              let inner = a.trim()
              if inner.starts-with("{") and inner.ends-with("}") {
                inner = inner.slice(1, inner.len() - 1)
              }
              protected-families.push(inner)
            }
          }
          result.insert(current-key, protected-families)
          in-author = false
          field-value = ""
        }
      }
    }
  }
  result
}
