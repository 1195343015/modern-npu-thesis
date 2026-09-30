#import "mark-medium/built-in.typ" as mark-medium
#import "emphasis.typ" as emphasis
#import "../punct/built-in.typ" as punct
#import "../field.typ"
#import "../detect/lang.typ" as language
#import "../category.typ"
#import "../terms/built-in.typ" as terms

#let addons(base, entry, subtitle-key: "subtitle", titleaddon-key: "titleaddon", correct-punct: false, punct-style: "half-with-space", custom-punct: (:)) = {
  if base == none { return none }
  let get = (e, k) => punct.field-text(e, k, correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct, force-correct: true)
  let subtitle = get(entry, subtitle-key)
  let titleaddon = get(entry, titleaddon-key)
  let colon = punct.get("colon", entry, punct-style, custom-punct)
  let out = base
  if subtitle != none { out = [#out#colon#subtitle] }
  if titleaddon != none { out = [#out#colon#titleaddon] }
  out
}

#let journal(entry, correct-punct, punct-style, custom-punct, short-journal) = {
  let journal = if short-journal { punct.field-text(entry, "shortjournal", correct-punct: correct-punct, punct-style: punct-style) } else { none }
  let used-short = journal != none
  if journal == none { journal = punct.field-text(entry, "journaltitle", correct-punct: correct-punct, punct-style: punct-style) }
  if journal == none { journal = punct.field-text(entry, "journal", correct-punct: correct-punct, punct-style: punct-style) }
  if not used-short {
    journal = addons(journal, entry, subtitle-key: "journalsubtitle", titleaddon-key: "journaltitleaddon", correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct)
  }
  journal
}

#let volume(entry, version: 2015, custom-terms: (:)) = {
  let volume-value = punct.field-text(entry, "volume"); if volume-value == none { return none }
  let entry-category = category.get(entry, version: version)
  if entry-category in ("serial-article", "serial-newspaper", "serial") { return none }

  if type(volume-value) != str { return volume-value }
  terms.volume(entry, volume-value, custom-terms: custom-terms)
}

#let format(entry, is-component-part: false, show-mark: true, show-medium: true, show-url: true, space-before-mark: false, mark-medium-bracket-style: "half", show-patent-country: false, preprint: false, hyperlink-title: false, correct-punct: false, punct-style: "half-with-space", custom-punct: (:), custom-terms: (:), version: 2015, title-spec: none, volume-title-gutter: auto, online: auto) = {
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let mark-block = mark-medium.render(entry, show-mark: show-mark, show-medium: show-medium, show-url: show-url, space-before-mark: space-before-mark, version: version, online: online, bracket-style: mark-medium-bracket-style)
  let title = punct.field-text(entry, "title", correct-punct: correct-punct, punct-style: punct-style)
  if title == none {

    return none
  }
  title = addons(title, entry, correct-punct: correct-punct, punct-style: punct-style, custom-punct: custom-punct)
  if hyperlink-title {
    let url = field.get(entry, "url"); let doi = field.get(entry, "doi")
    let target = if url != none { str(url) }
    else if doi != none { "https://doi.org/" + str(doi) }
    else { none }
    if target != none { title = link(target, title) }
  }
  let _emph(x) = emphasis.apply(x, title-spec)
  let _mark = mark-medium.mark(entry)
  if is-component-part {
    let scale = if version == 2025 and _mark == "CM" { punct.field-text(entry, "scale") } else { none }
    if scale != none { [#_emph(title)#p("period") #scale#mark-block] } else { _emph(title) + mark-block }
  }
  else if preprint { _emph(title) + mark-block }

  else if version == 2025 and _mark == "S" {
    let number = punct.field-text(entry, "number", correct-punct: correct-punct, punct-style: punct-style)
    let _num-sep = if language.is-cjk-entry(entry) { "\u{3000}" } else { " " }
    if number != none { [#number#_num-sep#_emph(title)#mark-block] } else { _emph(title) + mark-block }
  }
  else if _mark == "P" {
    let number = punct.field-text(entry, "number")
    if number == none { _emph(title) + mark-block }
    else {
      let country = if show-patent-country or version == 2005 { punct.field-text-alias(entry, "location", "address") } else { none }
      let number-part = if country != none { country + p("comma") + number } else { number }
      _emph(title + p("colon") + number-part) + mark-block
    }
  }
  else if version == 2025 and _mark == "CM" {
    let volume = volume(entry, version: version, custom-terms: custom-terms)
    let head = if volume != none { title + p("colon") + volume } else { title }
    let scale = punct.field-text(entry, "scale")
    if scale != none { [#_emph(head)#p("period") #scale#mark-block] } else { _emph(head) + mark-block }
  }
  else {

    let maintitle = punct.field-text(entry, "maintitle", correct-punct: correct-punct, punct-style: punct-style)
    if maintitle != none {
      let volume = volume(entry, version: version, custom-terms: custom-terms)
      let head = if volume != none { maintitle + p("colon") + volume } else { maintitle }

      let gutter-space = if volume-title-gutter == auto { " " } else if type(volume-title-gutter) in (length, relative, ratio) { h(volume-title-gutter) } else { volume-title-gutter }
      _emph(head + gutter-space + title) + mark-block
    } else {
      let number = punct.field-text(entry, "number")

      let number-inline-types = if version == 2025 { ("A", "R") } else { ("S", "A", "R") }
      if number != none and _mark in number-inline-types { _emph(title + p("colon") + number) + mark-block }
      else {
        let volume = volume(entry, version: version, custom-terms: custom-terms)
        if volume != none { _emph(title + p("colon") + volume) + mark-block } else { _emph(title) + mark-block }
      }
    }
  }
}
