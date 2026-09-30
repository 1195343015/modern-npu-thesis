#let _SYLLABLE-STR = (
  "a ai an ang ao " +
  "ba bai ban bang bao bei ben beng bi bian biao bie bin bing bo bu " +
  "ca cai can cang cao ce cen ceng cha chai chan chang chao che chen cheng chi chong chou chu chuai chuan chuang chui chun chuo ci cong cou cu cuan cui cun cuo " +
  "da dai dan dang dao de dei deng di dia dian diao die ding diu dong dou du duan dui dun duo " +
  "e ei en eng er " +
  "fa fan fang fei fen feng fo fou fu " +
  "ga gai gan gang gao ge gei gen geng gong gou gu gua guai guan guang gui gun guo " +
  "ha hai han hang hao he hei hen heng hong hou hu hua huai huan huang hui hun huo " +
  "ji jia jian jiang jiao jie jin jing jiong jiu ju juan jue jun " +
  "ka kai kan kang kao ke ken keng kong kou ku kua kuai kuan kuang kui kun kuo " +
  "la lai lan lang lao le lei leng li lia lian liang liao lie lin ling liu long lou lu luan lun luo lü lüe lyu lyue " +
  "ma mai man mang mao me mei men meng mi mian miao mie min ming miu mo mou mu " +
  "na nai nan nang nao ne nei nen neng ni nian niang niao nie nin ning niu nong nu nuan nuo nü nüe nyu nyue " +
  "o ou " +
  "pa pai pan pang pao pei pen peng pi pian piao pie pin ping po pou pu " +
  "qi qia qian qiang qiao qie qin qing qiong qiu qu quan que qun " +
  "ran rang rao re ren reng ri rong rou ru ruan rui run ruo " +
  "sa sai san sang sao se sen seng sha shai shan shang shao she shei shen sheng shi shou shu shua shuai shuan shuang shui shun shuo si song sou su suan sui sun suo " +
  "ta tai tan tang tao te teng ti tian tiao tie ting tong tou tu tuan tui tun tuo " +
  "wa wai wan wang wei wen weng wo wu " +
  "xi xia xian xiang xiao xie xin xing xiong xiu xu xuan xue xun " +
  "ya yan yang yao ye yi yin ying yong you yu yuan yue yun " +
  "za zai zan zang zao ze zei zen zeng zha zhai zhan zhang zhao zhe zhei zhen zheng zhi zhong zhou zhu zhua zhuai zhuan zhuang zhui zhun zhuo zi zong zou zu zuan zui zun zuo"
)

#let _SYLLABLES = {
  let out = (:)
  for syllable in _SYLLABLE-STR.split(" ") { if syllable != "" { out.insert(syllable, true) } }
  out
}

#let split-syllables(word) = {
  if word in _SYLLABLES { return none }
  let letters = word.clusters()
  for at in range(letters.len() - 1, 0, step: -1) {
    let head = letters.slice(0, at).join("")
    let tail = letters.slice(at).join("")
    if head in _SYLLABLES and tail in _SYLLABLES { return (head, tail) }
  }
  none
}

#let _is-double(word) = split-syllables(word) != none

#let _WESTERN-GIVEN-BLOCK-STR = (
  "anna lisa nina tina diana dana lina mina sara nana maya mona lana gina rina dina " +
  "leia mia lia sami cara lara tara zara kira mira nora dora cora vera lena bela nena " +
  "erin aidan jason dalia julia sofia luna jana hana kana mila lola lulu nini " +
  "ana ada ida ava eva ali ani ami ina ona una"
)
#let _WESTERN-GIVEN-BLOCK = {
  let out = (:)
  for w in _WESTERN-GIVEN-BLOCK-STR.split(" ") { if w != "" { out.insert(w, true) } }
  out
}

#let _FAMILY-SEPARATOR = regex("-+")
#let _GIVEN-SEPARATOR = regex("['\\s-]+")

#let _all-syllables(word, separator) = if word.contains(separator) {
  word.split(separator).filter(part => part != "").all(part => part in _SYLLABLES)
} else {
  (word in _SYLLABLES) or _is-double(word)
}

#let _COMPOUND-SURNAME-STR = (
  "moqi shangguan dongfang dongguo dongmen yuezheng zhangdu linghu zhongsun gongye gongsun " +
  "gongyang gongliang gongxi nangong nanmen sikou situ sikong sima huyan rangsi xiahou taishu " +
  "jiagu yuwen zongzheng zaifu yuchi zuoqiu wuma guihai weisheng murong tuoba liangqiu ouyang " +
  "duangan chunyu qidiao tantai puyang shentu baili huangfu guliang duanmu diwu yangshe wenren " +
  "ximen zhuge helian xuanyuan zhongli zhangsun luqiu lyuqiu zhuansun"
)
#let _COMPOUND-SURNAMES = {
  let out = (:)
  for surname in _COMPOUND-SURNAME-STR.split(" ") { if surname != "" { out.insert(surname, true) } }
  out
}

#let _family-pinyin(family) = {
  let lower-family = lower(family.trim())
  if lower-family == "" { return false }
  if lower-family in _SYLLABLES { return true }
  let compact = lower-family.replace("-", "").replace(" ", "").replace("'", "")
  if compact in _COMPOUND-SURNAMES { return true }
  _all-syllables(lower-family, _FAMILY-SEPARATOR)
}

#let _given-pinyin(given) = {
  let lower-given = lower(given.trim()).replace("’", "'")
  if lower-given == "" or lower-given.contains(".") { return false }
  if lower-given in _WESTERN-GIVEN-BLOCK { return false }
  _all-syllables(lower-given, _GIVEN-SEPARATOR)
}

#let is-name-pinyin(name) = {
  if name.at("prefix", default: "").trim() != "" { return false }
  if name.at("suffix", default: "").trim() != "" { return false }
  let given = name.at("given", default: "")
  let family = name.at("family", default: "")
  if given.trim() == "" or family.trim() == "" { return false }
  _family-pinyin(family) and _given-pinyin(given)
}
