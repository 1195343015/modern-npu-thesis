#import "../utils.typ": 字体
#import "../deps.typ": zh

// 摘要页
// abstract: 摘要字典，包含 content、keywords、funding
// title: 页面和页眉显示的标题
// outline-title: 目录中显示的标题（默认使用 title）
#let abstract-page(
  abstract: (:),
  keyword-label: none,
  keyword-weight: "regular",
  keyword-sep: none,
  keyword-indent: true,
  outline-title: none,
  title: none,
  outlined: true,
) = {
  let display-title = if title != none { title } else { outline-title }
  let keywords = abstract.at("keywords", default: ())
  let funding = abstract.at("funding", default: none)
  let content = abstract.at("content", default: [])

  {
    show heading: set text(font: 字体.黑体混排)
    heading(level: 1, outlined: outlined, display-title)
  }

  content

  [
    #set par(first-line-indent: 0pt)
    #v(1em)
    #let indent = if keyword-indent { 2em } else { 0pt }
    #{
      let label = if keyword-weight == "bold" {
        text(font: 字体.黑体混排, weight: "bold")[#keyword-label：]
      } else {
        [#h(indent)#text(font: 字体.黑体混排)[#keyword-label]：]
      }
      label + (("",) + keywords.intersperse(keyword-sep)).sum()
    }

    #if funding != none [
      #v(1fr)
      #text(zh(5))[#h(indent)#funding]
    ]
  ]
}
