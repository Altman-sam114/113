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
- 平台：SwiftUI iOS App，Swift 6.0，iOS deployment target 17.0，当前 app/test target 支持 iPhone、iPad 和 Mac Catalyst build-for-testing，并提供项目内 Mac Catalyst 本地 build/run 脚本入口；尚未创建原生 macOS target。
- 当前默认模型：`Gemma 1.5B Local`
- 当前推理：本地模拟 runtime，不下载模型权重，不执行真实模型推理。
- 当前核心测试：`LocalGemmaTests.swift` 中 43 个 XCTest 方法。
- 当前核心文档入口：`AGENTS.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`、`md/prompt/README.md`、`README.md`。
- 当前协作验证：默认 `main` 直推、GitHub Actions 云端重验证和 Agent C 下载未加密 CI 结果包验收；本地仓库当前已配置 `origin` remote，最终验收仍以最新 `origin/main` 对应的 GitHub Actions run 和结果包为准；文档已预留未来 `agentx:` 主控 Agent A -> Agent B -> Agent C 多轮循环的规则。

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

- 后续已配置 `origin` remote；真实云端闭环应按最新版本 push 后的 `ci-results` run 和 Agent C 下载结果包复判为准。
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

### v0.6 / 修复 CI 结果包版本追踪

日期：2026-07-03

核心变更：

- 将 `.github/workflows/ci-results.yml` 的 `CI_VERSION` 从固定 `v0.4` 改为从最新 commit 主题开头的 `vX.Y` 自动提取。
- 同步更新 `md/test/test.md` 和 README，说明 artifact 命名使用 commit 版本号。
- 本轮不改业务源码、模型 runtime、artifact 校验或 UI 行为。

关键文件：

