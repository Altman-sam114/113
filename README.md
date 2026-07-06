# Local Gemma iOS Prototype

一个 SwiftUI iOS 原型 App，主打 iPhone、iPad 与 Mac Catalyst 构建/本地运行基线下部署 Gemma 1.5B 的产品形态。当前版本不下载模型权重，使用本地模拟推理引擎验证 UI、模型管理、流式输出、停止生成和苹果芯片部署优化面板。

## 当前范围

- `LocalGemma.xcodeproj`：可用 Xcode 打开的 iOS 工程，当前 app/test target 支持 iPhone、iPad，并已启用 Mac Catalyst build-for-testing 基线和项目内本地 build/run 入口；本轮没有创建原生 macOS target。
- `LocalGemma/AppState.swift`：模型清单、`LocalInferenceRuntime` 协议、模拟/真实占位 runtime、会话管理、导出文本生成、设备优化状态、本地模型 artifact manifest、`ModelArtifactStore`、`ModelArtifactHasher`、`LocalArtifactValidator`、手动导入错误处理和 Apple Silicon 运行计划。
- `LocalGemma/LocalGemmaApp.swift`：SwiftUI app 入口，创建共享状态对象，并在 scene 层注册 `工作区` 和 `会话` command menu，让 Mac Catalyst 和 iPad 外接键盘用户可从系统菜单发现 workspace 切换、新建会话和导出当前会话。
- `LocalGemma/ContentView.swift`：支持暗色/亮色切换的 SwiftUI 界面，包含推理、模型、提示词、设置四个工作区；推理页改成极简会话界面，顶部 Gemma 模型胶囊集中展示运行状态、速度、内存、后端和权重状态，并以整体辅助语义合并当前模型、SIM/REAL、artifact、后端、速度、内存和准备度；提示词模板独立成页，页面整体内容按 `PromptTemplatesWorkspaceLayoutPolicy` 在 iPad/Mac 超宽窗口居中并限制最大宽度，模板网格在窄屏单列、iPad/Mac 宽区域多列伸展之间自适应，模板卡片文本按 `PromptTemplateTextLayoutPolicy` 使用 Dynamic Type 语义字体、多行标题/副标题/正文和更高最小卡片高度，分类筛选 chip 会按 `PromptCategoryLayoutPolicy` 在窄屏换行并保持 44pt 触控高度，并按 `PromptCategoryTextLayoutPolicy` 使用 Dynamic Type 语义字体和两行文本策略，模板卡片填入和发送动作达到 44pt 触控目标；设置页整合外观、相册壁纸和芯片部署优化，外观主题、相册壁纸选择和恢复系统背景图标动作按 `SettingsIconActionLayoutPolicy` 保持 44pt 触控目标，Apple Silicon 优化指标网格与运行策略开关网格在窄屏单列、iPad/Mac 宽区域双列之间自适应；iPhone 横屏、iPad 竖屏大画布和大屏窗口达到断点后会切换为左侧导航/模型状态栏、右侧工作区；regular 大屏侧栏显示工作区用途说明，compact 侧栏保持紧凑；推理页内部会话侧栏在大屏按 `SessionSidebarLayoutPolicy` 限制宽度，会话栏新建/导出图标按钮按 `SessionBarActionLayoutPolicy` 保持 44pt 触控目标，底部 composer 在 iPad/Mac 宽区域居中并限制最大输入行宽；模型页足够宽时内部并列展示选择/部署/文件操作与模型详情，右侧详情栏按 `ModelDetailColumnLayoutPolicy` 限制最大阅读宽度，窄屏保持单栏；Mac Catalyst 和 iPad 外接键盘可用 `Command+1...4` 或系统 `工作区` 菜单切换工作区，可用系统 `会话` 菜单及 `Command+N` / `Command+Shift+E` 新建或导出当前会话，也可点击会话栏可见按钮，`Command+Return` 发送或停止；工作区导航、会话选择、会话 chip 动作、顶部模型胶囊、模型概要面板、模型详情右栏与行级内容、模型文件工作流面板、模型卸载确认弹层、模型状态徽章、聊天记录容器、聊天消息气泡、头部主题与模型工作区入口、设置页图标动作、会话栏操作、导出弹层分享/复制、壁纸控件、模型选择器、模型部署控件、运行策略开关、芯片准备度卡片/圆环、优化指标卡、提示词分类筛选和提示词模板动作会向辅助技术暴露稳定语义，芯片准备度摘要会随离线隐私保护开关显示开启或关闭，切回推理页、新建/切换会话、提示词模板填入或发送后会请求聚焦输入框。
- `LocalGemmaTests/LocalGemmaTests.swift`：覆盖默认 Gemma 模拟状态、artifact missing/staged/verified 校验、手动导入文件复制、`.mlmodelc` 目录导入、启动自动扫描、本地模型管理状态流转、模型卸载确认弹层状态流与辅助语义、模拟输出、运行计划、优化开关、运行策略开关辅助语义、运行策略开关宽屏网格、芯片准备度辅助语义与隐私状态动态摘要、优化指标卡辅助语义、优化指标网格宽度策略、提示词页整体宽屏内容宽度策略、提示词模板宽屏布局策略、提示词模板文本动态排版策略、提示词分类筛选换行布局策略、提示词分类文本动态排版策略、提示词模板动作 44pt 触控目标、顶部模型胶囊整体辅助语义、模型概要面板辅助语义、模型详情右栏与行级辅助语义、模型详情右栏最大阅读宽度策略、模型文件工作流面板辅助语义、模型状态徽章辅助语义、会话 chip 动作语义、聊天消息气泡与聊天记录容器辅助语义、聊天气泡宽屏宽度策略、composer 宽屏输入宽度策略、预设提示词模板、提示词分类筛选辅助语义、提示词模板动作辅助语义、会话管理、Markdown 会话导出、导出弹层分享/复制辅助语义、工作区导航辅助语义、头部主题与模型工作区入口辅助语义、设置页图标动作 44pt 触控目标、壁纸控件辅助语义、iPhone/iPad/Mac Catalyst 桌面窗口布局断点、模型页内部宽屏布局策略、模型选择器辅助语义、模型部署控件辅助语义、会话栏操作辅助语义、会话栏操作 44pt 触控目标、会话侧栏宽度策略、工作区快捷键映射、工作区 command menu 映射、会话 command menu focused route、regular 侧栏说明、选择语义、composer 输入焦点、控件标识与辅助语义和空输入保护。
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

