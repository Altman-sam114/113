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
- 当前核心测试：`LocalGemmaTests.swift` 中 68 个 XCTest 方法。
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

### v1.9 / 模型部署控件辅助语义

日期：2026-07-04

核心变更：

- 新增 `ModelDeploymentControlAccessibilityMetadata`，为模型部署电源按钮和 artifact 操作按钮生成可测试的 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `DeploymentPowerButton` 保留现有可见 UI 和 `model-deployment-power` identifier，并补充部署状态、artifact 状态和 verified 门禁相关辅助语义。
- `ArtifactActionButton` 和“扫描本地 / 导入文件”utility buttons 接入统一 metadata；“下载模型”的辅助 hint 明确当前只是模拟暂存，不会联网下载真实权重。
- 新增 `testModelDeploymentControlsExposeAccessibilityMetadata`，测试函数数从 43 个增加到 44 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型部署控件辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `ModelCatalog`、artifact store、validator、runtime 或部署状态流。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v1（Mac体验审计）/v1.9（模型部署控件辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 44 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v1.9 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型部署控件辅助语义，没有做完整 UI Test target、模型页视觉重设、真实 runtime 接入或模型 artifact 下载。

### v2.0 / 模型选择器辅助语义

日期：2026-07-04

核心变更：

- 扩展 `ModelDeploymentControlAccessibilityMetadata`，为模型页选择器生成可测试的 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `ModelSelectorPanel` 的 `Picker` 接入模型选择器辅助语义；value 合并当前模型名、参数量、量化、安装状态、候选数量、artifact availability 和部署状态。
- 模型选择器 hint 明确切换模型只更新本地选择，不下载模型权重，不启动真实 runtime，也不会绕过 verified 门禁。
- 新增 `testModelSelectorExposesAccessibilityMetadata`，测试函数数从 44 个增加到 45 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型选择器辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `ModelCatalog`、artifact store、validator、runtime 或部署状态流。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.0（模型选择器辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 45 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.0 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型选择器辅助语义，没有做完整 UI Test target、模型页视觉重设、真实 runtime 接入或模型 artifact 下载。

### v2.1 / 会话栏操作辅助语义

日期：2026-07-04

核心变更：

- 新增 `SessionBarActionAccessibilityMetadata`，为推理页会话栏的新建和导出按钮生成可测试的 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `SessionBar` 的可见按钮复用 `.createSession` / `.exportSession` action metadata，和系统 `会话` command menu 的标题、快捷键与 focused route 保持对齐。
- 新建会话辅助文案说明会创建本地会话并请求 composer 聚焦，不会发送 prompt；导出辅助文案说明使用本地 Markdown / 文本分享兜底，不会把会话发送到云端服务。
- 新增 `testSessionBarActionsExposeAccessibilityMetadata`，测试函数数从 45 个增加到 46 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的会话栏操作辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `InferenceEngine`、导出 payload、分享兜底、会话状态流或 command menu 行为。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.1（会话栏操作辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 46 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.1 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立会话栏操作辅助语义，没有做完整 UI Test target、会话持久化、导出 UI 视觉重设、真实 runtime 接入或模型 artifact 下载。

### v2.2 / 导出分享复制辅助语义

日期：2026-07-05

核心变更：

- 新增 `ExportSessionActionAccessibilityMetadata`，为导出弹层分享 Markdown 文件、文本分享兜底和复制全文动作生成可测试的 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `ExportSessionView` 底部 ShareLink、复制按钮和 toolbar 分享入口复用统一 metadata；toolbar 分享入口由裸图标改为带文字的 icon-only `Label`，视觉保持不变。
- 辅助文案说明 Markdown 分享使用本地生成文件、文本分享是文件不存在时的兜底、复制全文写入系统剪贴板，且都不会把会话发送到云端服务。
- 新增 `testExportSessionActionsExposeAccessibilityMetadata`，测试函数数从 46 个增加到 47 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的导出弹层分享/复制辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `InferenceEngine`、`ExportPayload.existingFileURL`、分享内容、剪贴板写入或会话状态流。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.2（导出分享复制辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 47 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.2 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立导出弹层分享/复制辅助语义，没有做完整 UI Test target、导出 UI 视觉重设、真实 runtime 接入或模型 artifact 下载。

### v2.3 / 壁纸控件辅助语义

日期：2026-07-05

核心变更：

- 新增 `WallpaperPreferenceAccessibilityMetadata`，为设置页选择相册壁纸和恢复系统背景按钮生成可测试的 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `WallpaperPreferencePanel` 的 `PhotosPicker` 和清空按钮复用统一 metadata；辅助文案说明系统背景、相册图片已启用、正在处理、本地压缩、恢复系统背景和不发送云端服务边界。
- 壁纸预览图标和缩略图对辅助技术隐藏，避免 VoiceOver 读到无意义装饰图像；真实操作语义由两个按钮承担。
- 新增 `testWallpaperPreferenceControlsExposeAccessibilityMetadata`，测试函数数从 47 个增加到 48 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的壁纸控件辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `WallpaperImageProcessor`、`@AppStorage` 存储、相册读取流程、背景渲染或模型 runtime。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.3（壁纸控件辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 48 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.3 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立壁纸控件辅助语义，没有做完整 UI Test target、设置页视觉重设、真实 runtime 接入或模型 artifact 下载。

