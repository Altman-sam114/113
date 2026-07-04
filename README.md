# Local Gemma iOS Prototype

一个 SwiftUI iOS 原型 App，主打 iPhone、iPad 与 Mac Catalyst 构建/本地运行基线下部署 Gemma 1.5B 的产品形态。当前版本不下载模型权重，使用本地模拟推理引擎验证 UI、模型管理、流式输出、停止生成和苹果芯片部署优化面板。

## 当前范围

- `LocalGemma.xcodeproj`：可用 Xcode 打开的 iOS 工程，当前 app/test target 支持 iPhone、iPad，并已启用 Mac Catalyst build-for-testing 基线和项目内本地 build/run 入口；本轮没有创建原生 macOS target。
- `LocalGemma/AppState.swift`：模型清单、`LocalInferenceRuntime` 协议、模拟/真实占位 runtime、会话管理、导出文本生成、设备优化状态、本地模型 artifact manifest、`ModelArtifactStore`、`ModelArtifactHasher`、`LocalArtifactValidator`、手动导入错误处理和 Apple Silicon 运行计划。
- `LocalGemma/ContentView.swift`：支持暗色/亮色切换的 SwiftUI 界面，包含推理、模型、提示词、设置四个工作区；推理页改成极简会话界面，顶部 Gemma 模型胶囊集中展示运行状态、速度、内存、后端和权重状态；提示词模板独立成页；设置页整合外观、相册壁纸和芯片部署优化；iPhone 横屏、iPad 竖屏大画布和大屏窗口达到断点后会切换为左侧导航/模型状态栏、右侧工作区。
- `LocalGemmaTests/LocalGemmaTests.swift`：覆盖默认 Gemma 模拟状态、artifact missing/staged/verified 校验、手动导入文件复制、`.mlmodelc` 目录导入、启动自动扫描、本地模型管理状态流转、模拟输出、运行计划、优化开关、预设提示词模板、会话管理、Markdown 会话导出、iPhone/iPad/Mac Catalyst 桌面窗口布局断点和空输入保护。
- `Tools/LogicSmoke.swift`：不依赖 iOS runtime 的本地逻辑烟测，用来验证模拟模型、artifact 校验、手动导入文件复制、`.mlmodelc` 目录导入、启动自动扫描、模型管理状态流转、运行计划、提示词模板、会话管理、Markdown 导出与优化状态。
- `AGENTS.md`：项目入口记忆、基本规则、“人工目标 -> Agent A -> Agent B -> Agent C -> 人工复核”的单轮流程，以及未来 `agentx:` 主控 A/B/C 多轮循环的准备规则。
- `update_log.md`：版本更新记录、历史决策、完成事项和遗留问题。
- `md/test/test.md`：测试规范、测试分层、命令、触发条件和当前基线。
- `md/flow/flow.md`：当前核心数据流、执行流、状态对象、边界和未来扩展点。
- `md/flow/flowchart.md`：与 `flow.md` 同步的 Mermaid 可视化流程图。
- `md/prompt/`：Agent A 每轮输出给 Agent B 的详细实现提示词归档目录，按版本号管理；`md/prompt/README.md` 说明角色召唤、Agent X 循环提示词管理和云端阶段提示词要求。
- `script/build_and_run.sh`：项目内 Mac Catalyst 本地 build/run 入口，支持 `run`、`--build-only`、`--verify`、`--logs`、`--telemetry`、`--debug` 和 `--help`。
- `.github/workflows/ci-results.yml`：`main` push / 手动触发的 GitHub Actions workflow，生成 Agent C 可下载核对的未加密 CI 结果包。

## 运行方式

1. 打开 `LocalGemma.xcodeproj`。
2. 选择 `LocalGemma` scheme。
3. 选择 iPhone / iPad 模拟器或真机。
4. 运行 App。

可用以下命令在本机验证构建。当前机器的 `xcode-select` 指向 Command Line Tools，因此命令使用完整 Xcode 路径：

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
```

有可用 iOS 模拟器或真机后，可执行测试：

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/DerivedData \
  test
```

