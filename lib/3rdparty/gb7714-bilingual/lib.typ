// gb7714-bilingual - GB/T 7714 双语参考文献系统
// 支持 GB/T 7714—2015 和 GB/T 7714—2025 两个版本
// 基于 citegeist 自定义实现，支持中英文术语自动切换
//
// 使用方法：
//   #import "@preview/gb7714-bilingual:0.2.3": init-gb7714, gb7714-bibliography, multicite
//   #show: init-gb7714.with(read("ref.bib"), style: "numeric", version: "2025")
//   正文中使用 @key 引用...
//   #gb7714-bibliography()
//
// 多文件支持：
//   #show: init-gb7714.with(read("main.bib") + read("extra.bib"), style: "numeric")
//
// 版本选择：
//   - version: "2015" - 符合 GB/T 7714—2015
//   - version: "2025" - 符合 GB/T 7714—2025（2026-07-01实施，默认）

// 导入内部实现
#import "src/api.typ": (
  gb7714-bibliography, get-all-entries, get-cited-entries, init-gb7714-impl,
  multicite,
)
// 重新导出作者格式化工具，便于用户在 `full-control` 回调中复用默认的作者样式
#import "src/authors.typ": format-author-intext, format-authors
// 重新导出语言检测，便于用户按语言分支处理
#import "src/core/language.typ": detect-language
#import "src/versions/mod.typ": get-punctuation, get-terms
#import "src/core/state.typ": _version

/// 初始化 GB/T 7714 双语参考文献系统
///
/// - bib-content: BibTeX 文件内容（使用 `read("ref.bib")` 读取）
///                多文件可用 `read("a.bib") + read("b.bib")` 合并
/// - style: 引用风格，"numeric"（顺序编码制）或 "author-date"（著者-出版年制）
/// - version: 标准版本，"2015" 或 "2025"（默认）
/// - show-url: 是否显示 URL（默认 true）
/// - show-doi: 是否显示 DOI（默认 true）
/// - show-accessed: 是否显示访问日期（默认 true）
/// - cn-first: 仅 `style: "author-date"`。`true`（默认）中文条目排在外文之前，`false` 外文在前
/// - pinyin-override: 仅 author-date 下中文条目；`to-pinyin(..., style: "tone-num-end", override: ...)`，音节与 tone-num-end 一致
#let init-gb7714(
  bib-content,
  style: "numeric",
  version: "2025",
  show-url: true,
  show-doi: true,
  show-accessed: true,
  cn-first: true,
  pinyin-override: (:),
  range-tilde: false,
  punct-width: auto,
  bib-title: auto,
  bib-full-control: auto,
  doc,
) = {
  // 调用内部实现
  init-gb7714-impl(
    bib-content,
    style: style,
    version: version,
    show-url: show-url,
    show-doi: show-doi,
    show-accessed: show-accessed,
    range-tilde: range-tilde,
    punct-width: punct-width,
    bib-title: bib-title,
    bib-full-control: bib-full-control,
    cn-first: cn-first,
    pinyin-override: pinyin-override,
    doc,
  )
}

/// 取当前生效的标点配置（版本取自 init-gb7714，宽度取自 punct-width）。
/// 供 `full-control` 等自定义渲染场景复用，避免各处手写标点。
#let punctuation-for(lang) = get-punctuation(_version.get(), lang)

/// 取当前版本的语言术语（`in-word` 等），同样供自定义渲染复用。
#let terms-for(lang) = get-terms(_version.get(), lang)
