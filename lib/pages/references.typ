#import "../deps.typ": gb7714-bibliography, format-authors
#import "../utils.typ": page-title

#let is-other-entry(entry) = {
  let raw-type = lower(str(entry.raw-entry-type))
  let fields = entry.fields
  let subtype = lower(str(fields.at("entrysubtype", default: "")))
  let note = lower(str(fields.at("note", default: "")))
  let mark = str(fields.at("mark", default: fields.at("usera", default: "")))
  let medium = str(fields.at("medium", default: ""))
  let url = str(fields.at("url", default: fields.at("howpublished", default: "")))

  (
    raw-type == "other"
      or subtype == "other"
      or note == "other"
      or (raw-type in ("misc", "unknown") and url != "" and mark == "" and medium == "")
  )
}

#let render-custom-patent(entry, punct) = {
  let fields = entry.fields
  let owner = format-authors(entry.parsed-names, entry.lang, entry-key: entry.key)
  let title = fields.at("title", default: "")
  let country = fields.at("location", default: fields.at("address", default: ""))
  let patent-number = fields.at("number", default: fields.at("call-number", default: ""))
  let publish-date = fields.at("date", default: fields.at("issued", default: fields.at("year", default: "")))

  let body = []
  if owner != "" {
    let o = if type(owner) == str { owner.trim(regex("[.．]"), at: end) } else { owner }
    body += [#o#punct.period ]
  }
  body += [#title]
  body += [[P]#punct.period ]
  if country != "" {
    body += [#country#punct.colon]
  }
  if patent-number != "" {
    body += [#patent-number]
  }
  if patent-number != "" and publish-date != "" {
    body += [#punct.comma]
  }
  if publish-date != "" {
    body += [#publish-date]
  }
  body += [#punct.period #entry.ref-label]
  body
}

#let render-custom-conference(entry, graduate: false, punct) = {
  let fields = entry.fields
  let lang = entry.lang
  let author = format-authors(entry.parsed-names, lang, entry-key: entry.key)
  let editor-names = entry.parsed-names.at("editor", default: ())
  let editor = if editor-names.len() > 0 { format-authors((author: (), editor: editor-names), lang) } else { "" }
  let title = fields.at("title", default: "")
  let proceedings-title = fields.at("booktitle", default: fields.at("titleaddon", default: ""))
  let location = fields.at("location", default: fields.at("address", default: ""))
  let publisher = fields.at("publisher", default: fields.at("institution", default: ""))
  let year = str(fields.at("year", default: fields.at("date", default: "")))
  let pages = str(fields.at("pages", default: "")).replace("--", "-")
  let in-prefix = if lang == "zh" { "见；" } else { "In; " }

  let body = []
  if author != "" {
    let a = if type(author) == str { author.trim(regex("[.．]"), at: end) } else { author }
    body += [#a#punct.period ]
  }
  body += [#title]
  if graduate {
    body += [[C]]
    if proceedings-title != "" {
      body += [#("/" + "/")#proceedings-title#punct.period ]
    } else {
      body += [#punct.period ]
    }
  } else {
    body += [[A]#punct.period ]
    body += [#in-prefix]
    if editor != "" {
      let e = if type(editor) == str { editor.trim(regex("[.．]"), at: end) } else { editor }
      body += [#e#punct.period ]
    }
    if proceedings-title != "" {
      body += [#proceedings-title]
      body += [[C]#punct.period ]
    }
  }
  if location != "" {
    body += [#location#punct.colon]
  }
  if publisher != "" {
    body += [#publisher]
  }
  if publisher != "" and year != "" {
    body += [#punct.comma]
  }
  if year != "" {
    body += [#year]
  }
  if pages != "" {
    if graduate {
      body += [#punct.colon #pages#punct.period #entry.ref-label]
    } else {
      body += [#punct.period #pages#punct.period #entry.ref-label]
    }
  } else {
    body += [#punct.period #entry.ref-label]
  }
  body
}

#let render-custom-other(entry, punct) = {
  let fields = entry.fields
  let lang = entry.lang
  let author = format-authors(entry.parsed-names, entry.lang, entry-key: entry.key)
  let title = fields.at("title", default: "")
  let publish-date = str(fields.at("date", default: fields.at("year", default: fields.at("issued", default: fields.at("updated", default: "")))))
  let cited-date = str(fields.at("urldate", default: fields.at("accessed", default: "")))
  let url = str(fields.at("url", default: fields.at("howpublished", default: "")))

  let body = []
  if author != "" {
    let a = if type(author) == str { author.trim(regex("[.．]"), at: end) } else { author }
    body += [#a#punct.period ]
  }
  if title != "" {
    body += [#title#punct.period ]
  }
  let slash = if punct.period == "．" { "／" } else { "/" }
  if publish-date != "" {
    body += [#publish-date]
    if cited-date != "" {
      body += [#slash#cited-date]
    }
    body += [#punct.period ]
  } else if cited-date != "" {
    body += [#slash#cited-date#punct.period ]
  }
  if url != "" {
    body += [#url#punct.period #entry.ref-label]
  } else {
    body += [#entry.ref-label]
  }
  body
}

#let render-custom-standard(entry, punct) = {
  let fields = entry.fields
  let lang = entry.lang
  let drafter = format-authors(entry.parsed-names, lang, allow-anonymous: false, entry-key: entry.key)
  let standard-number = str(fields.at("number", default: fields.at("serial-number", default: "")))
  let title = fields.at("title", default: "")
  let location = fields.at("location", default: fields.at("address", default: ""))
  let publisher = fields.at("publisher", default: fields.at("institution", default: ""))
  let year = str(fields.at("year", default: fields.at("date", default: "")))

  let body = []
  if drafter != "" {
    let d = if type(drafter) == str { drafter.trim(regex("[.．]"), at: end) } else { drafter }
    body += [#d#punct.period ]
  }
  if standard-number != "" and title != "" {
    body += [#(standard-number + punct.comma + str(title))]
  } else if standard-number != "" {
    body += [#standard-number]
  } else if title != "" {
    body += [#title]
  }
  if location == "" and publisher == "" and year == "" {
    body += [[S]#punct.period #entry.ref-label]
    return body
  }

  body += [[S]#punct.period ]
  if location != "" {
    body += [#location]
    if publisher != "" {
      body += [#punct.colon]
    } else if year != "" {
      body += [#punct.comma]
    } else {
      body += [#punct.period #entry.ref-label]
      return body
    }
  }
  if publisher != "" {
    body += [#publisher]
    if year != "" {
      body += [#punct.comma]
    } else {
      body += [#punct.period #entry.ref-label]
      return body
    }
  }
  if year != "" {
    body += [#year#punct.period #entry.ref-label]
  } else {
    body += [#entry.ref-label]
  }
  body
}

#let bilingual-bibliography(
  graduate: false,
  english-writing: false,
  title: auto,
  full: false,
  par-indent: "none",
) = {
  if title == auto {
    title = page-title("references", english-writing: english-writing)
  }

  heading(level: 1, numbering: none, outlined: true)[#title]

  gb7714-bibliography(
    title: none,
    full: full,
    full-control: entries => {
      if par-indent == "first-line" {
        set par(first-line-indent: (amount: 2em, all: true))
        for entry in entries {
          let punct = if graduate or entry.lang == "en" {
            (period: ".", comma: ", ", colon: ": ")
          } else {
            (period: "．", comma: "，", colon: "：")
          }
          if entry.entry-type == "patent" {
            [[#entry.order]#h(0.5em)#render-custom-patent(entry, punct)]
          } else if entry.entry-type == "inproceedings" or entry.entry-type == "conference" {
            [[#entry.order]#h(0.5em)#render-custom-conference(entry, graduate: graduate, punct)]
          } else if is-other-entry(entry) {
            [[#entry.order]#h(0.5em)#render-custom-other(entry, punct)]
          } else if entry.entry-type == "standard" {
            [[#entry.order]#h(0.5em)#render-custom-standard(entry, punct)]
          } else {
            [[#entry.order]#h(0.5em)#entry.labeled-rendered]
          }
          parbreak()
        }
      } else if par-indent == "none" {
        set par(hanging-indent: 0em, first-line-indent: (amount: 0em, all: true))
        for entry in entries {
          let punct = if graduate or entry.lang == "en" {
            (period: ".", comma: ", ", colon: ": ")
          } else {
            (period: "．", comma: "，", colon: "：")
          }
          if entry.entry-type == "patent" {
            [[#entry.order]#h(0.5em)#render-custom-patent(entry, punct)]
          } else if entry.entry-type == "inproceedings" or entry.entry-type == "conference" {
            [[#entry.order]#h(0.5em)#render-custom-conference(entry, graduate: graduate, punct)]
          } else if is-other-entry(entry) {
            [[#entry.order]#h(0.5em)#render-custom-other(entry, punct)]
          } else if entry.entry-type == "standard" {
            [[#entry.order]#h(0.5em)#render-custom-standard(entry, punct)]
          } else {
            [[#entry.order]#h(0.5em)#entry.labeled-rendered]
          }
          parbreak()
        }
      } else {
        set par(hanging-indent: 2.5em, first-line-indent: (amount: 0em, all: true))
        for entry in entries {
          let punct = if graduate or entry.lang == "en" {
            (period: ".", comma: ", ", colon: ": ")
          } else {
            (period: "．", comma: "，", colon: "：")
          }
          if entry.entry-type == "patent" {
            [#box(width: 2em, align(right)[\[#entry.order\]])#h(0.5em)#render-custom-patent(entry, punct)]
          } else if entry.entry-type == "inproceedings" or entry.entry-type == "conference" {
            [#box(width: 2em, align(right)[\[#entry.order\]])#h(0.5em)#render-custom-conference(entry, graduate: graduate, punct)]
          } else if is-other-entry(entry) {
            [#box(width: 2em, align(right)[\[#entry.order\]])#h(0.5em)#render-custom-other(entry, punct)]
          } else if entry.entry-type == "standard" {
            [#box(width: 2em, align(right)[\[#entry.order\]])#h(0.5em)#render-custom-standard(entry, punct)]
          } else {
            [#box(width: 2em, align(right)[\[#entry.order\]])#h(0.5em)#entry.labeled-rendered]
          }
          parbreak()
        }
      }
    },
  )
}
  )
}
