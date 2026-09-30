#import "@preview/glotter:0.1.0" as _glotter
#import "../sentinel.typ": *
#import "../errors.typ"
#import "../field.typ"

#let is-cjk(s) = {
  for c in str(s).codepoints() {
    let codepoint = str.to-unicode(c)
    if (codepoint >= 0x4E00 and codepoint <= 0x9FFF) or (codepoint >= 0x3400 and codepoint <= 0x4DBF) or (codepoint >= 0x3040 and codepoint <= 0x30FF) or (codepoint >= 0xAC00 and codepoint <= 0xD7AF) { return true }
  }
  false
}

#let _detection-text(entry) = {
  let t = ""
  let names = entry.parsed_names.at("author", default: ())
  if names.len() > 0 { t += names.first().at("family", default: "") }
  let title = field.get(entry, "title")
  if title != none {
    if t != "" { t += " " }
    t += str(title)
  }

  if t == "" {
    for f in ("location", "address", "publisher", "institution", "organization", "school") {
      let v = field.get(entry, f)
      if v != none { t += str(v) }
    }
  }
  t
}

#let _scan-detect(text) = {
  let has-cjk = false
  for c in text.codepoints() {
    let codepoint = str.to-unicode(c)
    if (codepoint >= 0x3040 and codepoint <= 0x309F) or (codepoint >= 0x30A0 and codepoint <= 0x30FF) { return "ja" }
    if (codepoint >= 0xAC00 and codepoint <= 0xD7AF) or (codepoint >= 0x1100 and codepoint <= 0x11FF) or (codepoint >= 0x3130 and codepoint <= 0x318F) { return "ko" }
    if codepoint >= 0x0400 and codepoint <= 0x04FF { return "ru" }
    if (codepoint >= 0x4E00 and codepoint <= 0x9FFF) or (codepoint >= 0x3400 and codepoint <= 0x4DBF) { has-cjk = true }
  }
  if has-cjk { "zh" } else { "en" }
}

#let get(entry) = {
  let langid = field.alias(entry, "langid", "language")
  if langid != none {
    let lang-text = lower(str(langid))

    if lang-text == "chinese" or lang-text == "pinyin" or lang-text.starts-with("zh") { return "zh" }
    if lang-text == "japanese" or lang-text.starts-with("ja") { return "ja" }
    if lang-text == "korean" or lang-text.starts-with("ko") { return "ko" }
    if lang-text == "russian" or lang-text.starts-with("ru") { return "ru" }
    if lang-text in ("english", "american", "british") or lang-text.starts-with("en") { return "en" }
    if lang-text == "french" or lang-text.starts-with("fr") { return "fr" }

    let custom-code = entry.fields.at("_omni-lang", default: none)
    if custom-code != none { return custom-code }
  }
  _scan-detect(_detection-text(entry))
}

#let _built-in-lang-codes = ("zh", "ja", "ko", "ru", "fr", "en")

#let validate-languages(custom-languages) = {
  if type(custom-languages) != dictionary {
    errors.raise("languages.not-dict", got: repr(custom-languages))
  }
  for (code, aliases) in custom-languages {
    if type(code) != str or code.trim() == "" {
      errors.raise("languages.bad-code", got: repr(code))
    }
    if code in _built-in-lang-codes {
      errors.raise("languages.builtin-code", code: code)
    }
    let alias-list = if type(aliases) == array { aliases } else { (aliases,) }
    for a in alias-list {
      if type(a) != str or a.trim() == "" {
        errors.raise("languages.bad-alias", code: code, got: repr(a))
      }
    }
  }
}

#let _normalize-langid(s) = {
  let t = lower(str(s)).trim()
  let dash = t.position("-")
  if dash != none { t.slice(0, dash) } else { t }
}

#let apply-languages(bib-data, custom-languages) = {
  if custom-languages.len() == 0 { return bib-data }
  let alias-to-code = (:)
  for (code, aliases) in custom-languages {
    let alias-list = if type(aliases) == array { aliases } else { (aliases,) }
    alias-to-code.insert(code, code)
    for a in alias-list { alias-to-code.insert(_normalize-langid(a), code) }
  }
  let out = (:)
  for (k, e) in bib-data {
    let langid = field.alias(e, "langid", "language")
    if langid != none {
      let norm = _normalize-langid(langid)
      let code = alias-to-code.at(norm, default: none)
      if code != none {
        let new-fields = e.fields
        new-fields.insert("_omni-lang", code)
        e.fields = new-fields
      }
    }
    out.insert(k, e)
  }
  out
}

