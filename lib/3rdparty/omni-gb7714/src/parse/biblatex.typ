// vendored 补丁：原为根绝对导入 "/citegeist/lib.typ"（Universe 包根语义），
// 本地 vendoring 改为相对路径
#import "../../citegeist/lib.typ": load-bibliography
#import "../sentinel.typ": *
#import "../errors.typ"
#import "../punct/built-in.typ" as punct
#import "latex.typ"

#let load(bib-string, latex-strict-char: true, correct-punct: false, punct-style: "half-with-space", custom-punct: (:), titles-text-case: none) = {

  bib-string = bib-string.replace(
    regex("(?i)(,\\s*)address(\\s*=)"),
    m => m.captures.at(0) + "location" + m.captures.at(1),
  )

  bib-string = bib-string.replace(
    regex("(?i)(,\\s*)nameatype(\\s*=)"),
    m => m.captures.at(0) + "editoratype" + m.captures.at(1),
  )
  bib-string = bib-string.replace(
    regex("(?i)(,\\s*)namea(\\s*=)"),
    m => m.captures.at(0) + "editora" + m.captures.at(1),
  )

  bib-string = bib-string.replace("\\\\", _SLB)
  bib-string = bib-string.replace("\\$", _SD)
  bib-string = bib-string.replace(regex("\\\\textasciitilde(\\{\\}|\\s)?"), _ST)
  bib-string = bib-string.replace(regex("\\\\textasciicircum(\\{\\}|\\s)?"), _SCIRC)
  bib-string = bib-string.replace(regex("\\\\textbackslash(\\{\\}|\\s)?"), _SBS)

  bib-string = bib-string.replace(regex("\\\\textbraceleft(\\{\\}|\\s)?"), _SLBR)
  bib-string = bib-string.replace(regex("\\\\textbraceright(\\{\\}|\\s)?"), _SRBR)
  bib-string = bib-string.replace(regex("\\\\textunderscore(\\{\\}|\\s)?"), _SUND)
  bib-string = bib-string.replace(regex("\\\\textdollar(\\{\\}|\\s)?"), _SD)

  bib-string = bib-string.replace("\\&", _SAMP).replace("\\_", _SUND).replace("\\#", _SHSH).replace("\\%", _SPCT)

  if latex-strict-char and bib-string.matches("\\{").len() != bib-string.matches("\\}").len() {
    assert(false, message: "omni-gb7714: bib 中存在未配对的转义花括号 `\\{` / `\\}`（真 biblatex 下会打乱 biber 的花括号计数、导致解析失败——`\\{`/`\\}` 不是可靠写法）。\n— 字面花括号*推荐*用 `\\textbraceleft` / `\\textbraceright`（或 `$\\lbrace$` / `$\\rbrace$`）：它们不参与花括号计数、未配对也安全；\n— 或确保 `\\{` 与 `\\}` 成对出现；\n— 要让本包*容忍*未配对（宽松），设 `gb7714(latex-strict-char: false)`。")
  }
  bib-string = bib-string.replace("\\{", _SLBR).replace("\\}", _SRBR)

  bib-string = latex.normalize-decls(bib-string)

  bib-string = latex.normalize-html(bib-string)

  if calc.rem(bib-string.matches("$").len(), 2) != 0 {
    assert(false, message: "omni-gb7714: bib 中存在未配对的数学定界符 `$`（biblatex 下等价错误：“! Missing $ inserted.”）。\n— 要表示*字面美元符*，请写 `\\$`；\n— 要写*数学公式*，请成对使用 `$...$`（每个字段值内自闭合）。")
  }

  if correct-punct {
    bib-string = punct.preprocess(bib-string, punct-style, custom-punct)
  }

  let _ttc-fields = ("title", "subtitle", "titleaddon", "maintitle", "booktitle", "booksubtitle", "booktitleaddon", "journaltitle", "journalsubtitle", "journaltitleaddon", "eventtitle", "series")
  let _ttc-map = if std.type(titles-text-case) == dictionary {
    for (k, v) in titles-text-case {
      if k not in _ttc-fields and k != "journal" and k != "rest" { errors.raise("titles-text-case.bad-key", key: k) }
      if v not in (none, "sentence", "title") { errors.raise("titles-text-case.bad-value", key: k, value: repr(v)) }
    }
    let rest = titles-text-case.at("rest", default: none)
    let m = (:)
    for f in _ttc-fields {
      let v = titles-text-case.at(f, default: auto)
      if f == "journaltitle" and v == auto { v = titles-text-case.at("journal", default: auto) }
      m.insert(f, if v == auto { rest } else { v })
    }
    m
  } else {
    errors.check-enum("titles-text-case", titles-text-case)
    let m = (:)
    for f in _ttc-fields { m.insert(f, titles-text-case) }
    m
  }
  let _ttc-mode(v) = if v == "sentence" { "1" } else { "2" }
  let _ttc-parts = ()
  for pr in _ttc-map.pairs() {
    if pr.at(1) != none {
      _ttc-parts.push(pr.at(0) + "=" + _ttc-mode(pr.at(1)))
      if pr.at(0) == "journaltitle" { _ttc-parts.push("journal=" + _ttc-mode(pr.at(1))) }
    }
  }
  let _ttc-payload = _ttc-parts.join("," , default: "")
  load-bibliography(bib-string, keep-raw-names: true, sentence-case-titles: false, text-case: _ttc-payload)
}