### v2.4 / 头部主题入口辅助语义

日期：2026-07-05

核心变更：

- 新增 `HeaderActionAccessibilityMetadata`，为全局头部主题切换、设置页外观主题按钮和打开模型工作区按钮生成可测试的 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `HeaderView` 的主题按钮由英文 `Toggle theme` 改为中文辅助语义，说明当前主题、切换目标、本地 UI 外观边界、不下载模型权重、不启动真实 runtime 和不发送云端服务。
- `HeaderView` 的模型库按钮由英文 `Open model library` 改为中文辅助语义，说明只切换到模型工作区，可管理本地模型、artifact 和部署状态，不下载权重、不启动真实 runtime、不绕过 verified 门禁。
- `ThemePreferencePanel` 的 icon-only 主题按钮复用主题切换 metadata，并使用独立稳定 identifier，避免与头部按钮重复。
- 新增 `testHeaderAndThemePreferenceActionsExposeAccessibilityMetadata`，测试函数数从 48 个增加到 49 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的头部主题入口辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改主题存储、模型状态流、artifact 校验或 runtime 计划。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.4（头部主题入口辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 49 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.4 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立头部主题与模型工作区入口辅助语义，没有做完整 UI Test target、工作区导航 hint/input labels、运行策略开关辅助语义、真实 runtime 接入或模型 artifact 下载。

### v2.5 / 工作区导航辅助语义

日期：2026-07-05

核心变更：

- 新增 `WorkspaceNavigationAccessibilityMetadata`，为顶部工作区 tab 和大屏 sidebar 工作区按钮生成可测试的 label、value、hint、Voice Control 输入标签和稳定 identifier。
- 顶部工作区 tab 与 sidebar 工作区按钮接入统一 metadata；hint 说明对应工作区用途、`Command 1...4` 快捷键、只切换本地工作区、不会下载模型权重和不启动真实 runtime。
- metadata 复用 `WorkspaceTab.sidebarSubtitle`，避免 regular 大屏侧栏视觉用途说明和辅助语义分叉。
- 新增 `testWorkspaceNavigationAccessibilityMetadataDescribesShortcutsAndVoiceControl`，测试函数数从 49 个增加到 50 个；首次云端 run 暴露该测试的聚合断言失败摘要不够明确，随后拆成逐工作区断言并补充失败消息；第二次云端 run 仍显示同一测试失败但日志未展开断言，本轮继续移除可选字典期望，改为 switch helper 产出非可选期望，便于后续 CI 定位具体 tab / 字段。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的工作区导航辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改工作区顺序、快捷键、command menu、focused route、composer focus 或模型 runtime。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.5（工作区导航辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 50 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。
- GitHub Actions run `28729856599`：`staticChecksOutcome=success`、`logicSmokeOutcome=success`、`buildOutcome=success`、`macCatalystBuildOutcome=success`、`macCatalystRunScriptCheckOutcome=success`，但 `testOutcome=failure`，失败测试为 `testWorkspaceNavigationAccessibilityMetadataDescribesShortcutsAndVoiceControl`；本轮通过追加修复 commit 继续在 `main` 上重跑云端验证。
- GitHub Actions run `28730139142`：manifest `branch=main`、`version=v2.5`、`commitSha=9dd39b4c74023d5ab642f466c84e7a06634363d6`、`runId=28730139142`、`runAttempt=1` 与下载 artifact `localgemma-ci-v2.5-main-9dd39b4-run28730139142-attempt1` 对齐；`staticChecksOutcome=success`、`logicSmokeOutcome=success`、`buildOutcome=success`、`macCatalystBuildOutcome=success`、`macCatalystRunScriptCheckOutcome=success`，但 `testOutcome=failure`，失败仍是 `testWorkspaceNavigationAccessibilityMetadataDescribesShortcutsAndVoiceControl`；本轮继续追加修复 commit 后重跑云端验证。
- 本次测试修复追加本地轻量检查：`git diff --check` 无输出；`grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift` 确认 50 个测试方法；`test -x script/build_and_run.sh`、`bash -n script/build_and_run.sh`、`plutil -lint LocalGemma.xcodeproj/project.pbxproj`、`ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'` 均退出码 0；app module `swiftc -emit-module` 和测试源码 `swiftc -typecheck` 均退出码 0。本机尝试运行单个 iPhone Simulator XCTest 时 CoreSimulatorService 不可用，`xcodebuild` 报告找不到 `iPhone 17 Pro` destination，因此本轮完整 XCTest 仍交给 GitHub Actions 重验证。
- GitHub Actions run `28730700594`：manifest `branch=main`、`version=v2.5`、`commitSha=a4996ac47202a6276c1e5f90e12eebecf230b2a9`、`runId=28730700594`、`runAttempt=1` 与下载 artifact `localgemma-ci-v2.5-main-a4996ac-run28730700594-attempt1` 对齐；`staticChecksOutcome=success`、`logicSmokeOutcome=success`、`buildOutcome=success`、`macCatalystBuildOutcome=success`、`macCatalystRunScriptCheckOutcome=success`，但 `testOutcome=failure`。使用 `xcresulttool get test-results tests` 核对 `.xcresult` 后确认四个失败断言均为 `hint.contains("不会下载模型权重")`；实现文案原为“不下载模型权重”，本轮改为“不会下载模型权重”并继续追加修复 commit 后重跑云端验证。

