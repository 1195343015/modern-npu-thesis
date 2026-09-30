#import "sentinel.typ": *
#import "field.typ"
#import "elements/mark-medium/built-in.typ" as mark-medium

#let is-platform-form(entry, version: 2015) = version == 2025 and mark-medium.mark(entry) in ("EB", "CP", "DS", "PP")

#let lacks-imprint-slot(entry) = mark-medium.mark(entry) in ("A", "D", "S", "EB", "DB", "CP", "DS", "PP")

#let get(entry, version: 2015) = {
  let entry-type = entry.entry_type
  let _mark = mark-medium.mark(entry)
  let component-part-types = ("inbook", "incollection", "inproceedings", "conference", "inreference", "suppbook", "suppcollection")
  if entry-type in component-part-types { return "component-part" }

  let _has-dedicated-mark = _mark in ("D", "P", "S", "N", "A")
  if not _has-dedicated-mark and field.get(entry, "booktitle") != none {
    if entry-type not in ("proceedings", "mvproceedings", "book", "collection", "mvbook", "mvcollection") { return "component-part" }
  }

  if _mark == "CM" and (field.get(entry, "booktitle") != none or field.alias(entry, "journaltitle", "journal") != none) { return "component-part" }
  if _mark == "N" { return "serial-newspaper" }
  if entry-type == "article" {
    let eprint = field.get(entry, "eprint")
    let archive = field.alias(entry, "eprinttype", "archiveprefix")
    let journal = field.alias(entry, "journaltitle", "journal")
    let entrysubtype = field.get(entry, "entrysubtype")
    let is-arxiv = eprint != none and archive != none and lower(str(archive)).starts-with("arxiv")
    if not is-arxiv and journal != none {
      is-arxiv = lower(str(journal)).starts-with("arxiv")
    }
    let is-preprint = (entrysubtype != none and lower(str(entrysubtype)) == "preprint") or is-arxiv
    if is-preprint {
      if version == 2025 { return "electronic" }
      return "preprint"
    }
    return "serial-article"
  }
  if entry-type == "patent" or _mark == "P" { return "patent" }
  if entry-type == "online" { return "electronic" }
  if _mark in ("EB", "DB", "CP", "DS") and field.get(entry, "publisher") == none { return "electronic" }
  if _mark == "Z" and field.has-online(entry) and field.get(entry, "publisher") == none { return "electronic" }

  if is-platform-form(entry, version: version) { return "electronic" }

  let _online-redirect-types = if version == 2025 { ("D", "A") } else { ("R", "D", "A") }
  if _mark in _online-redirect-types {
    let has-location = field.get(entry, "location") != none or field.get(entry, "address") != none
    let has-url = field.has-online(entry)
    if not has-location and has-url { return "electronic" }
  }
  if entry-type == "periodical" { return "serial" }
  return "monograph"
}