#let _LANG-ZH-ONLY = (
  "专业丛东丝丢两严丧临为丽举义乌乐乔习乡书买亏亚产亩亲亵亸亿仅仑仓仪们众伛伞伟传伡伣伤伥伦伧伪伫佥侣侥侦侧侨侩侪侬俦俨俩俪俫俭债倾偻偾偿傤傥傧储傩兑兖兰关兴兹养兽冁冈军农冯冻净减凑凤凫凯击凿刍刘"
  + "则刚创删别刬刭刽刾刿剀剂剐剑剧劝办务劢动劲劳势勋勚匀匦匮华协单卖卢卤卧卫卺厅历厉压厌厍厐厕厢厣县叁叆叇发变叠叹叽吓吕吗启吴呐呒呓呕呖呗员呙呛呜咙咛咝响哑哒哓哔哕哗哙哜哝哟唛唝唠唡唢唤啧啬啭啮啯"
  + "啰啴啸喷喽喾嗫嗳嘤噜嚣团园囱围囵图圆圹场块坚坛坜坝坞坟坠垄垅垆垒垦垩垫垭垯垱垲垴埘埙埚堑塆墙壳壶壸处备够头夹夺奁奂奋奖妆妇妈妩妪妫姗姹娄娅娆娇娈娱娲娴婳婴婵婶媪媭嫒嫔嫱嬷孙孪实宠审宪宫宽宾对寻"
  + "导尔尘尝尧尴层屃屉屦屿岁岂岖岗岘岚岛岽岿峃峄峣峤峥峦崂崃崄崭嵘嵚嵝巅巩巯币帅师帏帐帜带帧帮帱帻帼幂庆庐庑库应庙庞废庼廪开张弪弹强归录彟彨彻徕忆忧忾态怂怃怄怅怆总怼怿恳恶恸恹恺恻恼恽悫悬悭悮悯惩"
  + "惫惬惭惮惯愠愤愦慑慭懑懒懔戆戋戏戗战戬户执扩扪扫扬抚抟抠抡抢护报拟拢拣拥拦拧拨择挚挛挜挝挞挠挡挢挣挤挥挦捝捞损捡换捣掳掷掸掺掼揽揾揿搀搁搂搄搅摄摅摆摇摈摊撄撑撵撷撸撺擜擞攒敌敚敛敩斋斓斩时旷旸"
  + "昙昽显晓晔晕晖暂暅暧术杀杂权杨杩枞枣枥枧枨枪枫枭柠柽栀栅标栈栉栊栋栌栎栏树样栾桠桡桢桤桥桦桨桩桪梾梿检棁棂椝椟椠椤椫椭椮榄榅榇榈榉榝槚槛槟槠樯樱橥橱橹橼檩欢欤歼殁殇殒殓殚殡毁毂毕毙毡毵毶氇氢氩"
  + "氲汇汉汤汹沟沣沤沥沦沧沨沩沪泶泷泸泺泻泼泽泾浃浆浇浈浉浊测浍济浏浐浑浒浓浔浕涚涝涞涟涠涡涢涣涤润涧涨涩渌渍渎渐渑渔渖渗溁溃溅溆溇滗滚滟滠满滢滤滥滦滨滩滪潆潇潋潍澛澜濑濒灏灭灵灾灿炀炜炝炼炽烁烂"
  + "烃烛烦烧烨烩烫烬热焕焖焘煴爱爷牍牦牵牺犊犷犸狈狝狞狮狯狰狱狲猃猎猕猡猬獭玑玙玚玛玮环现玱玺珐珑珰珲琎琏琐琼瑷瑸璎瓒瓯电畅疖疗疟疠疡疬疭疮疯疴痈痉痖痨痪痫瘅瘆瘗瘘瘪瘫瘾瘿癞癣癫皑皱皲盏盐监盘眍眬"
  + "睁睐睑瞆瞒瞩矫矶矾矿砀码砖砗砚砜砻砾础硁硕硖硗硙硚硵硷碛碜碱祃祎祯祸秃秆积秽秾稆稣稳穑穞穷窍窎窑窜窝窥窦窭竖竞笃笔笕笺笼笾筚筛筜筹筼签筿简箓箦箧箨箩箫篑篓篮篯簖籁籴类籼粜粝粪糁糇糍紧絷緼縆纟纠"
  + "纡红纣纤纥约级纨纩纪纫纬纭纮纯纰纱纲纳纴纵纶纷纸纹纺纻纼纽纾线绀绁绂练组绅细织终绉绊绋绌绍绎经绐绑绒结绔绕绖绗绘给绚绛络绝绞统绠绡绢绣绤绥绦继绨绩绪绫绬续绮绯绰绱绲绳维绵绶绷绸绹绺绻综绽绾绿缀"
  + "缁缂缃缄缅缆缇缈缉缊缋缌缍缎缏缐缑缒缓缔缕编缗缘缙缚缛缜缝缞缟缠缡缢缣缤缥缦缧缨缩缪缫缬缭缮缯缰缱缲缳缴缵罂罗罚罢罴羁羟翘翙翚耢耧耸聂聋职聍联聩聪肃肠肤肾肿胀胁胧胨胪胫胶脍脏脐脑脓脔脶脸腘腭腻"
  + "腼腽腾膑臜舆舣舰舱舻艰艳艺节芈芗芜苁苇苈苋苌苍苎苏茏茑茔茕荆荙荚荛荜荝荞荟荠荡荣荤荥荦荧荨荩荪荫荬荭荮药莲莳莴莶获莸莹莺莼萚萝萤营萦萧萨蒀蒇蒉蒌蓝蓟蓠蓣蓥蓦蔷蔹蔺蔼蕰蕲蕴藓藴虏虑虬虽虾虿蚀蚁蚂"
  + "蚃蚬蛊蛏蛰蛱蛲蛳蛴蜕蜗蝇蝈蝼蝾螀螨蟏衅衔补衬衮袄袅袆袜袭袯裆裈裢裣裤裥褛褴襕见观觃规觅视觇览觉觊觋觌觍觎觏觐觑觞觯訚詟誊讠计订讣认讥讦讧讨让讪讫讬训议讯记讱讲讳讴讵讶讷许讹论讻讼讽设访诀证诂诃"
  + "评诅识诇诈诉诊诋诌词诎诏诐译诒诓诔试诖诗诘诙诚诛诜话诞诟诠诡询诣诤该详诧诨诩诪诫诬语诮误诰诱诲诳说诵诶请诸诹诺读诼诽课诿谀谁谂调谄谅谆谇谈谉谊谋谌谍谎谏谐谑谒谓谔谕谖谗谘谙谚谛谜谝谞谟谠谡谢谣"
  + "谤谥谦谧谨谩谪谫谬谭谮谯谰谱谲谳谴谵谶豮贝贞负贠贡财责贤败账货质贩贪贫贬购贮贯贰贱贲贳贴贵贶贷贸费贺贻贼贽贾贿赀赁赂赃资赅赆赇赈赉赊赋赌赍赎赏赐赑赒赓赔赕赖赗赘赙赚赛赜赝赞赟赠赡赢赣赪赵趋趱趸"
  + "跃跄跞跶跷跸跹跻踌踬踯蹑蹒蹰蹿躏躜輼车轧轨轩轪轫转轭轮软轰轱轲轳轴轵轶轷轸轹轺轻轼载轾轿辀辁辂较辄辅辆辇辈辉辊辋辌辍辎辏辐辑辒输辔辕辖辗辘辙辚辩辫边辽达迁过迈运还这进远违连迟迳选逊递逦逻遗邓邝"
  + "邬邮邹邺邻郏郐郑郓郦郧郸酂酝酦酱酽酾酿醖释鉴銮錾钅钆钇针钉钊钋钌钍钎钏钐钑钒钓钔钕钖钗钘钙钚钛钜钝钞钟钠钡钢钣钤钥钦钧钨钩钪钫钬钭钮钯钰钱钲钳钴钵钶钷钸钹钺钻钼钽钾钿铀铁铂铃铄铅铆铇铈铉铊铋铌"
  + "铍铎铏铐铑铒铓铔铕铖铗铘铙铚铛铜铝铞铟铠铡铢铣铤铥铦铧铨铩铪铫铬铭铮铯铰铱铲铳铴铵银铷铸铹铺铻铼铽链铿销锁锂锃锄锅锆锇锈锉锊锋锌锍锎锏锐锑锒锓锔锕锖锗锘错锚锛锜锝锞锟锠锡锢锣锤锥锦锧锨锩锪锫锬"
  + "锭键锯锰锱锲锳锴锵锶锷锸锹锺锻锼锽锾锿镀镁镂镃镄镅镆镇镈镉镊镋镌镍镎镏镐镑镒镓镔镕镖镗镘镙镚镛镜镝镞镟镠镡镢镣镤镥镦镧镨镩镪镫镬镭镮镯镰镱镲镳镴镵镶长门闩闪闫闬闭问闯闰闱闲闳间闵闶闷闸闹闺闻闼"
  + "闽闾闿阀阁阂阃阄阅阆阇阈阉阊阋阌阍阎阏阐阑阒阓阔阕阖阗阘阙阚阛队阳阴阵阶际陆陇陈陉陕陧陨险隐隽难雏雠雳雾霁霡霭靓靔靥鞑鞒鞯鞲韦韧韨韩韪韫韬页顶顷顸项顺须顼顽顾顿颀颁颂颃预颅领颇颈颉颊颋颌颍颎颏"
  + "颐频颒颓颔颕颖颗题颙颚颛颜额颞颟颠颡颢颣颤颥颦颧风飏飐飑飒飓飔飕飖飗飘飙飚飞飨餍饣饤饥饦饧饨饩饪饫饬饭饮饯饰饱饲饳饴饵饶饷饸饹饺饻饼饽饾饿馀馁馂馃馄馅馆馇馈馉馊馋馌馍馎馏馐馑馒馓馔馕马驭驮驯驰"
  + "驱驲驳驴驵驶驷驸驹驺驻驼驽驾驿骀骁骂骃骄骅骆骇骈骉骊骋验骍骎骏骐骑骒骓骔骕骖骗骘骙骚骛骜骝骞骟骠骡骢骣骤骥骦骧髅髋髌鬓鬶魇魉鱼鱽鱾鱿鲀鲁鲂鲃鲄鲅鲆鲇鲈鲉鲊鲋鲌鲍鲎鲏鲐鲑鲒鲓鲔鲕鲖鲗鲘鲙鲚鲛鲜鲝"
  + "鲞鲟鲠鲡鲢鲣鲤鲥鲦鲧鲨鲩鲪鲫鲬鲭鲮鲯鲰鲱鲲鲳鲴鲵鲶鲷鲸鲹鲺鲻鲼鲽鲾鲿鳀鳁鳂鳃鳄鳅鳆鳇鳈鳉鳊鳋鳌鳍鳎鳏鳐鳑鳒鳓鳔鳕鳖鳗鳘鳙鳚鳛鳜鳝鳞鳟鳠鳡鳢鳣鳤鸟鸠鸡鸢鸣鸤鸥鸦鸧鸨鸩鸪鸫鸬鸭鸮鸯鸰鸱鸲鸳鸴鸵鸶鸷"
  + "鸸鸹鸺鸻鸼鸽鸾鸿鹀鹁鹂鹃鹄鹅鹆鹇鹈鹉鹊鹋鹌鹍鹎鹏鹐鹑鹒鹓鹔鹕鹖鹗鹘鹙鹚鹛鹜鹝鹞鹟鹠鹡鹢鹣鹤鹥鹦鹧鹨鹩鹪鹫鹬鹭鹮鹯鹰鹱鹲鹳鹴鹾麽黉黡黩黪黾鼋鼌鼍鼹齐齑齿龀龁龂龃龄龅龆龇龈龉龊龋龌龙龚龛龟鿎鿏鿒鿔"
)

