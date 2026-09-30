<div align="center">

**西北工业大学本硕博论文 Typst 模板**

***modern-npu-thesis***

[![CI](https://github.com/1195343015/modern-npu-thesis/actions/workflows/test.yml/badge.svg)](https://github.com/1195343015/modern-npu-thesis/actions/workflows/test.yml)
[![Nightly Built PDF](https://img.shields.io/badge/Preview-预览PDF_-C9CBFF?style=flat&logo=view&logoColor=D9E0EE&labelColor=302D41)](https://nightly.link/1195343015/modern-npu-thesis/workflows/test/main/thesis-pdf.zip)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

> 如果你想使用 LaTeX 模板，请移步 [nwputhesis](https://github.com/1195343015/nwputhesis)。

### 优势与特性

- **语法简洁**：上手难度与 Markdown 相当，无需记忆繁琐的命令。
- **极速编译**：毫秒级编译，百页论文即时预览。
- **环境简单**：即开即用，无需配置数 G 的开发环境。
- **生态丰富**：国内多所高校已有 Typst 论文模板，详见 [cn-university-typst-thesis-templates](https://github.com/1195343015/cn-university-typst-thesis-templates)。

### 使用方法

1. Fork 本仓库到自己的账号下，然后克隆 Fork 后的仓库。（方便后续同步模板更新。）
2. 使用 VS Code 打开项目，并安装 [Tinymist Typst](https://marketplace.visualstudio.com/items?itemName=myriad-dreamin.tinymist) 插件。
3. 打开项目后：
   分别修改 [template/graduate.typ](template/graduate.typ) 和 [template/bachelor.typ](template/bachelor.typ) 可编辑研究生或本科生论文。

非 Windows 系统用户需要另外下载 [`fonts`](https://github.com/1195343015/nwputhesis-fonts) 子模块。

#### 依赖包

本模板依赖以下 Typst 包，具体用法有疑惑可直接查阅相关文档：

- [`gb7714-bilingual`](https://typst.app/universe/package/gb7714-bilingual) `基于 Github main 分支的修改版本` — GB/T 7714 双语参考文献格式
- [`algorithmic`](https://typst.app/universe/package/algorithmic) `1.0.7` — 伪代码/算法排版
- [`cap-able`](https://typst.app/universe/package/cap-able) `0.1.1` — 图/表
- [`pointless-size`](https://typst.app/universe/package/pointless-size) `0.1.2` — 中文字号

### QQ 交流群

<img src="template/figures/QQ交流群.png" width="200">

> 本模板基于 [modern-nju-thesis](https://github.com/nju-lug/modern-nju-thesis) 开发，设计过程中还参考了 [pkuthss-typst](https://github.com/pku-typst/pkuthss-typst) 的实现。

### License

MIT License

Copyright (c) 2024 OrangeX4

Copyright (c) 2026 Jiayi Yan
