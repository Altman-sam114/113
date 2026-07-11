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
- 当前核心测试：`LocalGemmaTests.swift` 中 100 个 XCTest 方法。
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
- v2.46 push 后 GitHub Actions run `28849295338` 对最新 `origin/main` commit `dc5f36bf5617ac3a5ec81dceb273f85c400a2c99` 验收通过；artifact `localgemma-ci-v2.46-main-dc5f36b-run28849295338-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志、关键构建/测试日志和三个 `.xcresult/Info.plist` 已核对，新增 `testModelDeploymentControlLayoutPolicyMaintainsTouchTargets` 在 `test.log` 中通过，required checks 全部 success。

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

### v2.25 / 提示词模板动作触控目标

日期：2026-07-06

核心变更：

- Agent X 在 v2.24 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出 `PromptTemplateCard` 的发送按钮固定 `36x34`，填入按钮也缺少显式 44pt 触控目标，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.25（提示词模板动作按钮44pt触控目标）.md`。
- 新增 `PromptTemplateActionLayoutPolicy`，集中定义提示词模板动作区 spacing、卡片 padding、44pt 最小触控目标、发送按钮尺寸、最小填入按钮宽度和最小动作区宽度。
- `PromptTemplateCard` 的“填入”按钮显式保证最小 44pt 高度，“发送”图标按钮从 `36x34` 调整为 `44x44`，同时保留 `PromptTemplateActionAccessibilityMetadata`、`.disabled(isGenerating)` 和 apply/send 状态流。
- 新增 `testPromptTemplateActionLayoutPolicyMaintains44PointTouchTargets`，覆盖 44pt 最小触控目标、发送按钮尺寸、动作区 spacing、卡片 padding、最小填入按钮宽度、最小动作区宽度和现有最小卡片宽度兼容性；测试函数数从 68 个增加到 69 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的提示词模板动作触控目标基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.25（提示词模板动作按钮44pt触控目标）.md`

验证结果：

- `git fetch origin`：已同步远端。
- `git pull --ff-only origin main`：输出 `Already up to date.`。
- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift` 和 `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认当前 69 个 `test...` 方法，包含 `testPromptTemplateActionLayoutPolicyMaintains44PointTouchTargets`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.25 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立提示词模板动作 44pt 触控目标，没有做模型卸载确认、模型详情右栏最大阅读宽度、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.26 / 模型卸载确认弹层

日期：2026-07-06

核心变更：

- Agent X 在 v2.25 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出模型页 `ArtifactActionPanel` 的卸载按钮会直接调用 `uninstall(model)`，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.26（模型卸载确认弹层）.md`。
- `ModelLibraryView` 新增 `pendingUninstallModel` 状态和 `confirmationDialog`；宽屏双栏与窄屏单栏的卸载按钮现在只打开确认弹层，取消不删除文件、不停止部署，确认后才调用既有 `uninstall(_:)`。
- 新增 `ModelUninstallConfirmationAccessibilityMetadata`，为确认弹层标题、消息、确认/取消按钮 hint、Voice Control 输入标签和稳定 identifier 提供可测试语义；确认动作说明只删除 App 托管 artifact/tokenizer 并停止部署，不删除系统 Files 原始文件，不下载权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- 更新 `ModelDeploymentControlAccessibilityMetadata` 和 `ModelArtifactPanelAccessibilityMetadata` 的卸载文案，从“直接移除”改为“打开确认，确认后才删除”。
- 新增 `testModelUninstallConfirmationExposesAccessibilityMetadata`，并补强 catalog 卸载测试对必需文件删除结果的断言；测试函数数从 69 个增加到 70 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型卸载确认弹层基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.26（模型卸载确认弹层）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `70`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.26 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型卸载确认弹层，没有做模型详情右栏最大阅读宽度、提示词分类宽屏换行、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.27 / 模型详情右栏最大阅读宽度

日期：2026-07-06

核心变更：

- Agent X 在 v2.26 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；只读子 agent 指出模型页宽屏双栏的 `ModelDetailColumn` 使用 `.frame(maxWidth: .infinity)`，在超宽 iPad/Mac 窗口中会拉长概要、参数、性能和建议文本阅读行，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.27（模型详情右栏最大阅读宽度）.md`。
- 新增 `ModelDetailColumnLayoutPolicy`，集中定义详情右栏最小可读宽度、最大阅读宽度和列间距；单栏或无效尺寸返回 0，不启用固定详情列宽。
- `ModelLibraryView` 的双栏布局继续使用 `ModelLibraryLayoutMode` 控制左侧部署/文件操作列宽，右侧详情栏改为按剩余空间计算并限制最大阅读宽度，末尾保留弹性空白；窄屏单栏展示顺序不变。
- 新增 `testModelDetailColumnLayoutPolicyConstrainsWideReadingWidth`，锁住单栏回退、iPad/Mac 宽度、超宽封顶和无效宽度 clamp；测试函数数从 70 个增加到 71 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型详情右栏最大阅读宽度基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.27（模型详情右栏最大阅读宽度）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `71`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.27 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立模型详情右栏最大阅读宽度策略，没有做提示词分类宽屏换行、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.28 / 提示词分类筛选换行布局

日期：2026-07-06

核心变更：

- Agent X 在 v2.27 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；只读子 agent 指出提示词页 `PromptCategorySelector` 仍使用横向 `ScrollView` + `HStack`，窄 split view 和较大文字场景下筛选入口可发现性不足且未显式锁住 44pt 触控目标，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.28（提示词分类筛选换行布局）.md`。
- 新增 `PromptCategoryLayoutPolicy`，集中定义分类筛选 chip 的 44pt 最小触控目标、水平/垂直间距、padding、最小 chip 宽度、单行最小宽度、换行判断和无效宽度 clamp。
- 新增 `PromptCategoryFlowLayout`，将提示词分类筛选从横向滚动改为自适应换行布局；窄屏和窄 split view 直接换行展示全部筛选入口，iPad/Mac 宽区域可单行完整展示。
- `PromptCategorySelector` 保留 `Button` + `Label`、`PromptCategoryAccessibilityMetadata`、Voice Control 输入标签、稳定 identifier 和 `.isSelected` trait；不改变 `selectedCategory` 状态流、模板筛选结果、模板填入/发送或 composer 聚焦逻辑。
- 新增 `testPromptCategoryLayoutPolicyWrapsFilterChips`，锁住策略常量、44pt 触控目标、单行最小宽度、窄宽度换行、宽区域单行和无效宽度 clamp；测试函数数从 71 个增加到 72 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的提示词分类筛选换行布局基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.28（提示词分类筛选换行布局）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `72`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.28 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立提示词分类筛选换行布局策略，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.29 / 提示词模板文本动态排版

日期：2026-07-06

核心变更：

- Agent X 在 v2.28 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；只读子 agent 指出 `PromptTemplateCard` 仍使用固定小字号、标题/副标题单行截断和 168pt 最小高度，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.29（提示词模板文本动态排版）.md`。
- 新增 `PromptTemplateTextLayoutPolicy`，集中定义提示词模板卡片标题、副标题、正文、分类标签行数、标题区间距、正文行距和 204pt 最小卡片高度。
- `PromptTemplateCard` 将标题、副标题、正文、分类标签和动作文字改为 SwiftUI Dynamic Type 语义字体，标题/副标题/正文允许多行显示，减少 iPad/Mac、窄 split view 和较大文字设置下的截断。
- 保留 `PromptTemplateGridLayoutPolicy`、`PromptTemplateActionLayoutPolicy`、`PromptTemplateActionAccessibilityMetadata`、生成中禁用、模板填入/发送状态流和 composer 聚焦逻辑。
- 新增 `testPromptTemplateTextLayoutPolicySupportsReadableDynamicTypeCards`，锁住文本排版策略常量、最小高度提升和动作区 44pt 兼容性；测试函数数从 72 个增加到 73 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的提示词模板文本动态排版基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.29（提示词模板文本动态排版）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `73`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认包含 `testPromptTemplateTextLayoutPolicySupportsReadableDynamicTypeCards`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.29 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立提示词模板文本动态排版策略，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.30 / 提示词分类文本动态排版

日期：2026-07-06

核心变更：

- Agent X 在 v2.29 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；只读子 agent 指出 `PromptCategorySelector` 的分类筛选 chip 仍使用固定 11pt 字体，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.30（提示词分类文本动态排版）.md`。
- 新增 `PromptCategoryTextLayoutPolicy`，集中定义分类筛选 chip 的两行文本策略和多行能力。
- `PromptCategorySelector` 的分类 chip 从固定 `.system(size: 11, weight: .black)` 改为 `.subheadline.bold()`，并使用 `PromptCategoryTextLayoutPolicy.labelLineLimit`，减少较大文字设置、窄 split view 和 Mac Catalyst 窄窗口下的可读性风险。
- 保留 `PromptCategoryLayoutPolicy` 的换行布局、44pt 触控目标、最小 chip 宽度和无效宽度 clamp；不改变 `selectedCategory` 状态流、模板筛选结果、分类辅助语义、模板填入/发送或 composer 聚焦逻辑。
- 新增 `testPromptCategoryTextLayoutPolicySupportsDynamicTypeFilterChips`，锁住分类文本两行策略、44pt 触控兼容性和单个 chip 宽度行为；测试函数数从 73 个增加到 74 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的提示词分类文本动态排版基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.30（提示词分类文本动态排版）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `74`。
- `grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift`：确认包含 `testPromptCategoryTextLayoutPolicySupportsDynamicTypeFilterChips`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.30 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立提示词分类文本动态排版策略，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.31 / 会话栏操作触控目标

