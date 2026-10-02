// 参考文献后端：omni-gb7714（vendored fork，见 3rdparty/omni-gb7714/VENDORED.md）
#import "../3rdparty/omni-gb7714/lib.typ": gb7714 as omni-gb7714, bibliography as omni-bibliography

// 全局引用样式：在正文开始前以 show 规则生效
#let setup-bib(
  graduate: false,
  body,
) = {
  show: omni-gb7714(
    // 研究生 = GB/T 7714-2025；本科 = 2005 版析出文献著录习惯
    version: if graduate { 2025 } else { 2005 },
    style: "numeric",
    // 研究生半角标点+空格；本科按条目语言（中文全角、西文半角+空格）
    bib-punct-style: if graduate { "half-with-space" } else { "by-entry-with-space" },
    // 本科页码区间用 ~（研究生用 -）
    page-range-separator: if graduate { "-" } else { "~" },
    // 本科在线文献日期区间用 ISO 8601 斜杠式
    date-range-separator: if graduate { auto } else { "/" },
    // 首行缩进式条目（编号随首行缩进），与学校样式一致
    entry-hanging-indent: 0pt,
    entry-first-line-indent: 2em,
    number-placement: "inline",
    show-patent-country: true,
    // 本科西文姓氏首字母大写（DUBAR → Dubar）
    bib-name-style: if graduate { auto } else { (family-case: "capitalize-first") },
    // 本科混合标点体制：全角逗号/冒号 + 半角括号
    custom-punct: if graduate { (:) } else { ("(": "(", ")": ")") },
    custom-drivers: (
      // 专利：著者. 题名 [P]. 国别: 专利号, 公告日期.
      patent: "author .title [P] .country :number ,date .",
      // 标准：[著者.] 编号, 题名 [S][. 出版地: 出版者, 年].
      standard: "<author => author .>number ,title mark-medium <publisher => .location :publisher ,year> .",
      // misc 兜底类型按 mark/url 分支：报纸带刊名与期号；在线文献带日期与 URL；
      // 其余带出版项与日期
      misc: "author .title <!url => mark-medium> <mark=N => .journal ,date<number => {(}number{)}>> <url => .date .url> <!url & !mark=N & publisher => .location :publisher> <!url & !mark=N => .date> .",
      // 析出/会议文献：研究生 2015 式 [C]//；本科 2005 式 [A]. 见：/In; …[C].
      inproceedings: if graduate {
        "author .title <booktitle => [C]{//}booktitle .location :publisher ,year :pages> <!booktitle => .location :publisher ,year :pages> ."
      } else {
        "author .title<entry-lang=zh => { }> {[A]}{.}  <entry-lang=zh => {见：}><entry-lang=en => {In;}> <booktitle => booktitle {[C]} .location :publisher ,year :pages> <!booktitle => .location :publisher ,year :pages> ."
      },
      conference: if graduate {
        "author .title <booktitle => [C]{//}booktitle .location :publisher ,year :pages> <!booktitle => .location :publisher ,year :pages> ."
      } else {
        "author .title<entry-lang=zh => { }> {[A]}{.}  <entry-lang=zh => {见：}><entry-lang=en => {In;}> <booktitle => booktitle {[C]} .location :publisher ,year :pages> <!booktitle => .location :publisher ,year :pages> ."
      },
    ),
  )
  body
}

// 成果列表：独立 bib 全量渲染，label 隔离编号（独立从 [1] 起）
#let achievements-list(source) = {
  omni-bibliography(source, title: none, full: true, label: "achievements")
}

// 参考文献列表（只出列表，标题由 backmatter-page 统一提供）
#let bibliography-list(bibliography) = omni-bibliography(bibliography, title: none)
