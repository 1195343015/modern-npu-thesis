#import "../detect/lang.typ" as language

#let localized(value, entry) = {
  if value == none { return none }
  if type(value) != dictionary {
    if type(value) == str and value == "" { return none }
    return value
  }
  let lang = language.get(entry)
  if lang in value {
    let v = value.at(lang)
    if v != none and v != "" { return v }
  }
  for (_, v) in value {
    if v != none and v != "" { return v }
  }
  none
}

#let is-number-pair(v) = type(v) == dictionary and ("singular" in v or "plural" in v)

#let pick-number(v, plural) = {
  if not is-number-pair(v) { return v }
  let primary = if plural { v.at("plural", default: none) } else { v.at("singular", default: none) }
  if primary != none { return primary }
  if plural { v.at("singular", default: none) } else { v.at("plural", default: none) }
}

#let built-in-term-keys = ("et-al", "editor", "translator", "anon", "no-date", "sine-loco", "sine-nomine", "sine-anno", "ma-thesis", "phd-thesis", "edition", "volume", "pages", "ibid", "footnote-number")

#let cite-term-keys = ("et-al", "anon", "no-date", "ibid", "footnote-number")

#let cite-term-lang(setting, key, entry, document-lang) = {
  let v = if std.type(setting) == dictionary { setting.at(key, default: "by-entry") } else { setting }
  if v == "by-doc" { document-lang }
  else if v == "by-entry" { if entry != none { language.get(entry) } else { document-lang } }
  else { v }
}

#let _term(overrides, key, lang, fallback, plural: false) = {
  if type(overrides) != dictionary { return fallback }
  let o = overrides.at(key, default: none)
  if o == none { return fallback }
  if is-number-pair(o) { o = pick-number(o, plural) }
  if o == none { return fallback }
  if type(o) == dictionary {
    if lang in o and o.at(lang) != none {
      let v = pick-number(o.at(lang), plural)
      if v != none and str(v) != "" { return v }
    }
    return fallback
  }
  if type(o) == str and o != "" { return o }
  fallback
}

#let anon-for(lang, custom-terms: (:)) = _term(custom-terms, "anon", lang,
  (zh: "佚名", ja: "匿名", ko: "anon", ru: "анон.", fr: "anon.", de: "o. A.").at(lang, default: "Anon"))

#let anon(entry, custom-terms: (:)) = anon-for(language.get(entry), custom-terms: custom-terms)

#let no-date-for(lang, custom-terms: (:)) = _term(custom-terms, "no-date", lang,
  (zh: "无日期", ja: "日付なし", ko: "일자 없음", ru: "б. д.", fr: "s. d.", de: "o. J.").at(lang, default: "n.d."))

#let no-date(entry, custom-terms: (:)) = no-date-for(language.get(entry), custom-terms: custom-terms)

#let etal-for(lang, custom-terms: (:), version: 2025) = _term(custom-terms, "et-al", lang, (zh: "等", ja: "ほか", ko: "외", ru: if version == 2005 { "и др" } else { "и др." }).at(lang, default: if version == 2005 { "et al" } else { "et al." }))
#let etal(entry, custom-terms: (:), version: 2025) = etal-for(if entry != none { language.get(entry) } else { "en" }, custom-terms: custom-terms, version: version)