- `.github/workflows/ci-results.yml`
- `md/test/test.md`
- `README.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `rg -n "localgemma-ci-|CI_VERSION|version\\\": \\\"v|v0.6|v0.4" .github/workflows/ci-results.yml md/test/test.md README.md update_log.md`：确认 workflow、测试规范和 README 均说明 commit 版本号驱动 artifact 命名，历史 v0.4 仅保留在对应历史记录中。
- v0.6 push 后需等待 `ci-results.yml` 最新 run 完成，确认 manifest `version`、artifact 名称、`commitSha`、`runId` 和 `runAttempt` 均与最新 `origin/main` 对齐。

遗留事项：

- 无业务遗留；若 GitHub Actions runner 改变默认 macOS / Xcode 版本，以结果包 `environment.log` 为准。

### v0.7 / 校准云端验收闭环

日期：2026-07-03

核心变更：

- 修正 README 和当前状态记录中“尚未配置 origin remote”的过期描述，明确当前本地仓库已配置 `origin`，但最终验收仍以最新 GitHub Actions run 和 Agent C 下载结果包为准。
- 强化 `.github/workflows/ci-results.yml` 的结果包自描述能力：manifest 增加 `artifactName`、`repository`、`commitSubject`、`runUrl`，并继续记录 `staticChecksOutcome`、`logicSmokeOutcome`、`buildOutcome`、`testOutcome` 和 `destination`。
- 将 `artifact-name.txt` 提前生成，manifest、failure summary 和 artifact upload 共用同一个 artifact 名称，降低 Agent C 错验旧包的风险。
- 同步更新测试规范、核心流程文档、Mermaid 流程图和 README 的 Agent C 验收字段要求。
- 新增本轮 Agent A 提示词归档 `md/prompt/v0（云端验收闭环）/v0.7（云端验收闭环与文档校准）.md`。
- 本轮不改 Swift 业务源码、模型 runtime、artifact 校验、UI 行为或 XCTest 基线。

关键文件：

- `.github/workflows/ci-results.yml`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（云端验收闭环）/v0.7（云端验收闭环与文档校准）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `find md -maxdepth 4 -type f | sort`：确认 v0.7 Agent A 提示词和核心文档仍在归档结构内。
- `grep -n "Agent A\\|Agent B\\|Agent C\\|README\\|测试规范" AGENTS.md`：确认入口文档仍覆盖角色规则、README 和测试规范入口。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `rg -n "artifactName|commitSubject|runUrl|logicSmokeOutcome|localgemma-ci-|当前仓库|origin remote|v0.7" .github/workflows/ci-results.yml README.md md/test/test.md md/flow/flow.md md/flow/flowchart.md update_log.md`：确认 workflow 和文档均覆盖 v0.7 结果包字段、origin 当前状态和 artifact 命名。

遗留事项：

- v0.7 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、日志和 `.xcresult`。

### v0.8 / iPad宽屏与Mac准备度

日期：2026-07-04

核心变更：

- 将未提交文档中冲突的 `v0.5 / 引入 Agent X 循环迭代文档基线` 校准为 `v0.8`；最新已提交版本仍是 `v0.7`，历史 `v0.5 / 修复云端 Swift 6 构建隔离错误` 不改写。
- 新增 Agent X 召唤、职责、循环判断和停止条件，并用本轮目标启动 Agent X -> Agent A -> Agent B -> Agent C 的第一轮闭环。
- 将 `LocalGemma` app target 和 `LocalGemmaTests` test target 扩展为 iPhone+iPad。
- 调整 `WorkspaceLayoutMode`，按容器尺寸进入单栏、compact 双栏或 regular 大屏双栏；iPad Pro 竖屏和大屏窗口可进入 regular 大屏双栏。
- 新增 iPad Pro 竖屏、大屏窗口和中等 iPad 竖屏布局测试，测试函数数从 32 个增加到 33 个。
- 同步 flow、flowchart、test、prompt README、README 和入口文档中的 Agent X、iPhone+iPad、大屏断点和小数据量 artifact 规则。
- 本轮没有创建 Mac 独立 target 或 Mac Catalyst target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `AGENTS.md`
- `LocalGemma.xcodeproj/project.pbxproj`
- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/README.md`
- `md/prompt/v0（适配体验）/v0.8（iPad宽屏与Mac准备度）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 33 个 `test...` 方法。
- `find md -maxdepth 4 -type f | sort`：确认 v0.8 Agent A 提示词和核心文档仍在归档结构内。
- `rg -n "TARGETED_DEVICE_FAMILY|WorkspaceLayoutMode|iPad|iPhone\\+iPad|v0.8|Mac" ...`：确认工程、源码、测试和文档均覆盖 iPhone+iPad、布局断点、v0.8 和 Mac 非目标说明。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck ... LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module ... LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck ... LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。
- 本轮未默认重跑本机完整 `xcodebuild build-for-testing` 或模拟器 XCTest；完整 build/test 由 push 后 GitHub Actions 结果包和 Agent C 下载复判负责。

遗留事项：

- v0.8 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、日志和 `.xcresult`。
- Mac 方向仍是后续目标；启用 Mac Catalyst 或独立 macOS target 前，需要单独审计 `UIKit`、`PhotosPicker`、分享、剪贴板和文件导入路径。

### v0.9 / Mac Catalyst基线验证

日期：2026-07-04

核心变更：

- 选择 Agent A 提示词中的路径 A：Mac Catalyst。原因是启用 `SUPPORTS_MACCATALYST` 后，`LocalGemma` scheme 已出现 Mac Catalyst destination，本机 Mac Catalyst `build-for-testing` 成功。
- `LocalGemma` app target 和 `LocalGemmaTests` test target 的 Debug / Release 配置启用 `SUPPORTS_MACCATALYST = YES`，并为 iPad Info.plist 支持四方向，修复 Mac 上 Designed for iPad/iPhone 兼容性警告。
- 新增桌面窗口尺寸布局测试，锁住 `1280x800`、`1024x768` 进入 regular 大屏双栏，`760x720` 进入 compact 双栏，`680x900` 回退单栏；测试函数数从 33 个增加到 34 个。
- `.github/workflows/ci-results.yml` 增加 Mac Catalyst `build-for-testing` 步骤，结果包新增 `mac-catalyst-build.log`、`mac-baseline-notes.md`、`LocalGemma-maccatalyst-build.xcresult` 以及 manifest 的 `macBaselineKind`、`macCatalystBuildOutcome`、`macCatalystDestination`、`macCatalystBuildLogPath`、`macCatalystResultBundlePath`、`macCatalystSkippedReason`、`macDesignedForIPadOutcome` 和 `macBaselineNotesPath`。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图和入口规则中的 Mac Catalyst 构建基线边界。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `AGENTS.md`
- `LocalGemma.xcodeproj/project.pbxproj`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/test/test.md`
- `md/prompt/v0（适配体验）/v0.9（Mac Catalyst基线验证）.md`
- `update_log.md`

