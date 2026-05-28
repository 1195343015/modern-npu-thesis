#import "deps.typ": (
  Assign, Break, Comment, Else, ElseIf, For, Function, If, IfElseChain, Line, LineBreak, Procedure, Return, Terminate,
  While, capfig, capfig-style, capsubfig, captab, captab-style, init-gb7714, multicite, zh,
)
#import "layouts/doc.typ": doc
#import "layouts/floats.typ": algorithm, equation-note
#import "layouts/mainmatter.typ": frontmatter, mainmatter
#import "pages/appendix.typ": appendix-page
#import "pages/bachelor-cover.typ": bachelor-cover
#import "pages/graduate-cover.typ": master-cover
#import "pages/abstract.typ": abstract-page
#import "pages/outline.typ": outline-page
#import "pages/backmatter-page.typ": backmatter-page
#import "pages/references.typ": bilingual-bibliography
#import "utils.typ": distribute, page-title

#let default-bibliography(graduate) = {
  if not graduate {
    "../template/bib/bachelor.bib"
  } else {
    "../template/bib/graduate.bib"
  }
}

#let nwpu-thesis(
  graduate: false,
  degree: "master",
  track: "academic",
  anonymous: false,
  english-writing: false,
  colored-cover: false,
  print-mode: false,
  info: (:),
  abstract: (:),
  abstract-en: (:),
  acknowledgement: none,
  academic-achievements: none,
  appendix: none,
  scan-declaration: none,
  design-summary: none,
  ref-par-indent: "none",
  body,
) = {
  let bibliography = default-bibliography(graduate)

  // 1. 文稿设置
  show: doc.with(graduate: graduate)

  // 2. 封面
  if graduate {
    master-cover(
      degree: degree,
      track: track,
      colored-cover: colored-cover,
      anonymous: anonymous,
      info: info,
    )
  } else {
    bachelor-cover(
      anonymous: anonymous,
      info: info,
    )
  }

  // 本科生封面后的空页（封底），在 mainmatter 之前渲染，无页眉页脚
  if not graduate and print-mode {
    pagebreak()
  }

  show: init-gb7714.with(
    read(bibliography),
    style: "numeric",
    version: "2025",
    zh-period: if not graduate { "．" },
    zh-colon: if not graduate { "： " },
    zh-comma: if not graduate { "，" },
    en-family-titlecase: not graduate,
    range-sep: if not graduate { "~" } else { "-" },
  )

  // 3. mainmatter 包裹所有后续内容（前置 + 正文 + 后置）
  show: mainmatter.with(
    graduate: graduate,
    degree: degree,
    english-writing: english-writing,
    print-mode: print-mode,
  )

  // 4. 前置部分（摘要、目录）
  frontmatter[
    #abstract-page(
      abstract: abstract,
      keyword-label: "关键词",
      keyword-sep: if graduate { "；" } else { "，" },
      keyword-indent: graduate,
      outline-title: page-title("abstract", graduate: graduate),
      outlined: graduate,
    )
    #abstract-page(
      abstract: abstract-en,
      keyword-label: if graduate { "Key words" } else { "KEY WORDS" },
      keyword-weight: "bold",
      keyword-sep: if graduate { "; " } else { ", " },
      keyword-indent: false,
      outline-title: "ABSTRACT",
      title: if graduate { [*Abstract*] },
      outlined: graduate,
    )

    #{
      let outline-title = page-title("outline", graduate: graduate, english-writing: english-writing)
      outline-page(
        title: if graduate { outline-title } else { [*#outline-title*] },
        indent: if not graduate { (0em, 1.8em, 1.3em) } else { (0em, 1.8em, 1.7em) },
        weight: if not graduate { ("bold", "regular", "regular") } else { (auto,) },
        fill: if not graduate { ([#repeat(gap: -2pt)[#text(zh(6.5))[·]]],) } else { (repeat([.]),) },
        vspace: if not graduate { (1.25em, 1em) } else { (none,) },
        gap: if not graduate { (-0.5em, 0.5em) } else { (auto,) },
      )
    }

    #if graduate or print-mode {
      pagebreak(weak: true, to: "odd")
    }
  ]

  [#metadata(none) <__nwpu_mainmatter_start__>]
  counter(page).update(1)

  // 5. 正文
  body

  // 6. 后置部分
  bilingual-bibliography(
    graduate: graduate,
    english-writing: english-writing,
    par-indent: ref-par-indent,
  )

  if graduate and appendix != none {
    appendix-page(
      graduate: graduate,
      english-writing: english-writing,
    )[#appendix]
  }

  if not anonymous and acknowledgement != none {
    backmatter-page(
      "acknowledgement",
      graduate: graduate,
      english-writing: english-writing,
    )[#acknowledgement]
  }

  if graduate and academic-achievements != none {
    backmatter-page(
      "academic-achievements",
      english-writing: english-writing,
    )[#academic-achievements]
  }

  if not graduate and design-summary != none {
    backmatter-page(
      "design-summary",
      english-writing: english-writing,
    )[#design-summary]
  }

  if not graduate and appendix != none {
    appendix-page(
      graduate: graduate,
      english-writing: english-writing,
    )[#appendix]
  }

  if graduate {
    pagebreak(weak: true, to: "odd")
  }

  // 尾部独立页面（声明、封底）：统一无页眉页脚、无边距
  set page(margin: 0pt, header: none, footer: none)

  if scan-declaration != none and graduate {
    page[
      #scan-declaration
      #box(width: 0pt, height: 0pt)
    ]
  }

  if colored-cover and graduate {
    let bg = if degree == "doctor" {
      "assets/doctor-back-cover.jpg"
    } else if track == "professional" {
      "assets/professional-back-cover.jpg"
    } else {
      "assets/academic-back-cover.jpg"
    }
    page[
      #box(width: 0pt, height: 0pt)
    ]
    page(
      background: image(bg, width: 100%, height: 100%),
    )[
      #box(width: 1pt, height: 1pt)
    ]
  }
}
