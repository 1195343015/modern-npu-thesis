#let _ENUMS = (
  "bib-numbering-style": ("bracket", "paren", "dot", "plain", "fullwidth-bracket", "fullwidth-paren", "shell", "circled", none),
  "cite-numbering-style": ("bracket", "paren", "fullwidth-bracket", "fullwidth-paren", "shell", "circled"),
  "note": (none, "foot", "end"),
  "note-numbering-style": ("circled",),
  "mark-medium-bracket-style": ("half", "full"),
  "number-align": ("left", "right", "center"),

  "number-placement": ("column", "margin", "inline"),
  "number-punct-width": ("full", "native"),
  "cite-form": ("super", "inline", "normal", "prose", "author", "year", "full", none),
  "supplement-style": ("compact", "split"),
  "punct-style": ("half", "half-no-space", "half-with-space", "full",
    "by-doc-and-style", "by-doc-no-space", "by-doc-with-space",
    "by-entry-and-style", "by-entry-no-space", "by-entry-with-space"),
  "bib-punct-style": ("half", "half-no-space", "half-with-space", "full",
    "by-doc-no-space", "by-doc-with-space",
    "by-entry-no-space", "by-entry-with-space"),
  "entry-lang-detect": ("auto", "fast", "accurate"),
  "sort-zh-by": ("pinyin", "bihua"),
  "titles-text-case": (none, "sentence", "title"),

  "page-range-style": (none, "expanded", "minimal", "minimal-two", "chicago-15", "chicago-16", "chicago"),
  "date-fallback": (none, "urldate"),
)

#let _show-value(v) = if v == none { "none" } else { "\"" + str(v) + "\"" }

#let check-enum(param, value, extra: (), alias: none) = {
  let allowed = _ENUMS.at(param)
  if value in allowed or value in extra { return }
  let shown = if alias != none { alias } else { param }
  panic("gb7714: " + shown + " 收到非法值 " + _show-value(value)
    + "; 合法值: " + allowed.map(_show-value).join(" / "))
}

