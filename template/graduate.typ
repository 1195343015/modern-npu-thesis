#import "/template.typ": (
  Assign, IfElseChain, Return, While, algorithm, capfig, capsubfig, captab, equation-note, multicite, nwpu-thesis, zh,
)

#show: nwpu-thesis.with(
  ref-par-indent: "first-line", // 参考文献段落格式："none" | "first-line" | "hanging"
  graduate: true,
  degree: "master", // "master" | "doctor"，研究生学位级别
  track: "professional", // "academic" | "professional"，培养类型
  anonymous: false, // 是否开启盲审模式
  english-writing: false, // 是否用英文写作（国际研究生论文）
  colored-cover: true, // 是否启用彩色封面
  info: (
    title: ("基于 Typst 的", "西北工业大学论文模板"),
    title-en: "This is a Northwestern Polytechnical University thesis template based on Typst",
    student-id: "2023123456",
    class-no: "TP311.1",
    author: "航小天",
    author-en: "Xiaotian Hang",
    department: "计算机学院",
    major: "计算机科学与技术",
    supervisor: ("张三", "教授"),
    supervisor-en: "San Zhang",
    submit-date: (year: 2026, month: 3),
    // 默认为全盲审模式，如果需要指定评阅人名单，可以在 info 中添加 reviewers 字段，如下所示：
    // reviewers: (
    //   (name: "xxx", title: "教授", unit: "西北工业大学"),
    //   (name: "yyy", title: "教授", unit: "西北工业大学"),
    // ),
    defence-committee: (
      date: (year: 2026, month: 3, day: 9),
      chairman: (name: "赵某某", title: "教授", unit: "西北工业大学"),
      members: (
        (name: "周某某", title: "教授", unit: "西北工业大学"),
        (name: "吴某某", title: "副教授", unit: "西北工业大学"),
      ),
      secretary: (name: "郑某某", title: "讲师", unit: "西北工业大学"),
    ),
  ),
  abstract: (
    content: [
      中文摘要一般应说明研究工作目的、实验方法、结果和最终结论等，而重点是结果和结论。摘要中不用图、表、化学结构式、非公知公用的符号和术语。

      内容一般包括：从事这项研究工作的目的和意义；完成的工作（作者独立进行的研究工作及相应结果的概括性叙述）；获得的主要结论（这是摘要的中心内容）。
    ],
    keywords: ("关键词一", "关键词二", "关键词三", "关键词四"),
    funding: "本研究得到某某基金（编号：   ）资助。",
  ),
  abstract-en: (
    content: [
      English abstract content. The abstract should generally explain the purpose, experimental methods, results, and final conclusions of the research, with emphasis on the results and conclusions.
    ],
    keywords: ("Keyword1", "Keyword2", "Keyword3", "Keyword4"),
    funding: "The present work is supported by the XXX（Project No.xxx）",
  ),
  appendix: [
    附录是学位论文主体的补充，并不是必需的。

    =
    附录编号依次编为附录A、附录B。附录标题各占一行，按一级标题编排。每一个附录一般应另起一页编排，如果有多个较短的附录，也可接排。
  ],
  acknowledgement: [
    致谢是作者对该文章的形成作过贡献的组织或个人予以感谢的文字记载，语言要诚恳、恰当、简短。致谢内容可以包括但不限于：国家科学基金、资助研究工作的奖学金基金、合同单位、资助或支持的企业、组织或个人；协助完成研究工作和提供便利条件的组织或个人；在研究工作中提出建议和提供帮助的人；给予转载和引用权的资料、图片、文献、研究和调查的所有者；其他应感谢的组织和个人。
  ],
  academic-achievements: [
    不同类型的成果列表书写格式与参考文献相同。对于学术论文，如已发表的被EI或SCI收录，应标明收录号；SCI论文一般应标注发表当年的影响因子；对已录用但尚未发表的学术论文，请注明是否EI或SCI刊源。
  ],
  scan-declaration: image("figures/硕博论文签字版声明.pdf"),
)

