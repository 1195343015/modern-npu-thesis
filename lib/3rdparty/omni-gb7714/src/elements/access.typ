#import "@preview/jurlstify:0.3.1": jurlstify as _jurlstify
#import "../sentinel.typ": *
#import "../field.typ"
#import "../punct/built-in.typ" as punct
#import "mark-medium/built-in.typ" as mark-medium
#import "pids/built-in.typ" as pids
#import "pids/custom.typ" as custom-pid

#let _break-url(url-value, every, hyphen, at-delimiters) = _jurlstify(
  str(url-value),
  extra-break-every: every,
  show-hyphens-at-extra-breaks: hyphen,
  show-hyphens-after-delimiters: hyphen and at-delimiters,
)

#let has-visible-path(entry, show-url: true, show-pid: (:), custom-pids: (:), dedup-url-pid: true, version: 2015) = {
  if mark-medium.online-suppressed(show-url, entry, version: version) { return false }
  let show-url = mark-medium.gate(show-url, entry, version: version)
  if not show-url { return false }
  let _bov = name => if type(custom-pids) == dictionary and name in custom-pids and type(custom-pids.at(name)) == dictionary { custom-pids.at(name) } else { (:) }
  let _bfield = (name, dflt) => _bov(name).at("field", default: dflt)
  let url = field.get(entry, "url")
  if url != none { return true }

  let eprint-value = field.get(entry, _bfield("eprint", "eprint"))
  if version == 2025 and eprint-value != none and pids.resolve-eprint(entry, eprint-value, custom-pids: custom-pids) != none { return true }
  let url-str = ""
  let _defaults = (
    doi: version != 2005,
    cstr: version == 2025,
    eprint: version != 2005,
  )
  for name in ("doi", "cstr", "eprint") {
    let value = field.get(entry, _bfield(name, name))
    if pids.effective(name, value, show-pid, url-str, _defaults.at(name), entry: entry, custom-pids: custom-pids, dedup-url-pid: dedup-url-pid, version: version) { return true }
  }
  if type(custom-pids) == dictionary {
    for (name, spec) in custom-pids {
      if name in ("doi", "cstr", "eprint", "isbn", "issn") { continue }
      if type(spec) != dictionary { continue }
      let value = field.get(entry, spec.at("field", default: name))
      if pids.effective(name, value, show-pid, url-str, true, entry: entry, custom-pids: custom-pids, dedup-url-pid: dedup-url-pid, version: version) { return true }
    }
  }
  false
}