日期：2026-07-06

核心变更：

- Agent X 在 v2.30 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；本轮本地审计发现推理页 `SessionBar` 的新建和导出可见图标按钮仍为 `34x34`，低于 Apple 44pt 触控目标，据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.31（会话栏操作触控目标）.md`。
- 新增 `SessionBarActionLayoutPolicy`，集中定义会话栏操作按钮的 44pt 最小触控目标，并让横向会话栏和 iPad/Mac 大屏竖向会话栏共享同一图标按钮尺寸。
- `SessionBar` 中“导出当前会话”和“新建会话”按钮从固定 `34x34` 改为使用策略常量；保留 `SessionCommandAction`、`SessionCommandRoutingPolicy`、导出弹层、composer 聚焦、按钮图标和辅助语义。
- 新增 `testSessionBarActionLayoutPolicyMaintainsTouchTargets`，锁住最小触控目标、图标按钮尺寸和所有 `SessionCommandAction` 覆盖关系；测试函数数从 74 个增加到 75 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的会话栏操作触控目标基线。
- 两个只读子 agent 额外指出设置页图标动作 44pt 触控目标和提示词页整体宽屏内容宽度仍可作为后续小目标；本轮未扩大范围。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.31（会话栏操作触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `75`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.31 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立会话栏操作 44pt 触控目标策略，没有做设置页图标动作触控目标、提示词页整体宽屏内容宽度、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.32 / 设置页图标动作触控目标

日期：2026-07-06

核心变更：

- Agent X 在 v2.31 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；只读子 agent 指出 `ThemePreferencePanel` 的设置页主题切换按钮为 `42x42`，`WallpaperPreferencePanel` 的相册选择和恢复系统背景按钮为 `40x40`，低于 Apple 44pt 触控目标，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.32（设置页图标动作触控目标）.md`。
- 新增 `SettingsIconActionLayoutPolicy`，集中定义设置页外观主题切换、相册壁纸选择和恢复系统背景三个图标动作的 44pt 最小触控目标。
- `ThemePreferencePanel` 和 `WallpaperPreferencePanel` 改为复用策略常量；保留主题切换、相册读取、本地压缩、恢复系统背景、`PhotosPicker` 禁用状态、清除按钮禁用状态、错误弹层和既有辅助语义。
- 新增 `testSettingsIconActionLayoutPolicyMaintainsTouchTargets`，锁住最小触控目标、图标按钮尺寸和三个设置页图标动作覆盖关系；测试函数数从 75 个增加到 76 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的设置页图标动作触控目标基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.32（设置页图标动作触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `76`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.32 push 后需等待最新 `ci-results.yml` run 完成，由 Agent C 下载对应未加密结果包，核对 manifest、`artifact-name.txt`、JUnit、iOS 日志、Mac Catalyst 日志、run script 日志、baseline notes 和 `.xcresult`。
- 本轮只建立设置页图标动作 44pt 触控目标策略，没有做提示词页整体宽屏内容宽度、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.33 / 提示词页整体宽屏内容宽度

日期：2026-07-06

核心变更：

- Agent X 在 v2.32 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出 `PromptTemplatesWorkspace` 只有固定水平 padding，Mac Catalyst / iPad 超宽窗口下标题、分类筛选和模板网格整体没有最大内容宽度，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.33（提示词页整体宽屏内容宽度）.md`。
- 新增 `PromptTemplatesWorkspaceLayoutPolicy`，集中定义提示词页整体水平 padding、最小可读宽度、最大内容宽度和无效宽度 clamp。
- `PromptTemplatesWorkspace` 用容器宽度计算内容宽度，让提示词页标题、分类筛选和模板网格在 iPad/Mac 超宽窗口中整体居中并限制最大宽度；保留模板筛选、填入、发送、生成中禁用、composer 聚焦和辅助语义。
- `PromptTemplateGridLayoutPolicy` 新增 `maximumWidth(forColumnCount:)`，让提示词页最大内容宽度从四列模板网格最大宽度派生，避免额外固定魔法数。
- 新增 `testPromptTemplatesWorkspaceLayoutPolicyConstrainsWidePromptContent`，锁住 iPhone、iPad、Mac 宽窗口、负数/NaN clamp 和最大宽度派生关系；测试函数数从 76 个增加到 77 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的提示词页整体宽屏内容宽度基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.33（提示词页整体宽屏内容宽度）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `77`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

云端验收：

- v2.33 push 后 GitHub Actions run `28800583582` 对最新 `origin/main` commit `5210e0ed730c4b37a650c697dc1fa0c2053fea15` 验收通过；artifact `localgemma-ci-v2.33-main-5210e0e-run28800583582-attempt1` 的 manifest、`artifact-name.txt`、JUnit、iOS 测试日志、Mac Catalyst 日志、run script 日志、baseline notes 和三个 `.xcresult/Info.plist` 已核对。

遗留事项：

- 本轮只建立提示词页整体宽屏内容宽度策略，没有做设置页整体宽屏内容宽度、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.34 / 设置页整体宽屏内容宽度

日期：2026-07-06

核心变更：

- Agent X 在 v2.33 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出 `SettingsWorkspace` 只有固定水平 padding，Mac Catalyst / iPad 超宽窗口下标题、外观、壁纸、芯片准备度、优化指标和运行策略开关整体没有最大内容宽度，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.34（设置页整体宽屏内容宽度）.md`。
- 新增 `SettingsWorkspaceLayoutPolicy`，集中定义设置页整体水平 padding、最小可读宽度、最大内容宽度和无效宽度 clamp。
- `SettingsWorkspace` 用容器宽度计算内容宽度，让设置页标题、外观、壁纸、芯片准备度、优化指标和运行策略开关在 iPad/Mac 超宽窗口中整体居中并限制最大宽度；保留主题切换、相册壁纸导入、本地压缩、恢复系统背景、optimizer toggle、局部网格策略、图标触控目标和辅助语义。
- 新增 `testSettingsWorkspaceLayoutPolicyConstrainsWideSettingsContent`，锁住 iPhone、iPad、Mac 宽窗口、负数/NaN clamp、最大宽度和局部网格两列阈值兼容关系；测试函数数从 77 个增加到 78 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的设置页整体宽屏内容宽度基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.34（设置页整体宽屏内容宽度）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `78`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

云端验收：

- v2.34 push 后 GitHub Actions run `28803395056` 对最新 `origin/main` commit `a9175e60010a07be66313ea98ee13b5e7b0b9354` 验收通过；artifact `localgemma-ci-v2.34-main-a9175e6-run28803395056-attempt1` 的 manifest、`artifact-name.txt`、JUnit、iOS 测试日志、Mac Catalyst 日志、run script 日志、baseline notes 和三个 `.xcresult/Info.plist` 已核对。

遗留事项：

- 本轮只建立设置页整体宽屏内容宽度策略，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.35 / 全局 Header 图标动作触控目标

日期：2026-07-06