当前工程已允许 iPhone、iPad 和 Mac Catalyst build-for-testing。iPhone 竖屏保持单栏；iPhone 横屏、iPad Pro 竖屏大画布、Mac Catalyst 和足够大的桌面窗口达到 `WorkspaceLayoutMode` 断点后，App 主界面会切换为左侧状态/导航栏、右侧工作区；regular 大屏侧栏显示工作区用途说明，compact 双栏保持紧凑；推理页内部竖向会话栏由 `SessionSidebarLayoutPolicy` 限制在 240 到 310 宽度区间，会话栏可见新建/导出按钮由 `SessionBarActionLayoutPolicy` 保持 44pt 触控目标；模型页由 `ModelLibraryLayoutMode` 按内部容器宽度选择单栏或双栏，足够宽的 iPad/Mac 高窗口会并列展示选择/部署/文件操作与模型详情，右侧详情栏由 `ModelDetailColumnLayoutPolicy` 使用剩余空间并限制最大阅读宽度，窄屏仍按原顺序单栏展示；提示词页整体内容由 `PromptTemplatesWorkspaceLayoutPolicy` 在 iPad/Mac 超宽区域居中并限制最大宽度，提示词模板网格在窄屏保持单列，在 iPad/Mac 宽区域多列伸展并限制最大卡片宽度，模板卡片文本由 `PromptTemplateTextLayoutPolicy` 控制多行可读性和最小高度，提示词分类筛选 chip 由 `PromptCategoryLayoutPolicy` 保持 44pt 触控目标并在窄屏换行，分类 chip 文本由 `PromptCategoryTextLayoutPolicy` 允许两行并使用 Dynamic Type 语义字体；设置页外观主题、相册壁纸选择和恢复系统背景图标动作由 `SettingsIconActionLayoutPolicy` 保持 44pt 触控目标，设置页和优化 dashboard 的 Apple Silicon 指标网格与运行策略开关网格在窄屏/窄 split view 下回退单列，在 iPad/Mac 宽区域保持双列。Mac Catalyst 和 iPad 外接键盘可用 `Command+1...4` 或系统 `工作区` 菜单切换工作区，可用系统 `会话` 菜单及 `Command+N` / `Command+Shift+E` 新建或导出当前会话，也可点击会话栏可见按钮，`Command+Return` 发送或停止；顶部模型胶囊、模型概要面板、模型详情右栏与行级内容、模型文件工作流面板、模型卸载确认弹层、模型状态徽章、会话 chip 选择/删除动作、聊天记录容器、聊天消息气泡、工作区导航、头部主题切换、模型工作区入口、设置页图标动作、会话栏操作、壁纸控件、模型选择器、模型部署电源和模型文件操作按钮、运行策略开关、芯片准备度卡片/圆环、优化指标卡、提示词分类筛选 chip、提示词模板填入和发送按钮暴露 label、value、hint、Voice Control 输入标签和稳定 identifier；芯片准备度摘要随 `Offline privacy guard` 开关动态显示离线隐私保护开启或关闭；切回推理页、新建/切换会话、提示词模板填入或发送后会请求聚焦输入框。当前没有原生 macOS target。

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

