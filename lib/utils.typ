// 通用工具

// ── 字体配置 ──

#let 字体 = (
  宋体混排: (
    (name: "Times New Roman", covers: "latin-in-cjk"),
    "SimSun",
  ),
  黑体: (
    (name: "Arial", covers: "latin-in-cjk"),
    "SimHei",
  ),
  黑体混排: (
    (name: "Times New Roman", covers: "latin-in-cjk"),
    "SimHei",
  ),
)

// ── 封面共享工具 ──

// 分散对齐：将中文以指定宽度显示，每个字之间用均匀空隙填充
#let distribute(width: 4em, body) = box(
  width: width,
  body + linebreak(justify: true),
)

// 中文字符间插空格：full: false 用半角(0.5em)，full: true 用全角(1em)
#let char-space(full: false, body) = {
  let chars = body.clusters()
  chars.filter(c => c != " ").intersperse(if full { h(1em) } else { h(0.5em) }).join()
}

// 页面标题映射：key => (中文, 英文)
#let page-title-map = (
  abstract: ("摘要", "Abstract"),
  abstract-en: ("ABSTRACT", "ABSTRACT"),
  outline: ("目录", "Contents"),
  references: ("参考文献", "References"),
  acknowledgement: ("致谢", "Acknowledgements"),
  appendix: ("附录", "Appendix"),
  design-summary: ("毕业设计小结", "Design Summary"),
  academic-achievements: ("在学期间取得的学术成果和参加科研情况", "Academic Achievements and Research Experience"),
)

// 统一页面标题：根据 key 返回对应标题，两字标题自动插空格
#let page-title(key, graduate: false, english-writing: false) = {
  let entry = page-title-map.at(key)
  let zh-title = entry.at(0)
  if english-writing {
    entry.at(1)
  } else if zh-title != none and zh-title.clusters().len() == 2 {
    if graduate { char-space(full: true, zh-title) } else { char-space(zh-title) }
  } else {
    zh-title
  }
}

#let mask-value(body, anonymous: false) = {
  if anonymous { "***" } else { body }
}