核心变更：

- Agent X 在 v2.34 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出全局 `HeaderView` 的主题切换和打开模型工作区按钮仍为 `42x42`，低于 44pt 触控目标，另一个候选为模型页扫描/导入按钮触控目标，本轮优先处理影响所有工作区的 Header 入口。
- 新增 `HeaderActionLayoutPolicy`，集中定义全局 Header 主题切换和打开模型工作区两个图标动作的 44pt 最小触控目标。
- `HeaderView` 的主题切换和打开模型工作区按钮从固定 `42x42` 改为使用 `HeaderActionLayoutPolicy.iconButtonSize`；保留 `HeaderActionAccessibilityMetadata`、主题切换、工作区切换、模型胶囊状态、模型文件和 runtime 状态流。
- 新增 `testHeaderActionLayoutPolicyMaintainsTouchTargets`，锁住最小触控目标、图标按钮尺寸和两个 Header 可点击图标动作覆盖关系；测试函数数从 78 个增加到 79 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的全局 Header 图标动作触控目标基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.35（全局Header图标动作触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `79`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

云端验收：

- v2.35 push 后 GitHub Actions run `28805129049` 对最新 `origin/main` commit `6ef51f11765ad1575a4862b187b88df2ad6b0e66` 验收通过；artifact `localgemma-ci-v2.35-main-6ef51f1-run28805129049-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、LogicSmoke 日志和 Mac Catalyst run script 日志已核对，required checks 全部 success。

遗留事项：

- 本轮只建立全局 Header 图标动作 44pt 触控目标策略，没有做模型页扫描/导入按钮触控目标、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.36 / 模型文件操作触控目标

日期：2026-07-06

核心变更：

- Agent X 在 v2.35 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；只读子 agent 和主线程检查均指出模型页文件工作流面板的“扫描本地 / 导入文件”按钮只依赖 `compactUtilityStyle()`，缺少 44pt 触控目标策略。
- 新增 `ModelArtifactActionLayoutPolicy`，集中定义模型文件工作流面板扫描本地和导入文件两个 utility 动作的 44pt 最小触控目标。
- `ArtifactActionPanel` 的扫描本地和导入文件按钮显式使用 `ModelArtifactActionLayoutPolicy.utilityButtonMinHeight`，并保留 `ModelDeploymentControlAccessibilityMetadata`、模型文件工作流辅助语义、扫描本地、Files 手动导入、模拟暂存、卸载确认、artifact 校验和 verified 门禁。
- 新增 `testModelArtifactActionLayoutPolicyMaintainsUtilityTouchTargets`，锁住最小触控目标、utility 按钮高度、scan/import 覆盖关系和 accessibility metadata action 映射；测试函数数从 79 个增加到 80 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型文件操作触控目标基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.36（模型文件操作触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh && bash -n script/build_and_run.sh`：退出码 0。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `80`。
- `find md -maxdepth 4 -type f | sort | tail -n 20`：确认 v2.36 Agent A 提示词仍在 `md/prompt/v2（Mac体验审计）/` 归档结构内。
- `python3` workflow 关键标记检查：输出 `workflow markers ok`。
- `python3` pbxproj 关键标记检查：输出 `pbxproj markers ok`。
- `rg -n "v2\\.36|ModelArtifactActionLayoutPolicy|testModelArtifactActionLayoutPolicy|模型文件操作 44pt" ...`：确认源码、测试和文档均覆盖 v2.36、新策略、新测试和模型文件操作 44pt 触控目标说明。
- 当前容器不是 macOS/Xcode 环境，`plutil`、`ruby`、`swiftc` 和 Xcode 不可用；本轮未在本机执行 `plutil -lint`、Ruby YAML 解析、LogicSmoke、Swift typecheck、完整 iOS XCTest 或 Mac Catalyst build。上述检查由 push 后 GitHub Actions macOS runner 和 Agent C 结果包验收覆盖。
- v2.36 push 后 GitHub Actions run `28812167191` 对最新 `origin/main` commit `e3c703e2ef8deb163bc31c06d85d4999f09df188` 验收通过；artifact `localgemma-ci-v2.36-main-e3c703e-run28812167191-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、LogicSmoke 日志、static checks、Mac Catalyst run script 日志和三个 `.xcresult/Info.plist` 已核对，新增 `testModelArtifactActionLayoutPolicyMaintainsUtilityTouchTargets` 在 `test.log` 中通过。

遗留事项：

- 本轮只建立模型文件扫描/导入 utility 按钮 44pt 触控目标策略，没有做会话 chip 删除按钮触控目标、导出弹层宽屏限制、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.37 / 会话 Chip 删除触控目标

日期：2026-07-06

核心变更：

- Agent X 在 v2.36 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；只读子 agent 指出 `SessionChip` 删除按钮只有小号 `trash.fill` 图标，没有显式 44pt 命中尺寸。
- 新增 `SessionChipActionLayoutPolicy`，集中定义会话 chip 删除动作的 44pt 最小触控目标；选择动作不由该策略接管，避免误改 chip 主体布局。
- `SessionChip` 删除按钮显式使用 `SessionChipActionLayoutPolicy.deleteButtonSize`，并保留 `SessionChipActionAccessibilityMetadata`、删除禁用原因、会话选择/删除状态流、composer 聚焦、模型 artifact 边界和 verified 门禁。
- 新增 `testSessionChipActionLayoutPolicyMaintainsTouchTargets`，锁住最小触控目标、删除按钮尺寸、delete action 达标和 select action 不归该策略管理；测试函数数从 80 个增加到 81 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的会话 chip 删除触控目标基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.37（会话Chip删除触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh && bash -n script/build_and_run.sh`：退出码 0。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `81`。
- `find md -maxdepth 4 -type f | sort | tail -n 20`：确认 `md/prompt/v2（Mac体验审计）/v2.37（会话Chip删除触控目标）.md` 已归档。
- Python workflow 标记检查：输出 `workflow markers ok`。
- Python pbxproj 标记检查：输出 `pbxproj markers ok`。
- `rg -n 'v2\.37|SessionChipActionLayoutPolicy|testSessionChipActionLayoutPolicy|会话 chip 删除触控|测试函数数为 81|当前包含 81|当前核心测试：LocalGemmaTests.swift 中 81' ...`：确认源码、测试、README、测试规范、核心流程和入口规则均包含本轮基线。
- 当前 Linux 容器缺少 `plutil`、`ruby`、`swiftc` 和 Xcode，未在本机执行 pbxproj plutil、Ruby YAML 解析、LogicSmoke、Swift typecheck 或完整模拟器 XCTest；这些检查由 v2.37 push 后的 GitHub Actions 和 Agent C 结果包验收覆盖。

遗留事项：

- v2.37 push 后 GitHub Actions run `28814161724` 对最新 `origin/main` commit `8cab6b7a40c3a5610e2049baf1011f1e88a9bb3b` 验收通过；artifact `localgemma-ci-v2.37-main-8cab6b7-run28814161724-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志和三个 `.xcresult/Info.plist` 已核对，新增 `testSessionChipActionLayoutPolicyMaintainsTouchTargets` 在 `test.log` 中通过，required checks 全部 success。
- 本轮只建立会话 chip 删除按钮 44pt 触控目标策略，没有做导出弹层宽屏限制、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.38 / 导出弹层分享复制触控目标

日期：2026-07-07

核心变更：

- 新增 `ExportSessionActionLayoutPolicy`，集中定义导出弹层底部 Markdown 分享、底部文本兜底分享、底部复制全文、toolbar Markdown 分享和 toolbar 文本兜底分享入口的 44pt 最小触控目标。
- `ExportSessionView` 底部 `ShareLink`、复制按钮和 toolbar `ShareLink` 显式复用策略常量，底部分享/复制至少 44pt 高，toolbar 分享至少 44x44；保留 `ExportPayload`、`InferenceEngine` 导出文本、ShareLink 文件优先/文本兜底选择、`UIPasteboard` 写入、导出弹层辅助语义和会话状态流。
- 新增 `testExportSessionActionLayoutPolicyMaintainsTouchTargets`，锁住最小触控目标、底部按钮高度、toolbar 尺寸、全部 presentation 达标、分享动作覆盖 Markdown/文本兜底以及复制只归底部复制入口；测试函数数从 81 个增加到 82 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的导出弹层分享复制 44pt 触控目标基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v0（导出弹层触控目标）/v2.38（优化导出弹层分享复制触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh && bash -n script/build_and_run.sh`：无输出，退出码 0。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `82`。
- `find md -maxdepth 4 -type f | sort | tail -n 20`：输出包含 `md/test/test.md` 和现有 v2 prompt 归档尾部；另用 `test -f 'md/prompt/v0（导出弹层触控目标）/v2.38（优化导出弹层分享复制触控目标）.md'` 确认本轮 v2.38 Agent A 提示词存在。
- Python workflow 标记检查：输出 `workflow markers ok`。
- Python pbxproj 标记检查：输出 `pbxproj markers ok`。
- `rg -n 'v2\.38|ExportSessionActionLayoutPolicy|testExportSessionActionLayoutPolicy|导出弹层分享/复制 44pt|导出弹层分享复制触控目标|当前包含 82|当前核心测试' ...`：确认源码、测试、README、测试规范、核心流程、入口规则和 v2.38 提示词均包含本轮基线。
- 当前 Linux 容器缺少 `plutil`、`ruby`、`swiftc` 和 Xcode，未在本机执行 pbxproj plutil、Ruby YAML 解析、LogicSmoke、Swift typecheck、完整模拟器 XCTest 或 Mac Catalyst build；这些检查由 v2.38 push 后的 GitHub Actions 和 Agent C 结果包验收覆盖。

