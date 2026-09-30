#import "@preview/mitex:0.2.7": mi as _mi
#import "../sentinel.typ": *
#import "../errors.typ"

#let _LTR = "a-zA-Z\u{00C0}-\u{024F}\u{3400}-\u{4dbf}\u{4e00}-\u{9fff}\u{f900}-\u{faff}\u{3040}-\u{309f}\u{30a0}-\u{30ff}\u{ac00}-\u{d7af}"

#let _TRIVIAL-RE = regex("[\\\\~$'`&_#%^{}\u{E000}-\u{F8FF}]")

#let _strict-wrap(value, message, key) = context {
  if state(key, true).get() { panic(message) }
  value
}

#let _bare-special(s) = {
  for ch in ("&", "_", "#", "%", "^") { if s.contains(ch) { return ch } }
  none
}
#let _special-message(ch) = errors.message("latex.special-char", char: ch)

#let _restore-backslash-linebreak(t) = {
  let s = t.replace(_SBS, "\\").replace(_SAMP, "&").replace(_SUND, "_").replace(_SHSH, "#").replace(_SPCT, "%").replace(_SCIRC, "^")
  if "{" in s or "}" in s { s = s.replace("{", "").replace("}", "") }
  s = s.replace(_SLBR, "{").replace(_SRBR, "}")
  if _SLB in s {
    let segments = s.split(_SLB)
    segments.enumerate().map(((i, segment)) => if i == 0 { segment } else { segment.trim(at: start) }).join(linebreak())
  } else { s }
}

#let _brace-span(s, open) = {
  let depth = 0
  for b in s.matches(regex("[{}]")) {
    if b.start < open { continue }
    if b.text == "{" { depth += 1 } else { depth -= 1 }
    if depth == 0 { return (b.start, b.end) }
  }
  (s.len(), s.len())
}

#let _DECL-TO-CMD = (
  bfseries: "textbf", scshape: "textsc", ttfamily: "texttt", sffamily: "textsf",
  itshape: "textit", slshape: "textit", normalfont: "textnormal", mdseries: "textnormal",
  upshape: "textnormal", rmfamily: "textnormal",
  bf: "textbf", it: "textit", sl: "textit", sc: "textsc", tt: "texttt", sf: "textsf", em: "emph",
)

#let normalize-decls(s) = {
  let names = _DECL-TO-CMD.keys().join("|")
  let re = regex("\\{\\\\(" + names + ")[ \t\n]")
  let out = s
  let from = 0
  let guard = 0
  while guard < 5000 {
    guard += 1
    let m = out.slice(from).match(re)
    if m == none { break }
    let open = from + m.start
    if out.slice(0, open).trim(at: end).ends-with("=") { from = open + 1; continue }
    let span = _brace-span(out, open)
    let command = _DECL-TO-CMD.at(m.captures.at(0))
    let content = out.slice(from + m.end, span.at(0))
    out = out.slice(0, open) + "\\" + command + "{" + content + "}" + out.slice(span.at(1))
    from = open
  }
  out
}

#let normalize-html(s) = {
  let out = s

  out = out.replace("{\\textless}", "<").replace("{\\textgreater}", ">")
  out = out.replace(regex("\\\\textless\\b(\\{\\})?"), "<").replace(regex("\\\\textgreater\\b(\\{\\})?"), ">")
  for (tag, cmd) in (("i", "textit"), ("b", "textbf"), ("sup", "textsuperscript"), ("sub", "textsubscript"), ("sc", "textsc")) {
    out = out.replace(regex("(?i)<" + tag + ">"), "\\" + cmd + "{").replace(regex("(?i)</" + tag + ">"), "}")
  }
  out = out.replace(regex("(?i)<span\\s+class=[\"']nocase[\"']\\s*>"), "{").replace(regex("(?i)</span>"), "}")
  out
}

#let _TEX-FONT-ARG = (
  textbf: strong, textit: emph, emph: emph, textsc: smallcaps,
  textsuperscript: super, textsubscript: sub, textup: it => it, textmd: it => it,
  textnormal: it => it, textrm: it => it, textsf: it => it, textsl: emph, underline: underline,

  mkbibbold: strong, mkbibemph: emph, mkbibitalic: emph, mkbibsuperscript: super,
)

