#import "../deps.typ": algorithm-figure, cap-style, capfig-style, captab-style, i-figured, style-algorithm, zh
#import "../utils.typ": 字体

// 统一编号格式状态：正文 "1-1"，附录 "A-1"
#let numbering-format = state("nwpu-numbering-format", "1-1")

// 英文写作模式状态，由 setup-floats 在正文开始时写入
#let english-writing-state = state("nwpu-english-writing", false)

#let with-numbering-format(format, it) = {
  numbering-format.update(format)
  show: cap-style.with(numbering-format: format)
  it
}

#let algorithm(title: none, ..body) = {
  algorithm-figure(
    title,
    supplement: context {
      let en = english-writing-state.get()
      if en { [Algorithm] } else { [算法] }
    },
    inset: 0.43em,
    ..body,
  )
}

#let equation-note(body) = context {
  let en = english-writing-state.get()
  block(width: 100%)[
    #set par(first-line-indent: 0pt, justify: false)
    #set text(zh(5))
    #if en {
      [where ]
    } else {
      [式中，]
    }
    #body
  ]
}

#let setup-floats(
  graduate: false,
  english-writing: false,
  body,
) = {
  english-writing-state.update(english-writing)

  let line-height = 23pt

  // 算法样式
  show figure.where(kind: "algorithm"): set text(zh(5))
  show: style-algorithm.with(
    caption-style: body => text(zh(5), strong(body)),
    hlines: (
      grid.hline(stroke: 1.5pt + black),
      grid.hline(stroke: 1pt + black),
      grid.hline(stroke: 1.5pt + black),
    ),
  )

  // 公式编号
  set math.equation(supplement: if english-writing { [Equation] } else { [式] })
  show math.equation.where(block: true): i-figured.show-equation.with(
    numbering: (..nums) => context {
      set text(font: 字体.宋体混排)
      if graduate {
        numbering("(" + numbering-format.get() + ")", ..nums)
      } else {
        [（#numbering(numbering-format.get(), ..nums)）]
      }
    },
  )

  // cap-able 全局样式（共享参数）
  show: cap-style.with(
    numbering-format: "1-1",
    use-chapter: true,
    caption-size: zh(5),
    pre-supplement-number-spacing: if english-writing { 0.3em } else { 0em },
  )

  // 表格样式
  show table: set par(justify: false)
  set table(stroke: if graduate { 1pt } else { 0.5pt }, align: center + horizon)

  // 表格独有配置
  show: captab-style.with(
    three-line-table: if graduate { true } else { false },
    supplement: if english-writing { "Table" } else { "表" },
    body-size: zh(5),
    cell-inset: (x: if graduate { 0.5em } else { 0.8em }, y: if graduate { 0.55em } else { 0.7em }),
    middle-rule: 1pt,
    caption-text: if graduate { (font: 字体.宋体混排) } else { (font: 字体.黑体) },
    caption-below: if graduate { auto } else { 10pt },
    table-below: if graduate { 11pt } else { line-height },
    caption-above: if graduate { auto } else { line-height },
    breakable: false,
    continued-caption: true,
    width: if graduate { 100% } else { auto },
    number-title-spacing: if graduate { auto } else { 0.5em },
    extra-rule: if graduate { 1pt } else { 0.5pt },
  )

  // 图片独有配置
  show: capfig-style.with(
    supplement: if english-writing { "Figure" } else { "图" },
    show-subcaption: true,
    label-style: if english-writing { "(a)" } else { "（a）" },
    subcaption-number-title-spacing: if english-writing { 2pt } else { 0pt },
    caption-above: 0pt,
    figure-below: if graduate { auto } else { line-height },
    figure-above: if graduate { auto } else { line-height },
    subref-style: "full",
  )

  body
}