遗留事项：

- v2.38 push 后 GitHub Actions run `28837209804` 对最新 `origin/main` commit `3d5423475e1b9958cecc8db7b48af3738b46226e` 验收通过；artifact `localgemma-ci-v2.38-main-3d54234-run28837209804-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志和三个 `.xcresult/Info.plist` 已核对，新增 `testExportSessionActionLayoutPolicyMaintainsTouchTargets` 在 `test.log` 中通过，required checks 全部 success。
- 本轮只建立导出弹层分享/复制 44pt 触控目标策略，没有做导出弹层宽屏限制、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.39 / 工作区导航触控目标

日期：2026-07-07

核心变更：

- Agent X 在拉取最新 `origin/main` 后继续优化 UI、Mac 和 iPad 体验；并发只读子 agent 指出顶部工作区 tab 和大屏 sidebar 工作区按钮只依赖 padding，没有显式 44pt 触控目标策略，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.39（工作区导航触控目标）.md`。
- 新增 `WorkspaceNavigationActionLayoutPolicy`，集中定义顶部工作区 tab 和大屏 sidebar 工作区按钮的 44pt 最小触控目标。
- `ContentView` 的顶部 `tabPicker` 和 `sidebarTabPicker` 复用策略常量，让 compact tab 与 sidebar tab 的整体命中区域至少 44pt；保留 `WorkspaceNavigationAccessibilityMetadata`、`WorkspaceTab.shortcutKey`、工作区 command menu、`selectedTab` 状态流、composer focus 和辅助语义。
- 新增 `testWorkspaceNavigationActionLayoutPolicyMaintainsTouchTargets`，锁住最小触控目标、compact/sidebar 两种 placement、最小高度映射和全部 placement 达标；测试函数数从 82 个增加到 83 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的工作区导航触控目标基线。
- 顺手补齐 v2.37 和 v2.38 云端验收记录，并整理 v2.35 云端验收标题，避免把已通过 run 继续写成等待状态。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.39（工作区导航触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `83`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.39 push 后 GitHub Actions run `28839191027` 对最新 `origin/main` commit `f5f3f327bcd9a3c424029135b0762a7f5114f600` 验收通过；artifact `localgemma-ci-v2.39-main-f5f3f32-run28839191027-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志和三个 `.xcresult/Info.plist` 已核对，新增 `testWorkspaceNavigationActionLayoutPolicyMaintainsTouchTargets` 在 `test.log` 中通过，required checks 全部 success。
- 本轮只建立工作区导航按钮 44pt 触控目标策略，没有做会话 chip 选择触控目标、模型页整体宽屏内容上限、导出弹层宽屏限制、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.40 / 会话 Chip 选择触控目标

日期：2026-07-07

核心变更：

- Agent X 在拉取最新 `origin/main` 后继续优化 UI、Mac 和 iPad 体验；本轮选择 v2.39 遗留的会话 chip 选择动作触控目标，归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.40（会话Chip选择触控目标）.md`。
- 扩展 `SessionChipActionLayoutPolicy`，新增 `selectButtonMinHeight`，让单个会话 chip 的选择动作和删除动作都由同一策略保持至少 44pt 触控目标。
- `SessionChip` 选择按钮 label 显式使用 `SessionChipActionLayoutPolicy.selectButtonMinHeight`；保留 `SessionChipActionAccessibilityMetadata`、会话选择/删除状态流、删除禁用原因、composer 聚焦、模型 artifact 边界和 verified 门禁。
- 更新 `testSessionChipActionLayoutPolicyMaintainsTouchTargets`，锁住最小触控目标、选择按钮最小高度、删除按钮尺寸，以及 select/delete action 都达标；测试函数数保持 83 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的会话 chip 选择/删除 44pt 触控目标基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.40（会话Chip选择触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `83`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.40 push 后 GitHub Actions run `28840358548` 对最新 `origin/main` commit `2f9ab6a203ad108d923f1c04ad3232de58fb0443` 验收通过；artifact `localgemma-ci-v2.40-main-2f9ab6a-run28840358548-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志和三个 `.xcresult/Info.plist` 已核对，更新后的 `testSessionChipActionLayoutPolicyMaintainsTouchTargets` 在 `test.log` 中通过，required checks 全部 success。
- 本轮只补齐会话 chip 选择动作 44pt 触控目标，没有做模型页整体宽屏内容上限、导出弹层宽屏限制、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.41 / 模型页整体宽屏内容宽度

日期：2026-07-07

核心变更：

- Agent X 在确认 `origin/main` 已对齐 v2.40 后继续优化 UI、Mac 和 iPad 体验；本轮选择 v2.40 遗留的模型页整体宽屏内容上限，归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.41（模型页整体宽屏内容宽度）.md`。
- 新增 `ModelLibraryWorkspaceLayoutPolicy`，集中定义模型页整体左右 padding、最小可读宽度和最大内容宽度；最大内容宽度由 `ModelLibraryLayoutMode.maximumControlColumnWidth`、`ModelDetailColumnLayoutPolicy.interColumnSpacing` 和 `ModelDetailColumnLayoutPolicy.maximumReadableWidth` 派生。
- `ModelLibraryView` 在 `ScrollView` 内按 `ModelLibraryWorkspaceLayoutPolicy.contentWidth` 限制内容宽度并显式居中；内部 `deploymentContent` 改用内容宽度计算 `ModelLibraryLayoutMode`，保留控制列、详情列、模型选择/部署、模型文件操作、卸载确认、辅助语义和 verified 门禁。
- 新增 `testModelLibraryWorkspaceLayoutPolicyConstrainsWideContent`，锁住策略常量、窄屏扣除 padding、iPad 可用宽度、Mac 超宽封顶、无效宽度 clamp，并确认封顶后仍能触发双栏且详情列达到最大阅读宽度；测试函数数从 83 个增加到 84 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型页整体宽屏内容宽度基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.41（模型页整体宽屏内容宽度）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `84`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.41 push 后 GitHub Actions run `28841102750` 对最新 `origin/main` commit `40f6535216c7c8f5d6291c496d3fe543eb6ecaf8` 验收通过；artifact `localgemma-ci-v2.41-main-40f6535-run28841102750-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志和三个 `.xcresult/Info.plist` 已核对，新增 `testModelLibraryWorkspaceLayoutPolicyConstrainsWideContent` 在 `test.log` 中通过，required checks 全部 success。
- 本轮只建立模型页整体宽屏内容宽度策略，没有做导出弹层宽屏限制、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.42 / 导出弹层整体宽屏内容宽度

日期：2026-07-07

核心变更：

- Agent X 在拉取最新 `origin/main` 后继续优化 UI、Mac 和 iPad 体验；本轮选择 v2.41 遗留的导出弹层宽屏限制，归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.42（导出弹层宽屏内容宽度）.md`。
- 新增 `ExportSessionLayoutPolicy`，集中定义导出弹层整体水平 padding、最小可读宽度、最大内容宽度和无效宽度 clamp。
- `ExportSessionView` 使用 `GeometryReader` 按容器宽度计算内容列宽，让会话摘要、Markdown 预览和底部分享/复制动作在 iPad/Mac 宽 sheet 中整体居中并封顶；保留 `ExportPayload`、ShareLink 文件优先/文本兜底、`UIPasteboard` 复制、toolbar 分享、`ExportSessionActionAccessibilityMetadata`、`ExportSessionActionLayoutPolicy` 44pt 触控目标和会话状态流。
- 新增 `testExportSessionLayoutPolicyConstrainsWideContent`，锁住策略常量、窄屏扣除 padding、iPad/Mac 宽屏封顶和无效宽度 clamp；测试函数数从 84 个增加到 85 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的导出弹层整体宽屏内容宽度基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.42（导出弹层宽屏内容宽度）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `85`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- v2.42 push 后 GitHub Actions run `28842241799` 对最新 `origin/main` commit `bb226d6e13141b242e09344a8cafe11d69a56207` 验收通过；artifact `localgemma-ci-v2.42-main-bb226d6-run28842241799-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志和三个 `.xcresult/Info.plist` 已核对，新增 `testExportSessionLayoutPolicyConstrainsWideContent` 在 `test.log` 中通过，required checks 全部 success。
- 本轮只建立导出弹层整体宽屏内容宽度策略，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.43 / 运行策略开关行触控目标

日期：2026-07-07

核心变更：

- Agent X 在拉取最新 `origin/main` 后继续优化 UI、Mac 和 iPad 体验；本轮选择设置页和优化 dashboard 的单个运行策略开关行触控目标，归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.43（运行策略开关行触控目标）.md`。
- 新增 `OptimizationToggleRowLayoutPolicy`，集中定义运行策略开关行 44pt 最小触控目标。
- `OptimizationToggleRow` 复用策略常量设置最小高度，让设置页和优化 dashboard 中的单个运行策略开关行保持 44pt 命中高度；保留 `DeviceOptimizer` 开关状态流、运行策略顺序、`OptimizationToggleAccessibilityMetadata`、`OptimizationToggleGridLayoutPolicy`、芯片准备度摘要、模型文件状态和 runtime 状态。
- 新增 `testOptimizationToggleRowLayoutPolicyMaintainsTouchTarget`，锁住最小触控目标、行最小高度映射和策略达标判断；测试函数数从 85 个增加到 86 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的运行策略开关行 44pt 触控目标基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.43（运行策略开关行触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `86`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。
- v2.43 push 后 GitHub Actions run `28843242474` 对最新 `origin/main` commit `a8ec2df05952dff953795966745051799576935d` 验收通过；artifact `localgemma-ci-v2.43-main-a8ec2df-run28843242474-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志、Mac baseline notes 和三个 `.xcresult/Info.plist` 已核对，新增 `testOptimizationToggleRowLayoutPolicyMaintainsTouchTarget` 在 `test.log` 中通过，required checks 全部 success。

遗留事项：

- 本轮只建立运行策略开关行 44pt 触控目标策略，没有做 Composer 发送/停止按钮触控目标策略、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.44 / Composer 发送停止触控目标

日期：2026-07-07

核心变更：

- Agent X 在 v2.43 最新 `origin/main` run 验收通过后继续优化 UI、Mac 和 iPad 体验；本轮选择推理页 composer 发送/停止按钮触控目标，归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.44（Composer发送停止触控目标）.md`。
- 新增 `ComposerInputAction` 和 `ComposerInputActionLayoutPolicy`，集中定义 composer 发送/停止按钮的 44pt 最小触控目标和 48pt 当前视觉尺寸。
- `ComposerBar` 复用策略常量设置发送/停止按钮尺寸；保留发送/停止闭包、空输入禁用、`Command+Return`、输入焦点、`ComposerInputMetadata` 辅助语义、本地模拟 runtime、模型文件状态和 verified 门禁边界。
- 新增 `testComposerInputActionLayoutPolicyMaintainsTouchTargets`，锁住最小触控目标、48pt 按钮尺寸、send/stop 两种 action、isGenerating 映射和 `composer-send-button` / `composer-stop-button` identifier 边界；测试函数数从 86 个增加到 87 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的 composer 发送/停止 44pt 触控目标基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.44（Composer发送停止触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `87`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。
- v2.44 push 后 GitHub Actions run `28845260084` 对最新 `origin/main` commit `80efd148722a71cda71eff156503a4f20c782f1d` 验收通过；artifact `localgemma-ci-v2.44-main-80efd14-run28845260084-attempt1` 的 manifest、`artifact-name.txt`、JUnit、failure summary、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志、Mac baseline notes 和三个 `.xcresult/Info.plist` 已核对，新增 `testComposerInputActionLayoutPolicyMaintainsTouchTargets` 在 `test.log` 中通过，required checks 全部 success。