遗留事项：

- v2.5 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立工作区导航辅助语义，没有做完整 UI Test target、运行策略开关辅助语义、优化摘要动态文案、真实 runtime 接入或模型 artifact 下载。

### v2.6 / 运行策略开关辅助语义

日期：2026-07-05

核心变更：

- Agent X 在 v2.5 验收通过后并发调用只读子 agent 审计 Mac/iPad/UI 缺口，两个结果均指出设置页“运行策略”开关缺少稳定辅助语义；本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.6（运行策略开关辅助语义）.md`。
- 新增 `OptimizationToggleAccessibilityMetadata`，为设置页和优化 dashboard 的运行策略开关生成可测试的 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `OptimizationToggleRow` 接入统一 metadata，并在开关开启时添加 `.isSelected` trait；点击行为仍只调用 `optimizer.toggle(item)`，不改变 readiness 公式、开关顺序、标题或视觉结构。
- 辅助文案明确运行策略开关只切换本地运行策略，不会下载模型权重、不会启动真实 runtime，也不会发送到云端服务。
- 新增 `testOptimizationToggleRowsExposeAccessibilityMetadata`，测试函数数从 50 个增加到 51 个，覆盖四个默认运行策略的 label/value/hint/input labels/identifier、开启/关闭状态和 toggle 后 metadata value。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的运行策略开关辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改芯片准备度动态摘要、模型胶囊、模型详情右栏或 UI Test target。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.6（运行策略开关辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 51 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.6 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立运行策略开关辅助语义，没有做芯片准备度动态摘要、模型胶囊辅助语义、模型详情右栏辅助语义、完整 UI Test target、真实 runtime 接入或模型 artifact 下载。

### v2.7 / 芯片准备度辅助语义与隐私状态

日期：2026-07-05

核心变更：

- Agent X 在 v2.6 验收通过后继续选择 v2.6 遗留的“芯片准备度动态摘要”作为下一轮小目标，并归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.7（芯片准备度辅助语义与隐私状态）.md`。
- `DeviceOptimizer` 新增 `offlinePrivacyGuardTitle` 和 `isOfflinePrivacyGuardEnabled`，只读派生 `Offline privacy guard` 当前状态，不改变开关顺序、默认值或 readiness 公式。
- `ChipReadinessCard` 新增隐私保护状态输入，设置页和优化 dashboard 均传入 `optimizer.isOfflinePrivacyGuardEnabled`；可见摘要从硬编码“离线隐私保护开启”改为随开关显示“开启/关闭”。
- 新增 `ChipReadinessAccessibilityMetadata`，为芯片准备度卡片和 `ReadinessRing` 生成中文 label/value/hint、Voice Control 输入标签和稳定 identifier；文案明确本地芯片准备度、不会下载模型权重、不会启动真实 runtime、不会发送到云端服务。
- `ReadinessRing` 复用 metadata 计算并 clamp 百分比，替换原英文 VoiceOver label，不改变可见圆环结构。
- 新增 `testChipReadinessCardDescribesPrivacyGuardAndAccessibilityMetadata`，测试函数数从 51 个增加到 52 个，覆盖默认隐私保护开启、toggle 后关闭、百分比 clamp、热状态、模拟 Metal 预热、卡片/圆环辅助语义和本地/云端边界。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的芯片准备度辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 readiness 公式、模型胶囊、模型详情右栏或 UI Test target。

关键文件：

- `LocalGemma/AppState.swift`
- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.7（芯片准备度辅助语义与隐私状态）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 52 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.7 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立芯片准备度辅助语义与隐私状态动态摘要，没有做模型胶囊辅助语义、模型详情右栏辅助语义、完整 UI Test target、真实 runtime 接入或模型 artifact 下载。

### v2.8 / 模型胶囊整体辅助语义

日期：2026-07-05

核心变更：