#let _LANG-JA-ONLY = (
  "丗両乕乗乢亀亅亊亜亰仏仭仮伜価侫侭俤俥値倶倹偐偖偸働僞儁儖兎児兪円冐冦冨冩冴凖処凧凩凪凾刄刋刔刧剏剣剤剰剱剳劒劔労劵効勅勠勧勲匁匂匳匸卆単厠厰厳収叺呉呑呟呪咲哘唖啌啓啝喞喩喰営噐噛噺嚊嚔嚠嚢囎"
  + "囘団囲図圀圏圦圧圷圸坿垈垉垪垰垳埀埓埖堺塀塁塩塰塲増墸墹墻壊壌壗壜壥壱売壷壻変夊夐夘夛夲奨奬妛妬姉姙姫娚娯嫐嫺嬢嬶宍実寃寉寛寳対専尅尓尠尭屓屶岻岼岾峅峠峩峯峺崕崘嵜嵳嵶嶋嶌嶐巌巓巣巵巻帋帯帰幇"
  + "幤庁広廃廏廐廰廸廻廼弉弌弍弐弖弾彁彑彜徃従徳徴応忰怱怺恊恠恵恷悋悧悩悪悳惣愡愼愽慂慙慯憇憙懐懴戝戞戦戯戸戻払扨抂抜択拝拠拡挙挧挿捜掲掵掻揺摂撃撹擡擧擶攅敍斈斉斎旙昿晄晧晩暁暃暎暦暼曁曵曽朖朞朶"
  + "朷杁杢杣杤枠枡枦枩査柾栂栃栄栞栢桙桜桝桟梍梶梹梺梼棊椀椙椚椛検椡椢椣椦椨椶楕楡楳楽楾榁榊榲槇様槝槞槹樋樌樒樢権樫樮樶橲橸檪櫁欅欝欟歓歩歯歳歴殱殻毎毟気氷汚汢沢浄涙涜渇済渉渋渓渕湶満溂溌滝漑潅澁"
  + "澑濳濶瀞瀬烱焔焼煕熈熕燗燵爲爼牀犂犇犠犲狛狢猟猯獏獣珎珱瑠璢瓧瓰瓱瓲瓸甅甎甞産甼畄畆畉畊畍畑畠畧畩畭畳疂疉疎痩瘻癧癨癶発皀皃皐皷皹県眞眤瞹砕砿硲硴碁碯碵磆礇禝秡稲稾穂穃穉穏穐穣穽窓窰竃竈竍竏竒"
  + "竓竕竚竜竝竡竢竪竰竸笂笶笹筬筺箆箒箚箟篏篭篶簒簓簔簗籏籖籘籾粂粃粋粐粛粧粫粭糀糂糘糺絋経絵絶綉継続綛綫総緑緕緜緤縁縄縅縦繊繋繍繝繦繧繿纃纉纎纐纒罎罸羂羣羮翆聟聡聢聨聴肬脇脳腟膓膤膸臈臓舎舗舘舩"
  + "舮艝艢艪艶苅茘茣荘莟莵菓菷萠萢萪葢蒄蒭蓙蓚蔵蕋蕚薗薫薬蘂蘓蘯蘰蚫蛍蛯蝋蝿蟇蟐蠎蠏蠧衂衆衞袮袰袴袵袿裃裄裏褄褝襃襍襷覇覊覚覧覩観觧訳説読諌諚謌謡譌譛譱譲讃讐谺豼貎貭貮賍賎賛贋赱踈躙躰躱躾軅軆軈転"
  + "軣軽輌輙轌轜辧辷辺辻込迚迯逎逓逧逹遅遖遡邉邨郷酔醗醤醸釈釖釛釟釡釶釼鈎鈩鈬鉄鉢鉱銭銹鋭鋲鋳錬録錺錻鍄鍮鎭鎹鏥鐚鐡鑁鑓鑚鑛閇閊閖閙閠関閧閲闘陥陦険隠隣隲隷雑雫霊靤靫靭靱靹鞆鞐韈韮韲頚頬頴頼頽顋顔"
  + "顕颪飃飜飮餝餠饂馼駄駅駆駈駲騒験騨髄髞髢髪髴鬪鮃鮎鮖鮗鮟鮴鯏鯑鯒鯣鯱鯲鯵鰄鰊鰌鰐鰕鰛鰮鰯鰰鰺鱇鱚鱶鳫鳬鳰鴎鴪鴫鴬鵄鵆鵈鵐鵞鵤鵺鶏鶫鷄鷆鹸麁麕麪麹麺麿黒黙鼈鼡齢龝"
)