遗留事项：

- 本轮只建立 Composer 发送/停止按钮 44pt 触控目标策略，没有做 SectionHeader Dynamic Type 多行策略、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.45 / SectionHeader 动态排版

日期：2026-07-07

核心变更：

- Agent X 在拉取最新 `origin/main` 后先验收 v2.44 最新文档 run：GitHub Actions run `28845890072` 对 `e3639b25ab60d0318e44e9ed394f529faba71cb9` 通过，artifact `localgemma-ci-v2.44-main-e3639b2-run28845890072-attempt1` 的 manifest、`artifact-name.txt`、JUnit、outcomes、关键日志和三个 `.xcresult/Info.plist` 已核对。
- 本轮继续优化 UI、Mac 和 iPad 体验；根据子 agent 只读审计选择 v2.44 遗留的共享 `SectionHeader` Dynamic Type 多行策略，归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.45（SectionHeader动态排版）.md`。
- 新增 `SectionHeaderTextLayoutPolicy`，集中定义共享小节标题的 vertical spacing、eyebrow tracking、eyebrow/title/subtitle 行数和多行标题能力。
- `SectionHeader` 改用 Dynamic Type 语义字体：eyebrow 使用 caption，title 使用 title2 并允许两行，subtitle 使用 subheadline 并允许多行；移除主标题单行压缩，改善 iPad/Mac 窄 split view 与较大文字设置下的标题可读性。
- 新增 `testSectionHeaderTextLayoutPolicySupportsDynamicTypeHeadings`，锁住共享标题策略常量和多行能力；测试函数数从 87 个增加到 88 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的共享 SectionHeader 动态排版基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.45（SectionHeader动态排版）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `88`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。
- v2.45 push 后 GitHub Actions run `28846998571` 对最新 `origin/main` commit `fddfb8eebf10b9f7205c90fb690ffe8df9ee7f03` 验收通过；artifact `localgemma-ci-v2.45-main-fddfb8e-run28846998571-attempt1` 的 manifest、`artifact-name.txt`、JUnit、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志、关键构建/测试日志和三个 `.xcresult/Info.plist` 已核对，新增 `testSectionHeaderTextLayoutPolicySupportsDynamicTypeHeadings` 在 `test.log` 中通过，required checks 全部 success。

遗留事项：

- 本轮只建立共享 SectionHeader Dynamic Type 多行策略，没有做完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.46 / 模型部署控件触控目标

日期：2026-07-07

核心变更：

- Agent X 在拉取最新 `origin/main` 后继续优化 UI、Mac 和 iPad 体验；根据两个子 agent 只读审计结果选择模型部署控件触控目标策略，归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.46（模型部署控件触控目标）.md`。
- 新增 `ModelDeploymentControlLayoutPolicy`，集中定义模型选择器和部署电源按钮的 44pt 最小触控目标、当前高度和稳定 identifier 映射。
- `ModelSelectorPanel` 的 Picker 触发区复用策略常量保持至少 44pt 命中高度；`DeploymentPowerButton` 使用策略常量保留 92pt 当前视觉高度。
- 新增 `testModelDeploymentControlLayoutPolicyMaintainsTouchTargets`，锁住模型选择器、部署电源按钮、控件枚举、identifier 映射和 44pt 达标判断；测试函数数从 88 个增加到 89 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的模型部署控件 44pt 触控目标基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.46（模型部署控件触控目标）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `89`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- 本轮只建立模型选择器和部署电源按钮 44pt 触控目标策略，没有做 Header 标题动态排版、设置偏好行文本动态排版、优化指标卡文本动态排版、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。

