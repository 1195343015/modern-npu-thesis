#import "../deps.typ": zh, numbly
#import "../utils.typ": 字体
#import "header-footer.typ": page-footer, page-header-footer
#import "floats.typ": setup-floats

#let mainmatter(
  graduate: false,
  degree: "master",
  english-writing: false,
  print-mode: false,
  it,
) = {
  let leading = if graduate { 11.8pt } else { 11pt }
  let heading-above = if graduate { (13pt, 7pt, 5pt) } else { (20pt, 0pt, 0pt) }
  let heading-below = if graduate { (14pt, 0pt, 0pt) } else { (24pt, 2pt, 0pt) }
  let heading-numbering = if english-writing {
    numbly("Chapter {1}  ", "{1}.{2}", "{1}.{2}.{3}", "({4})", "{5}")
  } else if graduate {
    numbly("第 {1} 章  ", "{1}.{2}", "{1}.{2}.{3}", "（{4}）", "{5}）")
  } else {
    numbly("第{1:一}章\u{3000}", "{1}.{2}", "{1}.{2}.{3}", "（{4}）", "{5}）")
  }

  // 图、表、公式、算法样式
  show: setup-floats.with(graduate: graduate, english-writing: english-writing)

  // 页眉页脚
  show: page-header-footer.with(graduate: graduate, degree: degree)

  // 文本和段落样式
  set align(left)
  set par(
    leading: leading,
    justify: true,
    first-line-indent: (amount: 2em, all: true),
    spacing: leading,
  )

  // 处理标题
  set heading(numbering: heading-numbering)
  show heading.where(level: 1): set text(font: 字体.黑体)
  show heading.where(level: 2): set text(font: 字体.黑体)
  show heading.where(level: 3): set text(font: 字体.黑体)
  show heading: it => {
    if it.level == 1 {
      counter(figure.where(kind: "algorithm")).update(0)
      counter(figure.where(kind: image)).update(0)
      counter(figure.where(kind: table)).update(0)
      counter(math.equation).update(0)
    }

    set text(
      size: (zh(3), zh(4), zh(4.5)).at(calc.min(it.level, 3) - 1),
      weight: "regular",
    )
    set par(first-line-indent: (amount: 0pt))

    let above-extra = heading-above.at(calc.min(it.level, heading-above.len()) - 1)
    let below-extra = heading-below.at(calc.min(it.level, heading-below.len()) - 1)

    // 一级标题统一换页并居中
    if it.level == 1 {
      pagebreak(weak: true, to: if graduate or print-mode { "odd" })
      v(leading + above-extra)
      align(center, block(below: leading + below-extra, it))
    } else if it.level >= 4 {
      // 四级及以后：首行缩进 2em，无额外间距
      block(above: leading, below: leading, pad(left: 2em, it))
    } else {
      block(above: leading + above-extra, below: leading + below-extra, it)
    }
  }

  it
}

// 前置部分（摘要、目录）：罗马数字页码 + 标题不编号
#let frontmatter(body) = {
  set page(footer: page-footer("I"))
  set heading(numbering: none)
  counter(page).update(1)
  body
}