#let _TEX-DECL = (
  bfseries: strong, bf: strong, itshape: emph, it: emph, em: emph, slshape: emph, sl: emph,
  scshape: smallcaps, sc: smallcaps,
  mdseries: none, upshape: none, normalfont: none, rmfamily: none, rm: none, selectfont: none,
  sffamily: none, sf: none,
  tiny: none, scriptsize: none, footnotesize: none, small: none, normalsize: none,
  large: none, Large: none, LARGE: none, huge: none, Huge: none,
)

#let PUNCT-MACROS = (
  adddot: ".", addcomma: ",", addsemicolon: ";", addcolon: ":", addperiod: ".",
  addspace: " ", addnbspace: "\u{00A0}", addnbthinspace: "\u{202F}",
  isdot: "", adddotspace: ". ", addslash: "/",
  addabbrvspace: " ", addlowpenspace: " ", addhighpenspace: " ", addabthinspace: "\u{202F}",
)

#let _TEX-SYM = (
  ldots: "\u{2026}", dots: "\u{2026}",
  ddag: "\u{2021}", dag: "\u{2020}", P: "\u{00B6}", S: "\u{00A7}",
  copyright: "\u{00A9}", pounds: "\u{00A3}", textsterling: "\u{00A3}",
  texttrademark: "\u{2122}", textregistered: "\u{00AE}", textcopyright: "\u{00A9}",
  textbullet: "\u{2022}", textperiodcentered: "\u{00B7}", textasciicircum: "^",
  texteuro: "\u{20AC}", textyen: "\u{00A5}", textcent: "\u{00A2}",
  textordfeminine: "\u{00AA}", textordmasculine: "\u{00BA}",
  textquotedblleft: "\u{201C}", textquotedblright: "\u{201D}",
  textquoteleft: "\u{2018}", textquoteright: "\u{2019}",
  textendash: "\u{2013}", textemdash: "\u{2014}",
  quad: "\u{2003}", qquad: "\u{2003}\u{2003}", space: " ", thinspace: "\u{2009}",
  textdegree: "\u{00B0}", textmu: "\u{00B5}", texttimes: "\u{00D7}", textdiv: "\u{00F7}",
  textpm: "\u{00B1}", textminus: "\u{2212}", textonehalf: "\u{00BD}", textonequarter: "\u{00BC}",
  textthreequarters: "\u{00BE}", textnumero: "\u{2116}", textcelsius: "\u{2103}", textohm: "\u{2126}",
  textquotedbl: "\u{201D}", textsection: "\u{00A7}", textparagraph: "\u{00B6}",
  textasteriskcentered: "\u{2217}", textbar: "|", textless: "<", textgreater: ">",
  textexclamdown: "\u{00A1}", textquestiondown: "\u{00BF}",

  textbraceleft: _SLBR, textbraceright: _SRBR,
  textunderscore: _SUND, textdollar: _SD,
  textpilcrow: "\u{00B6}", textperthousand: "\u{2030}", textpertenthousand: "\u{2031}",
  textbardbl: "\u{2016}", textlnot: "\u{00AC}", textlangle: "\u{2329}", textrangle: "\u{232A}",
  textleftarrow: "\u{2190}", textrightarrow: "\u{2192}", textuparrow: "\u{2191}", textdownarrow: "\u{2193}",
  textsurd: "\u{221A}", textbrokenbar: "\u{00A6}", textreferencemark: "\u{203B}",
  textfractionsolidus: "\u{2044}", textflorin: "\u{0192}",
  enspace: "\u{2002}", enskip: "\u{2002}", nobreakspace: "\u{00A0}", bibellipsis: "[\u{2026}]",
  hyphen: "-", nbhyphen: "\u{2011}",

  ..PUNCT-MACROS,
)
#let _TEX-BREAK = ("newline", "linebreak", "par", "newblock")
#let _TEX-PASSTHRU = (
  "mbox", "hbox", "vbox", "fbox", "makebox", "text", "protect", "frenchspacing",
  "bibstring", "selectlanguage", "foreignlanguage", "othername", "textln", "autocap", "bibhyphen",
)

#let TEX-DROP-ARG = ("noopsort", "sortname", "bibsort")
#let _TEX-DROP-TOK = ("relax", "noindent", "verb", "ignorespaces", "unskip", "bibsentence", "noexpand", "bigskip", "medskip", "smallskip")
#let _TEX-CTRL-SYM = (
  " ": " ", ",": "\u{2009}", ";": "\u{2005}", ":": "\u{2005}", "!": "",
  "-": "\u{00AD}", "/": "", ">": "", "<": "",
)