当前工程已允许 iPhone、iPad 和 Mac Catalyst build-for-testing。iPhone 竖屏保持单栏；iPhone 横屏、iPad Pro 竖屏大画布、Mac Catalyst 和足够大的桌面窗口达到 `WorkspaceLayoutMode` 断点后，App 主界面会切换为左侧状态/导航栏、右侧工作区；模型页仍会在宽度足够时切换为左侧选择/部署控制、右侧模型详情的两栏布局。当前没有原生 macOS target。

Mac Catalyst 本地 build/run 入口：

```sh
./script/build_and_run.sh --build-only
./script/build_and_run.sh
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
./script/build_and_run.sh --debug
```

脚本使用 `LocalGemma.xcodeproj` 和 `LocalGemma` scheme 构建 Debug Mac Catalyst app，DerivedData 固定在 `.build/DerivedDataCodex-MacCatalystRun`，默认模式会先停止旧的 `LocalGemma` 进程，再用 `/usr/bin/open -n` 启动新构建的 `.app`。`--build-only` 只构建并输出 app bundle 路径，适合无 GUI 环境；`--verify` 会启动后用进程检查确认是否运行，可能受本机窗口服务器、签名或沙箱权限影响。

本轮未提交 `.codex/environments/environment.toml`，因为当前 Codex 沙箱下项目内 `.codex` 路径不可写；稳定入口是 CLI `./script/build_and_run.sh`。CI manifest 会把 `codexRunEnvironmentCheckOutcome` 标记为 `skipped`，原因是 `not-added-in-v1.0-cli-entrypoint-only`。

Mac Catalyst 构建基线可用以下命令验证：

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -sdk macosx \
  -destination 'generic/platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath .build/DerivedDataCodex-Catalyst \
  -resultBundlePath .build/LocalGemma-maccatalyst-build.xcresult \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