#let role(entry, role, truncated, comma, bare-etal: false, custom-terms: (:), et-al-translator-separator: auto, version: 2025, plural: false) = {
  let lang = language.get(entry)
  let et-al-word = etal(entry, custom-terms: custom-terms, version: version)

  let lead(gutter) = if bare-etal { "" } else { gutter }
  let role-word = if role == "ed" {
    _term(custom-terms, "editor", lang, (zh: "主编", ja: "編", ko: "편", fr: "éd.", ru: "ред.").at(lang, default: "ed."), plural: plural)
  } else {
    _term(custom-terms, "translator", lang, (zh: "译", ja: "訳", ko: "역", fr: "trad.", ru: "пер.").at(lang, default: "trans."), plural: plural)
  }
  let translator-gutter(language-default) = if role == "trans" and et-al-translator-separator != auto { et-al-translator-separator } else { language-default }
  if lang == "zh" {
    if role == "ed" { (if truncated { lead(comma) + et-al-word } else { "" }) + role-word }
    else { (if truncated { lead(comma) + et-al-word + translator-gutter(if version == 2015 { "" } else { comma }) } else { comma }) + role-word }
  } else if lang == "ja" {
    (if truncated { lead(comma) + et-al-word + translator-gutter("") } else { "" }) + role-word
  } else if lang == "ko" {
    (if truncated { lead(" ") + et-al-word + translator-gutter(" ") } else { " " }) + role-word
  } else {
    (if truncated { lead(comma) + et-al-word + translator-gutter(comma) } else { comma }) + role-word
  }
}

#let degree(entry, level, custom-terms: (:)) = {
  let lang = language.get(entry)
  if level == "MA" {
    _term(custom-terms, "ma-thesis", lang, (zh: "硕士学位论文", ja: "修士論文", ko: "석사학위논문", ru: "магистерская диссертация", fr: "thèse de master").at(lang, default: "MA thesis"))
  } else {
    _term(custom-terms, "phd-thesis", lang, (zh: "博士学位论文", ja: "博士論文", ko: "박사학위논문", ru: "докторская диссертация", fr: "thèse de doctorat").at(lang, default: "PhD thesis"))
  }
}

#let _IBID-WORDS = (zh: "同上", ja: "前掲", ru: "Там же")

#let _ibid-parts(raw) = {
  if type(raw) == dictionary { (text: raw.at("text", default: none), supplement-separator: raw.at("supplement-separator", default: auto)) }
  else { (text: raw, supplement-separator: auto) }
}

#let _ibid-resolved(lang, custom-terms) = {
  let fallback = (text: _IBID-WORDS.at(lang, default: "Ibid."), supplement-separator: auto)
  let o = if type(custom-terms) == dictionary { custom-terms.at("ibid", default: none) } else { none }
  if o == none { return fallback }
  let raw = if type(o) == dictionary and "text" not in o and "supplement-separator" not in o {
    if lang in o and o.at(lang) != none { o.at(lang) } else { return fallback }
  } else { o }
  let parts = _ibid-parts(raw)
  (
    text: if parts.text != none and parts.text != "" { parts.text } else { fallback.text },
    supplement-separator: parts.supplement-separator,
  )
}

#let ibid-for(lang, custom-terms: (:)) = _ibid-resolved(lang, custom-terms).text

#let ibid-supplement-separator(lang, custom-terms: (:)) = _ibid-resolved(lang, custom-terms).at("supplement-separator")

#let _EDITION-WRAP = (
  zh: (prefix: "", suffix: "版"), ja: (prefix: "", suffix: "版"),
  ko: (prefix: "", suffix: "판"), ru: (prefix: "", suffix: "-е изд"),
  fr: (prefix: "", suffix: "e éd"), en: (prefix: "", suffix: " ed"),
)
#let _VOLUME-WRAP = (
  zh: (prefix: "第", suffix: "卷"), ja: (prefix: "第", suffix: "巻"),
  ko: (prefix: "제", suffix: "권"), ru: (prefix: "Т. ", suffix: ""),
  en: (prefix: "vol. ", suffix: ""),
)

#let _FOOTNOTE-NUMBER-WRAP = (
  zh: (prefix: "同", suffix: ""),
  ru: (prefix: "Смотри сноску ", suffix: ""),
  fr: (prefix: "Voir note ", suffix: ""),
  en: (prefix: "See note ", suffix: ""),
)

#let _footnote-number-resolved(lang, custom-terms) = {
  let default-pair = if lang in _FOOTNOTE-NUMBER-WRAP { _FOOTNOTE-NUMBER-WRAP.at(lang) } else { _FOOTNOTE-NUMBER-WRAP.en }
  let o = if type(custom-terms) == dictionary { custom-terms.at("footnote-number", default: none) } else { none }
  let user = if type(o) == dictionary and lang in o and type(o.at(lang)) == dictionary { o.at(lang) } else { (:) }
  (
    prefix: user.at("prefix", default: default-pair.prefix),
    suffix: user.at("suffix", default: default-pair.suffix),
    supplement-separator: user.at("supplement-separator", default: auto),
  )
}

