#import "../deps.typ": hydra, zh

// ============================================
// 页眉页脚统一配置
// ============================================

// 页码渲染函数
#let page-footer(fmt) = context align(center)[
  #set text(zh(5.5))
  #counter(page).display(fmt)
]

// hydra 页眉显示回调：显示编号 + 剥离加粗的标题体
#let hydra-display(ctx, it) = {
  if it.has("numbering") and it.numbering != none {
    numbering(it.numbering, ..counter(heading).at(it.location()))
    [ ]
  }
  show strong: it => it.body
  it.body
}

#let graduate-header-title(degree) = {
  if degree == "doctor" {
    "西北工业大学博士学位论文"
  } else {
    "西北工业大学硕士学位论文"
  }
}

// 研究生页眉渲染
#let graduate-header(content) = {
  [
    #set par(spacing: 0pt)
    #set text(zh(5.5))
    #align(center)[#content]
    #v(0.5em)
    #line(length: 100%, stroke: 3.2pt)
    #v(0.32em)
    #line(length: 100%, stroke: 0.6pt)
  ]
}

// 本科生页眉渲染
#let bachelor-header() = {
  [
    #set par(spacing: 4pt, first-line-indent: (amount: 6.1em, all: true))
    #set text(zh(3), weight: "bold")
    #box(width: 2.99cm, height: 0.61cm, move(dy: 0.1em, image("../assets/nwpu-name.png")))#h(0.2em)本科毕业设计（论文）
    #line(length: 100%, stroke: 0.8pt)
    #v(5pt)
  ]
}

// 页眉页脚整体配置（mainmatter 调用）
#let page-header-footer(
  graduate: false,
  degree: "master",
  body,
) = {
  set page(
    footer: page-footer("1"),
    header-ascent: if graduate { 18% } else { 12% },
    footer-descent: 1.2em,
    header: context {
      if graduate {
        let header-content = if calc.rem(here().page(), 2) == 0 {
          graduate-header-title(degree)
        } else {
          hydra(1, display: hydra-display, use-last: true, skip-starting: false)
        }
        graduate-header(header-content)
      } else {
        bachelor-header()
      }
    },
  )
  body
}
