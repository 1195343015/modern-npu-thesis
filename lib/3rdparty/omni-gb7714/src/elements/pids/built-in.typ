#import "../../field.typ"
#import "../../punct/built-in.typ" as punct
#import "../mark-medium/built-in.typ" as mark-medium
#import "./custom.typ" as custom-pid

#let normalize-platform(s) = lower(str(s)).replace(regex("[\\s_-]"), "")

#let _PLATFORM-NAMES = (
  arxiv: "arXiv", chinaxiv: "ChinaXiv", pssxiv: "PSSXiv",
  biorxiv: "bioRxiv", medrxiv: "medRxiv", researchsquare: "Research Square", osf: "OSF",
)

#let _EPRINT-RESOLVERS = (
  arxiv:          "https://arxiv.org/abs/{}",
  chinaxiv:       "https://chinaxiv.org/abs/{}",
  biorxiv:        "https://www.biorxiv.org/content/{}",
  researchsquare: "https://www.researchsquare.com/article/{}",
  osf:            "https://osf.io/preprints/{}",
)

#let is-preprint-platform(name, custom-pids: (:)) = {
  if name == none or type(name) != str { return false }
  let key = normalize-platform(name)
  if key == "" { return false }
  if key in _PLATFORM-NAMES { return true }
  if type(custom-pids) == dictionary and "eprint" in custom-pids and type(custom-pids.at("eprint")) == dictionary {
    let resolver = custom-pids.at("eprint").at("resolver", default: none)
    if type(resolver) == dictionary {
      for (platform, _) in resolver { if normalize-platform(platform) == key { return true } }
    }
  }
  false
}

#let eprint-prefix(entry) = {
  let archive-prefix = field.alias(entry, "archiveprefix", "eprinttype")
  if archive-prefix == none { return none }
  let key = normalize-platform(archive-prefix)
  _PLATFORM-NAMES.at(key, default: str(archive-prefix))
}

#let resolve-doi(v) = "https://doi.org/" + str(v)
#let resolve-cstr(v) = {
  let cstr-value = str(v).trim()
  if lower(cstr-value).starts-with("cstr:") { cstr-value = cstr-value.slice(5).trim() }
  "https://cstr.cn/" + cstr-value
}

#let resolve-eprint(entry, v, custom-pids: (:)) = {
  let archive-prefix = field.alias(entry, "archiveprefix", "eprinttype")
  if archive-prefix == none { return none }
  let key = normalize-platform(archive-prefix)
  let eprint-value = str(v).trim()

  let template = _EPRINT-RESOLVERS.at(key, default: none)
  if type(custom-pids) == dictionary and "eprint" in custom-pids and type(custom-pids.at("eprint")) == dictionary {
    let resolver = custom-pids.at("eprint").at("resolver", default: none)
    if type(resolver) == dictionary {
      for (platform, url-template) in resolver {
        if normalize-platform(platform) == key { template = str(url-template); break }
      }
    } else if type(resolver) == str { template = resolver }
  }
  if template == none { return none }
  if template.contains("{}") { template.replace("{}", eprint-value) } else { template + eprint-value }
}

#let colon(entry, punct-style, custom-punct, pid-colon-style: auto) = {
  if pid-colon-style != auto {
    let dir = punct.resolve-dir(pid-colon-style, punct.is-cj-entry(entry))
    return if dir == "full" { "：" } else if dir == "half-with-space" { ": " } else { ":" }
  }
  if punct.has-override(custom-punct, "colon") {
    let override-value = punct.resolve-value(punct.get-override(custom-punct, "colon"))
    if type(override-value) == str { return override-value.trim(at: end) }
    return override-value
  }
  let use-full = punct.resolve-dir(punct-style, punct.is-cj-entry(entry)) == "full"
  if use-full { "：" } else { ":" }
}

#let _meta-keys = ("max", "rest")

#let effective(name, value, show-pid, url-str, default-show, entry: none, custom-pids: (:), dedup-url-pid: true, version: 2015) = {
  if value == none or value == "" { return false }
  let _online = v => v != "online-only" or (entry != none and mark-medium.is-online(entry, version: version))
  let explicit-show = show-pid.at(name, default: auto)
  if explicit-show == false { return false }
  if explicit-show == true { return true }
  if explicit-show == "online-only" {
    if not _online(explicit-show) { return false }
  } else {
    let entry-setting = auto
    if entry != none {
      if entry.entry_type in show-pid { entry-setting = show-pid.at(entry.entry_type) }
      else {
        let code = mark-medium.base-mark(entry)
        if code in show-pid { entry-setting = show-pid.at(code) }
      }
    }
    if entry-setting == false { return false }
    if entry-setting == "online-only" and not _online(entry-setting) { return false }
    if entry-setting == auto {
      let rest = show-pid.at("rest", default: auto)
      if rest == false { return false }
      if rest == "online-only" and not _online(rest) { return false }
      if rest == auto and default-show == false { return false }
    } else if default-show == false { return false }
  }
  if not dedup-url-pid { return true }

  let dedup-value = if name == "eprint" and entry != none { custom-pid.strip-label-prefix(str(value), eprint-prefix(entry)) } else { str(value) }
  if dedup-value != "" and lower(url-str).contains(lower(dedup-value)) { return false }
  true
}

#let DEFAULT-PID-PRIORITY = ("cstr", "doi", "eprint", "isbn", "issn")

#let pid-name-order(pid-priority, custom-pids) = {
  let order = ()
  for k in pid-priority {
    let s = str(k)
    if s in _meta-keys { continue }
    if s not in order { order.push(s) }
  }
  for built-in in DEFAULT-PID-PRIORITY {
    if built-in not in order { order.push(built-in) }
  }
  for n in custom-pid.order-names(custom-pids) {
    if n not in order { order.push(n) }
  }
  order
}