```

## 协作与云端验证

项目协作默认使用 `main` 直推和云端重验证：Agent B 在本地完成轻量检查后提交并 push 到 `origin/main`，GitHub Actions 运行 `ci-results.yml`，上传包含 manifest、失败摘要、JUnit、日志和 Xcode 结果包的未加密 CI artifact。Agent C 必须下载该结果包，核对 `origin/main` 最新 commit、artifact name、run URL、run id、run attempt 和日志后再给出验收结论。

CI artifact 的版本号从最新 commit 主题开头的 `vX.Y` 提取，例如 `v1.0: ...` 会生成 `localgemma-ci-v1.0-main-<sha>-run<run_id>-attempt<attempt>`，避免结果包沿用旧版本号。v0.9 起，`ci-artifact-manifest.json` 明确记录 `artifactName`、`repository`、`commitSubject`、`runUrl`、`runId`、`runAttempt`、各阶段 outcome、`destination`、`macBaselineKind`、`macCatalystBuildOutcome` 和 Mac baseline 日志路径；v1.0 起，manifest 还记录 `macCatalystRunEntrypoint`、`macCatalystRunScriptCheckOutcome`、`macCatalystRunScriptLogPath`、`codexRunEnvironmentPath`、`codexRunEnvironmentCheckOutcome` 和 `codexRunEnvironmentSkippedReason`。`artifact-name.txt` 必须与 manifest 中的 `artifactName` 一致。

角色召唤约定：`agenta` / `a:` / `A:` 召唤 Agent A，`agentb` / `b:` / `B:` 召唤 Agent B，`agentc` / `c:` / `C:` 召唤 Agent C，`agentx` / `x:` / `X:` 召唤 Agent X。没有角色前缀时按普通 Codex 任务处理。

`agentx:` 用于后续启动主控循环。Agent X 接收人工总目标 X，把目标拆成多个小轮次，并按 Agent A 写提示词、Agent B 实现并 push、GitHub Actions 生成 artifact、Agent C 下载验收的顺序推进。Agent X 不直接替代 A/B/C，也不能跳过 Agent C 对最新 artifact 的验收；失败时必须退回修复或暂停，不能继续下一轮伪装成功。

当前本地仓库已配置 `origin` remote，Agent B 可按规则执行 `git push origin main` 触发云端重验证。若后续环境缺少 `origin`、push 权限或 GitHub Actions artifact 下载权限，必须明确报告阻塞，不能伪装为已 push、已运行 CI 或已完成 Agent C 验收。

## 模型状态

当前不会下载 Gemma 权重。`Gemma 1.5B Local` 默认处于 `Simulation` 状态，聊天流式输出经由 `LocalInferenceRuntime` 协议执行，默认实现是 `SimulatedGemmaRuntime`，文本由 `GemmaSimulationProvider` 生成。

模型管理页现在是一个单页部署控制台：

- `选择模型`：用下拉菜单切换当前模型，不再展开所有模型卡片；只有选中模型会显示详情。
- `启动模型部署` / `关闭模型部署`：大号部署按钮会切换当前模型的 `ModelDeploymentState`，并保证同一时间只有一个模型处于运行状态。
- `下载模型`：当前版本执行模拟暂存，不联网下载权重；用于验证下载后的 staged 状态和 UI 流程。
- `卸载模型`：删除 App 托管目录里的 manifest 必需文件，并停止当前模型部署。
- `导入文件`：打开 iOS Files picker，多选 manifest 指定的模型 artifact 和 tokenizer，复制到 `Application Support/LocalModels`，随后立即扫描并校验。文件名必须与 manifest 完全匹配，例如 Gemma 预留为 `gemma-1.5b-it-q4.mlmodelc` 和 `gemma-tokenizer.model`。
- `扫描本地`：检查 `Application Support/LocalModels` 里的 manifest 必需文件；若 manifest 已登记 concrete SHA-256 且文件齐全，会对本地模型 artifact 计算 SHA-256 并更新模型详情和聊天页运行状态。

App 启动时会自动扫描 `Application Support/LocalModels`，如果用户之前已经手动导入过 manifest 指定文件，会恢复到 `staged` 或 `verified` 状态；单元测试仍用注入目录隔离真实用户目录。聊天页会把当前选中模型的 artifact availability 传入 `InferenceRequest`，并在 `InferenceEngine.lastPreparationReport` 记录本次生成使用的端侧运行计划，同时在顶部 Gemma 模型胶囊显示本次响应是 `SIM` 还是 `REAL`、计划后端、速度、内存和权重状态。

推理页交互已做简化：

- 顶部只保留一个 Gemma 模型胶囊，速度、内存、后端和权重状态都收进这里，避免重复显示模型名。
- 会话栏参考 ChatGPT 网页端的历史列表结构，支持新建会话、切换会话、删除会话；会话会根据首条用户输入自动生成名字。
- 导出按钮会生成当前会话的 `.md` 文件，导出弹层显示会话摘要、正文预览和底部分享按钮，并通过系统分享面板分享 Markdown 文件。
- 输入区以 `问本地模型任何问题` 为主入口，只保留发送/停止一个核心动作按钮。

提示词页提供 `部署方案`、`隐私评审`、`芯片优化`、`技术总结`、`产品文案`、`排障清单` 六个模板，并支持按部署、隐私、性能、写作、产品、排障筛选。模板可先填入输入框再编辑，也可以通过卡片内发送按钮直接作为当前模型输入发送。

设置页集中放置外观和芯片策略：

- 太阳/月亮图标用于在暗色和亮色 UI 之间切换。
- 壁纸面板可以从系统相册选择图片作为 App 背景，也可以一键恢复系统背景；背景会叠加主题遮罩，保证文字可读。
- 原芯片工作区已整合到设置页，继续展示 A17 Pro / M 系列准备度、Metal 预热、KV cache、热状态和离线隐私保护。

Gemma 1.5B 已预留真实模型接入清单：

- 模型包：`gemma-1.5b-it-q4.mlmodelc`
- tokenizer：`gemma-tokenizer.model`
- 文件格式：Core ML compiled package
- 存储目录：`Application Support/LocalModels`
- 下载策略：`allowsNetworkDownload = false`，只接受后续手动导入或 Xcode 打包，不会自动联网下载权重
- 主运行后端：Core ML + ANE
- 回退后端：Metal Performance Shaders

`LocalArtifactValidator` 当前支持三种本地 artifact 状态：

- `missing`：缺少模型包或 tokenizer，真实 runtime 禁用，继续使用模拟输出。
- `staged`：文件已存在，但 Gemma manifest 仍为 `manual-import-required` 或 SHA-256 未匹配，真实 runtime 仍禁用。
- `verified`：必需文件存在且 concrete SHA-256 匹配，才允许 `RuntimePreparationReport.canRunRealWeights = true`。

对普通文件，`ModelArtifactHasher` 直接计算文件 SHA-256；对 `.mlmodelc` 这类目录 artifact，会按相对路径排序并组合文件路径与文件内容生成稳定目录哈希。`ModelArtifactStore.importArtifacts` 只复制用户通过 Files picker 选择的本地文件，不会联网拉取模型；缺少必需文件时会提示缺失文件名。当前 Gemma manifest 仍是 `manual-import-required`，所以不会误把未登记官方哈希的文件提升为真实 runtime。

后续接真实模型时，可以把 `RealGemmaRuntimePlaceholder` 替换为 Core ML、MLX Swift 或 llama.cpp 的推理适配层。当前占位 runtime 会在权重缺失时安全回退为模拟结果，明确拒绝下载模型；在 artifact 校验通过后才暴露真实运行计划、后端预热与 KV cache 策略。

## 苹果芯片部署优化预留

界面和状态层已预留以下能力：

- Metal graph prewarm
- Paged KV cache
- Adaptive token budget
- Offline privacy guard
- Core ML / ANE 编译路径展示
- 统一内存预算与热状态展示
- Artifact missing/staged/verified 状态、本地文件导入、扫描与 SHA-256 校验入口
- Core ML + ANE 主路径与 Metal fallback 运行计划
- `LocalInferenceRuntime` 边界，方便后续替换真实 Core ML / Metal 推理实现
- 单模型部署状态、启动/关闭控制、模拟下载和卸载本地 artifact

## 已完成验证

v1.0 本轮已完成本地轻量检查和 Mac Catalyst run 入口验证：

```sh
git diff --check
test -f script/build_and_run.sh
test -x script/build_and_run.sh
bash -n script/build_and_run.sh
plutil -lint LocalGemma.xcodeproj/project.pbxproj
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift
./script/build_and_run.sh --build-only
./script/build_and_run.sh --verify
```

结果：脚本存在且可执行，`bash -n` 通过；`plutil` 输出 `LocalGemma.xcodeproj/project.pbxproj: OK`；Ruby YAML 解析输出 `yaml ok`；测试函数数仍为 34；`--build-only` 成功输出 `.build/DerivedDataCodex-MacCatalystRun/Build/Products/Debug-maccatalyst/LocalGemma.app`；`--verify` 成功构建、启动并通过 `pgrep -x LocalGemma`。本轮未修改 Swift UI 行为，未新增 XCTest。

当前这轮已完成本地逻辑烟测：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -module-cache-path .build/SwiftSmokeModuleCache \
  LocalGemma/AppState.swift Tools/LogicSmoke.swift \
  -o .build/logic-smoke

.build/logic-smoke
```

