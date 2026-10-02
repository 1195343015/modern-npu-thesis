# 贡献指南

感谢你为 `modern-npu-thesis` 做出贡献。

本项目是西北工业大学学位论文的 Typst 模板仓库。贡献内容可以包括：

- 修复排版问题、编号问题、页眉页脚问题。
- 补充或调整本硕博模板功能。
- 改进 README、迁移说明和使用文档。
- 增加测试样例或修复跨平台编译问题。

## 仓库结构

- [lib/](lib)：模板实现代码，页面布局、样式、工具函数等主要逻辑都在这里。
- [template/](template)：模板示例入口与示例内容，也是用户初始化后最常修改的目录。
- [template.typ](template.typ)：模板包入口。
- [typst.toml](typst.toml)：Typst 包元信息。
- [fonts/](fonts)：仓库内置字体资源。
- [.github/workflows/test.yml](.github/workflows/test.yml)：CI 编译检查。

如果你是在修模板实现，通常应该改 `lib/`、`template.typ`、`typst.toml` 或文档；不要随意把用户写作内容和模板实现混在一起。

## 开发环境

推荐环境：

- VS Code 或类 VS Code 编辑器（如 Cursor、Qoder 等）
- Tinymist Typst 插件
- Typst `0.15.1`

仓库自带 [.vscode/settings.json](.vscode/settings.json)，会自动追加 `--font-path fonts`。

## 本地验证

提交前建议至少完成一次模板编译检查：

```powershell
typst compile --root . --font-path fonts template/graduate/main.typ dist/thesis.pdf
```

如果你在验证模板包入口，也可以执行：

```powershell
typst compile --root . --package-cache-path .typst/packages --font-path fonts template/graduate/main.typ dist/thesis-template.pdf
```

如果改动影响本科模板、页眉页脚、目录、参考文献、附录、封面等公共部分，建议同时检查本科与研究生示例。

## 提交建议

- 一次提交只解决一类问题，避免把无关调整混在一起。
- 提交信息尽量直接说明行为，例如 `Fix graduate header spacing`、`Unify graduate heading layout`。
- 修改样式或布局时，优先保持本科/研究生两套逻辑边界清晰。
- 修改公共变量时，注意检查是否会影响摘要、目录、致谢、参考文献、附录等多个页面。

## Pull Request 建议

提交 PR 时，建议在描述中说明：

1. 修改动机。
2. 影响范围。
3. 本地如何验证。
4. 是否涉及视觉变化。

如果改动是排版类修复，最好附上修改前后截图或生成 PDF 对比说明。

## 文档与迁移

如果你的改动会影响用户升级模板的方式，记得同步更新 [README.md](README.md) 中的说明。

当前仓库的升级原则是：用户通常只需要保留自己的 [template/](template) 目录，并用新版仓库替换其余文件。