#let _LANG-ZH-SUR1 = (
  "丁万上丌世丘业丛东严中丰丹主丽乃义乌乐乔乙乜习书乾于云亓井亢京仁仇仉介从仓付仙仝代令仪仰仲仵任伉伊伍伏会伟传伦伯但位佐佔何佘余佟佳佴侃來侍依侯俊保俞信修俱倉候倪倫倭偉傅傑傕储傲傳僖僧儀儋儲兀允"
  + "元充兆先光克党兜全公兮兰关兴具养冀冉冒军农冠冬冮冯况冶冷冼凌凡凤凯凱刁刑列刘刚初別利别剑剛劉劍力加励劲劳勁勇勒勞勤勵勾包化北匡区匿區千升华卓单南博卜卞占卡卢卫卯印危卲卿历厉厍厐厙厚厝原厥厲及友"
  + "双叠叢古句只可台史叶司合吉同名后向吕君吳吴吾呂员周呼和咸哀哈員哲唐商問啜善喜喬單喻嘉嚴囊回国國圣均坚埃執基堅堯堵塔塗增墨士壽夏夔多夢天太奇奉奎奕奚奥奧好如妙姚姜姬威娄娜婁婴嫪嬰嬴子孔字孙孝孟季"
  + "学孫學宁宇守安宋完宏宓宗官定宛宜宝宣宦宫宮宰家容宾宿密寇富寒寧寶寻寿封将將尉尋尔尚尤尧尹尼居屈展屠山岑岩岱岳峯峰崇崔嵇嶽巖巢左巨巩巫巴布帅师希帖帥師席常干平年幸幹广庄庆库应庚庞庫康庾廉廖廣廬延"
  + "建开弋弓弘张弥張強强彌归彥彦彩彭律後徐從德徽忠念忻忽怀思怡恆恒恩恭息恽悅悦惠惲愛慈慎慕慶應懷戈戎成战戚戢戰戴房扈才执扬扶承把折拓招拜掌採提揚揭撒操支敏敖教敦敬文斐斯方於施旁无日时旷旺昊昌明易昝"
  + "星春晁時晉晋晏晓晨普景智暢暨暴曉曠曲書曹曼曾會月有朋朗望朝木未本朱朴权李杜束来杨杭杰東松极林枚果柏查柯柳柴栎树栗格栾桂桃桑桓梁梅梦棠森植楊楚業極楼榆榮槐樂樊樓樸樹檀櫟權欒欧欽歐正步武歷歸殳段殷"
  + "毋母毓毕毛水永求汉汝江池汤汪汲沃沈沉沐沙河治況法泰洋洗洛洪浦浩浮海涂润淡淩淮淳清渠温游湖湘湛湯源溥溪溫滑滕满滿漆漢潘潛潜潤潭潮濮火烈烏無焦熊燕爱爵爾牙牛牟牧狄玄玉王环珠班理琴瑞璩環甄甘生甯田由"
  + "甲申畅留畢疊白百皇皮益盖盘盛盤盧相真眭睦瞿石碧礼祁祕祖祝神祿禄福禮禹禾秀秋种科秘秦程種稽穆空窦竇立章童端竹竺符笪第答简管節範簡籁籍籟米粘粟粱糜紀紅納素索紫紹終經綠綦緱練繆繼續红纪纳练终绍经继续"
  + "绿缑缪罗羅羊美義羽羿翁習翟翠翦翼耆耿聂聖聞聶肖胡胥能脫脱腾臧自臺興舒良艳艾节芦芮花芳苍苏苑苗苟若英苻范茅茆茶茹荀荆荊荣药荷莊莎莘莫莲菊華萧萨萬葉葛董蒋蒙蒯蒲蒼蓋蓝蓟蓬蓮蔚蔡蔣蔺蕭薄薊薛薩藍藏藤"
  + "藥藺蘆蘇蘭虎虙虞融行衛衡衣补衷袁裏裘補裴褚西要覃見见解言計許訾詩詹談諶諸謝譙譚计许诗诸谈谌谢谭谯谷豆豐豔象貝貢貫貴買費賀賁資賈賓賞賢賴賽贝贡贤贯贲贵费贺贾资赏赖赛赤赫赵超越趙路蹇車軍軒載輝车轩"
  + "载辉辛辜農边达过运还远连迟迪逄通逢連逯遇遊運過道達遠遲還邊邓邝邢那邦邬邮邰邱邴邵邸邹郁郄郈郎郏郑郗郜郝郟郤郦郭郵都鄂鄒鄔鄢鄧鄭鄺酆酈采释釋里野金針鈔鈕銀錢鍾鎖鎮鐘鐵针钞钟钦钮钱铁银锁锺镇長长門"
  + "閃閆閉開閔閩閭閻闊闕關闞门闪闫闭问闵闻闽闾阎阔阙阚阮阳阴阿陆陈陰陳陶陸陽隆隋随隗隨雄雅雍雒雙雪雲雷霍霞青靖静靜靳鞏鞠韋韓韦韩韶項順須顏顓顧项顺须顾颛颜風风飛飞養餘饒饶首香馬馮駱騰马骆高鬱魏魚魯"
  + "鮑鮮鱼鲁鲍鲜鳳鴻鸿鹹鹿麗麥麦麴麹麻黃黄黎黑默黨齊齐龍龎龐龔龙龚龜龟"
)