- Agent X 在 v2.7 验收通过后继续选择 v2.7 遗留的“模型胶囊辅助语义”作为下一轮小目标，并归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.8（模型胶囊整体辅助语义）.md`。
- 新增 `ModelCapsuleAccessibilityMetadata`，为顶部模型胶囊生成整体 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `ModelCapsule` 接入统一辅助语义，value 合并当前模型名、参数量、量化、安装状态、SIM/REAL、artifact missing/staged/verified、生成状态、后端、速度、内存和准备度；hint 明确模型胶囊只展示本地状态摘要，不会下载模型权重、不会启动真实 runtime、不会发送到云端服务，也不会绕过 verified 门禁。
- 模型胶囊可见 UI、状态来源、`ReadinessRing` 可见结构、`ModelCatalog`、`InferenceEngine`、artifact validation 和 runtime plan 均保持不变。
- 新增 `testModelCapsuleExposesOverallAccessibilityMetadata`，测试函数数从 52 个增加到 53 个，覆盖 label/value/hint/input labels/identifier、missing/staged/verified、SIM/REAL、生成中/空闲、速度/内存/准备度和本地/云端边界。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型胶囊整体辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改模型部署状态流、artifact verified 门禁、模型详情右栏或 UI Test target。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.8（模型胶囊整体辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 53 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.8 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型胶囊整体辅助语义，没有做模型详情右栏辅助语义、完整 UI Test target、真实 runtime 接入或模型 artifact 下载。

### v2.9 / 模型详情右栏辅助语义

日期：2026-07-05

核心变更：

- Agent X 在 v2.8 验收通过后继续选择 v2.8 遗留的“模型详情右栏辅助语义”作为下一轮小目标；本轮两个只读子 agent 因 429 限流失败，改由主线程基于现有文档和源码锚点继续推进，并归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.9（模型详情右栏辅助语义）.md`。
- 新增 `ModelDetailAccessibilityMetadata`，为模型页详情右栏和窄屏详情段生成整体 label、value、hint、Voice Control 输入标签和稳定 identifier。
- 新增 `ModelDetailColumn`，让宽屏右栏和窄屏详情段复用同一组详情面板与辅助语义；可见的模型摘要、参数、性能和建议面板不改变。
- 辅助 value 合并模型名、家族、参数量、量化、上下文长度、文件格式、包体大小、artifact missing/staged/verified、validation summary、预计速度、内存预算、主后端、回退后端、KV cache、运行阻塞项和下一步。
- 辅助 hint 明确详情区只展示本地模型详情，不会下载模型权重、不会启动真实 runtime、不会发送到云端服务，也不会绕过 verified 门禁。
- 新增 `testModelDetailColumnExposesAccessibilityMetadata`，测试函数数从 53 个增加到 54 个，覆盖 label/value/hint/input labels/identifier、missing/staged/verified、blocker/next step、后端、KV cache 和本地/云端边界。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型详情右栏辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改模型部署状态流、artifact verified 门禁或 UI Test target。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.9（模型详情右栏辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 54 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.9 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型详情右栏辅助语义，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.10 / 提示词模板动作辅助语义

日期：2026-07-05

核心变更：

- Agent X 在 v2.9 验收通过后继续优化 Mac/iPad 提示词页；两个只读子 agent 都指出提示词模板卡片“填入/发送”动作仍缺稳定中文辅助语义，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.10（提示词模板动作辅助语义）.md`。
- 新增 `PromptTemplateActionAccessibilityMetadata`，为提示词模板卡片“填入”和“发送”动作生成 label、value、hint、Voice Control 输入标签和稳定 identifier。
- “填入”动作说明模板会写入 composer、切回推理页并聚焦输入框，且不会发送 prompt、不会下载模型权重、不会启动真实 runtime、不会发送到云端服务。
- “发送”动作说明模板会作为当前输入发送到本地模拟 runtime、切回推理页并聚焦输入框，且不会下载模型权重、不会启动真实 runtime、不会发送到云端服务，也不会绕过 verified 门禁。
- 发送按钮从纯 `Image` 调整为 `Label("发送", systemImage: "paperplane.fill").labelStyle(.iconOnly)`，视觉保持图标按钮，辅助技术有真实文本标签。
- 新增 `testPromptTemplateActionsExposeAccessibilityMetadata`，测试函数数从 54 个增加到 55 个，覆盖 action 枚举、中文 label、生成中禁用 value、本地边界 hint、Voice Control input labels、每个模板两个动作的唯一 identifier。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的提示词模板动作辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改提示词模板内容、筛选结果、`InferenceEngine` 状态流、composer 焦点策略或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.10（提示词模板动作辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 55 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.10 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立提示词模板动作辅助语义，没有做 composer 按钮 identifier、会话 chip 动作细化、聊天消息气泡整体辅助语义、优化指标卡辅助语义、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.11 / Composer控件标识与语音控制语义

日期：2026-07-05

核心变更：

- Agent X 在 v2.10 验收通过后继续优化推理页主输入工作流；子 agent 前序审计指出 composer 发送/停止控件仍缺稳定 identifier 和 Voice Control 语义，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.11（Composer控件标识与语音控制语义）.md`。
- `ComposerInputMetadata` 新增 composer 输入框 identifier、发送/停止按钮 input labels 和按钮 identifier。
- 发送/停止按钮从纯 `Image` 改为保留文本语义的 `Label(...).labelStyle(.iconOnly)`，视觉仍保持圆形图标按钮。
- composer action hint 扩展为空输入、发送本地模拟 runtime、停止当前模拟生成三态，并统一说明不下载模型权重、不启动真实 runtime、不发送云端服务且不绕过 artifact verified 门禁。
- 扩展 `testComposerInputMetadataAndFocusPolicyDescribeEntryPoints`，锁住输入框 identifier、发送/停止 input labels、按钮 identifier 和三态 hint 边界；测试函数数保持 55 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的 composer 控件标识与语音控制语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `InferenceEngine` 发送/停止行为、提示词模板逻辑、runtime plan 或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.11（Composer控件标识与语音控制语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 55 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.11 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立 composer 控件标识与语音控制语义，没有做会话 chip 动作细化、聊天消息气泡整体辅助语义、优化指标卡辅助语义、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.12 / 优化指标卡辅助语义