### v2.47 / Header 标题动态排版

日期：2026-07-07

核心变更：

- Agent X 在拉取最新 `origin/main` 后继续优化 UI、Mac 和 iPad 体验；根据子 agent 只读审计结果选择顶部 Header 标题动态排版策略，归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.47（Header标题动态排版）.md`。
- 新增 `HeaderTitleTextLayoutPolicy`，集中定义顶部 Header eyebrow 和主标题的 vertical spacing、eyebrow tracking、eyebrow/title 行数和多行标题能力。
- `HeaderView` 的 `LOCAL GEMMA` eyebrow 改用 Dynamic Type 语义字体并保持单行；`端侧大模型工作台` 主标题改用语义标题字体并允许两行，移除 `minimumScaleFactor` 单行压缩，降低 iPad split view、Mac Catalyst 窄窗口和较大文字设置下压缩或截断风险。
- 新增 `testHeaderTitleTextLayoutPolicySupportsDynamicTypeHeadings`，锁住 Header 标题策略常量和多行能力；测试函数数从 89 个增加到 90 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的 Header 标题动态排版基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.47（Header标题动态排版）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `90`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。

遗留事项：

- 本轮只建立 Header 标题 Dynamic Type 多行策略，没有做设置偏好行文本动态排版、优化指标卡文本动态排版、完整 UI Test target、真实 runtime 接入、模型 artifact 下载或原生 macOS target。
- v2.47 push 后 GitHub Actions run `28855068809` 对最新 `origin/main` commit `78384c07877b5ebd304579f06eeca94561105c52` 验收通过；artifact `localgemma-ci-v2.47-main-78384c0-run28855068809-attempt1` 已下载到 `/private/tmp/localgemma-c-review-28855068809/`，manifest、`artifact-name.txt`、JUnit、failure summary、outcomes、LogicSmoke 日志、Mac Catalyst run script 日志、关键构建/测试日志和三个 `.xcresult/Info.plist` 已核对，新增 `testHeaderTitleTextLayoutPolicySupportsDynamicTypeHeadings` 在 `test.log` 中通过，required checks 全部 success。

### v2.48 / 优化指标卡文本动态排版

日期：2026-07-11

核心变更：

- Agent X 继续推进全面优化 UI、Mac 和 iPad 体验；并发只读子 agent 确认优化指标卡仍使用固定小字号、单行限制和缩放压缩，本轮据此归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.48（优化指标卡文本动态排版）.md`。
- 新增 `OptimizerMetricTextLayoutPolicy`，集中定义指标卡 vertical spacing、状态圆点尺寸、label/value/detail 行数、detail lineSpacing 和最小卡片高度。
- `OptimizerMetricCard` 的 label、value 和 detail 改用 Dynamic Type 语义字体并允许多行，移除 label/value 的 `minimumScaleFactor` 单行压缩，改善 iPad split view、Mac Catalyst 窄窗口和较大文字设置下的可读性。
- 保留 `DeviceOptimizer.metrics` 数据、progress、tint、`OptimizerMetricAccessibilityMetadata`、`OptimizerMetricGridLayoutPolicy`、设置页整体宽度、模型文件、runtime 和 verified 门禁状态流。
- 新增 `testOptimizerMetricTextLayoutPolicySupportsDynamicTypeCards`，锁住策略常量、多行能力、至少 44pt 的最小卡片高度和既有网格阈值；测试函数数从 90 个增加到 91 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的优化指标卡文本动态排版基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.48（优化指标卡文本动态排版）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `rg -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `91`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -module-cache-path .build/SwiftSmokeModuleCache LocalGemma/AppState.swift Tools/LogicSmoke.swift -o .build/logic-smoke`：退出码 0。
- `.build/logic-smoke`：输出 `Logic smoke passed`。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -emit-module -emit-module-path .build/Typecheck/LocalGemma.swiftmodule -module-name LocalGemma -enable-testing -parse-as-library -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift`：退出码 0。
- `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target arm64-apple-ios17.0-simulator -module-cache-path .build/ModuleCache -I .build/Typecheck -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks LocalGemmaTests/LocalGemmaTests.swift`：退出码 0。
- 本轮按项目默认策略未在本机运行完整模拟器 XCTest；完整 iOS 与 Mac Catalyst build/test 由 push 后的 GitHub Actions 结果包验收。

遗留事项：

- Agent C 验收 v2.48 云端结果包通过：run `29138462221`，commit `d299798`，artifact `localgemma-ci-v2.48-main-d299798-run29138462221-attempt1`；required checks 全部 success。
- 本轮只完成优化指标卡文本动态排版；全面科技感视觉重构、设置偏好行文本动态排版、完整 UI Test target、真实 runtime 接入、模型 artifact 下载和原生 macOS target 仍属于后续迭代。

### v2.49 / 设置偏好行文本动态排版

日期：2026-07-12

核心变更：

- Agent X 在确认 v2.48 云端 artifact 验收通过后继续优化 UI、Mac 和 iPad 体验；本轮选择 v2.48 遗留的设置页外观/壁纸偏好行文本动态排版，归档 Agent A 提示词 `md/prompt/v2（Mac体验审计）/v2.49（设置偏好行文本动态排版）.md`。
- 新增 `SettingsPreferenceTextLayoutPolicy`，集中定义偏好行 vertical spacing、title/status 行数和多行能力。
- `ThemePreferencePanel` 与 `WallpaperPreferencePanel` 的标题与状态改用 Dynamic Type 语义字体并允许两行，移除固定小字号，改善 iPad split view、Mac Catalyst 窄窗口和较大文字设置下的可读性。
- 保留 `SettingsIconActionLayoutPolicy` 44pt 图标触控目标、主题切换、相册读取、本地压缩、恢复系统背景、辅助语义、设置页整体宽度、模型文件、runtime 和 verified 门禁状态流。
- 新增 `testSettingsPreferenceTextLayoutPolicySupportsDynamicTypeRows`，锁住策略常量、多行能力和与 44pt 图标策略共存关系；测试函数数从 91 个增加到 92 个。
- 同步 README、测试规范、核心流程文档、Mermaid 流程图、入口规则和 Agent A 提示词归档中的设置偏好行文本动态排版基线。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.49（设置偏好行文本动态排版）.md`

验证结果：

- `git diff --check`：无输出，退出码 0。
- `test -x script/build_and_run.sh`：退出码 0。
- `bash -n script/build_and_run.sh`：退出码 0。
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`：输出 `LocalGemma.xcodeproj/project.pbxproj: OK`。
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'`：输出 `yaml ok`。
- `rg -c "func test" LocalGemmaTests/LocalGemmaTests.swift`：输出 `92`。
- LogicSmoke compile/run：`Logic smoke passed`。
- Swift sources typecheck、emit-module、tests typecheck：退出码 0。
- 本轮按项目默认策略未在本机运行完整模拟器 XCTest / Xcode build；完整 iOS 与 Mac Catalyst build/test 由 push 后的 GitHub Actions 结果包验收。

验证补充（Agent C）：

- GitHub Actions run `29164006779` 对 `65cbb596d465c7814291399d1ef7d2c16525c03c` 通过；artifact `localgemma-ci-v2.49-main-65cbb59-run29164006779-attempt1` 已下载到 `/private/tmp/localgemma-c-review-29164006779/`。
- manifest 的 branch/commitSha/runId/runAttempt/version 与最新 run 一致；`artifact-name.txt`、JUnit（failures=0）、failure summary、outcomes、LogicSmoke/static 日志和三个 `.xcresult` 已核对。
- `test.log` 包含 `testSettingsPreferenceTextLayoutPolicySupportsDynamicTypeRows` 并通过；required checks 全部 success。

遗留事项：

- 本轮只完成设置偏好行文本动态排版；全面科技感视觉重构、模型胶囊/详情行等其余固定字号收敛、完整 UI Test target、真实 runtime 接入、模型 artifact 下载和原生 macOS target 仍属于后续迭代。

### v2.50 / 模型详情行文本动态排版

日期：2026-07-12

核心变更：

