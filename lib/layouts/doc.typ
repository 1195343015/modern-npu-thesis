#import "../deps.typ": cjk-spacer, show-cn-fakebold, zh
#import "../utils.typ": 字体

#let doc(
  graduate: false,
  it,
) = {
  let margin = if graduate {
    (top: 2.54cm, bottom: 2.54cm, left: 2.5cm, right: 2.5cm)
  } else {
    (top: 2.54cm, bottom: 2.54cm, left: 3.18cm, right: 3.18cm)
  }
  show: show-cn-fakebold
  show: cjk-spacer
  set text(zh(4.5), font: 字体.宋体混排, hyphenate: true, lang: "zh")
  set smartquote(enabled: false)
  show regex("[a-zA-Z]+"): set text(lang: "en")
  set par(leading: 12pt, spacing: 12pt)
  set align(center)
  set table(stroke: none, align: center, inset: (x: 0pt, y: 4pt))
  set page(
    margin: margin,
  )

  it
}