#let _LANG-ZH-SUR2 = (
  "万俟", "上官", "东方", "东郭", "东门", "乐正", "仉督", "令狐", "仲孙", "仲孫", "公冶", "公孙", "公孫", "公羊", "公良", "公西", "南宫", "南宮", "南門", "南门",
  "司寇", "司徒", "司空", "司馬", "司马", "呼延", "壤駟", "壤驷", "夏侯", "太叔", "夹谷", "夾谷", "宇文", "宗政", "宰父", "尉迟", "尉遲", "左丘", "巫馬", "巫马",
  "归海", "微生", "慕容", "拓跋", "東方", "東郭", "東門", "梁丘", "樂正", "欧阳", "歐陽", "歸海", "段干", "段幹", "淳于", "淳於", "漆雕", "澹台", "澹臺", "濮阳",
  "濮陽", "申屠", "百裏", "百里", "皇甫", "穀梁", "端木", "第五", "羊舌", "聞人", "萬俟", "西門", "西门", "諸葛", "诸葛", "赫连", "赫連", "軒轅", "轩辕", "鍾離",
  "锺离", "長孫", "长孙", "閭丘", "闻人", "闾丘", "顓孫", "颛孙"
)

#let _zh-surname(entry) = {
  let names = entry.parsed_names.at("author", default: ())
  if names.len() == 0 { return "" }
  let family = str(names.first().at("family", default: ""))
  if family.contains("·") or family.contains("・") { return "zh" }
  let han = ""
  for c in family.codepoints() {
    let codepoint = str.to-unicode(c)
    if codepoint >= 0x4E00 and codepoint <= 0x9FFF { han += c }
  }
  if han == "" { return "" }
  let han-clusters = han.clusters()
  let n = han-clusters.len()
  if n >= 2 and _LANG-ZH-SUR2.contains(han-clusters.slice(0, 2).join("")) { return "zh" }
  if n <= 3 and _LANG-ZH-SUR1.contains(han-clusters.at(0)) { return "zh" }
  "ja"
}

