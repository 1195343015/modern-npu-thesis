#let load-bibliography(
  bibtex-string,
  keep-raw-names: true,
  sentence-case-titles: true,
  text-case: "",
  on-duplicate: "error",
  source: none,
  verbatim: false,
  runs: false,
) = {
  let p = plugin("citegeist.wasm")
  let raw-names-opt = if keep-raw-names { bytes((1,)) } else { bytes((0,)) }

  let sentence-opt = if text-case != "" { bytes(text-case) } else if sentence-case-titles { bytes((1,)) } else { bytes((0,)) }
  let source-opt = if source == none { bytes(()) } else { bytes(source) }

  let dup-opt = bytes((
    if on-duplicate == "keep-first" { 1 }
    else if on-duplicate == "keep-last" { 2 }
    else { 0 },
  ))

  let verbatim-opt = if verbatim { bytes((1,)) } else { bytes((0,)) }

  let runs-opt = if runs { bytes((1,)) } else { bytes((0,)) }
  let serialized = p.get_bib_map(bytes(bibtex-string), raw-names-opt, sentence-opt, dup-opt, source-opt, verbatim-opt, runs-opt)
  let bib-map = cbor(serialized)

  bib-map
}