验证结果：

- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project LocalGemma.xcodeproj -scheme LocalGemma -showdestinations`：输出包含 `variant:Mac Catalyst` 和 `variant:Designed for [iPad,iPhone]`。
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project LocalGemma.xcodeproj -scheme LocalGemma -configuration Debug -sdk macosx -destination 'generic/platform=macOS,variant=Mac Catalyst' -derivedDataPath .build/DerivedDataCodex-Catalyst -resultBundlePath .build/LocalGemma-maccatalyst-build.xcresult CODE_SIGNING_ALLOWED=NO build-for-testing`：输出 `** TEST BUILD SUCCEEDED **`。
- `git diff --check`：无输出，退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- 从 `.github/workflows/ci-results.yml` 提取 `Generate manifest, JUnit, and failure summary` 内嵌 Python 并执行 `python3 -m py_compile`：退出码 0。
- 用临时 outcomes 目录 mock 运行内嵌 Python：manifest 输出 `macCatalystRunEntrypoint=script/build_and_run.sh`、`macCatalystRunScriptCheckOutcome=success`、`codexRunEnvironmentCheckOutcome=skipped`、`codexRunEnvironmentSkippedReason=not-added-in-v1.0-cli-entrypoint-only`，JUnit suite 输出 `tests=7 failures=0 skipped=1`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 34 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck ... LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module ... LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck ... LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -quiet -project LocalGemma.xcodeproj -scheme LocalGemma -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedDataCodex-iOS-v09c -resultBundlePath .build/LocalGemma-ios-build-v09c.xcresult CODE_SIGNING_ALLOWED=NO build-for-testing`：沙箱内受 CoreSimulator/Xcode 服务权限影响返回 133；按审批在沙箱外重跑同一命令后退出码 0。

遗留事项：

- v0.9 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、baseline notes 和 `.xcresult`。
- 当前仅建立 Mac Catalyst build-for-testing 基线，不代表原生 macOS target 或真实模型 runtime 已完成。

### v1.0 / Mac Catalyst窗口与交互基线

日期：2026-07-04

核心变更：

- 新增 `script/build_and_run.sh`，作为项目内 Mac Catalyst 本地 build/run 入口；支持 `run`、`--build-only`、`--verify`、`--logs`、`--telemetry`、`--debug` 和 `--help`。
- 脚本使用 `LocalGemma.xcodeproj`、`LocalGemma` scheme、`platform=macOS,variant=Mac Catalyst` destination 和 `.build/DerivedDataCodex-MacCatalystRun`，默认会停止旧进程、构建 Debug Catalyst app 并通过 `/usr/bin/open -n` 启动。
- 修正脚本 stdout/stderr 边界：`xcodebuild` 输出走 stderr，stdout 只保留最终 `.app` 路径，避免 `--verify` 把 build log 当作 app bundle 路径。
- `.github/workflows/ci-results.yml` 新增 Mac Catalyst run script contract step，检查 `script/build_and_run.sh` 存在、可执行且 `bash -n` 通过；CI 结果包新增 `mac-catalyst-run-script.log`。
- CI manifest、JUnit 和 failure summary 增加 `macCatalystRunEntrypoint`、`macCatalystRunScriptCheckOutcome`、`macCatalystRunScriptLogPath`、`codexRunEnvironmentPath`、`codexRunEnvironmentCheckOutcome` 和 `codexRunEnvironmentSkippedReason`。
- 本轮未提交 `.codex/environments/environment.toml`，因为当前 Codex 沙箱下项目内 `.codex` 路径不可写；CI 将 Codex Run action 检查记录为 `skipped`，原因是 `not-added-in-v1.0-cli-entrypoint-only`。
- 本轮未修改 Swift UI 行为，未新增 XCTest，`LocalGemmaTests.swift` 仍为 34 个测试函数；没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `script/build_and_run.sh`
- `.github/workflows/ci-results.yml`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v1（Mac体验审计）/v1.0（Mac Catalyst窗口与交互基线）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -f script/build_and_run.sh`：退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 34 个 `test...` 方法。
- `find md -maxdepth 4 -type f | sort`：确认 v1.0 Agent A 提示词和核心文档仍在归档结构内。
- `rg -n "build_and_run|macCatalystRunEntrypoint|macCatalystRunScriptCheckOutcome|codexRunEnvironment|Mac Catalyst|v1.0" script .github/workflows/ci-results.yml README.md md/test/test.md md/flow/flow.md md/flow/flowchart.md update_log.md AGENTS.md`：确认脚本、workflow 和文档均覆盖 v1.0 run 入口、结果包字段和 Codex Run action 跳过原因。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `./script/build_and_run.sh --build-only`：退出码 0，输出 `.build/DerivedDataCodex-MacCatalystRun/Build/Products/Debug-maccatalyst/LocalGemma.app`；沙箱内仍有 CoreSimulator 日志警告，但 Mac Catalyst build 成功。
- `./script/build_and_run.sh --verify`：按审批在沙箱外执行，退出码 0；脚本成功构建、启动并通过 `pgrep -x LocalGemma` 验证进程存在。