#let _wrap-numbered(custom-terms, key, lang, num-text, default-wrap, plural: false) = {
  let ov = if type(custom-terms) == dictionary { custom-terms.at(key, default: none) } else { none }
  if is-number-pair(ov) { ov = pick-number(ov, plural) }
  let picked = if type(ov) == dictionary and lang in ov { pick-number(ov.at(lang), plural) } else { none }
  let pair = if type(picked) == dictionary and not is-number-pair(picked) { picked }
    else if lang in default-wrap { default-wrap.at(lang) }
    else { default-wrap.en }
  pair.at("prefix", default: "") + num-text + pair.at("suffix", default: "")
}

#let footnote-number-wrap(lang, note-number-text, custom-terms: (:)) = {
  let resolved = _footnote-number-resolved(lang, custom-terms)
  resolved.prefix + note-number-text + resolved.suffix
}

#let footnote-number-supplement-separator(lang, custom-terms: (:)) = _footnote-number-resolved(lang, custom-terms).at("supplement-separator")

#let edition(entry, n, version: 2015, custom-terms: (:)) = {
  let lang = language.get(entry)
  let num-text = if lang in ("zh", "ja", "ko", "ru", "fr") { str(n) }
    else {
      let ordinal-suffix = if n == 2 { "nd" } else if n == 3 { "rd" } else { "th" }
      str(n) + ordinal-suffix
    }
  let base = _wrap-numbered(custom-terms, "edition", lang, num-text, _EDITION-WRAP)
  let overridden = custom-terms.at("edition", default: none) != none
  if lang in ("en", "fr", "ru") and version != 2025 and not overridden { base + "." } else { base }
}

#let volume(entry, volume-str, custom-terms: (:)) = {
  let lang = language.get(entry)

  let chars = volume-str.clusters()
  let is-number = chars.len() > 0 and chars.all(c => "0123456789".contains(c))

  let is-multi = (
    not is-number and chars.len() > 0
      and chars.all(c => "0123456789-–,，、 ".contains(c))
      and chars.any(c => "0123456789".contains(c))
  )
  if not is-number and not is-multi { return volume-str }
  _wrap-numbered(custom-terms, "volume", lang, volume-str, _VOLUME-WRAP, plural: is-multi)
}

#let _PAGES-WRAP = (en: (prefix: "", suffix: ""))

#let pages-label(entry, page-text, plural, custom-terms: (:)) = {
  _wrap-numbered(custom-terms, "pages", language.get(entry), page-text, _PAGES-WRAP, plural: plural)
}

#let sine-loco(entry, custom-terms: (:)) = {
  let lang = language.get(entry)
  _term(custom-terms, "sine-loco", lang, (zh: "出版地不详", ja: "出版地不明", ko: "발행지불명").at(lang, default: "S.l."))
}

#let sine-nomine(entry, custom-terms: (:)) = {
  let lang = language.get(entry)
  _term(custom-terms, "sine-nomine", lang, (zh: "出版者不详", ja: "出版者不明", ko: "발행처불명").at(lang, default: "s.n."))
}

#let sine-anno(entry, custom-terms: (:)) = {
  let lang = language.get(entry)
  _term(custom-terms, "sine-anno", lang, (zh: "出版年不详", ja: "日付不明", ko: "발행일불명").at(lang, default: "s.a."))
}

#let bib-title(lang, region) = {
  if lang == "zh" {
    if region == "TW" or region == "HK" { "參考文獻" } else { "参考文献" }
  }
  else if lang == "ja" { "参考文献" }
  else if lang == "ko" { "참고 문헌" }
  else if lang == "fr" { "Bibliographie" }
  else if lang == "ru" { "Библиография" }
  else { "Bibliography" }
}
