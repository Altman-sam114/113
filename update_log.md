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
- 当前核心文档入口：`AGENTS.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`、`md/prompt/README.md`、`README.md`。
- 当前协作验证：默认 `main` 直推、GitHub Actions 云端重验证和 Agent C 下载未加密 CI 结果包验收；本地仓库当前尚未配置 `origin` remote。

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

### v0.4 / 建立 main 直推云端验证制度

日期：2026-07-03

核心变更：

- 将入口规则升级为角色召唤、身份标识、`main` 直推、GitHub Actions 云端重验证和 Agent C 结果包验收。
- 明确 `main` 是唯一上传、提交、推送和云端验证分支；不引入 `smalldata_test`、`develop`、`codeb/...` 或 PR 合并流。
- 新增 `.github/workflows/ci-results.yml`，在 `main` push 和手动触发时运行静态检查、逻辑烟测、Xcode build-for-testing 和可用模拟器 XCTest，并上传未加密 CI 结果包。
- 新增 `md/prompt/README.md`，记录 `agenta` / `agentb` / `agentc` 召唤约定、Agent A 提示词归档规则和云端阶段要求。
- 同步更新测试规范、核心流程文档、Mermaid 流程图和 README 的协作与云端验证说明。

关键文件：

- `AGENTS.md`
- `.github/workflows/ci-results.yml`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/README.md`
- `README.md`
- `update_log.md`

验证结果：

- 本轮为流程和 CI 制度改造，未修改 Swift 业务源码，未默认重跑本机完整 XCTest。
- `git diff --check`：无输出，退出码 0。
- `find md -maxdepth 4 -type f | sort`：确认 `md/flow/flow.md`、`md/flow/flowchart.md`、`md/prompt/README.md`、历史 prompt 和 `md/test/test.md` 存在。
- `grep -n "Agent A\\|Agent B\\|Agent C\\|README\\|测试规范" AGENTS.md`：确认入口文档覆盖角色规则、README 同步和测试规范入口。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- 当前本地仓库 `git remote -v` 为空，尚未配置 `origin` remote；因此真实 `git push origin main`、GitHub Actions 试跑、`gh run download` 和 Agent C 结果包复判在本轮环境中阻塞，不能伪装为已完成。

遗留事项：

- 配置 `origin` remote 后，按 v0.4 流程执行一次真实 `main` push，等待 `ci-results` workflow 完成，并由 Agent C 下载 `/private/tmp/localgemma-c-review-<run_id>/` 下的结果包核对 manifest、JUnit、日志和 `.xcresult`。
- 若 GitHub-hosted runner 的可用 iPhone Simulator 名称与本地不同，以 workflow 自动选择结果和 manifest 中的 `destination` 为准。

### v0.5 / 修复云端 Swift 6 构建隔离错误

日期：2026-07-03

核心变更：

- 修复 GitHub Actions run `28669343294` 暴露的 `ContentView.swift` Swift 6 actor isolation 构建错误。
- `WallpaperPreferencePanel` 在 `PhotosPicker` label 闭包外先读取 `theme.accent` 和 `theme.inverseText`，闭包内只使用局部颜色值，避免从可发送闭包直接引用 main actor-isolated `@Environment`。
- 本轮不改变 UI 行为、模型 runtime、artifact 校验、会话、壁纸处理或核心流程。

关键文件：

- `LocalGemma/ContentView.swift`
- `README.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project LocalGemma.xcodeproj -scheme LocalGemma -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedDataCodex CODE_SIGNING_ALLOWED=NO build-for-testing`：本机输出 `** TEST BUILD SUCCEEDED **`。
- 本机 CoreSimulator 日志访问仍有沙箱警告，但 generic build-for-testing 成功，不影响本轮修复判断。

遗留事项：

- v0.5 push 后需等待 `ci-results.yml` 最新 run 完成，下载结果包核对 manifest、JUnit、日志和 `.xcresult`。
