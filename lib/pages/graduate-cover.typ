#import "../utils.typ": (
  blind-review, char-space, datetime-display, datetime-display-en, distribute, info-row, major-en-map, mask-value, 字体,
)
#import "../deps.typ": zh

// 研究生封面
// 包含：外封、中文标题页、英文标题页、评阅人名单
#let master-cover(
  degree: "master",
  track: "academic",
  colored-cover: false,
  anonymous: false,
  info: (:),
) = {
  let anonymous-info-keys = (
    "student-id",
    "author",
    "author-en",
    "supervisor",
    "supervisor-en",
  )

  let anonymous-text(key, body) = {
    mask-value(body, anonymous: anonymous and (key in anonymous-info-keys))
  }

  let major-label = if track == "professional" { "专业领域" } else { "学科专业" }

  if "reviewers" not in info {
    info.reviewers = (blind-review, blind-review)
  }

  // 外封
  let outer-cover() = {
    align(right)[
      #set text(zh(5), font: 字体.黑体混排, weight: "bold")
      #table(
        columns: (2.05cm, 2.4cm),
        rows: 0.55cm,
        stroke: 0.5pt,
        inset: (x: 8pt, y: 3pt),
        [学校代码], [10699],
        [#distribute[分类号]], [#info.class-no],
        [#distribute[密级]], [公开],
        [#distribute[学号]], [#anonymous-text("student-id", info.student-id)],
      )
    ]

    v(231pt)

    text(zh(2), font: 字体.黑体, weight: "bold")[
      #table(
        columns: (2.34cm, 12.13cm),
        rows: (1.45cm, 1.45cm),
        ..info-row([题目], [#info.title.at(0, default: "")]),
        ..info-row([], [#info.title.at(1, default: "")]),
      )
    ]

    v(21pt)

    context {
      let author-display = anonymous-text("author", info.author)
      let author-width = calc.max(
        3.72cm,
        measure(text(zh(3), weight: "bold", author-display)).width,
      )
      set text(zh(3), weight: "bold")
      table(
        columns: (1.56cm, author-width),
        rows: 1.28cm,
        ..info-row([作者], [#author-display]),
      )
    }

    v(33pt)

    text(zh(3), weight: "bold")[
      #table(
        columns: (3.59cm, 9cm),
        rows: (1cm,),
        ..info-row(char-space(major-label), info.major),
        ..info-row([#char-space("指导教师")], anonymous-text(
          "supervisor",
          info.supervisor.intersperse("  ").sum(),
        )),
        ..info-row([#char-space("培养单位")], info.department),
        ..info-row([#char-space("申请日期")], datetime-display(info.submit-date)),
      )
    ]
  }

  // 中文标题页
  let chinese-title-page() = {
    v(88pt)
    text(zh(3))[
      #char-space("西北工业大学")
    ]
    v(10pt)
    let degree-label = if degree == "doctor" { "博士学位论文" } else { "硕士学位论文" }
    text(zh(1))[
      #char-space(degree-label)
    ]
    v(140pt)
    text(zh(2))[
      #table(
        columns: (2.34cm, 9.13cm),
        rows: (1.45cm, 1.45cm),
        ..info-row([题目：], [#info.title.at(0, default: "")]),
        ..info-row([], [#info.title.at(1, default: "")]),
      )
    ]

    let author-name = info.author
    let supervisor-name = info.supervisor.at(0)
    let max-name-len = calc.max(author-name.clusters().len(), supervisor-name.clusters().len())
    let name-width = max-name-len * 1em

    v(94pt)

    text(zh(3))[
      #context {
        let info-column-width = calc.max(
          5cm,
          measure(text(zh(3), info.major)).width,
        )

        table(
          columns: (3.59cm, info-column-width),
          rows: 1.2cm,
          ..info-row([#major-label:], info.major),
          ..info-row([#distribute[作者]:], anonymous-text("author", distribute(width: name-width, author-name))),
          ..info-row([指导教师:], anonymous-text("supervisor", distribute(width: name-width, supervisor-name))),
        )
      }

      #v(35pt)
      #text(datetime-display(info.submit-date))
    ]
  }

  // 英文标题页
  let english-title-page() = {
    let major-en = major-en-map.at(info.major)
    let degree-title = if degree == "doctor" { "Doctor of " } else { "Master of " }

    v(95pt)

    text(zh(2), weight: "bold")[Title: ]

    text(zh(3))[
      #text(info.title-en)
      #v(65pt)
    ]

    // 中文学术职称到英文的映射
    let title-en-map = (
      "教授": "Professor",
      "副教授": "Associate Professor",
      "研究员": "Researcher",
      "讲师": "Lecturer",
    )
    // 获取导师英文职称，默认为 Professor
    let supervisor-title-en = title-en-map.at(info.supervisor.at(1, default: "教授"), default: "Professor")

    text(zh(3.5))[
      #text(weight: "bold")[By]
      #linebreak()
      #text(anonymous-text("author-en", info.author-en))
      #linebreak()
      #text(weight: "bold")[Under the Supervision of #supervisor-title-en]
      #linebreak()
      #text(anonymous-text("supervisor-en", { info.supervisor-en }))
      #v(100pt)
      A Dissertation Submitted to
      #linebreak()
      Northwestern Polytechnical University
      #v(25pt)
      In Partial Fulfillment of The Requirement
      #linebreak()
      For The Degree of
      #linebreak()
      #if degree == "doctor" {
        text(degree-title)
        text(weight: "bold", major-en)
      } else {
        text(degree-title)
        text(major-en)
      }
      #v(75pt)
      #text(font: "Times New Roman")[Xi'an, P. R. China]
      #linebreak()
      #text(datetime-display-en(info.submit-date))
    ]
  }

  // 评阅人和答辩委员会名单
  let reviewers-page() = {
    v(50pt)
    text(zh(3), font: 字体.黑体混排)[学位论文评阅人和答辩委员会名单]
    v(40pt)

    text(zh(4), font: 字体.黑体混排)[学位论文评阅人名单]
    table(
      columns: (3.71cm, 2.83cm, 8.73cm),
      inset: (x: 4pt, y: 8pt),
      [*姓名*], [*职称*], [*工作单位*],
      ..info.reviewers.map(r => ([#r.at(0)], [#r.at(1)], [#r.at(2)])).flatten(),
    )
    v(79pt)

    let defence-date-display = mask-value(datetime-display(info.defence-committee.date), anonymous: anonymous)
    let defence-committee = info.defence-committee
    let defence-members = {
      let entries = ()
      entries.push(("主席",) + defence-committee.chairman)
      for m in defence-committee.members {
        entries.push(("委员",) + m)
      }
      entries.push(("秘书",) + defence-committee.secretary)
      entries
    }

    v(10pt)

    text(zh(4), font: 字体.黑体混排)[答辩委员会名单]
    table(
      columns: (3.76cm, 2.68cm, 2.25cm, 6.75cm),
      inset: (x: 4pt, y: 8pt),
      [*答辩日期*], table.cell(colspan: 3, [#defence-date-display]),
      [*答辩委员会*], [*姓名*], [*职称*], [*工作单位*],
      ..defence-members.map(m => ([*#m.at(0)*], [#mask-value(m.at(1), anonymous: anonymous)], [#mask-value(m.at(2), anonymous: anonymous)], [#mask-value(m.at(3), anonymous: anonymous)])).flatten(),
    )
  }

  // 组装
  let bg = none
  if colored-cover {
    let cover-image-path = if degree == "doctor" {
      "../assets/doctor-cover.jpg"
    } else if track == "professional" {
      "../assets/professional-cover.jpg"
    } else {
      "../assets/academic-cover.jpg"
    }
    bg = image(cover-image-path, width: 100%, height: 100%)
  }
  set page(background: bg)
  outer-cover()

  set page(background: none)
  pagebreak(weak: true, to: "odd")
  chinese-title-page()

  pagebreak(weak: true, to: "odd")
  english-title-page()

  pagebreak(weak: true, to: "odd")
  reviewers-page()
}
