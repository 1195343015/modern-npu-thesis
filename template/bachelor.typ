#import "/template.typ": (
  Assign, IfElseChain, Return, While, algorithm, capfig, capsubfig, captab, multicite, nwpu-thesis, zh
)

#show: nwpu-thesis.with(
  ref-par-indent: "none", // 参考文献段落格式："none" | "first-line" | "hanging"
  anonymous: false, // 是否开启盲审模式
  print-mode: true, // 是否开启印刷模式
  info: (
    title: ("基于Typst的西工大论文模板", "长标题支持"),
    author: "航小天",
    major: "计算机科学与技术",
    supervisor: ("张三", "教授"),
    submit-date: (year: 2026, month: 3),
  ),
  abstract: (
    content: [
      听觉虚拟又可称为可听化，是近年来随着声学仿真技术的发展而出现的新概念，即通过对包含单个（或多个）声源的声场进行物理或数学建模，以达到模拟空间听音效果的目的。若考虑双耳效应，则可称为双耳听觉虚拟（Binaural Modeling）。

      ……
    ],
    keywords: ("听觉虚拟", "HRTF", "神经网络"),
  ),
  abstract-en: (
    content: [
      Virtual auditory technology is also called auralization. It is brought forward as a new concept with the development of acoustic simulation techniques in recent years and can be implemented by establishing the physical or mathematical models of a sound field to achieve sound effects simulation. If we consider the binaural effect, it can be called binaural virtual auditory.

      ……..
    ],
    keywords: ("virtual auditory", "HRTF", "neural network"),
  ),
  appendix: [
    附录内容……
  ],
  acknowledgement: [
    致谢内容……
  ],
  design-summary: [
    小结内容……
  ],
)

= 图、表、公式、算法示例

== 图示例

=== 单张图

可以使用 `capfig()` 来创建图，支持图标题、标签等功能。如@test 所示。

#capfig(
  image("figures/QQ交流群.png", width: 20%),
  caption: [图片测试],
  label: <test>,
)

=== 多张图

可以使用 `capsubfig()` 来创建多子图，支持子图标题、标签，以及总图标题和标签。下面是两列的两张图示例，以及两列的四张图示例。子图也可以直接引用，如@fig-sub1。

#capsubfig(
  (
    (content: image("figures/QQ交流群.png", width: 40%), subcaption: [第一个子图说明], label: <fig-sub1>),
    (content: image("figures/QQ交流群.png", width: 40%), subcaption: [第二个子图说明], label: <fig-sub2>),
  ),
  columns: 2,
  caption: [总图标题],
  label: <fig-main>,
)

#capsubfig(
  (
    (content: image("figures/QQ交流群.png", width: 40%), subcaption: [第一个子图说明], label: <fig-sub3>),
    (content: image("figures/QQ交流群.png", width: 40%), subcaption: [第二个子图说明], label: <fig-sub4>),
    (content: image("figures/QQ交流群.png", width: 40%), subcaption: [第三个子图说明], label: <fig-sub5>),
    (content: image("figures/QQ交流群.png", width: 40%), subcaption: [第四个子图说明], label: <fig-sub6>),
  ),
  columns: 2,
  caption: [总图标题],
  label: <fig-2x2>,
  placement: top,
)

== 表示例

可以使用 `captab()` 来创建表格，支持表格标题、标签、列宽、横线等功能。下面是一个简单的表示例，@timing-tlt，以及一个复杂的表示例，@composite-performance。

可以使用 `placement` 参数来设置表格位置，支持 `none`、 `top`、`bottom` 和 `auto`。其中，`none` 是默认值，表示位于本来的位置；`auto` 只是 `top` 和 `bottom` 的简单增强版，会自动选择到顶部/底部。可以使用 `three-line-table` 参数来设置是否使用三线表风格。

#captab(
  caption: [表标题],
  label: <timing-tlt>,
  placement: top,
  three-line-table: true
)[
  | t   | 1    | 2    | 3    |
  | --- | ---- | ---- | ---- |
  | y   | 0.3s | 0.4s | 0.8s |
]

#captab(
  caption: [复杂表示例：聚合物基复合材料的性能],
  label: <composite-performance>,
)[
  | 材料           | 碳/环氧 | <    | 玻璃/环氧 | <    |
  | ^              | 纵向    | 横向 | 纵向      | 横向 |
  | 模量，GPa      | 181     | 10.3 | 38.6      | 8.3  |
]

可以通过 `breakable` 参数来设置表格是否允许分页，默认为 `false`。可以通过 `size` 参数来设置表格内文字的字号，默认为五号字体。

#captab(
  caption: [表标题],
  label: <timing>,
  breakable: true,
  size: zh(5.5),  // 手动设置为小五号
)[
  | t   | 1    | 2    | 3    |
  | --- | ---- | ---- | ---- |
  | a   | 0.3s | 0.4s | 0.8s |
  | b   | 0.3s | 0.4s | 0.8s |
  | c   | 0.3s | 0.4s | 0.8s |
  | d   | 0.3s | 0.4s | 0.8s |
  | e   | 0.3s | 0.4s | 0.8s |
  | f   | 0.3s | 0.4s | 0.8s |
]

== 公式示例

可以像 Markdown 一样写行内公式 $x + y$。

引用数学公式需要加上 `eqt:` 前缀，如@eqt:energy-mass。

$ E = m c^2 $ <energy-mass>

== 算法示例

下面给出采用单独算法编号的三线表风格算法示例，见@binary-search。

#algorithm(
  title: [二分查找算法],
  {
    Assign[left][$0$]
    Assign[right][len(A) - 1]
    While(
      [$"left" <= "right"$],
      {
        Assign[mid][$floor(("left" + "right") / 2)$]
        IfElseChain(
          [$A_"mid" = "target"$],
          { Return[mid] },
          [$A_"mid" < "target"$],
          { Assign[left][$"mid" + 1$] },
          { Assign[right][$"mid" - 1$] },
        )
      },
    )
    Return[$-1$]
  },
) <binary-search>

= 参考文献引用示例

可以像这样引用参考文献@周融2003，引用两个的文献 #multicite("伍蠡甫", "图书馆")，引用三个以上的文献 #multicite("张筑生", "gbt16159-1996", "冯西桥1998", "姜锡洲", "中国大学学报论文文摘", "DUBAR2013--", "FOURNEY")。

== 二级标题
=== 三级标题
==== 四级标题
===== 五级标题
目前模板支持五级标题，不支持六级标题