遗留事项：

- v1.0 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- Codex Run action 文件仍未提交；后续如果项目内 `.codex/environments/` 可写，可追加 `.codex/environments/environment.toml` 并将 Run action 指向 `./script/build_and_run.sh`。
- 当前仍仅是 Mac Catalyst build/run 基线，不代表原生 macOS target 或真实模型 runtime 已完成。

### v1.1 / Mac iPad键盘导航基线

日期：2026-07-04

核心变更：

- 为 `WorkspaceTab` 增加 `shortcutKey` 映射，锁住 `Command+1` 推理、`Command+2` 模型、`Command+3` 提示词、`Command+4` 设置。
- 为顶部 tab picker 和侧栏 tab picker 添加 SwiftUI `keyboardShortcut`，让 Mac Catalyst 和 iPad 外接键盘可直接切换工作区。
- 为会话栏导出按钮添加 `Command+Shift+E`，为新建会话按钮添加 `Command+N`。
- 为 composer 发送/停止按钮添加 `Command+Return`，继续尊重空 prompt 禁用和生成中停止逻辑。
- 新增 `testWorkspaceTabsExposeKeyboardShortcuts`，测试函数数从 34 个增加到 35 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图和入口规则中的 Mac/iPad 键盘导航基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v1（Mac体验审计）/v1.1（Mac iPad键盘导航基线）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 35 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v1.1 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立快捷键基线，没有新增 CommandMenu 或 responder-chain 层；后续如需要更完整 Mac 菜单，可另起小目标。

### v1.2 / Mac iPad命令菜单发现层

日期：2026-07-04

核心变更：