日期：2026-07-05

核心变更：

- Agent X 在 v2.11 验收通过后继续优化 Mac/iPad 设置页和优化 dashboard；并发只读子 agent 指出 `OptimizerMetricCard` 仍缺整体辅助语义，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.12（优化指标卡辅助语义）.md`。
- 新增 `OptimizerMetricAccessibilityMetadata`，为 Apple Silicon 优化指标卡生成 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `OptimizerMetricCard` 接入整体只读辅助语义，value 合并指标当前状态、progress 百分比和 detail；hint 明确指标卡只展示本地 Apple Silicon 优化摘要，不会下载模型权重、不会启动真实 runtime、不会发送云端服务，也不会绕过 artifact verified 门禁。
- 新增 `testOptimizerMetricCardsExposeAccessibilityMetadata`，覆盖默认 4 个指标、identifier、百分比 clamp、label/value/input labels 和本地/云端/verified 边界；测试函数数从 55 个增加到 56 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的优化指标卡辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `DeviceOptimizer.metrics` 默认数据、运行策略开关、准备度公式、runtime plan 或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.12（优化指标卡辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 56 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.12 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立优化指标卡辅助语义，没有做会话 chip 动作细化、聊天消息气泡整体辅助语义、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.13 / 聊天消息气泡辅助语义

日期：2026-07-05

核心变更：

- Agent X 在 v2.12 验收通过后继续优化推理页 Mac/iPad 阅读体验；并发只读子 agent 分别建议会话 chip 动作语义和聊天消息气泡整体辅助语义，本轮选择范围更窄、连续遗留且不触碰会话状态流的 `ChatBubble` 作为 v2.13，并归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.13（聊天消息气泡辅助语义）.md`。
- 新增 `ChatMessageAccessibilityMetadata`，为用户消息、本地模型消息和系统状态消息生成整体 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `ChatBubble` 接入整体只读辅助语义，value 合并正文或“正在生成”状态、token 数和本地会话消息边界；hint 明确消息气泡只展示本地会话内容，不会下载模型权重、不会启动真实 runtime、不会发送云端服务，也不会绕过 artifact verified 门禁。
- 新增 `testChatMessagesExposeAccessibilityMetadata`，覆盖三种角色、空 assistant 生成态、token 摘要、hint 边界、Voice Control input labels、identifier 使用 role 和 UUID 前缀且不泄露正文；测试函数数从 56 个增加到 57 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的聊天消息气泡辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `InferenceEngine` 会话/生成/导出状态流、消息数据结构、runtime plan 或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.13（聊天消息气泡辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 57 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.13 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立聊天消息气泡辅助语义，没有做会话 chip 动作细化、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.14 / 会话 chip 动作语义

日期：2026-07-05

核心变更：