- `选择模型`：用下拉菜单切换当前模型，不再展开所有模型卡片；只有选中模型会显示详情；选择器会向辅助技术说明当前模型、参数量、量化、候选数量、artifact 状态和部署状态，并明确切换模型不会下载权重或启动真实 runtime。
- `启动模型部署` / `关闭模型部署`：大号部署按钮会切换当前模型的 `ModelDeploymentState`，并保证同一时间只有一个模型处于运行状态。
- `下载模型`：当前版本执行模拟暂存，不联网下载权重；用于验证下载后的 staged 状态和 UI 流程。
- `卸载模型`：先显示确认弹层；取消不删除文件、不停止部署，确认后才删除 App 托管目录里的 manifest 必需文件，并停止当前模型部署。
- `导入文件`：打开 iOS Files picker，多选 manifest 指定的模型 artifact 和 tokenizer，复制到 `Application Support/LocalModels`，随后立即扫描并校验。文件名必须与 manifest 完全匹配，例如 Gemma 预留为 `gemma-1.5b-it-q4.mlmodelc` 和 `gemma-tokenizer.model`。
- `扫描本地`：检查 `Application Support/LocalModels` 里的 manifest 必需文件；若 manifest 已登记 concrete SHA-256 且文件齐全，会对本地模型 artifact 计算 SHA-256 并更新模型详情和聊天页运行状态。

模型选择器、安装状态徽章、artifact 状态徽章、部署状态徽章、部署电源、模拟暂存、卸载确认入口、确认卸载/取消卸载按钮、扫描、导入按钮、模型文件工作流面板、模型概要面板、模型详情区域和详情参数/性能/建议行都暴露稳定的辅助技术 label/value/hint、Voice Control 输入标签和 identifier；辅助文案会明确切换模型不下载权重、不启动真实 runtime、状态徽章只展示本地模型状态、模拟暂存不联网下载，卸载按钮只打开确认弹层，确认后只删除 App 托管模型文件并停止部署，取消不会删除文件或停止部署，也不会删除用户 Files 中的原始文件，模型文件工作流只管理本地文件、扫描只读取本地 manifest 必需文件、Files 导入只复制用户选择的本地文件，概要面板只读取本地模型简介、能力标签和 artifact 校验摘要，详情摘要和行级内容只读取本地模型规格、artifact 状态、后端和运行计划，未 verified 的 artifact 不会运行真实权重。

App 启动时会自动扫描 `Application Support/LocalModels`，如果用户之前已经手动导入过 manifest 指定文件，会恢复到 `staged` 或 `verified` 状态；单元测试仍用注入目录隔离真实用户目录。聊天页会把当前选中模型的 artifact availability 传入 `InferenceRequest`，并在 `InferenceEngine.lastPreparationReport` 记录本次生成使用的端侧运行计划，同时在顶部 Gemma 模型胶囊显示本次响应是 `SIM` 还是 `REAL`、计划后端、速度、内存和权重状态；模型胶囊整体辅助语义会合并当前模型、参数、量化、artifact missing/staged/verified、后端、生成状态、速度、内存和准备度，并说明只展示本地状态、不下载权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。

推理页交互已做简化：