- `LocalGemmaApp` 在 `WindowGroup` scene 层新增 `工作区` command menu，提供推理、模型、提示词、设置四个工作区命令。
- `ContentView` 通过 focused scene binding 暴露 `selectedTab`，command menu 只切换 workspace，不触碰模型、artifact、runtime 或会话状态。
- `WorkspaceTab` 增加 `commandMenuTitle`、`commandTitle` 和 `commandItems` 元数据，command menu 与 v1.1 `Command+1...4` 快捷键复用同一 source of truth。
- 新增 `testWorkspaceCommandMenuCoversWorkspaceTabs`，测试函数数从 35 个增加到 36 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图和入口规则中的 Mac/iPad command menu 发现层。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `LocalGemma/LocalGemmaApp.swift`
- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v1（Mac体验审计）/v1.2（Mac iPad命令菜单发现层）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 36 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v1.2 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立 workspace command menu 发现层，没有把会话导出、新建会话或 composer 操作提升到 scene command。

### v1.3 / Mac iPad侧栏选择语义基线

日期：2026-07-04

核心变更：

- `WorkspaceLayoutMode` 新增 `usesDetailedSidebar`，只有 regular 大屏双栏显示详细侧栏；compact 双栏和 portrait 保持原有密度。
- `WorkspaceTab` 新增 `sidebarSubtitle`，regular 大屏侧栏在工作区标题下显示一行用途说明。
- 新增 `SelectionAccessibilityMetadata`，为工作区和会话选择生成可测试的 accessibility label/value。
- 顶部 tab、侧栏 tab 和会话 chip 增加选中状态语义；当前项通过 `.isSelected` trait 暴露给辅助技术。
- 会话删除图标按钮补充明确 accessibility label。
- 新增 `testSelectionAccessibilityMetadataDescribesWorkspaceAndSessions`，测试函数数从 36 个增加到 37 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图和入口规则中的 Mac/iPad 侧栏说明与选择语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v1（Mac体验审计）/v1.3（Mac iPad选择语义基线）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 37 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v1.3 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立 regular 侧栏说明和选择语义基线，没有调整全局字体、动画或完整视觉风格。

### v1.4 / Mac iPad Composer输入焦点与辅助语义

日期：2026-07-04

核心变更：

- `ContentView` 通过统一 workspace selection binding 拦截按钮、TabView 和 `工作区` command menu 的推理页切换，并在进入推理页时请求 composer 聚焦。
- 新增 `ComposerFocusReason`、`ComposerFocusRequest`、`ComposerFocusPolicy` 和 `ComposerInputMetadata`，把输入焦点策略和辅助技术文案放在 UI view 层，避免污染 `InferenceEngine` 会话状态。
- `ChatWorkspace` 在新建会话、切换会话后请求 composer 聚焦；提示词模板“填入”和“发送”回到推理页后也请求聚焦。
- `ComposerBar` 接入 `@FocusState`，输入框补充 accessibility label、hint 和 Voice Control input labels；发送/停止按钮补充 label、value 和 hint，同时保留 `Command+Return`，普通 Return 继续留给 vertical input。
- 新增 `testComposerInputMetadataAndFocusPolicyDescribeEntryPoints`，测试函数数从 37 个增加到 38 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图和入口规则中的 composer 输入焦点与辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v1（Mac体验审计）/v1.4（Composer输入焦点与辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 38 个 `test...` 方法。
- `find md -maxdepth 4 -type f | sort`：确认 v1.4 Agent A 提示词和核心文档仍在归档结构内。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v1.4 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立 composer 输入焦点和辅助语义基线，没有做全局视觉重设、持久化会话或真实 runtime 接入。

### v1.5 / 模型页宽屏布局策略

日期：2026-07-04

核心变更：