- Agent X 在 v2.13 验收通过后继续收敛推理页 Mac/iPad 高频交互；前序审计多次遗留“会话 chip 动作细化”，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.14（会话chip动作语义）.md`。
- 新增 `SessionChipActionAccessibilityMetadata`，为推理页单个会话 chip 的选择和删除动作生成 label、value、hint、Voice Control 输入标签和稳定 identifier。
- 选择动作说明只切换本地会话并请求 composer 输入焦点，不发送 prompt、不下载模型权重、不启动真实 runtime、不发送云端服务，也不绕过 artifact verified 门禁。
- 删除动作说明只作用于本地会话列表，不删除模型 artifact 或权重，不发送云端服务，也不改变 artifact verified 门禁；默认空白当前会话暴露“不可删除”原因。
- 会话 chip 删除按钮从纯 `Image` 调整为 `Label(..., systemImage: "trash.fill").labelStyle(.iconOnly)`，视觉保持图标按钮，辅助技术保留文本标签。
- 新增 `testSessionChipActionsExposeAccessibilityMetadata`，覆盖选择/删除 label、value、hint、input labels、identifier、删除禁用原因和 UUID 前缀稳定标识；测试函数数从 57 个增加到 58 个。
- 首个云端 run `28739054467` 的 build、Mac Catalyst 和 run script 通过，但 XCTest 在 `testSessionChipActionsExposeAccessibilityMetadata` 的整句 disabled hint 断言处失败；本轮追加修复将 disabled hint 文案拆成更清晰的“默认空白当前会话”和“不可删除”语义，并把测试改为锁住核心 token，避免脆弱整句匹配。
- 第二个云端 run `28740705988` 仍失败后，本地静态复核发现 disabled delete hint 使用“不会删除模型 artifact 或权重”，与测试和文档锁住的“不删除模型 artifact 或权重”连续 token 不一致；本轮追加把实现文案对齐到测试用词。
- 第三个云端 run `28743360555` 对最新 `origin/main` commit `a3af2ed1775b3098bb66b89de0626189198fa5b0` 验收通过；artifact `localgemma-ci-v2.14-main-a3af2ed-run28743360555-attempt1` 的 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志和三个 `.xcresult/Info.plist` 已核对。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的会话 chip 动作语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `InferenceEngine` 会话创建/选择/删除行为、command menu、runtime plan 或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.14（会话chip动作语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 58 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- 本轮只建立会话 chip 动作语义，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.15 / 聊天记录容器辅助语义

日期：2026-07-05

核心变更：

- Agent X 在 v2.14 最新云端 artifact 验收通过后继续优化推理页 Mac/iPad 阅读体验；只读审计指出 `ChatBubble` 单条消息已有语义，但 `ChatTranscript` 消息列表容器缺少列表级摘要，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.15（聊天记录容器辅助语义）.md`。
- 新增 `ChatTranscriptAccessibilityMetadata`，为推理页聊天记录容器生成 label、value、hint、Voice Control 输入标签和稳定 identifier。
- 容器 value 合并空记录、消息总数、最新消息角色和 assistant 空文本生成中摘要；hint 明确只浏览当前本地会话消息列表，不发送 prompt、不下载模型权重、不启动真实 runtime、不发送云端服务，也不绕过 artifact verified 门禁。
- `ChatTranscript` 的 `ScrollView` 接入容器辅助语义，同时保留单条 `ChatBubble` 的消息级辅助语义。
- 新增 `testChatTranscriptExposesAccessibilityMetadata`，覆盖空列表、普通消息列表、生成中最新消息、hint 边界、Voice Control input labels、identifier 不泄露消息正文；测试函数数从 58 个增加到 59 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的聊天记录容器辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `InferenceEngine` 会话/生成/导出状态流、消息数据结构、runtime plan 或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.15（聊天记录容器辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 59 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.15 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立聊天记录容器辅助语义，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.16 / 模型状态徽章辅助语义

日期：2026-07-06

核心变更：

- Agent X 在 v2.15 云端 artifact 验收通过后继续优化 Mac/iPad 模型页扫描体验；只读子 agent 复核认为“模型状态徽章辅助语义”范围窄、可测试，但提醒顶部模型胶囊已有整体语义，需避免重复播报。
- 新增 `ModelStatusBadgeAccessibilityMetadata`，为模型页安装状态、artifact 状态和部署状态徽章生成 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `ModelSelectorPanel` 中的 `StatusBadge`、`AvailabilityBadge` 和 `DeploymentBadge` 接入独立只读辅助语义；顶部模型胶囊里的 `StatusBadge` 保持视觉展示但对辅助技术隐藏，避免与 `ModelCapsuleAccessibilityMetadata` 重复播报。
- 新增 `testModelStatusBadgesExposeAccessibilityMetadata`，覆盖安装状态、artifact 状态、部署状态全状态、hint 边界、Voice Control input labels、稳定 identifier 和 identifier 不依赖模型名或 prompt；测试函数数从 59 个增加到 60 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型状态徽章辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `ModelCatalog` 状态流、artifact 校验、runtime plan、模型页布局或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.16（模型状态徽章辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 60 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.16 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型状态徽章辅助语义，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.17 / 模型详情行级辅助语义

日期：2026-07-06

核心变更：

- Agent X 在 v2.16 云端 artifact 验收通过后继续优化 Mac/iPad 模型页宽屏扫描体验；只读子 agent 复核认为 `DetailRow` / `AdviceRow` 行级辅助语义适合作为下一轮，但必须处理 `ModelDetailColumn` 之前 `.combine` 吞掉子行焦点的问题。
- 新增 `ModelDetailRowAccessibilityMetadata`，为模型详情参数行、性能行和建议行生成 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `ModelDetailColumn` 从 `.accessibilityElement(children: .combine)` 调整为 `.contain`，保留整体详情摘要，同时让行级 `DetailRow` 和 `AdviceRow` 可达。
- `AdviceRow` 增加明确的建议类型：运行阻塞项、下一步建议和芯片策略建议；identifier 使用类型和序号，不依赖完整建议文本。
- 新增 `testModelDetailRowsExposeAccessibilityMetadata`，覆盖参数行、性能行、三类建议、hint 边界、Voice Control input labels、稳定 identifier 和 identifier 不泄露建议全文；测试函数数从 60 个增加到 61 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型详情行级辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `ModelCatalog` 状态流、artifact 校验、runtime plan、模型页布局或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.17（模型详情行级辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 61 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.17 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型详情行级辅助语义，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.18 / 模型概要面板辅助语义

日期：2026-07-06

核心变更：

