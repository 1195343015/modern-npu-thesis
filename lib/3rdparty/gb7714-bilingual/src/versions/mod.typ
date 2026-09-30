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
/// 可通过 init-gb7714 的 zh-period / zh-colon 参数覆盖中文标点
#let get-punctuation(version, lang) = {
  let punct = get-version-config(version).punctuation
  if lang == "en" {
    punct.insert("period", ".")
  } else if lang == "zh" {
    let cfg = _config.get()
    let zh-period = cfg.at("zh-period", default: none)
    if zh-period != none {
      punct.insert("period", zh-period)
    }
    let zh-colon = cfg.at("zh-colon", default: none)
    if zh-colon != none {
      punct.insert("colon", zh-colon)
    }
    let zh-comma = cfg.at("zh-comma", default: none)
    if zh-comma != none {
      punct.insert("comma", zh-comma)
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