// 信息行：标签 + 下划线值（用于封面表格）
#let info-row(label, value, stroke-width: 0.5pt) = (
  table.cell(align(bottom)[#label]),
  table.cell(stroke: (bottom: stroke-width), align(bottom)[#value]),
)

// 显示中文日期（无前导零），date 为 (year, month, day?) 数组
#let datetime-display(date) = {
  str(date.at(0)) + " 年 " + str(date.at(1)) + " 月" + if date.at(2, default: none) != none {
    " " + str(date.at(2)) + " 日"
  }
}

// 显示英文年月（如 March/2026），date 为 (year, month) 数组
#let datetime-display-en(date) = {
  let months = ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
  months.at(date.at(1) - 1) + "/" + str(date.at(0))
}

// 全盲评阅条目（三个字段固定）
#let blind-review = ("全盲评阅", "无", "无")

// 学科专业中英文名称对照（仅含西北工业大学开设专业）
// 来源：NWPU 2026 博士 / 2025 硕士招生简章
#let major-en-map = (
  "应用经济学": "Applied Economics",
  "统计学": "Statistics",
  "法学": "Science of Law",
  "马克思主义理论": "Theory of Marxism",
  "教育学": "Education",
  "教育技术学": "Education Technology",
  "体育学": "Physical Education and Sport Science",
  "外国语言文学": "Foreign Languages and Literatures",
  "英语语言文学": "English Language and Literature",
  "德语语言文学": "German Language and Literature",
  "外国语言学及应用语言学": "Linguistics and Applied Linguistics in Foreign Languages",
  "数学": "Mathematics",
  "物理学": "Physics",
  "凝聚态物理": "Condensed Matter Physics",
  "声学": "Acoustics",
  "光学": "Optics",
  "化学": "Chemistry",
  "有机化学": "Organic Chemistry",
  "物理化学": "Physical Chemistry",
  "高分子化学与物理": "Chemistry and Physics of Polymers",
  "生物学": "Biology",
  "生态学": "Ecology",
  "力学": "Mechanics",
  "机械工程": "Mechanical Engineering",
  "机械制造及其自动化": "Mechanical Manufacture and Automation",
  "机械电子工程": "Mechatronic Engineering",
  "机械设计及理论": "Mechanical Design and Theory",
  "车辆工程": "Vehicle Engineering",
  "光学工程": "Optical Engineering",
  "材料物理与化学": "Materials Physics and Chemistry",
  "材料学": "Materialogy",
  "材料加工工程": "Materials Processing Engineering",
  "动力工程及工程热物理": "Power Engineering and Engineering Thermophysics",
  "工程热物理": "Engineering Thermophysics",
  "热能工程": "Thermal Power Engineering",
  "动力机械及工程": "Power Machinery and Engineering",
  "流体机械及工程": "Fluid Machinery and Engineering",
  "电气工程": "Electrical Engineering",
  "电子科学与技术": "Electronic Science and Technology",
  "信息与通信工程": "Information and Communication Engineering",
  "通信与信息系统": "Communication and Information Systems",
  "信号与信息处理": "Signal and Information Processing",
  "控制科学与工程": "Control Science and Engineering",
  "计算机科学与技术": "Computer Science and Technology",
  "建筑学": "Architecture",
  "土木工程": "Civil Engineering",
  "交通运输工程": "Transportation Engineering",
  "船舶与海洋工程": "Naval Architecture and Ocean Engineering",
  "航空宇航科学与技术": "Aerospace Science and Technology",
  "航空宇航推进理论与工程": "Aerospace Propulsion Theory and Engineering",
  "兵器科学与技术": "Armament Science and Technology",
  "环境工程": "Environmental Engineering",
  "生物医学工程": "Biomedical Engineering",
  "软件工程": "Software Engineering",
  "网络空间安全": "Cyberspace Security",
  "化学工程": "Chemical Engineering",
  "化学工艺": "Chemical Technology",
  "应用化学": "Applied Chemistry",
  "药学": "Pharmaceutical Science",
  "管理科学与工程": "Management Science and Engineering",
  "工商管理学": "Business Administration",
  "公共管理学": "Public Administration",
  "集成电路科学与工程": "Integrated Circuit Science and Engineering",
  "设计学": "Design Science",
  "应用统计": "Applied Statistics",
  "教育": "Education",
  "文物": "Cultural Heritage",
  "工商管理": "Business Administration",
  "公共管理": "Public Administration",
  "会计": "Professional Accounting",
  "工程管理": "Engineering Management",
  "新一代电子信息技术（含量子技术等）": "New Generation Electronic Information Technology",
  "新一代电子信息技术": "New Generation Electronic Information Technology",
  "通信工程（含宽带网络、移动通信等）": "Communication Engineering",
  "通信工程": "Communication Engineering",
  "集成电路工程": "Integrated Circuit Engineering",
  "计算机技术": "Computer Technology",
  "控制工程": "Control Engineering",
  "仪器仪表工程": "Instrument and Meter Engineering",
  "光电信息工程": "Optoelectronic Information Engineering",
  "人工智能": "Artificial Intelligence",
  "网络与信息安全": "Network and Information Security",
  "航空工程": "Aeronautical Engineering",
  "航天工程": "Astronautical Engineering",
  "船舶工程": "Ship Engineering",
  "兵器工程": "Arms Engineering",
  "工业设计工程": "Industrial Design Engineering",
  "智能制造技术": "Intelligent Manufacturing Technology",
  "机器人工程": "Robotics Engineering",
  "材料工程": "Materials Engineering",
  "动力工程": "Power Engineering",
  "航空发动机工程": "Aero Engine Engineering",
  "航天动力工程": "Aerospace Power Engineering",
  "清洁能源技术": "Clean Energy Technology",
  "生物技术与工程": "Biotechnology and Bioengineering",
  "道路交通运输": "Road Transportation",
  "航空交通运输": "Air Transportation",
  "微机电系统及纳米技术": "MEMS and Nanotechnology",
  "工业设计": "Industrial Design",
  "工业工程": "Industrial Engineering",
  "柔性电子学": "Flexible Electronics",
  "无人系统科学与技术": "Unmanned Systems Science and Technology",
  "低空技术与工程": "Low Altitude Technology and Engineering",
  "智能科学与工程": "Intelligent Science and Engineering",
  "航空宇航制造工程": "Aerospace Manufacturing Engineering",
  "风能和太阳能系统及工程": "Wind and Solar Energy Systems and Engineering",
  "工业工程与管理": "Industrial Engineering and Management",
  "英语笔译": "English Translation",
  "英语口译": "English Interpreting",
)