- Agent X 在 v2.17 云端 artifact 验收通过后继续优化 Mac/iPad 模型页宽屏扫描体验；两个只读子 agent 并行扫描后，选择 `ModelSummaryPanel` 作为低风险、高价值的小轮次目标。
- 新增 `ModelSummaryAccessibilityMetadata`，为模型页概要面板生成 label、value、hint、Voice Control 输入标签和稳定 identifier。
- `ModelSummaryPanel` 接入独立只读辅助语义；value 合并模型名称、简介、能力标签、artifact availability、validation summary、文件格式和包体大小。
- 新增 `testModelSummaryPanelExposesAccessibilityMetadata`，覆盖 missing / staged / verified validation summary、能力标签、空能力标签兜底、hint 边界、Voice Control input labels、稳定 identifier 和 identifier 不依赖模型名称或简介；测试函数数从 61 个增加到 62 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型概要面板辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `ModelCatalog` 状态流、artifact 校验、runtime plan、模型页布局或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.18（模型概要面板辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 62 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.18 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型概要面板辅助语义，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.19 / 模型文件工作流面板辅助语义

日期：2026-07-06

核心变更：

- Agent X 在 v2.18 云端 artifact 验收通过后继续优化 Mac/iPad 模型页文件管理体验；本轮选择 `ArtifactActionPanel` 作为低风险、可测试的小轮次目标。
- 新增 `ModelArtifactPanelAccessibilityMetadata`，为模型页文件工作流面板生成 label、value、hint、Voice Control 输入标签和稳定 identifier。
- 面板 value 合并 artifact availability、validation summary、模拟暂存、卸载本地文件、扫描本地目录和 Files 手动导入模型文件/tokenizer 入口；hint 明确只管理本地模型文件工作流，不联网下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 artifact verified 门禁。
- `ArtifactActionPanel` 接入 `.accessibilityElement(children: .contain)`，保留面板整体摘要，同时让下载模型、卸载模型、扫描本地和导入文件四个按钮继续独立可达。
- 新增 `testModelArtifactPanelExposesAccessibilityMetadata`，覆盖 missing / staged / verified 状态摘要、本地文件动作、hint 边界、Voice Control input labels、稳定 identifier 和 identifier 不依赖 validation summary 或模型名称；测试函数数从 62 个增加到 63 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型文件工作流面板辅助语义基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `ModelCatalog` 状态流、artifact 校验、runtime plan、模型页布局或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.19（模型文件面板辅助语义）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 63 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.19 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型文件工作流面板辅助语义，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.20 / 优化指标网格宽度策略

日期：2026-07-06

核心变更：

- Agent X 在 v2.19 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出设置页和优化 dashboard 的 Apple Silicon 指标区域使用固定双列，窄屏和窄 split view 容易挤压文本，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.20（优化指标网格宽度策略）.md`。
- 新增 `OptimizerMetricGridLayoutPolicy`，集中定义指标卡最小宽度、网格间距、两列阈值、最大列数和列数夹取规则。
- 新增 `OptimizerMetricGrid`，由 `SettingsWorkspace` 和 `OptimizerDashboard` 共用；窄屏或窄 split view 回退单列，达到两列阈值的 iPad/Mac 宽区域保持双列。
- 新增 `testOptimizerMetricGridLayoutPolicyUsesSingleColumnOnNarrowSettingsWidth`，覆盖单列/双列阈值、最大列数、最小宽度和 GridItem 数量；测试函数数从 63 个增加到 64 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的优化指标网格宽度策略基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `DeviceOptimizer` 指标数据、开关状态、准备度计算、运行策略语义或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.20（优化指标网格宽度策略）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 64 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.20 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立优化指标网格宽度策略，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.21 / 提示词模板宽屏布局策略

日期：2026-07-06

核心变更：

- Agent X 在 v2.20 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出提示词模板页网格可用 `adaptive(minimum: 230)` 但卡片自身固定 230 宽，iPad/Mac 宽屏下无法充分利用列宽，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.21（提示词模板宽屏布局策略）.md`。
- 新增 `PromptTemplateGridLayoutPolicy`，集中定义模板卡片最小宽度、最大宽度、网格间距、最大列数、列数阈值和卡片宽度计算。
- 新增 `PromptTemplateGrid`，由 `PromptTemplatesWorkspace` 使用；窄屏保持单列，iPad/Mac 宽区域多列伸展，并限制最大卡片宽度避免超宽文本行。
- `PromptTemplateCard` 不再固定 `.frame(width: 230)`，改为在网格列内 `maxWidth: .infinity` 伸展。
- 新增 `testPromptTemplateGridLayoutPolicyExpandsCardsOnWidePromptWorkspace`，覆盖单列/多列阈值、最大列数、卡片最小/最大宽度和 GridItem 数量；测试函数数从 64 个增加到 65 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的提示词模板宽屏布局策略基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改提示词模板内容、分类筛选、模板动作辅助语义、`InferenceEngine` 状态流、composer 焦点策略或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.21（提示词模板宽屏布局策略）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift` 和 `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 65 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.21 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立提示词模板宽屏布局策略，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.22 / 聊天气泡宽屏宽度策略

日期：2026-07-06

核心变更：