- 顶部只保留一个 Gemma 模型胶囊，速度、内存、后端和权重状态都收进这里，避免重复显示模型名。
- 会话栏参考 ChatGPT 网页端的历史列表结构，支持新建会话、切换会话、删除会话；系统 `会话` 菜单和会话栏可见按钮通过同一组 action 语义覆盖新建和导出当前会话动作；单个会话 chip 的选择和删除动作会向辅助技术说明本地会话切换、composer 聚焦、删除范围、默认空白当前会话不可删除原因、Voice Control 输入标签和稳定 identifier；会话栏按钮会向辅助技术说明快捷键、本地会话焦点流和本地 Markdown / 文本分享兜底，不会把会话发送到云端服务；会话会根据首条用户输入自动生成名字。
- 聊天记录容器会向辅助技术说明当前本地会话消息总数、最新消息角色、生成中状态、Voice Control 输入标签和稳定 identifier；单条消息气泡继续说明角色、正文或生成中状态、token 数和本地边界。
- 导出按钮会生成当前会话的 `.md` 文件，导出弹层显示会话摘要、正文预览、底部分享/复制按钮和 toolbar 分享入口；分享 Markdown、文本兜底和复制全文动作会向辅助技术说明本地文件、文本兜底、剪贴板和不发送云端服务边界。
- 输入区以 `问本地模型任何问题` 为主入口，只保留发送/停止一个核心动作按钮；输入框和发送/停止按钮有稳定的辅助技术 label/value/hint、Voice Control 输入标签和 identifier，按钮保留 `Command+Return`，hint 明确本地模拟 runtime、不下载权重、不启动真实 runtime、不发送云端服务且不绕过 verified 门禁；切回推理、新建/切换会话或使用模板后会请求聚焦。

提示词页提供 `部署方案`、`隐私评审`、`芯片优化`、`技术总结`、`产品文案`、`排障清单` 六个模板，并支持按部署、隐私、性能、写作、产品、排障筛选。提示词页标题、分类筛选和模板网格作为整体在 Mac/iPad 超宽窗口中居中并限制最大内容宽度；模板网格在窄屏保持单列，在 iPad/Mac 宽区域多列伸展并限制最大卡片宽度，避免旧固定宽度浪费宽屏空间。筛选 chip 会向 VoiceOver 和 Voice Control 暴露当前筛选、动作提示、输入标签和稳定 identifier。模板可先填入输入框再编辑，也可以通过卡片内发送按钮直接作为当前模型输入发送；模板动作会说明填入只写入 composer 且不发送 prompt，发送走本地模拟 runtime，不下载模型权重、不启动真实 runtime、不发送到云端服务，也不绕过 verified 门禁。

设置页集中放置外观和芯片策略：

- 太阳/月亮图标用于在暗色和亮色 UI 之间切换。
- 壁纸面板可以从系统相册选择图片作为 App 背景，也可以一键恢复系统背景；选择相册和恢复系统背景按钮会向辅助技术说明系统背景、相册图片已启用、正在处理、本地压缩和不发送云端服务边界；背景会叠加主题遮罩，保证文字可读。
- 原芯片工作区已整合到设置页，继续展示 A17 Pro / M 系列准备度、Metal 预热、KV cache、热状态和离线隐私保护；优化指标网格和运行策略开关网格窄屏单列、宽屏双列，优化指标卡会向辅助技术说明指标状态、进度、detail 和本地边界，不会下载权重、启动真实 runtime 或发送云端服务。

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
- 统一内存预算、热状态和离线隐私保护动态摘要展示
- Artifact missing/staged/verified 状态、本地文件导入、扫描与 SHA-256 校验入口
- Core ML + ANE 主路径与 Metal fallback 运行计划
- `LocalInferenceRuntime` 边界，方便后续替换真实 Core ML / Metal 推理实现
- 单模型部署状态、启动/关闭控制、模拟下载和确认后卸载本地 artifact

## 已完成验证

v2.33 本轮增加提示词页整体宽屏内容宽度策略：提示词页标题、分类筛选和模板网格作为整体在 iPad/Mac 超宽窗口中由 `PromptTemplatesWorkspaceLayoutPolicy` 居中并限制最大宽度，同时保留分类筛选、模板填入/发送、生成中禁用、composer 聚焦和辅助语义；`LocalGemmaTests.swift` 当前测试函数数为 77。