= 图、表、公式、算法示例

== 图示例

=== 单张图

可以使用 `capfig()` 来创建图，支持图标题、标签等功能。如@test 所示。

#capfig(
  image("figures/QQ交流群.png", width: 25%),
  caption: [图片测试],
  label: <test>,
)

=== 多张图

可以使用 `capsubfig()` 来创建多子图，支持子图标题、标签，以及总图标题和标签。下面是两列的两张图示例，以及两列的四张图示例。子图也可以直接引用，如@fig-sub1。

#capsubfig(
  (
    (content: image("figures/QQ交流群.png", width: 45%), subcaption: [第一个子图说明], label: <fig-sub1>),
    (content: image("figures/QQ交流群.png", width: 45%), subcaption: [第二个子图说明], label: <fig-sub2>),
  ),
  columns: 2,
  caption: [总图标题],
  label: <fig-main>,
)

#capsubfig(
  (
    (content: image("figures/QQ交流群.png", width: 38%), subcaption: [第一个子图说明], label: <fig-sub3>),
    (content: image("figures/QQ交流群.png", width: 38%), subcaption: [第二个子图说明], label: <fig-sub4>),
    (content: image("figures/QQ交流群.png", width: 38%), subcaption: [第三个子图说明], label: <fig-sub5>),
    (content: image("figures/QQ交流群.png", width: 38%), subcaption: [第四个子图说明], label: <fig-sub6>),
  ),
  columns: 2,
  caption: [总图标题],
  label: <fig-2x2>,
  placement: top
)

== 表示例

=== 三线表示例

可以使用 `captab()` 来创建表格，支持表格标题、标签、列宽、横线等功能。下面是一个简单的三线表示例@timing-tlt，以及一个复杂的三线表示例@composite-performance。

可以使用 `placement` 参数来设置表格位置，支持 `none`、 `top`、`bottom` 和 `auto`。其中，`none` 是默认值，表示位于本来的位置；`auto` 只是 `top` 和 `bottom` 的简单增强版，会自动选择到顶部/底部。

#captab(
  caption: [三线表标题],
  label: <timing-tlt>,
  placement: top,
)[
  | t   | 1    | 2    | 3    |
  | --- | ---- | ---- | ---- |
  | y   | 0.3s | 0.4s | 0.8s |
]

#captab(
  caption: [复杂三线表示例：聚合物基复合材料的性能],
  label: <composite-performance>,
  hlines: (2,),   // 额外线条
)[
  | 材料           | 碳/环氧 | <    | 玻璃/环氧 | <    |
  | ^              | 纵向    | 横向 | 纵向      | 横向 |
  | 模量，GPa      | 181     | 10.3 | 38.6      | 8.3  |
  | 压缩强度，MPa  | 1500    | 246  | 610       | 118  |
  | 拉伸强度，MPa  | 1500    | 40   | 1062      | 31   |
]

=== 续表示例

可以通过 `breakable` 参数来设置表格是否允许分页，默认为 `false`。可以通过 `size` 参数来设置表格内文字的字号，默认为五号字体。

#captab(
  caption: [三线表标题],
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

如果需要在公式下方给出变量含义说明，可以使用 `equation-note` ：

$ E = m c^2 $ <energy-mass>
#equation-note[$E$ 为能量，$m$ 为质量，$c$ 为光速。]

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

可以像这样引用参考文献@周融2003，引用两个的文献 #multicite("图书馆", "李大伦1998")，引用三个以上的文献 #multicite(
  "伍蠡甫",
  "张筑生",
  "冯西桥1998",
  "姜锡洲",
  "gbt16159-1996",
  "科学技术期刊管理办法",
  "中国大学学报论文文摘",
  "DUBAR2013--",
  "FOURNEY",
)。

== 二级标题
=== 三级标题
==== 四级标题
===== 五级标题
目前模板支持五级标题，不支持六级标题
