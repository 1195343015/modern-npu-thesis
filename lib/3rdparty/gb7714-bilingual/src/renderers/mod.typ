// GB/T 7714 双语参考文献系统 - 渲染器入口

#import "article.typ": render-article
#import "book.typ": render-book
#import "conference.typ": render-inproceedings
#import "thesis.typ": render-thesis
#import "patent.typ": render-patent
#import "standard.typ": render-standard
#import "report.typ": render-report
#import "webpage.typ": render-webpage
#import "misc.typ": render-misc
#import "preprint.typ": render-preprint

// 类型 -> 渲染函数映射
#let _renderers = (
  // 期刊文章
  "article": render-article,
  "periodical": render-article, // 连续出版物
  "newspaper": render-article, // 报纸
  // 书籍
  "book": render-book,
  "inbook": render-book,
  "incollection": render-book,
  "collection": render-book, // 汇编
  // 会议论文
  "inproceedings": render-inproceedings,
  "conference": render-inproceedings,
  // 学位论文
  "phdthesis": render-thesis,
  "mastersthesis": render-thesis,
  "thesis": render-thesis,
  // 专利
  "patent": render-patent,
  // 标准
  "standard": render-standard,
  // 报告
  "techreport": render-report,
  "report": render-report,
  // 预印本：按 GB/T 7714—2025 格式渲染（日期用圆括号包裹）
  "preprint": render-preprint,
  "unpublished": render-article,
  // 网页/在线资源
  "online": render-webpage,
  "webpage": render-webpage,
  "www": render-webpage,
)

// 检测是否为标准（citegeist 不支持 @standard，返回 unknown）
#let _is-standard-entry(entry) = {
  let f = entry.at("fields", default: (:))
  let number = f.at("number", default: "")
  let std-prefixes = ("GB", "ISO", "IEC", "IEEE", "ANSI", "DIN", "JIS", "BS")
  std-prefixes.any(p => upper(number).starts-with(p))
}

// 工具：把空字符串归一化为 `none`，避免 `mark = {}` 这种空值被误认作“用户显式声明”
#let _normalize-empty(v) = if type(v) == str and v == "" { none } else { v }

// 获取用户指定的 mark/usera 字段（用于手动声明类型标识）
// biblatex 推荐使用 usera，mark 是为了兼容 gbt7714 宏包
// 空字符串视为未设置——否则 mark = {} 会走进 override 分支并绕过
// entrysubtype / note / number 前缀等启发式检测。
#let _get-mark(entry) = {
  let f = entry.at("fields", default: (:))
  let mark = _normalize-empty(f.at("mark", default: none))
  if mark != none { return mark }
  _normalize-empty(f.at("usera", default: none))
}

// 获取用户指定的 medium 字段（用于手动声明载体标识）
#let _get-medium(entry) = {
  let f = entry.at("fields", default: (:))
  _normalize-empty(f.at("medium", default: none))
}

// 通过 entrysubtype 或 note 字段检测特殊类型
// 兼容 biblatex-gb7714 的写法：@book + entrysubtype/note = standard
#let _detect-subtype(entry, raw-type) = {
  let f = entry.at("fields", default: (:))
  let subtype = lower(f.at("entrysubtype", default: ""))
  let note = lower(f.at("note", default: ""))

  // 标准：@book/@inbook + entrysubtype/note = "standard"
  if raw-type in ("book", "inbook", "unknown") {
    if subtype == "standard" or note == "standard" {
      return "standard"
    }
  }

  // 报纸：@article + entrysubtype/note = "news"/"newspaper"
  if raw-type in ("article", "unknown") {
    if subtype in ("news", "newspaper") or note in ("news", "newspaper") {
      return "newspaper"
    }
  }

  // 预印本：entrysubtype/note = "preprint"
  if raw-type in ("article", "misc", "unpublished", "unknown") {
    if subtype == "preprint" or note == "preprint" {
      return "preprint"
    }
  }

  none
}

// 通过字段启发式检测预印本（arXiv 等）
#let _is-preprint-entry(entry) = {
  let f = entry.at("fields", default: (:))
  // eprint + archiveprefix/eprinttype（biblatex 风格 arXiv 导出）
  let eprint = f.at("eprint", default: "")
  if eprint != "" {
    let prefix = lower(f.at("archiveprefix", default: f.at(
      "eprinttype",
      default: "",
    )))
    if prefix == "arxiv" { return true }
  }
  // journal 包含 "arxiv"（常见的手写形式）
  let journal = lower(f.at("journal", default: f.at(
    "journaltitle",
    default: "",
  )))
  if journal.contains("arxiv") { return true }
  false
}

/// 解析条目的规范化类型（如 @book + entrysubtype=standard → "standard"）
/// 返回解析后的 entry_type，供渲染器和外部 API 使用
#let resolve-entry-type(entry) = {
  let raw-type = lower(entry.at("entry_type", default: "misc"))
  let mark = _get-mark(entry)

  if mark != none {
    // mark 值直接映射到类型（S -> standard, N -> newspaper 等）
    let mark-to-type = (
      "S": "standard",
      "N": "newspaper",
      "J": "article",
      "M": "book",
      "C": "inproceedings",
      "D": "thesis",
      "R": "report",
      "P": "patent",
      "G": "collection",
      "EB": "online",
      "DB": "misc",
      "CP": "misc",
      "CM": "misc",
      "DS": "misc",
      "A": "preprint",
      "PP": "preprint",
      "Z": "misc",
    )
    return mark-to-type.at(upper(mark), default: raw-type)
  }

  let subtype-detected = _detect-subtype(entry, raw-type)
  if subtype-detected != none {
    return subtype-detected
  }
  if raw-type == "unknown" and _is-standard-entry(entry) {
    return "standard"
  }
  if (
    raw-type in ("misc", "unpublished", "unknown") and _is-preprint-entry(entry)
  ) {
    return "preprint"
  }
  raw-type
}

/// 根据类型选择渲染函数
#let render-entry(
  entry,
  lang,
  year-suffix: "",
  style: "numeric",
  version: "2025",
  config: (show-url: true, show-doi: true, show-accessed: true),
) = {
  let entry-type = resolve-entry-type(entry)
  let mark = _get-mark(entry)
  let medium = _get-medium(entry)

  // 查找渲染函数，未找到则使用 misc
  let renderer = _renderers.at(entry-type, default: render-misc)

  // 创建带有正确类型和 medium 的 entry 副本
  let entry-with-type = entry
  entry-with-type.entry_type = entry-type
  // 如果用户指定了 mark，将其存入 fields 以便 render-type-id 使用
  if mark != none {
    entry-with-type.fields.insert("_resolved_mark", mark)
  }
  if medium != none {
    entry-with-type.fields.insert("_resolved_medium", medium)
  }

  renderer(
    entry-with-type,
    lang,
    year-suffix: year-suffix,
    style: style,
    version: version,
    config: config,
  )
}