#let access(entry, show-url: true, hyperlink: true, show-pid: (:), pid-priority: (), dedup-url-pid: true, custom-pids: (:), punct-style: "half-with-space", custom-punct: (:), pid-colon-style: auto, url-break-every: 1, url-break-hyphen: true, url-break-hyphen-at-delimiters: true, version: 2015) = {
  if mark-medium.online-suppressed(show-url, entry, version: version) { return none }
  let show-url = mark-medium.gate(show-url, entry, version: version)
  let p = name => punct.get(name, entry, punct-style, custom-punct)
  let _brk = s => _break-url(str(s), url-break-every, url-break-hyphen, url-break-hyphen-at-delimiters)
  let _link-fn = (target, body) => if hyperlink and target != none { link(target, body) } else { body }
  let parts = ()
  let _bov = name => if type(custom-pids) == dictionary and name in custom-pids and type(custom-pids.at(name)) == dictionary { custom-pids.at(name) } else { (:) }
  let _bfield = (name, dflt) => _bov(name).at("field", default: dflt)
  let url = field.get(entry, "url")
  let doi = field.get(entry, _bfield("doi", "doi")); let cstr = field.get(entry, _bfield("cstr", "cstr")); let eprint = field.get(entry, _bfield("eprint", "eprint"))
  let isbn = field.get(entry, _bfield("isbn", "isbn")); let issn = field.get(entry, _bfield("issn", "issn"))

  let url-str = if show-url and url != none { str(url) } else { "" }

  if version == 2025 and url == none and eprint != none {
    let prefix = pids.eprint-prefix(entry)
    let eprint-value = custom-pid.strip-label-prefix(eprint, prefix)
    let synthesized = pids.resolve-eprint(entry, eprint-value, custom-pids: custom-pids)
    if synthesized != none {
      url = synthesized
      url-str = if show-url { str(url) } else { "" }
    }
  }
  if show-url and url != none {
    parts.push(_link-fn(str(url), _brk(url)))
  }

  let _pid-off-2005 = version == 2005
  let _default-show = (
    doi: not _pid-off-2005,
    cstr: version == 2025,

    eprint: not _pid-off-2005,
    isbn: false,
    issn: false,
  )

  let pcolon = pids.colon(entry, punct-style, custom-punct, pid-colon-style: pid-colon-style)

  let _label = (name, dflt) => custom-pid.label-text(_bov(name), entry, dflt)
  let _resolve = (name, value, built-in-target) => {
    let ov = _bov(name)
    if ov.at("resolver", default: none) != none { custom-pid.resolve-custom(ov, value) } else { built-in-target }
  }
  let _effective(name, value) = pids.effective(name, value, show-pid, url-str, _default-show.at(name), entry: entry, custom-pids: custom-pids, dedup-url-pid: dedup-url-pid, version: version)
  let _emit-built-in(name) = {
    if name == "doi" and _effective("doi", doi) {
      _link-fn(_resolve("doi", doi, pids.resolve-doi(doi)), [#(_label("doi", "DOI"))#pcolon#(_brk(doi))])
    } else if name == "cstr" and _effective("cstr", cstr) {
      let cstr-value = custom-pid.strip-label-prefix(cstr, _label("cstr", "CSTR"))
      _link-fn(_resolve("cstr", cstr-value, pids.resolve-cstr(cstr-value)), [#(_label("cstr", "CSTR"))#pcolon#(_brk(cstr-value))])
    } else if name == "eprint" and _effective("eprint", eprint) {
      let prefix = pids.eprint-prefix(entry)
      let prefix-text = if prefix != none { prefix } else { "eprint" }
      let eprint-value = custom-pid.strip-label-prefix(eprint, prefix-text)
      _link-fn(_resolve("eprint", eprint-value, pids.resolve-eprint(entry, eprint-value, custom-pids: custom-pids)), [#(_label("eprint", prefix-text))#pcolon#eprint-value])
    } else if name == "isbn" and _effective("isbn", isbn) {
      _link-fn(_resolve("isbn", isbn, none), [#(_label("isbn", "ISBN"))#pcolon#punct.field-text(entry, _bfield("isbn", "isbn"))])
    } else if name == "issn" and _effective("issn", issn) {
      _link-fn(_resolve("issn", issn, none), [#(_label("issn", "ISSN"))#pcolon#punct.field-text(entry, _bfield("issn", "issn"))])
    } else { none }
  }

  let _custom-effective(name, value) = pids.effective(name, value, show-pid, url-str, not _pid-off-2005, entry: entry, custom-pids: custom-pids, dedup-url-pid: dedup-url-pid, version: version)
  let _emit-custom(term-name) = custom-pid.emit(term-name, custom-pids, entry, _custom-effective, pcolon, _brk, _link-fn)

  let max-pids = show-pid.at("max", default: none)
  let quota = if max-pids == none { none } else { calc.max(0, int(max-pids)) }

  if quota == none or quota > 0 {
    let emitted = 0
    for name in pids.pid-name-order(pid-priority, custom-pids) {
      let item = if name in ("doi", "cstr", "eprint", "isbn", "issn") {
        _emit-built-in(name)
      } else {
        _emit-custom(name)
      }
      if item != none {
        parts.push(item)
        emitted += 1
        if quota != none and emitted >= quota { break }
      }
    }
  }

  if parts.len() > 0 { parts.join(p("period")) } else { none }
}