- Agent X 在 v2.49 云端验收通过后继续优化 UI、Mac 和 iPad 体验；选择模型详情 `DetailRow` / `AdviceRow` 固定小字号与缩放压缩问题，归档 `md/prompt/v2（Mac体验审计）/v2.50（模型详情行文本动态排版）.md`。
- 新增 `ModelDetailRowTextLayoutPolicy`，集中定义详情行间距、标题/数值/建议行数、建议行距和最小行高。
- `DetailRow` 与 `AdviceRow` 改用 Dynamic Type 语义字体并允许多行，移除 `DetailRow` `minimumScaleFactor`。
- 保留行级辅助语义、详情列宽、模型选择/部署、文件、runtime 和 verified 门禁。
- 新增 `testModelDetailRowTextLayoutPolicySupportsDynamicTypeRows`；测试函数数从 92 增加到 93。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.50（模型详情行文本动态排版）.md`

验证结果：

- 本地轻量检查：`git diff --check`、脚本、`plutil`、workflow YAML、测试函数统计 93、LogicSmoke、Swift typecheck（无本机完整 Xcode/Simulator XCTest）。
- 完整 iOS/Mac Catalyst 以 push 后 GitHub Actions 与 Agent C 验收为准。

验证补充（Agent C）：

- GitHub Actions run `29164309862` 对 `4c183ca21d0fa45ae569cf85c5a7c2aa4ff1b67c` 通过；artifact `localgemma-ci-v2.50-main-4c183ca-run29164309862-attempt1` 已下载到 `/private/tmp/localgemma-c-review-29164309862/`。
- manifest 的 branch/commitSha/runId/runAttempt/version 与最新 run 一致；`artifact-name.txt`、JUnit（failures=0）、failure summary、outcomes 和三个 `.xcresult` 已核对。
- `test.log` 包含 `testModelDetailRowTextLayoutPolicySupportsDynamicTypeRows` 并通过；required checks 全部 success。

遗留事项：

- 模型胶囊/HeaderMetric 等其余固定字号、全面视觉重构、UI Test target、真实 runtime、原生 macOS target 仍属后续。

### v2.51 / 模型胶囊文本动态排版

日期：2026-07-12

核心变更：

- Agent X 在 v2.50 云端验收通过后继续优化 UI、Mac 和 iPad 体验；选择顶部 `ModelCapsule` / `HeaderMetricChip` 固定小字号与缩放压缩问题，归档 `md/prompt/v2（Mac体验审计）/v2.51（模型胶囊文本动态排版）.md`。
- 新增 `ModelCapsuleTextLayoutPolicy`，集中定义胶囊间距、名称/状态/指标行数和指标最小高度。
- `ModelCapsule` 模型名与状态摘要、`HeaderMetricChip` 标题/数值改用 Dynamic Type 语义字体并允许多行，移除名称/状态/数值 `minimumScaleFactor`。
- 保留模型胶囊整体辅助语义、SIM/REAL 徽标语义、主题/工作区切换、模型文件、runtime 和 verified 门禁。
- 新增 `testModelCapsuleTextLayoutPolicySupportsDynamicTypeRows`；测试函数数从 93 增加到 94。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.51（模型胶囊文本动态排版）.md`

验证结果：

- 本地轻量检查：`git diff --check`、脚本、`plutil`、workflow YAML、测试函数统计 94、LogicSmoke、Swift typecheck（无本机完整 Xcode/Simulator XCTest）。
- 完整 iOS/Mac Catalyst 以 push 后 GitHub Actions 与 Agent C 验收为准。

验证补充（Agent C）：

- GitHub Actions run `29164563415` 对 `9ee9099e7e9dc594110d3a314cc4466fd105357c` 通过；artifact `localgemma-ci-v2.51-main-9ee9099-run29164563415-attempt1` 已下载到 `/private/tmp/localgemma-c-review-29164563415/`。
- manifest 的 branch/commitSha/runId/runAttempt/version 与最新 run 一致；`artifact-name.txt`、JUnit（failures=0）、failure summary、outcomes 已核对。
- `test.log` 包含 `testModelCapsuleTextLayoutPolicySupportsDynamicTypeRows` 并通过；required checks 全部 success。

验证补充（Agent C）：

- GitHub Actions run `29165018813` 对 `8551310d59b3a51efd1f5e9d6f1d23e9091a9537` 通过；artifact `localgemma-ci-v2.53-main-8551310-run29165018813-attempt1` 已下载到 `/private/tmp/localgemma-c-review-29165018813/`。
- manifest 的 branch/commitSha/runId/runAttempt/version 与最新 run 一致；`artifact-name.txt`、JUnit（failures=0）、failure summary、outcomes 已核对。
- `test.log` 包含 `testSessionChipTextLayoutPolicySupportsDynamicTypeTitles` 并通过；required checks 全部 success。

验证补充（Agent C）：

- GitHub Actions run `29165271962` 对 `1f9986a9582392114cc2f9d2aabac76257639ef1` 通过；artifact `localgemma-ci-v2.54-main-1f9986a-run29165271962-attempt1` 已下载到 `/private/tmp/localgemma-c-review-29165271962/`。
- manifest 的 branch/commitSha/runId/runAttempt/version 与最新 run 一致；`artifact-name.txt`、JUnit（failures=0）、failure summary、outcomes 已核对。
- `test.log` 包含 `testModelSelectorTextLayoutPolicySupportsDynamicTypeRows` 并通过；required checks 全部 success。

遗留事项：

- 其余固定字号收敛、全面视觉重构、UI Test target、真实 runtime、原生 macOS target 仍属后续。

### v2.52 / 模型部署电源按钮文本动态排版

日期：2026-07-12

核心变更：

- Agent X 在 v2.51 云端验收通过后继续优化 UI、Mac 和 iPad 体验；选择模型页 `DeploymentPowerButton` 固定字号与主标题缩放压缩问题，归档 `md/prompt/v2（Mac体验审计）/v2.52（模型部署电源按钮文本动态排版）.md`。
- 新增 `ModelDeploymentPowerTextLayoutPolicy`，集中定义电源按钮标题/副标题间距与行数。
- `DeploymentPowerButton` 主标题与副标题改用 Dynamic Type 语义字体并允许两行，移除主标题 `minimumScaleFactor`。
- 保留 `ModelDeploymentControlLayoutPolicy` 44pt 触控目标、部署启停状态流、辅助语义、模型文件、runtime 和 verified 门禁。
- 新增 `testModelDeploymentPowerTextLayoutPolicySupportsDynamicTypeRows`；测试函数数从 94 增加到 95。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.52（模型部署电源按钮文本动态排版）.md`

验证结果：

- 本地轻量检查：`git diff --check`、脚本、`plutil`、workflow YAML、测试函数统计 95、LogicSmoke、Swift typecheck（无本机完整 Xcode/Simulator XCTest）。
- 完整 iOS/Mac Catalyst 以 push 后 GitHub Actions 与 Agent C 验收为准。

验证补充（Agent C）：

- GitHub Actions run `29164782546` 对 `8489771c6a2fb3c9ee0a14883172cdce74e21519` 通过；artifact `localgemma-ci-v2.52-main-8489771-run29164782546-attempt1` 已下载到 `/private/tmp/localgemma-c-review-29164782546/`。
- manifest 的 branch/commitSha/runId/runAttempt/version 与最新 run 一致；`artifact-name.txt`、JUnit（failures=0）、failure summary、outcomes 已核对。
- `test.log` 包含 `testModelDeploymentPowerTextLayoutPolicySupportsDynamicTypeRows` 并通过；required checks 全部 success。

遗留事项：

- 会话 chip 标题等其余固定字号、全面视觉重构、UI Test target、真实 runtime、原生 macOS target 仍属后续。

### v2.53 / 会话 Chip 标题文本动态排版

日期：2026-07-12

核心变更：

- Agent X 在 v2.52 云端验收通过后继续优化 UI、Mac 和 iPad 体验；选择推理页 `SessionChip` 标题固定字号与缩放压缩问题，归档 `md/prompt/v2（Mac体验审计）/v2.53（会话Chip标题文本动态排版）.md`。
- 新增 `SessionChipTextLayoutPolicy`，集中定义会话标题行数与多行能力。
- `SessionChip` 标题改用 Dynamic Type 语义字体并允许两行，移除 `minimumScaleFactor`。
- 保留选择/删除 44pt 触控目标、会话状态流、composer 聚焦、辅助语义、模型文件、runtime 和 verified 门禁。
- 新增 `testSessionChipTextLayoutPolicySupportsDynamicTypeTitles`；测试函数数从 95 增加到 96。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.53（会话Chip标题文本动态排版）.md`