结果：`Logic smoke passed`。

当前这轮已完成 Swift 编译器验证：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -typecheck \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path .build/ModuleCache \
  LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift
```

结果：通过。

同时已生成可测试导入的 `LocalGemma.swiftmodule`，并用 iPhone Simulator 的 XCTest framework 对测试源码做 API 层 typecheck。当前测试源码包含 34 个 `XCTestCase` 测试函数，覆盖提示词模板库、模板填入输入框、模板直接发送、会话创建/切换/删除、Markdown 会话导出、iPhone/iPad/Mac Catalyst 桌面窗口布局断点、壁纸处理和分享兜底：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -emit-module \
  -emit-module-path .build/Typecheck/LocalGemma.swiftmodule \
  -module-name LocalGemma \
  -enable-testing \
  -parse-as-library \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path .build/ModuleCache \
  LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift

/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -typecheck \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path .build/ModuleCache \
  -I .build/Typecheck \
  -I /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib \
  -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks \
  LocalGemmaTests/LocalGemmaTests.swift
```

结果：通过。

最近一次本地 iOS Xcode build system 验证记录如下。完整 iOS build/test 交由 `main` push 后的 GitHub Actions 结果包验收。

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -destination generic/platform=iOS \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
```

历史结果：`TEST BUILD SUCCEEDED`。

完整 iPhone 17 Pro 模拟器 XCTest 命令如下：

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  test \
  -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO
```