- Agent X 在 v2.21 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出 `ChatBubble` 用户消息固定 `310`pt，iPad/Mac 宽屏下长 prompt 过窄，而本地模型长回复缺少最大阅读宽度，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.22（聊天气泡宽屏宽度策略）.md`。
- 新增 `ChatBubbleLayoutPolicy`，集中定义聊天记录容器横向 padding、最小可读宽度、用户/本地模型/系统消息最大宽度、角色宽度比例和无效宽度 clamp。
- `ChatTranscript` 使用容器宽度计算消息列表内容宽度并传给 `ChatBubble`；用户消息在 iPad/Mac 宽区域从旧 310pt 上限增长并封顶，本地模型和系统消息限制最大阅读宽度，避免 Mac 宽窗口文本行无限变长。
- `ChatBubble` 保留原有左右对齐、token 显示、背景、边框和 `ChatMessageAccessibilityMetadata`，本轮不修改消息语义、聊天记录容器语义、会话状态流、composer 焦点策略或 runtime。
- 新增 `testChatBubbleLayoutPolicyAdaptsToWideChatTranscripts`，覆盖 iPhone、iPad 和 Mac 宽窗口内容宽度、用户/assistant/system 角色最大宽度、最大上限和无效宽度 clamp；测试函数数从 65 个增加到 66 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的聊天气泡宽屏宽度策略基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 `InferenceEngine`、`ChatMessage` 数据结构、会话创建/删除/导出逻辑、composer 输入控件或 artifact verified 门禁。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.22（聊天气泡宽屏宽度策略）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift` 和 `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 66 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.22 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立聊天气泡宽屏宽度策略，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.23 / 运行策略开关宽屏网格

日期：2026-07-06

核心变更：

- Agent X 在 v2.22 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出设置页和优化 dashboard 的 `运行策略` 四个开关仍固定单列，iPad/Mac 宽屏浪费横向空间并拉长滚动，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.23（运行策略开关宽屏网格）.md`。
- 新增 `OptimizationToggleGridLayoutPolicy`，集中定义运行策略开关最小卡片宽度、网格间距、最大列数、两列阈值和列数 clamp。
- 新增 `OptimizationToggleGrid`，由 `SettingsWorkspace` 和 `OptimizerDashboard` 复用；窄屏和窄 split view 保持单列，iPad/Mac 宽区域双列展示四个运行策略开关，减少 Apple Silicon 设置区纵向滚动。
- `OptimizationToggleRow` 保留原有 label/value/hint、Voice Control input labels、identifier 和 `.isSelected` trait，本轮不修改 `DeviceOptimizer` 状态流、开关顺序、标题、subtitle 或 readiness 公式。
- 新增 `testOptimizationToggleGridLayoutPolicyUsesTwoColumnsOnWideSettingsWidth`，覆盖 390pt 窄屏、两列阈值、iPad/Mac 宽度、GridItem 数量和越界列数 clamp；测试函数数从 66 个增加到 67 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的运行策略开关宽屏网格基线。
- 本轮没有创建原生 macOS target，没有下载模型权重，没有接入真实模型推理，没有修改 Apple Silicon 指标卡、指标网格、芯片准备度卡片、离线隐私保护摘要、模型、artifact、runtime、会话、提示词、导出、壁纸或 composer 状态流。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `AGENTS.md`
- `md/prompt/v2（Mac体验审计）/v2.23（运行策略开关宽屏网格）.md`
- `update_log.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift` 和 `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 67 个 `test...` 方法。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.23 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立运行策略开关宽屏网格，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.24 / Composer宽屏输入宽度

日期：2026-07-06

核心变更：

- Agent X 在 v2.23 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出推理页底部 `ComposerBar` 在 iPad/Mac 宽窗口中仍随 `chatSurface` 无限拉伸，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.24（Composer宽屏输入宽度）.md`。
- 新增 `ComposerBarLayoutPolicy`，集中定义 composer 横向 padding、底部 padding、最小可读宽度、最大内容宽度和无效宽度 clamp。
- `ChatWorkspace.chatSurface` 只在 `ComposerBar` 外层应用最大宽度和居中布局；保留 `ComposerBar` 内部 `TextField`、发送/停止 `Button`、`@FocusState`、`Command+Return` 和 `ComposerInputMetadata` 辅助语义。
- 新增 `testComposerBarLayoutPolicyConstrainsWideComposerInput`，覆盖 390pt iPhone 宽度、834pt iPad 宽度、1200pt Mac 宽窗口、padding、底部间距、最大内容宽度和无效宽度 clamp；测试函数数从 67 个增加到 68 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的 composer 宽屏输入宽度策略基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.24（Composer宽屏输入宽度）.md`

验证结果：

- `git fetch origin`：已同步远端。
- `git pull --ff-only origin main`：输出 `Already up to date.`。
- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift` 和 `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 68 个 `test...` 方法，包含 `testComposerBarLayoutPolicyConstrainsWideComposerInput`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.24 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立 composer 宽屏输入宽度策略，没有做提示词模板动作区 44pt 触控目标、模型卸载确认、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。