```sh
git diff --check
test -x script/build_and_run.sh
bash -n script/build_and_run.sh
plutil -lint LocalGemma.xcodeproj/project.pbxproj
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck ... LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift
.build/logic-smoke
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -typecheck ... LocalGemmaTests/LocalGemmaTests.swift
```

结果：`git diff --check` 无输出；脚本可执行且语法、pbxproj、workflow YAML 均通过；测试函数数为 77；`Logic smoke passed`；SwiftUI 源码 typecheck、测试模块生成和测试源码 typecheck 均通过。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

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

同时已生成可测试导入的 `LocalGemma.swiftmodule`，并用 iPhone Simulator 的 XCTest framework 对测试源码做 API 层 typecheck。当前测试源码包含 77 个 `XCTestCase` 测试函数，覆盖提示词模板库、提示词页整体宽屏内容宽度策略、提示词模板宽屏布局策略、提示词模板文本动态排版策略、提示词分类筛选换行布局策略、提示词分类文本动态排版策略、提示词模板动作 44pt 触控目标、提示词分类筛选辅助语义、提示词模板动作辅助语义、模板填入输入框、模板直接发送、会话创建/切换/删除、会话 command menu focused route、工作区导航辅助语义、设置页图标动作 44pt 触控目标、会话栏操作辅助语义、会话栏操作 44pt 触控目标、会话 chip 动作语义、聊天消息气泡与聊天记录容器辅助语义、聊天气泡宽屏宽度策略、composer 宽屏输入宽度策略、Markdown 会话导出、导出弹层分享/复制辅助语义、头部主题与模型工作区入口辅助语义、壁纸控件辅助语义、iPhone/iPad/Mac Catalyst 桌面窗口布局断点、模型页内部宽屏布局策略、模型详情右栏最大阅读宽度策略、顶部模型胶囊整体辅助语义、模型概要面板辅助语义、模型详情右栏与行级辅助语义、模型文件工作流面板辅助语义、模型卸载确认弹层状态流与辅助语义、模型选择器辅助语义、模型状态徽章辅助语义、模型部署控件辅助语义、运行策略开关辅助语义、运行策略开关宽屏网格、芯片准备度辅助语义与隐私状态动态摘要、优化指标卡辅助语义、优化指标网格宽度策略、会话侧栏宽度策略、工作区快捷键映射、工作区 command menu 映射、regular 侧栏说明、选择语义、composer 输入焦点、控件标识与辅助语义、壁纸处理和分享兜底：

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

说明：当前 Codex 沙箱内的 CoreSimulator 访问受限；v2.33 本轮未默认重跑本机完整模拟器 XCTest。已在工作区内完成 `git diff --check`、`plutil -lint`、workflow YAML 解析、77 个测试函数统计、逻辑烟测和 Swift typecheck；完整 iOS XCTest 与云端 Mac Catalyst 重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

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