#let _hspace(arg) = {
  let m = arg.match(regex("([0-9.]+)(em|pt|cm|mm|in)"))
  if m == none { return none }
  let value = float(m.captures.at(0)); let unit = m.captures.at(1)
  if unit == "em" { h(value * 1em) } else if unit == "pt" { h(value * 1pt) }
  else if unit == "cm" { h(value * 1cm) } else if unit == "mm" { h(value * 1mm) }
  else if unit == "in" { h(value * 1in) } else { h(value * 1pt) }
}

#let _read-arg(s, p) = {
  if p < s.len() and s.slice(p).starts-with("{") {
    let span = _brace-span(s, p)
    (s.slice(p + 1, span.at(0)), span.at(1))
  } else if p < s.len() {
    let clusters = s.slice(p).clusters()
    if clusters.len() == 0 { ("", s.len()) } else { (clusters.first(), p + clusters.first().len()) }
  } else { ("", s.len()) }
}

#let _command-scan(s) = {
  let parts = ()
  let rest = s
  let buffer = ""
  let bad-command = none
  while rest.len() > 0 {
    let backslash-at = rest.position("\\")
    if backslash-at == none { buffer += rest; rest = ""; break }
    buffer += rest.slice(0, backslash-at)
    let after = rest.slice(backslash-at + 1)
    let command-word = after.match(regex("^[" + _LTR + "]+"))
    if command-word != none {
      let name = command-word.text
      let p = name.len()
      let absorbed = after.slice(p).find(regex("^\\s+"))
      if absorbed != none { p += absorbed.len() }
      let argpos = backslash-at + 1 + p
      let aftercmd = backslash-at + 1 + p
      if name == "ttfamily" or name == "tt" {
        if buffer != "" { parts.push(buffer); buffer = "" }
        let s = _restore-backslash-linebreak(rest.slice(argpos))
        parts.push(if type(s) == str { raw(s) } else { s })
        rest = ""; break
      } else if name in _TEX-DECL {
        if buffer != "" { parts.push(buffer); buffer = "" }
        let wrapper = _TEX-DECL.at(name)
        let inner = _command-scan(rest.slice(argpos))
        parts.push(if wrapper == none { inner } else { wrapper(inner) })
        rest = ""; break
      } else if name == "texttt" {
        if buffer != "" { parts.push(buffer); buffer = "" }
        let (arg, nxt) = _read-arg(rest, argpos)
        let s = _restore-backslash-linebreak(arg)
        parts.push(if type(s) == str { raw(s) } else { s }); rest = rest.slice(nxt)
      } else if name in _TEX-FONT-ARG {
        if buffer != "" { parts.push(buffer); buffer = "" }
        let (arg, nxt) = _read-arg(rest, argpos)
        let inner = if arg.contains("\\") { _command-scan(arg) } else { _restore-backslash-linebreak(arg) }
        parts.push((_TEX-FONT-ARG.at(name))(inner)); rest = rest.slice(nxt)
      } else if name == "hspace" {
        if buffer != "" { parts.push(buffer); buffer = "" }
        let (arg, nxt) = _read-arg(rest, argpos)
        let hspace-result = _hspace(arg); if hspace-result != none { parts.push(hspace-result) }
        rest = rest.slice(nxt)
      } else if name == "url" {
        let (arg, nxt) = _read-arg(rest, argpos)
        buffer += arg; rest = rest.slice(nxt)
      } else if name in ("MakeUppercase", "MakeLowercase", "MakeTextUppercase", "MakeTextLowercase", "uppercase", "lowercase") {
        let (arg, nxt) = _read-arg(rest, argpos)
        buffer += if lower(name).contains("upper") { upper(arg) } else { lower(arg) }
        rest = rest.slice(nxt)
      } else if name == "mkbibquote" {
        if buffer != "" { parts.push(buffer); buffer = "" }
        let (arg, nxt) = _read-arg(rest, argpos)
        let inner = if arg.contains("\\") { _command-scan(arg) } else { _restore-backslash-linebreak(arg) }
        parts.push([\u{201C}#inner\u{201D}]); rest = rest.slice(nxt)
      } else if name in _TEX-PASSTHRU {
        if buffer != "" { parts.push(buffer); buffer = "" }
        let (arg, nxt) = _read-arg(rest, argpos)
        let inner = if arg.contains("\\") { _command-scan(arg) } else { _restore-backslash-linebreak(arg) }
        parts.push(inner); rest = rest.slice(nxt)
      } else if name in TEX-DROP-ARG {
        let (_a, nxt) = _read-arg(rest, argpos)
        rest = rest.slice(nxt)
      } else if name in _TEX-DROP-TOK {
        rest = rest.slice(aftercmd)
      } else if name in _TEX-SYM {
        buffer += _TEX-SYM.at(name)
        rest = rest.slice(aftercmd)
      } else if name in _TEX-BREAK {
        if buffer != "" { parts.push(buffer); buffer = "" }
        parts.push(linebreak()); rest = rest.slice(aftercmd)
      } else {

        if bad-command == none { bad-command = name }
        if argpos < rest.len() and rest.slice(argpos).starts-with("{") {
          if buffer != "" { parts.push(buffer); buffer = "" }
          let (arg, nxt) = _read-arg(rest, argpos)
          let inner = if arg.contains("\\") { _command-scan(arg) } else { _restore-backslash-linebreak(arg) }
          parts.push(inner); rest = rest.slice(nxt)
        } else {
          rest = rest.slice(aftercmd)
        }
      }
    } else {
      if after.len() == 0 { rest = "" } else {
        let ch = after.clusters().first()
        if ch in _TEX-CTRL-SYM { buffer += _TEX-CTRL-SYM.at(ch) }
        rest = after.slice(ch.len())
      }
    }
  }
  if buffer != "" { parts.push(buffer) }
  let result = []
  for part in parts { result += if type(part) == str { _restore-backslash-linebreak(part) } else { part } }

  if bad-command != none {
    return _strict-wrap(result, errors.message("latex.undefined-command", command: bad-command), "gb7714-latex-strict-command")
  }
  result
}

#let to-typst(s) = {
  if s == none { return none }
  let text = if type(s) == str { s } else { return s }

  if not text.contains(_TRIVIAL-RE) { return text }

  if not text.contains("\\") and not text.contains("~") and not text.contains("$") and not text.contains("'") and not text.contains("`") {
    let bare = _bare-special(text)
    let restored = _restore-backslash-linebreak(text.replace(_SD, "$").replace(_ST, "~"))
    return if bare != none { _strict-wrap(restored, _special-message(bare), "gb7714-latex-strict-char") } else { restored }
  }

  if text.contains("\\ensuremath{") {
    text = text.replace(regex("\\\\ensuremath\\s*\\{([^{}]*)\\}"), m => "$" + m.captures.at(0) + "$")
  }

  if text.contains("$") {
    let work = text.replace("\\$", _SD)
    if work.contains("$") {
      let _space-only-math = ("\\quad": "\u{2003}", "\\qquad": "\u{2003}\u{2003}", "\\,": "\u{2009}", "\\;": "\u{2005}", "\\:": "\u{2004}", "\\ ": " ", "\\!": "")
      let math-parts = ()
      let rest = work
      while rest.contains("$") {
        let start = rest.position("$")
        if start > 0 { math-parts.push(rest.slice(0, start)) }
        let after = rest.slice(start + 1)
        let end = after.position("$")
        if end == none { math-parts.push(_SD + after); rest = ""; break }
        let _math-content = after.slice(0, end)
        if _math-content.trim() in _space-only-math { math-parts.push(_space-only-math.at(_math-content.trim())) }
        else { math-parts.push(_mi(_math-content)) }
        rest = after.slice(end + 1)
      }
      if rest.len() > 0 { math-parts.push(rest) }
      let result = []
      for p in math-parts {
        if type(p) == str { result += to-typst(p) } else { result += p }
      }
      return result
    }
    text = work.replace(_SD, "$")
  }
  text = text.replace(_SD, "$")

  text = text.replace("~", "\u{00A0}")
  text = text.replace(_ST, "~")

  text = text.replace("``", "\u{201C}").replace("''", "\u{201D}")
  text = text.replace("`", "\u{2018}")

  let bare = _bare-special(text)
  let scanned = _command-scan(text)
  if bare != none { _strict-wrap(scanned, _special-message(bare), "gb7714-latex-strict-char") } else { scanned }
}