说明：当前 Codex 沙箱内的 CoreSimulator 访问受限；v1.0 本轮未默认重跑本机完整模拟器 XCTest。已在工作区内完成 `git diff --check`、`plutil -lint`、workflow YAML 解析、34 个测试函数统计、逻辑烟测、Mac Catalyst run script 静态检查、`--build-only` 和 `--verify`；完整 iOS XCTest 与云端 Mac Catalyst 重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

## 项目管理文档体系

当前已建立多 Agent 协作系统：

- `AGENTS.md`：后续 Agent 的入口规则和协作流程。
- `update_log.md`：版本历史、关键决策和遗留事项。
- `md/test/test.md`：测试分层和当前测试基线。
- `md/flow/flow.md`：当前真实核心逻辑文档。
- `md/flow/flowchart.md`：给人工快速读懂核心逻辑的 Mermaid 图。
- `md/prompt/README.md`：角色召唤、Agent X 循环提示词管理、提示词归档和云端阶段要求。
- `md/prompt/v0（项目管理体系）/v0.2（建立多Agent协作规范）.md`：本轮文档体系搭建的 Agent A 提示词归档。
- `.github/workflows/ci-results.yml`：main 直推后的云端 CI 结果包 workflow。

v0.4 将协作制度升级为 main 直推、云端重验证和 Agent C 结果包验收。本轮未修改 Swift 源码，未默认重跑本机完整 XCTest。已完成以下本地轻量检查要求：

```sh
find md -maxdepth 4 -type f | sort
grep -n "Agent A\\|Agent B\\|Agent C\\|README\\|测试规范" AGENTS.md
plutil -lint LocalGemma.xcodeproj/project.pbxproj
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

结果：`git diff --check` 无输出并退出 0；文档结构包含 `md/prompt/README.md`；`AGENTS.md` 覆盖 Agent A/B/C、README 和测试规范入口；`plutil` 输出 `LocalGemma.xcodeproj/project.pbxproj: OK`；Ruby YAML 解析输出 `yaml ok`。v0.4 执行环境当时尚未配置 `origin` remote，因此该历史版本未完成真实 `origin/main` push、GitHub Actions 试跑和 Agent C 结果包下载；当前仓库已配置 `origin`，后续以最新 push 触发的结果包为准。

v0.5 修复了 GitHub Actions run `28669343294` 暴露的 Swift 6 actor isolation 构建错误：`WallpaperPreferencePanel` 不再从 `PhotosPicker` 的可发送 label 闭包直接读取 `@Environment` theme，而是在闭包外捕获需要的颜色值。本轮不改变 UI 行为。已完成本机构建验证：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedDataCodex \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
```

结果：`** TEST BUILD SUCCEEDED **`。最新云端 `ci-results.yml` 结果以本轮 push 后的 GitHub Actions run 和下载结果包为准。

v0.7 校准云端验收闭环：当前仓库已配置 `origin`，CI 结果包 manifest 增加 `artifactName`、`repository`、`commitSubject`、`runUrl` 和各阶段 outcome，Agent C 下载后可直接核对 `artifact-name.txt`、manifest、JUnit、日志和 `.xcresult` 是否对应最新 `origin/main`。本轮不修改 Swift 业务源码、不接真实模型、不改变 UI 行为。

v0.8 启动 Agent X 第一轮适配体验优化：app/test target 改为 iPhone+iPad，`WorkspaceLayoutMode` 改为按容器尺寸进入 compact 双栏或 regular 大屏双栏，并新增 iPad Pro 竖屏和大屏窗口布局测试。本轮仍不创建 Mac 独立 target 或 Mac Catalyst target，不接真实模型，不下载权重。

v0.9 建立 Mac Catalyst build-for-testing 基线：app/test target 启用 `SUPPORTS_MACCATALYST`，CI 结果包新增 Mac Catalyst build outcome、日志、baseline notes 和 `.xcresult` 路径，并新增桌面窗口布局断点测试。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v1.0 建立 Mac Catalyst 本地 build/run 入口：新增 `script/build_and_run.sh`，并把脚本存在性、可执行权限和 `bash -n` 语法检查接入 CI 结果包。本轮未修改 Swift UI 行为，未新增 XCTest，`LocalGemmaTests.swift` 仍为 34 个测试函数；完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。