- 新增 `ModelLibraryLayoutMode`，将模型页内部单栏/双栏判断从临时 `width > height` 条件抽成可测试策略。
- 模型页在足够宽的 iPad/Mac 容器中进入内部双栏，并列展示模型选择/部署/artifact 操作和模型摘要/参数/性能/建议；窄 iPhone 和窄 split view 继续保持单栏。
- `ModelLibraryLayoutMode.controlColumnWidth(for:)` 统一控制双栏左侧控制列宽度，保持最小 300、最大 390 的稳定区间。
- 新增 `testModelLibraryLayoutModeSupportsWideModelWorkflows`，测试函数数从 38 个增加到 39 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图和入口规则中的模型页内部宽屏布局基线。
- 本轮没有修改全局 `WorkspaceLayoutMode` 断点，没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v1（Mac体验审计）/v1.5（模型页宽屏布局策略）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 39 个 `test...` 方法。
- `find md -maxdepth 4 -type f | sort`：确认 v1.5 Agent A 提示词和核心文档仍在归档结构内。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。

遗留事项：

- v1.5 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型页内部布局策略，没有做全局视觉重设、CI 结果包契约重构或真实 runtime 接入。

### v1.6 / 提示词分类筛选辅助语义

日期：2026-07-04

核心变更：

- 新增 `PromptCategoryAccessibilityMetadata`，为提示词页分类筛选 chip 生成稳定 title、label、value、hint、Voice Control input labels 和 accessibility identifier。
- `PromptCategorySelector` 的“全部/部署/隐私/性能/写作/产品/排障”按钮接入辅助语义，当前筛选项继续通过 `.isSelected` trait 暴露给辅助技术。
- 新增 `testPromptCategoryAccessibilityMetadataDescribesFilterSelectionAndInputLabels`，测试函数数从 39 个增加到 40 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图和入口规则中的提示词分类筛选辅助语义基线。
- 本轮没有修改提示词模板业务内容，没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v1（Mac体验审计）/v1.6（提示词分类筛选辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 40 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v1.6 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立提示词分类筛选辅助语义，没有做全局视觉重设、完整 UI Test target 或真实 runtime 接入。

### v1.7 / 会话命令菜单发现层

日期：2026-07-04

核心变更：

- 新增 `SessionCommandAction`、`SessionCommandItem`、`SessionCommandRoutingPolicy` 和 `SessionCommandActions`，把会话菜单标题、命令顺序、快捷键和 focused action route 抽成可测试元数据。
- `LocalGemmaApp` 在 scene commands 中注册系统 `会话` CommandMenu；`ChatWorkspace` 通过 focused scene value 暴露新建会话和导出当前会话动作，菜单不直接持有 `InferenceEngine` 或导出 sheet 状态。
- `Command+N` 新建会话后继续请求 composer 聚焦，`Command+Shift+E` 导出当前会话；会话栏按钮保留可见入口，但不再重复注册同一快捷键。
- 新增 `testSessionCommandMenuCoversFocusedSessionActions` 和 `testSessionCommandFocusedRouteDescribesAvailabilityAndFocusPolicy`，测试函数数从 40 个增加到 42 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的会话命令菜单基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemma/LocalGemmaApp.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v1（Mac体验审计）/v1.7（会话命令菜单发现层）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 42 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v1.7 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立会话命令菜单发现层，没有做完整 UI Test target、会话持久化、全局视觉重设或真实 runtime 接入。

### v1.8 / 会话侧栏宽度策略

日期：2026-07-04

核心变更：

- 新增 `SessionSidebarLayoutPolicy`，将推理页大屏会话列表宽度从 `ChatWorkspace` 内联公式抽成可测试策略。
- 会话侧栏在双栏布局中继续按容器宽度 28% 计算，并限制在 240 到 310 之间；窄屏单栏返回 0，保持旧视觉行为不变。
- `ChatWorkspace` 使用新策略设置竖向 `SessionBar` 宽度，不改变会话创建、切换、删除、导出、v1.7 command menu 或 composer focus 行为。
- 新增 `testSessionSidebarLayoutPolicyConstrainsWideChatHistory`，测试函数数从 42 个增加到 43 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的会话侧栏宽度策略基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v1（Mac体验审计）/v1.8（会话侧栏宽度策略）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 43 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v1.8 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立会话侧栏宽度策略，没有做完整 UI Test target、会话持久化、全局视觉重设或真实 runtime 接入。
