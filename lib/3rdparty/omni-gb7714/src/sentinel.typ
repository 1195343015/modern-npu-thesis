#let _M    = "\u{E710}\u{EA93}\u{E5C4}"
#let _MB   = "\u{E2F8}\u{ED41}\u{E886}"
#let _MS   = "\u{E3B7}\u{E91D}\u{EC6A}"
#let _ML   = "\u{E508}\u{EE32}\u{E7A9}"
#let _MNM  = "\u{E6B4}\u{E2C1}\u{ED59}"
#let _MF   = "\u{E97B}\u{E24E}\u{ED12}"
#let _LSEP = "\u{E14D}\u{EB76}\u{E4E1}"
#let _MSP  = "\u{E4B2}\u{EC77}\u{E19E}"

#let _CJK-ADJ = "[\\p{Han}\\p{Hiragana}\\p{Katakana}\\p{Hangul}\u{3000}-\u{303F}\u{FF00}-\u{FF65}\u{2026}\u{2014}\u{00B7}]"
#let _SD   = "\u{E612}\u{EF35}\u{E8A7}"
#let _ST   = "\u{EA09}\u{E5E1}\u{EDB6}"
#let _SBS  = "\u{E3C4}\u{E70F}\u{EBA8}"
#let _SLB  = "\u{E1D9}\u{E4A2}\u{EC37}"
#let _SAMP = "\u{E821}\u{EC5D}\u{E3F2}"
#let _SUND = "\u{E940}\u{E2B6}\u{EF18}"
#let _SHSH = "\u{E6D3}\u{EA47}\u{E5B9}"
#let _SPCT = "\u{EB82}\u{E319}\u{ED6E}"

#let _SCIRC = "\u{E5A3}\u{EB28}\u{E6F1}"

#let _SLBR = "\u{E70C}\u{E2D1}\u{EB64}"
#let _SRBR = "\u{E933}\u{E1A8}\u{EC50}"

#let _SPECIAL-ENTRY-TYPES = ("xdata", "set", "string", "comment")

#let _IS-HTML = "html" in dictionary(std)

#let _anchor-id(lbl) = "gbref-" + lbl.clusters().map(c => str(str.to-unicode(c))).join("_")