#let _MESSAGES = (
  "mark-medium.show-mark-online-only": "show-mark 不支持 \"online-only\"：文献类型标识不是获取途径，联机判据对它无语义",
  "mark-medium.setting-key-not-mark": "{param} 大写键 \"{key}\" 不是 GB/T 7714 附录 A 的文献类型标识码（全集：{marks}）",

  "latex.undefined-command": "omni-gb7714: bib 字段含未定义的 LaTeX 命令 “\\{command}”（biblatex 下等价错误：“! Undefined control sequence.”）。\n— 若确为拼写错，请改正；要表示*字面反斜杠*请用 `\\textbackslash`。\n— 要让本包*静默丢弃未知命令、继续渲染*（宽松），请设 `gb7714(latex-strict-command: false)`。",
  "latex.special-char": "omni-gb7714: bib 字段含未转义的 LaTeX 特殊字符 “{char}”（LaTeX 文本模式下须写 “\\{char}” 之类的转义；biblatex 直接写会报错）。\n— 要按字面输出该字符,请写转义形式（`\\&` `\\_` `\\#` `\\%`,或 `^` 用 `\\textasciicircum`）;\n— 要让本包*直接接受*这些裸字符(宽松),请设 `gb7714(latex-strict-char: false)`。",

  "custom-terms.structural-name": "gb7714: custom-terms `{name}` 与内置结构 token 同名，不可重定义；可覆盖的内置本地化词仅：{allowed}。",
  "custom-terms.bad-value": "gb7714: custom-terms `{name}` 的值须为字符串或多语言字典 (zh: \"..\", en: \"..\")。",
  "custom-terms.structural-key": "gb7714: custom-terms `{name}` 含结构键 `{key}`——带 bib 字段的 token 请用 `custom-fields`，永久标识符请用 `custom-pids`；`custom-terms` 只放本地化字面量。",
  "custom-terms.lang-value-not-str": "gb7714: custom-terms `{name}`.{key} 必须是字符串（本地化字面量）。",
  "custom-terms.wrap-value-not-pair": "gb7714: custom-terms `{name}`.{key} 是模式词，值须为前后缀对 (prefix: \"..\", suffix: \"..\")。",
  "custom-terms.wrap-bad-key": "gb7714: custom-terms `{name}` 的槽位字典只接受 {allowed} 键，收到 `{key}`。",
  "custom-terms.ibid-bad-key": "gb7714: custom-terms `ibid` 的字典值只接受 `text` / `supplement-separator` 键，收到 `{key}`。",

  "custom-fields.built-in-name": "gb7714: custom-fields `{name}` 与内置 token 同名，禁止重定义；请改用其它名字。",
  "custom-fields.bad-value": "gb7714: custom-fields `{name}` 的值须为 `auto`（同名透传）或字典 `(field: \"..\", prefix:.., suffix:..)`。",
  "custom-fields.missing-field": "gb7714: custom-fields `{name}` 字典形态必须含 `field: \"字段名\"`（纯透传请用 `auto`）。",
  "custom-fields.field-conflict": "gb7714: custom-fields `{name}`.field=`{field}` 与内部已使用的字段名冲突，请换用其它字段名。",
  "custom-fields.affix-not-str": "gb7714: custom-fields `{name}`.{key} 必须是字符串或多语言字典 (zh: \"..\", en: \"..\")。",

  "custom-punct.unknown-key": "gb7714: custom-punct 的键必须是标点字符本身（半角、全角都认），收到 `{key}`。可覆写的字符：{keys}",

  "custom-pids.structural-name": "gb7714: custom-pids `{name}` 与内置结构 token 同名，不可作新 PID 名；可覆写的内置 PID 仅：{allowed}。",
  "custom-pids.bad-value": "gb7714: custom-pids `{name}` 的值须为字典 (field: \"字段名\", prefix:.., resolver:..)。",
  "custom-pids.missing-field": "gb7714: custom-pids `{name}` 必须含 `field: \"字段名\"`（从 bib 读取标识符值）；覆写内置 PID 时 field 才可省。",
  "custom-pids.field-conflict": "gb7714: custom-pids `{name}`.field=`{field}` 与内部已使用的字段名冲突，请换用其它字段名。",
  "custom-pids.prefix-bad": "gb7714: custom-pids `{name}`.prefix 必须是字符串或多语言字典 (zh: \"..\", en: \"..\")。",
  "custom-pids.resolver-bad": "gb7714: custom-pids `{name}`.resolver 必须是字符串模板（含 `{}` 占位则替换，否则当前缀拼接）；只有 `eprint` 另收*按平台的字典*（`(medrxiv: \"https://..{}\")`，键是 archiveprefix，大小写/空格/连字符不敏感）。",

  "note-repeat-style.bad-value": "gb7714: `note-repeat-style` 只收 auto / {values}，收到 {got}",
  "note-ibid.bad-value": "gb7714: `note-ibid` 只收 auto / true / false，收到 {got}",
  "note-repeat-reset.bad-value": "gb7714: `note-repeat-reset` 只收 none 或 selector（如 heading.where(level: 1)、标签 <part-break>、元素函数 heading），收到 {got}",

  "disambiguate.bad-form": "gb7714: `disambiguate` 须是 auto / true / false 或三键字典（date / given-name / names），收到 {got}",
  "disambiguate.unknown-key": "gb7714: `disambiguate` 收到未知机制 \"{key}\"；合法键：date（同责任者同年的 a/b/c 后缀）/ given-name（同姓不同人补名）/ names（展开 et al 名单）",
  "disambiguate.bad-value": "gb7714: `disambiguate.{key}` 须是 auto / true / false，收到 {got}",

  "name-style.not-dictionary": "gb7714: `{param}` 须是维度字典（如 `(family-case: \"uppercase\")`）或 `auto`，收到 {got}",
  "name-style.unknown-key": "gb7714: `{param}` 收到未知维度 \"{key}\"；合法键：{keys}",
  "name-style.order-dict": "gb7714: `{param}.order` 的字典形须同时给出 `first`（第一责任者）与 `rest`（其余责任者）两键、值各为 family-ahead / given-ahead——全体统一请写标量。收到 {got}",
  "name-style.bad-value": "gb7714: `{param}.{key}` 收到值域外的值 {got}。各维值域：order = family-ahead / given-ahead（标量）或 (first:, rest:) 字典；family-case = auto / uppercase / lowercase / none；given-form = auto / none / initials / full / pinyin-initials；given-separator = auto / none / 任意字符串；given-case = none / uppercase / lowercase / capitalize-first / capitalize-each；given-initial-separator / family-given-separator / given-family-separator = auto / 任意字符串（case 与 given-separator 键的 none 是「不处理」，given-form 的 none 是「只姓」）。四个 -separator 维另收多语言字典 (zh: .., rest: ..)，按条目语言分设。",

  "bib-numbering-style.circled-dict": "gb7714: `{param}` 的字典形只收 `(circled: \"unicode\")` 或 `(circled: \"quan\")`（圈码的绘制引擎二级展开，其余样式无引擎可选请写标量）。收到 {got}",

  "style.unknown-axis": "gb7714: `style` 字典只收 `cite`（正文标注形态）与 `bib`（著录格式）两个键，收到 \"{key}\"",
  "style.missing-axis": "gb7714: `style` 字典须同时给出 `cite` 与 `bib` 两轴——两轴相同请写标量（如 style: \"numeric\"）；只想指定一轴，另一轴写 `auto`（继承）。收到 {got}",
  "style.bad-axis-value": "gb7714: `style.{key}` 须是 {values} 或 `auto`，收到 {value}。\n国标 CSL 全名只能写在标量形态（它同时锁 version）；要锁版本请用 `version:`。",

  "sort-by.not-array": "gb7714: `{param}` 须是排序键数组；另可取 `none`（保持引用序 / 写法序）或 `auto`（按标注体系派生）。收到 {got}",
  "sort-by.bad-element": "gb7714: `{param}` 的元素须是键名字符串（如 \"date\"）或单条方向字典（如 `(date: \"descending\")`）。收到 {got}",
  "sort-by.dict-size": "gb7714: `{param}` 的字典元素只能含一个键，如 `(date: \"descending\")`。收到 {got}",
  "sort-by.unknown-key": "gb7714: `{param}` 收到未知排序键 \"{key}\"；合法键：{keys}。\n文种是隐式的最高优先级键（GB/T 7714 9.3.2「先按文种集中」），不写进排序键数组；文种先后由 `entry-lang-order` 决定。",
  "sort-by.bad-order": "gb7714: `{param}` 里 \"{key}\" 的方向须是 {orders}，收到 {order}",
  "collapse-date.bad-value": "gb7714: `{param}` 只收 {allowed}，收到 {got}",

  "template.unclosed-literal": "gb7714: 模板 verbatim 花括号未闭合（缺少配对的 `}`）：{src}",
  "template.unmatched-close": "gb7714: 模板 `>` 无配对的 `?<` / `&<`",
  "template.alias-no-left": "gb7714: 模板 `|` 缺左操作数",
  "template.alias-no-right": "gb7714: 模板 `|` 缺右操作数",
  "template.unclosed-group": "gb7714: 模板条件组 `?<` / `&<` 未闭合（缺 `>`）",
  "template.unknown-token": "gb7714: 模板里的 token `{token}` 既不是内置标识，也不在 `custom-fields` / `custom-terms` 字典里。\n请检查拼写，或在 `gb7714(custom-fields: (..))`（带字段的 token）/ `gb7714(custom-terms: (..))`（本地化字面量）里声明。\n内置 token 速查见手册「自定义条目格式」一节。",
  "template.guard-type-is-bib-field": "gb7714: 卫语句 `type={value}` 里的 `type` 现在指*bib 的 `type` 字段*（报告种类、学位类型），不再是文献类型标识码。要按标识码判，写 `mark={value}`；要按载体码判，写 `medium=OL`。（真想匹配 `type` 字段值为「{value}」的条目，这条卫语句写不出来——那个值恰好是标识码，无法与误用区分。）",
  "template.guard-expected-field": "gb7714: 卫语句表达式里应是「字段=值」或光秃秃一个字段名（空非空），这里缺字段名（写法如 `<mark=M => …>` / `<doi => …>`）",
  "template.guard-ambiguous-or": "gb7714: 卫语句里 `{field}=…` 的 `?` 后面跟了一个裸 token 名 `{token}`——两种读法都说得通，写明白一点：\n1) 想问「这条目有没有 `{token}`」（空非空），把它包进尖括号：`{field}=… ? <{token}> => …`；\n2) 想把 `{token}` 当成 `{field}` 的候选*取值*，把它包进花括号（verbatim）：`{field}=…?{{token}} => …`。\n（`?` 在卫语句里身兼两职：算符「或」与同字段的「值或」。裸值不是 token 名时不会有这个歧义。）",
  "template.guard-expected-value": "gb7714: 卫语句字段 `{field}` 的 `=` 后缺值（值带空格或冒号请用花括号 verbatim，如 `t={10:30}`）",
  "template.guard-nested-arrow": "gb7714: 卫语句的 `<…>` 分组里不能再出现 `=>`（分组只作布尔括号，不是嵌套卫语句组）",
  "template.guard-arrow-outside-group": "gb7714: `=>` 只能作 `<…>` 卫语句组里的谓词与组体的分界（写法如 `<mark=M => {图书}>`），组外没有这个算符",
  "template.guard-multiple-arrows": "gb7714: 同一个 `<…>` 卫语句组里出现了不止一个 `=>`——卫语句组的形态是「一个谓词、一个组体」，组体里要再分支就再嵌一层 `<…>`",
  "template.guard-trailing": "gb7714: 卫语句表达式解析后有多余内容——检查算符（`& ? !`）与 `<…>` 分组是否配对",
  "custom-drivers.banned-category-key": "custom-drivers 键 \"{key}\" 是内部类别词，不再开放：{hint}",
  "custom-drivers.key-not-mark": "custom-drivers 大写键 \"{key}\" 不是 GB/T 7714 附录 A 的文献类型标识码（全集：{marks}）",

  "titles-text-case.bad-key": "gb7714: titles-text-case 收到非法键 \"{key}\"；合法键: title / subtitle / titleaddon / maintitle / booktitle / booksubtitle / booktitleaddon / journaltitle|journal / journalsubtitle / journaltitleaddon / eventtitle / series / rest（shortjournal 是缩写刊名，大小写即其规范，不受理）。",
  "titles-text-case.bad-value": "gb7714: titles-text-case.{key} 收到非法值 {value}；合法值: none / \"sentence\" / \"title\"。",

  "separator.unknown-lang-key": "gb7714: 分隔符的多语言字典收到未知键 \"{key}\"；合法键: {keys}（条目语言码，加 rest 回退档——未点名的语言走本参数的预设值）。",

  "et-al.unknown-key": "gb7714: {param} 的字典收到未知键 \"{key}\"；合法键有两套——角色键 {roles}（截断发生的四个位置），或语言键 {langs}（条目语言码）；两套都可以加 rest 回退档，但不能并列在同一层。",
  "et-al.unknown-lang-key": "gb7714: {param} 的语言字典收到未知键 \"{key}\"；合法键: {keys}（条目语言码，加 rest 回退档）。",
  "et-al.mixed-keys": "gb7714: {param} 的字典不能把角色键（{roles}）与语言键（{langs}）并列在同一层；语言分设要写进角色的值里，如 (editor: (en: 5, rest: 4), rest: 4)。",
  "et-al.no-role-fallback": "gb7714: {param} 的角色字典既没有键 \"{role}\"，也没有回退键 rest；补上其中之一。",
  "et-al.no-lang-fallback": "gb7714: {param} 的语言字典没有点到本条目的语言（{lang}），也没有回退键 rest；补上其中之一。",
  "et-al.use-last-too-few-omitted": "gb7714: et-al-use-last 要求 et-al-use-first + et-al-use-last <= et-al-min - 1，当前 {first} + {last} > {min} - 1（角色 {role}，条目语言 {lang}）。责任者数恰好达到 {min} 时，「前 {first} 位 … 末 {last} 位」一位都没省掉，省略号是假的。把 et-al-min 调大、或把 use-first / use-last 调小。（若用了字典档，这三个数是本条目按角色与语言解析后的值。）",

  "page-range-style.bad-value": "gb7714: page-range-style 收到非法值 {value}；合法值: none（默认，页码原样）/ \"expanded\" / \"minimal\" / \"minimal-two\" / \"chicago-15\" / \"chicago-16\"（CSL 1.0.1 的 \"chicago\" 收作 \"chicago-15\" 的别名）。",

  "custom-marks.bad-value": "gb7714: custom-marks `{name}` 的值必须是非空字符串标识码（如 \"SW\"）；载体段不在此写（用 medium 字段或联机判据）。",
  "emphasis.not-dict": "gb7714: emphasis 必须是字典（槽位 → 规格）。默认 (:) 不装饰。",
  "emphasis.bad-slot": "gb7714: emphasis 收到未知槽位 \"{slot}\"；合法槽位：{slots}。（槽是渲染位置，不是裸 .bib 字段。）",
  "emphasis.bad-value": "gb7714: emphasis 槽位 \"{slot}\" 的值必须是规格 (italic:/bold:/prefix:/suffix:)、语言分设 (zh:/rest: → 规格) 或 none。",
  "emphasis.bad-key": "gb7714: emphasis 槽位 \"{slot}\" 的规格键 \"{key}\" 非法；合法：{keys}。",

  "languages.not-dict": "gb7714: custom-languages 必须是字典（语言码 → langid 别名）。收到：{got}。",
  "languages.bad-code": "gb7714: custom-languages 的键（语言码）必须是非空字符串（如 \"de\"）。收到：{got}。",
  "languages.builtin-code": "gb7714: custom-languages 的码 \"{code}\" 与内置码相撞（zh/ja/ko/ru/fr/en 的 langid 识别已内建）；请换一个新码。",
  "languages.bad-alias": "gb7714: custom-languages 码 \"{code}\" 的别名必须是非空字符串或其数组（如 (\"german\", \"deu\")）。收到：{got}。",

  "load.not-bib-content": "gb7714: {what} 不是有效的 .bib 内容。\n请确保通过 `read()` 读取内容再传入，如 gb7714(read(\"refs.bib\"))。\n收到的值：{value}",
  "load.bad-path-type": "gb7714: path 必须是 read() 内容字符串、字符串数组或标签字典；不支持直接路径字符串（包沙箱读不到调用方文件）。\n请通过 `read()` 读取内容再传入，如 bibliography(read(\"refs.bib\"))。",
  "csl-json.item-not-object": "gb7714: CSL JSON 顶层数组里存在非对象元素（每个条目应是一个 JSON 对象）。\n收到的值：{value}",
  "load.missing-title": "gb7714: bib 条目 `{key}` 缺 title 字段（或为空）；GB/T 7714 要求每条文献都必须著录题名。请补全 .bib 中该条目的 title，或设 `warn-missing-title: false` 允许空题名。",

  "cite.no-keys": "gb7714: cite() 至少需要一个引用键。用 #cite[@k] 或 #cite(<k>) 形式调用。",
  "cite.bad-positional": "gb7714: cite() 位置参数必须是 label 或包含 @ref 的 content",
  "cite.unknown-key": "gb7714: cite key `{key}` 不在任何 bibliography 的 source 里。检查拼写或者 bib 条目是否存在。",
  "cite.number-missing": "gb7714: cite key `{key}` (实际归属 key={redirected}) 在引用编号 map 中找不到——可能列表归属（set-bib-label）跟当前 active-list 不一致，或该列表无 bibliography。",

  "shell.style-invalid": "gb7714: 全局 style 只接受 \"numeric\" / \"author-date\" 或国标 CSL 全名（如 \"gb-7714-2015-numeric\" / \"gb-7714-2025-author-date\" / \"…-note\"）。其它原生 CSL 名（\"ieee\" / \"apa\" 等 91 种）是*列表级*概念，请在 bibliography(style: ..) 使用。",
  "shell.bib-source-positional": "omni-gb7714：`gb7714(..)` 不收 bib 源作位置参数——它只收配置与文档 body。文献数据交 `#bibliography(read(\"x.bib\"), ..)`（keys / label / filter / sort-keys 等子列表能力都在 bibliography 上），用法：#show: gb7714.with(..)。",
  "shell.native-bibliography-called": "gb7714: 检测到原生 typst `#bibliography(...)` 调用。请用本包导出的 `bibliography` 函数：\n  #import \"@preview/omni-gb7714:0.1.0\": *\n  #show: gb7714(version: 2025)\n  正文 @k1 @k2\n  #bibliography(read(\"refs.bib\"))     // 我们的 bibliography，含原生所有参数 + 50+ 扩展\n  // 多 bib：#bibliography(read(\"ch1.bib\"), label: \"ch1\") #bibliography(read(\"ch2.bib\"), label: \"ch2\")\n我们的版本支持 label / entrytype / filter / sort-keys 等扩展，且 source 直接收 read() 结果。",
  "shell.native-014-single-bib": "gb7714: typst 0.14 一份文档只能有一个 std.bibliography，原生 CSL 样式列表（style: \"ieee\" / \"apa\" 等）无法与其它列表共存；请升级 typst 0.15+。",
  "shell.native-with-label": "gb7714: 原生 CSL 样式列表（style: \"ieee\" / \"apa\" 等）不能与 label: 命名列表混用。",
  "shell.footnote-with-native": "gb7714: note: \"foot\" 暂不能与原生 CSL 样式列表（ieee / apa / CSL 文件）混用；GB 轴的 target / group / 多表路由可以混用。",
  "shell.bad-source-type": "gb7714: bibliography source 必须是 bytes / str / array",
  "shell.source-looks-like-path": "gb7714: `bibliography(..)` 收到的像是文件*路径* `\"{path}\"`，但本包收的是 bib *内容*（与原生不同：原生 `bibliography(\"refs.bib\")` 把字符串当路径）。请改用 `bibliography(bytes(read(\"{path}\")), ..)`——此写法在原生 typst 与 omni 下都通用；或 `bibliography(read(\"{path}\"), ..)`（omni）。",
  "shell.style-version-conflict": "gb7714: style 全名已含版本（{style-version}），与显式 version: {version} 矛盾。去掉 version 或改用短名 style + version 组合。",
  "shell.style-footnote-conflict": "gb7714: style 全名 *-note 即脚注制，与显式 note: none 矛盾。去掉 note 或改用短名 style + note 组合。",
  "shell.target-needs-015": "gb7714: `target:` / `group:` 参数需要 typst 0.15+（原生多 bibliography 路由）。typst 0.14 请用 `label:` + `set-bib-label` 实现多列表。",
  "shell.cite-unexpected-argument": "unexpected argument: {name}",
  "shell.cite-before-init": "gb7714: 调用 `#cite(..)` 之前必须先 `#show: gb7714(..)` 并写至少一个 `#bibliography(read(\"...\"))`。",
  "shell.cite-adjacent-space-invalid": "gb7714: cite-adjacent-space 只收 auto / true / false，收到 {value}",
  "shell.space-before-annotation-invalid": "gb7714: space-before-annotation 只收 auto / true / false，收到 {value}",
  "shell.cite-footnote-with-native": "gb7714: cite(note: \"foot\") 暂不能与原生 CSL 样式列表（ieee / apa / CSL 文件）混用；GB 轴的 target / group / 多表路由可以混用。",
)

#let message(id, ..args) = {
  let template = _MESSAGES.at(id, default: none)
  if template == none { panic("gb7714[internal]: 未登记的错误 id: " + id) }
  if type(template) == function { return (template)(args.named()) }
  let m = template
  for (k, v) in args.named() {
    m = m.replace("{" + k + "}", if type(v) == str { v } else { repr(v) })
  }
  m
}

#let raise(id, ..args) = panic(message(id, ..args.named()))
