// GB/T 7714 双语参考文献系统 - 版本配置入口

#import "v2015.typ": config-2015
#import "v2025.typ": config-2025
#import "../core/state.typ": _config

// 版本 -> 配置映射
#let _configs = (
  "2015": config-2015,
  "2025": config-2025,
)

/// 获取版本配置
#let get-version-config(version) = {
  _configs.at(version, default: config-2025)
}

/// 根据版本和语言获取术语
#let get-terms(version, lang) = {
  let config = get-version-config(version)
  if lang == "zh" { config.terms-zh } else { config.terms-en }
}

/// 根据版本获取类型映射
#let get-type-map(version) = {
  get-version-config(version).type-map
}

/// 根据版本获取引用格式配置
#let get-citation-config(version) = {
  get-version-config(version).citation
}

/// 获取标点符号配置
#let get-punctuation(version, lang) = {
  let punct = get-version-config(version).punctuation
  // punct-width: auto 跟随版本配置；"half" 全部半角；"full" 全部全角；
  // 亦可为字典按类覆盖：(default: .., period/comma/colon/paren/semicolon: "half"|"full")
  // 其中 default 缺省为 auto，paren 同时作用于左右圆括号
  let width = _config.get().at("punct-width", default: auto)
  let base = if type(width) == dictionary { width.at("default", default: auto) } else { width }
  let overrides = if type(width) == dictionary {
    // 显式重建，避免 remove 原地修改污染全局 state 中的字典
    let o = (:)
    for (k, v) in width {
      if k != "default" { o.insert(k, v) }
    }
    o
  } else {
    (:)
  }
  // 半角/全角符号表（内部键与 punct 字典一致；用户侧括号为单键 paren，同时控制左右）
  let half-table = (period: ".", comma: ", ", colon: ": ", lparen: "(", rparen: ")", semicolon: "; ")
  let full-table = (period: "．", comma: "，", colon: "：", lparen: "（", rparen: "）", semicolon: "；")
  let valid-keys = ("period", "comma", "colon", "paren", "semicolon")
  // 先按基准宽度覆盖版本配置
  let base-table = if base == "half" { half-table } else if base == "full" { full-table } else { none }
  if base-table != none {
    for (k, v) in base-table {
      punct.insert(k, v)
    }
  }
  // 再应用类别覆盖
  for (k, v) in overrides {
    assert(k in valid-keys, message: "gb7714-bilingual: punct-width 字典键无效: " + k + "（合法键 default/period/comma/colon/paren/semicolon）")
    assert(v == "half" or v == "full", message: "gb7714-bilingual: punct-width." + k + " 的值须为 \"half\" 或 \"full\"")
    let table = if v == "half" { half-table } else { full-table }
    if k == "paren" {
      punct.insert("lparen", table.lparen)
      punct.insert("rparen", table.rparen)
    } else {
      punct.insert(k, table.at(k))
    }
  }
  punct
}

/// 获取作者格式化规则
#let get-author-format-rules(version) = {
  get-version-config(version).author-format
}

/// 获取条目类型相关规则
#let get-entry-type-rules(version) = {
  get-version-config(version).entry-type-rules
}