#let _LANG-ZH-ONLY-SET = { let d = (:); for c in _LANG-ZH-ONLY.clusters() { d.insert(c, true) }; d }
#let _LANG-JA-ONLY-SET = { let d = (:); for c in _LANG-JA-ONLY.clusters() { d.insert(c, true) }; d }

#let _zh-vs-ja(text) = {
  let zh = false
  let ja = false
  for c in text.codepoints() {
    if c in _LANG-ZH-ONLY-SET { zh = true }
    if c in _LANG-JA-ONLY-SET { ja = true }
  }
  if zh and not ja { "zh" }
  else if ja and not zh { "ja" }
  else { "" }
}

#let bib-has-japanese(bib-data) = {
  for (_k, e) in bib-data {
    let detected-text = _detection-text(e)
    for c in detected-text.codepoints() {
      let codepoint = str.to-unicode(c)
      if (codepoint >= 0x3040 and codepoint <= 0x309F) or (codepoint >= 0x30A0 and codepoint <= 0x30FF) { return true }
      if c in _LANG-JA-ONLY-SET { return true }
    }
  }
  false
}

#let detect-accurate(entry) = {
  let detected-text = _detection-text(entry)
  let scan-result = _scan-detect(detected-text)
  if scan-result == "ja" or scan-result == "ko" or scan-result == "ru" { return scan-result }
  if detected-text.trim() == "" { return "en" }
  if scan-result == "zh" {
    let han-lang = _zh-vs-ja(detected-text)
    if han-lang != "" { return han-lang }
    let surname-lang = _zh-surname(entry)
    if surname-lang != "" { return surname-lang }
    "zh"
  } else {

    let glotter-result = _glotter.detect(detected-text)
    let glotter-lang = if glotter-result.len() > 0 { glotter-result.first().lang } else { "" }
    if glotter-lang == "fr" { "fr" } else { "en" }
  }
}

#let is-cjk-entry(entry) = {
  get(entry) in ("zh", "ja", "ko")
}