验证结果：

- 本地轻量检查：`git diff --check`、脚本、`plutil`、workflow YAML、测试函数统计 96、LogicSmoke、Swift typecheck（无本机完整 Xcode/Simulator XCTest）。
- 完整 iOS/Mac Catalyst 以 push 后 GitHub Actions 与 Agent C 验收为准。

遗留事项：

- 其余固定字号收敛、全面视觉重构、UI Test target、真实 runtime、原生 macOS target 仍属后续。

### v2.54 / 模型选择器文本动态排版

日期：2026-07-12

核心变更：

- Agent X 在 v2.53 云端验收通过后继续优化 UI、Mac 和 iPad 体验；选择模型页 `ModelSelectorPanel` 固定字号与缩放压缩问题，归档 `md/prompt/v2（Mac体验审计）/v2.54（模型选择器文本动态排版）.md`。
- 新增 `ModelSelectorTextLayoutPolicy`，集中定义选择器名称/规格行数与间距。
- 选中模型名与规格摘要改用 Dynamic Type 语义字体并允许两行，移除 `minimumScaleFactor`。
- 保留选择器 44pt 触控目标、模型选择状态流、辅助语义、部署/文件、runtime 和 verified 门禁。
- 新增 `testModelSelectorTextLayoutPolicySupportsDynamicTypeRows`；测试函数数从 96 增加到 97。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.54（模型选择器文本动态排版）.md`

验证结果：

- 本地轻量检查：`git diff --check`、脚本、`plutil`、workflow YAML、测试函数统计 97、LogicSmoke、Swift typecheck（无本机完整 Xcode/Simulator XCTest）。
- 完整 iOS/Mac Catalyst 以 push 后 GitHub Actions 与 Agent C 验收为准。

遗留事项：

- 其余固定字号收敛、全面视觉重构、UI Test target、真实 runtime、原生 macOS target 仍属后续。

### v2.55 / 模型概要标题文本动态排版

日期：2026-07-12

核心变更：

- Agent X 在 v2.54 云端验收通过后继续优化 UI、Mac 和 iPad 体验；选择模型页 `ModelSummaryPanel` 名称固定字号与缩放压缩问题，归档 `md/prompt/v2（Mac体验审计）/v2.55（模型概要标题文本动态排版）.md`。
- 新增 `ModelSummaryTextLayoutPolicy`，集中定义概要名称/简介行数、行距与间距。
- 模型名称与简介改用 Dynamic Type 语义字体，名称允许两行，简介允许多行，移除名称 `minimumScaleFactor`。
- 保留概要辅助语义、模型选择/部署、文件、runtime 和 verified 门禁。
- 新增 `testModelSummaryTextLayoutPolicySupportsDynamicTypeRows`；测试函数数从 97 增加到 98。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.55（模型概要标题文本动态排版）.md`

验证结果：

- 本地轻量检查：`git diff --check`、脚本、`plutil`、workflow YAML、测试函数统计 98、LogicSmoke、Swift typecheck（无本机完整 Xcode/Simulator XCTest）。
- 完整 iOS/Mac Catalyst 以 push 后 GitHub Actions 与 Agent C 验收为准。

验证补充（Agent C）：

- GitHub Actions run `29165656595` 对 `401344644e60fbafb6214b0a9b315e870c0349fa` 通过；artifact `localgemma-ci-v2.55-main-4013446-run29165656595-attempt1` 已下载到 `/private/tmp/localgemma-c-review-29165656595/`。
- manifest 的 branch/commitSha/runId/runAttempt/version 与最新 run 一致；`artifact-name.txt`、JUnit（failures=0）、failure summary、outcomes 已核对。
- `test.log` 包含 `testModelSummaryTextLayoutPolicySupportsDynamicTypeRows` 并通过；required checks 全部 success。

遗留事项：

- ArtifactActionButton / 侧栏副标题 / 导出标题等其余固定字号、全面视觉重构、UI Test target、真实 runtime、原生 macOS target 仍属后续。

### v2.56 / 模型文件动作按钮文本动态排版

日期：2026-07-12

核心变更：

- Agent X 在 v2.55 云端验收通过后继续优化 UI、Mac 和 iPad 体验；选择模型页 `ArtifactActionButton` 固定小字号与缩放压缩问题，归档 `md/prompt/v2（Mac体验审计）/v2.56（模型文件动作按钮文本动态排版）.md`。
- 新增 `ModelArtifactActionTextLayoutPolicy`，集中定义文件动作按钮标题/副标题行数、间距和最小高度。
- 标题与副标题改用 Dynamic Type 语义字体并允许两行，移除 `minimumScaleFactor`。
- 保留文件动作辅助语义、模拟暂存/卸载确认/扫描导入状态流、artifact 校验和 verified 门禁。
- 新增 `testModelArtifactActionTextLayoutPolicySupportsDynamicTypeRows`；测试函数数从 98 增加到 99。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.56（模型文件动作按钮文本动态排版）.md`

验证结果：

- 本地轻量检查：`git diff --check`、脚本、`plutil`、workflow YAML、测试函数统计 99、LogicSmoke、Swift typecheck（无本机完整 Xcode/Simulator XCTest）。
- 完整 iOS/Mac Catalyst 以 push 后 GitHub Actions 与 Agent C 验收为准。

验证补充（Agent C）：

- GitHub Actions run `29165957345` 对 `6c6b1c0df1fabb8206492f921e5f4c45acfc5f54` 通过；artifact `localgemma-ci-v2.56-main-6c6b1c0-run29165957345-attempt1` 已下载到 `/private/tmp/localgemma-c-review-29165957345/`。
- manifest 的 branch/commitSha/runId/runAttempt/version 与最新 run 一致；`artifact-name.txt`、JUnit（failures=0）、failure summary、outcomes 已核对。
- `test.log` 包含 `testModelArtifactActionTextLayoutPolicySupportsDynamicTypeRows` 并通过；required checks 全部 success。

遗留事项：

- 侧栏副标题 / 导出标题等其余固定字号、全面视觉重构、UI Test target、真实 runtime、原生 macOS target 仍属后续。

### v2.57 / 导出弹层标题文本动态排版

日期：2026-07-12

核心变更：

- Agent X 在 v2.56 云端验收通过后继续优化 UI、Mac 和 iPad 体验；选择导出弹层 `exportHeader` 标题固定字号与缩放压缩问题，归档 `md/prompt/v2（Mac体验审计）/v2.57（导出弹层标题文本动态排版）.md`。
- 新增 `ExportSessionTitleTextLayoutPolicy`，集中定义导出会话标题/摘要间距与行数。
- 导出会话标题与消息摘要改用 Dynamic Type 语义字体并允许两行，移除标题 `minimumScaleFactor`。
- 保留 ExportPayload、ShareLink 文件优先/文本兜底、剪贴板、分享/复制 44pt 触控目标、导出弹层宽屏宽度策略、辅助语义和会话状态流。
- 新增 `testExportSessionTitleTextLayoutPolicySupportsDynamicTypeRows`；测试函数数从 99 增加到 100。

关键文件：

- `LocalGemma/ContentView.swift`
- `LocalGemmaTests/LocalGemmaTests.swift`
- `AGENTS.md`
- `README.md`
- `md/test/test.md`
- `md/flow/flow.md`
- `md/flow/flowchart.md`
- `md/prompt/v2（Mac体验审计）/v2.57（导出弹层标题文本动态排版）.md`

验证结果：

- 本地轻量检查：`git diff --check`、脚本、`plutil`、workflow YAML、测试函数统计 100、LogicSmoke、Swift typecheck（无本机完整 Xcode/Simulator XCTest）。
- 完整 iOS/Mac Catalyst 以 push 后 GitHub Actions 与 Agent C 验收为准。

遗留事项：

- 侧栏副标题等其余固定字号、全面视觉重构、UI Test target、真实 runtime、原生 macOS target 仍属后续。