v1.1 建立 Mac/iPad 键盘导航基线：`Command+1...4` 切换工作区，`Command+N` 新建会话，`Command+Shift+E` 导出，`Command+Return` 发送或停止；新增 workspace 快捷键映射测试，`LocalGemmaTests.swift` 增加到 35 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v1.2 增加 Mac/iPad `工作区` command menu 发现层：`LocalGemmaApp` 在 scene 层注册工作区命令，`ContentView` 通过 focused scene binding 暴露 workspace selection，菜单命令复用 `WorkspaceTab.commandItems`，新增 command menu 映射测试，`LocalGemmaTests.swift` 增加到 36 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v1.3 建立 Mac/iPad 侧栏选择语义基线：regular 大屏侧栏显示工作区用途说明，compact 侧栏保持紧凑；工作区和会话选择按钮补充可访问性 label/value 与选中状态，新增选择语义测试，`LocalGemmaTests.swift` 增加到 37 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v1.4 建立 Mac/iPad composer 输入焦点与辅助语义基线：切回推理页、新建/切换会话、提示词模板填入或发送后请求聚焦输入框；composer 输入框和发送/停止按钮补充可测试辅助技术文案，新增 composer metadata/focus policy 测试，`LocalGemmaTests.swift` 增加到 38 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v1.5 建立模型页内部宽屏布局策略：`ModelLibraryLayoutMode` 按内部容器宽度决定单栏或双栏，足够宽的 iPad/Mac 高窗口也能并列展示部署控制和模型详情，新增模型页布局策略测试，`LocalGemmaTests.swift` 增加到 39 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v1.6 增强提示词分类筛选辅助语义：提示词页分类 chip 补充可测试的 label、value、hint、Voice Control 输入标签和稳定 identifier，新增提示词分类辅助语义测试，`LocalGemmaTests.swift` 增加到 40 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v1.7 增加会话命令菜单发现层：`LocalGemmaApp` 注册系统 `会话` CommandMenu，`ChatWorkspace` 通过 focused route 暴露新建会话和导出当前会话动作，新增会话 command metadata/routing 测试，`LocalGemmaTests.swift` 增加到 42 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v1.8 抽取会话侧栏宽度策略：`SessionSidebarLayoutPolicy` 锁住推理页大屏会话列表宽度，窄屏单栏返回 0，Mac/iPad 双栏宽度限制在 240 到 310 之间，新增会话侧栏宽度策略测试，`LocalGemmaTests.swift` 增加到 43 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v1.9 增强模型部署控件辅助语义：`ModelDeploymentControlAccessibilityMetadata` 为模型部署电源、模拟暂存、卸载、扫描和导入按钮提供稳定 label/value/hint、Voice Control 输入标签和 identifier，新增模型部署控件辅助语义测试，`LocalGemmaTests.swift` 增加到 44 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.0 增强模型选择器辅助语义：模型页 Picker 补充稳定 label/value/hint、Voice Control 输入标签和 identifier，辅助 value 合并当前模型、参数量、量化、候选数量、artifact 状态和部署状态，新增模型选择器辅助语义测试，`LocalGemmaTests.swift` 增加到 45 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.1 增强会话栏操作辅助语义：推理页会话栏新建/导出按钮补充稳定 label/value/hint、Voice Control 输入标签和 identifier，并与系统 `会话` command menu 标题、快捷键和 focused route 对齐，新增会话栏操作辅助语义测试，`LocalGemmaTests.swift` 增加到 46 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.2 增强导出分享复制辅助语义：导出弹层分享 Markdown、文本兜底和复制全文动作补充稳定 label/value/hint、Voice Control 输入标签和 identifier，新增导出弹层动作辅助语义测试，`LocalGemmaTests.swift` 增加到 47 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.5 增强工作区导航辅助语义：顶部工作区 tab 和大屏 sidebar 工作区按钮补充稳定 label/value/hint、Voice Control 输入标签和 identifier，新增工作区导航辅助语义测试，`LocalGemmaTests.swift` 增加到 50 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.6 增强运行策略开关辅助语义：设置页和优化 dashboard 的运行策略开关补充稳定 label/value/hint、Voice Control 输入标签和 identifier，新增运行策略开关辅助语义测试，`LocalGemmaTests.swift` 增加到 51 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.7 增强芯片准备度辅助语义：设置页和优化 dashboard 的芯片准备度卡片/圆环补充中文辅助语义，准备度摘要随 `Offline privacy guard` 开关动态显示离线隐私保护开启或关闭，新增芯片准备度辅助语义测试，`LocalGemmaTests.swift` 增加到 52 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.8 增强模型胶囊整体辅助语义：顶部模型胶囊补充整体 label/value/hint、Voice Control 输入标签和 identifier，辅助 value 合并当前模型、SIM/REAL、artifact 状态、后端、生成状态、速度、内存和准备度，新增模型胶囊辅助语义测试，`LocalGemmaTests.swift` 增加到 53 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.9 增强模型详情右栏辅助语义：模型页详情右栏和窄屏详情段补充整体 label/value/hint、Voice Control 输入标签和 identifier，辅助 value 合并模型规格、artifact 状态、validation summary、性能预算、主/回退后端、KV cache、运行阻塞项和下一步，新增模型详情辅助语义测试，`LocalGemmaTests.swift` 增加到 54 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.10 增强提示词模板动作辅助语义：提示词模板卡片“填入”和“发送”按钮补充整体 label/value/hint、Voice Control 输入标签和稳定 identifier，填入动作说明只写入 composer 且不发送 prompt，发送动作说明走本地模拟 runtime、不发送到云端服务且不绕过 verified 门禁，新增模板动作辅助语义测试，`LocalGemmaTests.swift` 增加到 55 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.11 增强 Composer 控件标识与语音控制语义：composer 输入框补充稳定 identifier，发送/停止按钮改为保留文本语义的 icon-only `Label`，并补充 Voice Control 输入标签、按钮 identifier 和三态 hint；空输入、发送本地模拟 runtime、停止当前模拟生成都会说明不下载模型权重、不启动真实 runtime、不发送云端服务且不绕过 verified 门禁。测试函数数保持 55 个。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.12 增强优化指标卡辅助语义：设置页和优化 dashboard 的 Apple Silicon 指标卡补充整体 label/value/hint、Voice Control 输入标签和稳定 identifier，辅助 value 合并指标状态、进度百分比和 detail，hint 明确只展示本地优化摘要、不下载模型权重、不启动真实 runtime、不发送云端服务且不绕过 verified 门禁；新增优化指标卡辅助语义测试，`LocalGemmaTests.swift` 增加到 56 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.13 增强聊天消息气泡辅助语义：推理页用户消息、本地模型消息和系统状态消息补充整体 label/value/hint、Voice Control 输入标签和稳定 identifier，空本地模型消息会读作正在生成；新增聊天消息气泡辅助语义测试，`LocalGemmaTests.swift` 增加到 57 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.14 增强会话 chip 动作语义：推理页单个会话 chip 的选择和删除动作补充 label/value/hint、Voice Control 输入标签和稳定 identifier，选择动作说明本地会话切换和 composer 聚焦，删除动作说明只删除本地会话记录、不删除模型 artifact 或权重，并为默认空白当前会话暴露不可删除原因；新增会话 chip 动作语义测试，`LocalGemmaTests.swift` 增加到 58 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.15 增强聊天记录容器辅助语义：推理页消息列表容器补充 label/value/hint、Voice Control 输入标签和稳定 identifier，空记录、消息总数、最新消息角色和生成中状态会被合并为列表级摘要；新增聊天记录容器辅助语义测试，`LocalGemmaTests.swift` 增加到 59 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.16 增强模型状态徽章辅助语义：模型页安装状态、artifact 状态和部署状态徽章补充 label/value/hint、Voice Control 输入标签和稳定 identifier，徽章说明只展示本地模型状态，不下载模型权重、不启动真实 runtime、不发送云端服务且不绕过 verified 门禁；新增模型状态徽章辅助语义测试，`LocalGemmaTests.swift` 增加到 60 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.17 增强模型详情行级辅助语义：模型详情参数行、性能行和建议行补充 label/value/hint、Voice Control 输入标签和稳定 identifier，详情容器保留整体摘要并让行级元素可达；新增模型详情行级辅助语义测试，`LocalGemmaTests.swift` 增加到 61 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.18 增强模型概要面板辅助语义：模型页概要面板补充 label/value/hint、Voice Control 输入标签和稳定 identifier，概要 value 合并模型名称、简介、能力标签、artifact availability、validation summary、文件格式和包体大小；新增模型概要面板辅助语义测试，`LocalGemmaTests.swift` 增加到 62 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.19 增强模型文件工作流面板辅助语义：模型页文件工作流面板补充 label/value/hint、Voice Control 输入标签和稳定 identifier，面板 value 合并 artifact availability、validation summary、模拟暂存、卸载、扫描本地和 Files 手动导入入口；新增模型文件工作流面板辅助语义测试，`LocalGemmaTests.swift` 增加到 63 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.20 优化指标网格宽度策略：设置页和优化 dashboard 共用 `OptimizerMetricGrid` 与 `OptimizerMetricGridLayoutPolicy`，窄屏/窄 split view 使用单列，iPad/Mac 宽区域保持双列；新增优化指标网格宽度策略测试，`LocalGemmaTests.swift` 增加到 64 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.21 优化提示词模板宽屏布局策略：提示词页共用 `PromptTemplateGrid` 与 `PromptTemplateGridLayoutPolicy`，窄屏保持单列，iPad/Mac 宽区域多列伸展并限制最大卡片宽度；`PromptTemplateCard` 不再固定 230 宽；新增提示词模板宽屏布局策略测试，`LocalGemmaTests.swift` 增加到 65 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.22 优化聊天气泡宽屏宽度策略：推理页新增 `ChatBubbleLayoutPolicy`，用户消息在 iPad/Mac 宽区域不再固定 310pt，而是按容器宽度增长并封顶；本地模型和系统消息限制最大阅读宽度，避免 Mac 宽窗口文本行过长；新增聊天气泡宽屏宽度策略测试，`LocalGemmaTests.swift` 增加到 66 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.23 优化运行策略开关宽屏网格：设置页和优化 dashboard 共用 `OptimizationToggleGrid` 与 `OptimizationToggleGridLayoutPolicy`，窄屏/窄 split view 保持单列，iPad/Mac 宽区域双列展示四个运行策略开关；新增运行策略开关宽屏网格测试，`LocalGemmaTests.swift` 增加到 67 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.24 优化 Composer 宽屏输入宽度：推理页新增 `ComposerBarLayoutPolicy`，保持窄屏可用宽度，iPad/Mac 宽区域让 composer 居中并限制最大输入行宽；新增 composer 宽屏输入宽度策略测试，`LocalGemmaTests.swift` 增加到 68 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.25 优化提示词模板动作触控目标：提示词页新增 `PromptTemplateActionLayoutPolicy`，模板卡片“填入”和“发送”动作达到 44pt 触控目标，且最小卡片宽度继续容纳动作行；新增提示词模板动作触控目标测试，`LocalGemmaTests.swift` 增加到 69 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.26 增加模型卸载确认弹层：模型页卸载按钮改为先打开确认弹层，取消无副作用，确认后才删除 App 托管 artifact/tokenizer 并停止部署；新增卸载确认弹层辅助语义测试，`LocalGemmaTests.swift` 增加到 70 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.27 优化模型详情右栏最大阅读宽度：模型页宽屏双栏新增 `ModelDetailColumnLayoutPolicy`，右侧详情栏在 iPad/Mac 宽窗口中使用剩余空间但限制最大阅读宽度，窄屏单栏不启用固定详情列宽；新增模型详情右栏最大阅读宽度策略测试，`LocalGemmaTests.swift` 增加到 71 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.28 优化提示词分类筛选换行布局：提示词页新增 `PromptCategoryLayoutPolicy` 和 `PromptCategoryFlowLayout`，分类筛选 chip 从横向滚动改为自适应换行，窄屏可直接看到全部筛选入口，iPad/Mac 宽区域可单行完整展示，并保持 44pt 触控高度；新增提示词分类筛选换行布局策略测试，`LocalGemmaTests.swift` 增加到 72 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.29 优化提示词模板文本动态排版：提示词页新增 `PromptTemplateTextLayoutPolicy`，模板卡片主要文本改用 Dynamic Type 语义字体，标题/副标题/正文允许多行显示并提高最小卡片高度，减少 iPad/Mac、窄 split view 和较大文字设置下的截断；新增提示词模板文本动态排版测试，`LocalGemmaTests.swift` 增加到 73 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.30 优化提示词分类文本动态排版：提示词页新增 `PromptCategoryTextLayoutPolicy`，分类筛选 chip 从固定 11pt 字体改为 Dynamic Type 语义字体，并允许两行文本，减少较大文字设置和窄 split view 下的可读性风险；新增提示词分类文本动态排版测试，`LocalGemmaTests.swift` 增加到 74 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.31 优化会话栏操作触控目标：推理页新增 `SessionBarActionLayoutPolicy`，会话栏新建和导出可见图标按钮从 34pt 提升到 44pt，横向会话栏和 iPad/Mac 大屏竖向会话栏共享同一触控目标策略；新增会话栏操作触控目标测试，`LocalGemmaTests.swift` 增加到 75 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.32 优化设置页图标动作触控目标：设置页新增 `SettingsIconActionLayoutPolicy`，外观主题切换、相册壁纸选择和恢复系统背景三个图标动作统一达到 44pt 触控目标；新增设置页图标动作触控目标测试，`LocalGemmaTests.swift` 增加到 76 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.33 优化提示词页整体宽屏内容宽度：提示词页新增 `PromptTemplatesWorkspaceLayoutPolicy`，标题、分类筛选和模板网格在 iPad/Mac 超宽窗口中整体居中并限制最大内容宽度，最大宽度从四列模板网格最大宽度派生；新增提示词页整体宽屏内容宽度测试，`LocalGemmaTests.swift` 增加到 77 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
