# 项目版本更新记录

本文记录项目正式版本、重要维护事项、关键决策和遗留问题。它不是流水账；只记录对后续迭代有价值的事实。

## 维护规则

- 每完成一个正式版本或重要任务后追加记录。
- 记录必须包含：版本/任务名、日期、核心变更、关键文件、验证结果、遗留事项。
- 文档整理、目录迁移、回滚、打捞等不伪装成新版本，可写入“历史维护记录”。
- 若核心逻辑、测试规范或项目行为变化，必须同步更新本日志。
- 任何测试结果都必须写具体命令和结果，不写空泛“已验证”。

## 当前状态

- 项目：`Local Gemma iOS Prototype`
- 平台：SwiftUI iOS App，Swift 6.0，iOS deployment target 17.0。
- 当前默认模型：`Gemma 1.5B Local`
- 当前推理：本地模拟 runtime，不下载模型权重，不执行真实模型推理。
- 当前核心测试：`LocalGemmaTests.swift` 中 32 个 XCTest 方法。
- 当前核心文档入口：`AGENTS.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`、`README.md`。

## 历史记录

### v0.1 / 初始 iOS 原型

日期：2026-06-25 前后

核心变更：

- 建立 `LocalGemma.xcodeproj` SwiftUI iOS 工程。
- 实现模型清单、artifact manifest、本地导入、SHA-256 校验、missing/staged/verified 状态。
- 实现默认模拟推理 runtime、真实 runtime 占位、运行计划、会话管理、Markdown 导出。
- 实现推理、模型、提示词、设置工作区。
- 实现横屏分栏、相册壁纸、分享兜底和 Apple Silicon 优化面板。

关键文件：

- `LocalGemma/AppState.swift`
- `LocalGemma/ContentView.swift`
- `LocalGemma/LocalGemmaApp.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `Tools/LogicSmoke.swift`
- `README.md`

验证结果：

- `LocalGemmaTests.swift` 当前包含 32 个 XCTest 方法。
- 曾使用 iPhone 17 模拟器执行 `test-without-building`，结果为 `TEST EXECUTE SUCCEEDED`。
- 曾执行 `build-for-testing`，结果为 `TEST BUILD SUCCEEDED`。
- 具体最新基线以后以 `md/test/test.md` 和 README 的“已完成验证”章节为准。

遗留事项：

- README 中部分测试数量和验证描述可能落后，应在下一次功能迭代前同步。
- `AppState.swift` 和 `ContentView.swift` 文件偏大，后续扩展时建议按功能拆分。
- 真实模型 runtime 仍是占位，接入前必须明确模型格式、tokenizer、SHA-256 来源、内存预算、后端 fallback 和隐私边界。
- 尚无 UI Test target；复杂分享、相册权限和横屏交互可逐步补 UI tests。

### v0.2 / 建立多 Agent 协作与核心文档体系

日期：2026-06-28

核心变更：

- 将项目入口记忆升级为 `AGENTS.md`。
- 创建 `update_log.md` 记录版本、决策和遗留事项。
- 创建 `md/test/test.md` 作为测试分层和命令基线。
- 创建 `md/flow/flow.md` 作为当前真实核心逻辑文档。
- 创建 `md/flow/flowchart.md` 作为 Mermaid 可视化流程图。
- 创建 `md/prompt/v0（项目管理体系）/v0.2（建立多Agent协作规范）.md` 作为 Agent A 提示词归档示例和本轮文档任务记录。

关键文件：

- `AGENTS.md`
- `update_log.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（项目管理体系）/v0.2（建立多Agent协作规范）.md`
- `README.md`

验证结果：

- 文档结构检查：`find md -maxdepth 4 -type f | sort`
- 入口规则检查：`grep -n "Agent A\\|Agent B\\|Agent C\\|README\\|测试规范" AGENTS.md`
- 本轮为文档体系搭建，未修改 Swift 源码，未重跑 XCTest。

遗留事项：

- 下一轮代码任务前，Agent A/B/C 必须按新文档体系运行。
- README 的“已完成验证”章节仍建议同步到最新 32 个 XCTest 基线。

### v0.3 / 完善 Agent C 版本提交规则

日期：2026-06-29

核心变更：

- 将 Agent C 职责扩展为“验收、核心逻辑更新与版本提交”。
- 明确 Agent C 不通过时必须列出阻塞问题并退回 Agent B 修复，不允许提交。
- 明确 Agent C 最终通过后按版本号自动创建 git commit。
- 新增版本提交规则：提交主题使用 `<版本号>: <一句话概括>`，提交正文简要汇报核心变更、关键文件、验证结果和遗留事项。
- 要求提交前复核 `git status --short` 和 diff，只提交本版本相关文件。

关键文件：

- `AGENTS.md`
- `update_log.md`

验证结果：

- 本轮为文档工作流调整，未修改 Swift 源码，未跑 XCTest。
- 已执行 `git status --short` 确认修改前工作区干净。

遗留事项：

- 后续 Agent C 在正式验收通过后，应按本规则实际执行版本提交，并在交付中报告 commit hash。
