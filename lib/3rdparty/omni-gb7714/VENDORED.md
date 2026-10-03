# vendored omni-gb7714

- 上游：<https://github.com/typst-omni-gb7714/omni-gb7714>
- 来源：fork `1195343015/omni-gb7714` 分支 `poc-combined`（= 上游 commit `e7301af` + 本地修复分支
  `fix-16-guard-literal`、`fix-17-apostrophe`、`fix-18-family-case`、`feat-date-range-separator` 的合并）
- 对应上游 PR：#20、#21、#22、#24（合并后可切换到上游发布版本）
- 许可：Apache-2.0（见 LICENSE / NOTICE；捆绑的 citegeist fork 为 MIT）

## 本地补丁（相对上游的差异）

1. `src/parse/biblatex.typ:1`：根绝对导入 `"/citegeist/lib.typ"` 改为相对路径
   `"../../citegeist/lib.typ"`（Universe 包根语义在本地 vendoring 下不成立）。

2. `src/parse/guard.typ`：新增 `_g-pos` 助手，并把 `_g-skip`、`_g-read-value` 由 `while`
   改写为无循环实现（`position` / `slice` / `map`）。原因是 Tinymist LSP 在分析
   「循环体内调用了自身含循环的函数」时会栈溢出（`tokio-rt-worker`），本包经
   `api.typ` 必然命中；去掉这两处循环即可规避。
   已验证：新旧实现对 token 类型 × 标点做穷举对拍一致；本科/研究生样刊提取文本逐字一致。
   上游修好后可移除。参见 <https://github.com/Myriad-Dreamin/tinymist/issues/2731>。

## 更新流程

1. 上游合并相关 PR 并发布新版本后，整体替换本目录（保留本文件与上述补丁，若上游未吸收）；
2. 或同步 fork `poc-combined` 后重新打补丁。
