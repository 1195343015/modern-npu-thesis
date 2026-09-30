#import "../../errors.typ"

#let validate-marks(custom-marks) = {
  for (k, v) in custom-marks {
    if std.type(v) != str or v.trim() == "" { errors.raise("custom-marks.bad-value", name: k) }
  }
}

#let apply-marks(bib-data, custom-marks) = {
  if custom-marks.len() == 0 { return bib-data }
  let patched = (:)
  for (k, e) in bib-data {
    let code = custom-marks.at(e.entry_type, default: none)
    if code != none {
      let new-fields = e.fields; new-fields.insert("_omni-mark-custom", code)
      let new-entry = e; new-entry.fields = new-fields
      patched.insert(k, new-entry)
    } else { patched.insert(k, e) }
  }
  patched
}

#let registered-marks(custom-marks) = custom-marks.values().dedup()
