# 项目核心流程文档

一句话总览：本项目是一个 SwiftUI iOS 原型，通过本地模拟 runtime 和严格 artifact 校验流程，验证 iPhone、iPad 与 Mac Catalyst build/run 基线下端侧部署 Gemma 1.5B 的 UI、状态管理、文件导入、会话导出、导出弹层分享/复制辅助语义、顶部模型胶囊整体辅助语义、模型详情右栏与行级辅助语义、模型状态徽章辅助语义、会话 chip 动作语义、聊天消息气泡与聊天记录容器辅助语义、工作区导航辅助语义、头部主题与模型库入口辅助语义、运行策略开关辅助语义、芯片准备度辅助语义、优化指标卡辅助语义、提示词模板动作辅助语义、壁纸控件辅助语义、大屏布局和 Apple Silicon 运行计划；协作流程默认采用 `main` 直推、GitHub Actions 云端重验证和 Agent C 下载结果包验收。

本文只写当前真实链路，不写历史流水账。

## 当前核心数据流

1. App 启动。
2. `LocalGemmaApp` 创建三个共享状态对象：
   - `ModelCatalog(autoScanLocalArtifacts: true)`
   - `InferenceEngine()`
   - `DeviceOptimizer()`
   - 并在 scene 层注册 `工作区` 和 `会话` command menu。
3. `ContentView` 通过 `EnvironmentObject` 读取共享状态。
4. `ModelCatalog` 初始化默认模型列表，并扫描 `Application Support/LocalModels`。
5. `LocalArtifactValidator` 根据 manifest、必需文件和 SHA-256 产出 artifact 状态。
6. UI 顶部模型胶囊展示当前模型、速度、内存、后端、artifact 状态和模拟/真实标记，并用整体辅助语义合并这些本地状态。
7. 用户在推理页输入 prompt。
8. `InferenceEngine.send(using:availability:)` 创建用户消息和 assistant 占位消息。
9. `SimulatedGemmaRuntime.generate` 根据 prompt 和模型生成模拟回答。
10. `InferenceEngine` 分 chunk 流式写回 messages，并同步 active session。
11. 用户可导出当前会话，生成 Markdown 文本和临时 `.md` 文件。
12. 分享视图优先分享真实存在的 Markdown 文件；文件不存在时分享文本，导出弹层分享/复制动作向辅助技术说明本地文件、文本兜底和剪贴板边界。

## 当前核心执行流

### App 启动

- `LocalGemmaApp` 是入口。
- `ModelCatalog` 会自动扫描本地 artifact。
- 如果文件缺失，Gemma 默认保持 `simulated`。
- 如果文件存在但 hash 未验证，状态为 `staged`。
- 如果 concrete SHA-256 匹配，状态为 `verified`。

### 模型管理

- 用户在模型页选择模型。
- `ModelCatalog.select` 更新 `selectedModel`。
- `startDeployment` 会停止其他模型，只让一个模型运行。
- `toggleDeployment` 在 running / stopped 之间切换。
- `simulateDownload` 只模拟 staged，不联网下载。
- `importArtifacts` 从 Files picker 复制用户选择的本地文件。
- `uninstallArtifacts` 删除 App 托管目录中的 manifest 必需文件，并停止部署。

### 推理

- 当前默认 runtime 是 `SimulatedGemmaRuntime`。
- `InferenceRequest` 携带 prompt、model、artifact availability。
- `LocalRuntimePlanner` 为当前 availability 生成运行计划。
- `RealGemmaRuntimePlaceholder` 不是默认 runtime，只是未来真实 runtime 的安全边界示例。
- 权重未 verified 时，真实 runtime 占位必须安全回退模拟说明。

### UI 工作区

- `ContentView` 包含四个工作区：推理、模型、提示词、设置。
- 小屏容器使用顶部 header、tab picker 和分页工作区。
- iPhone 横屏、iPad 大画布、Mac Catalyst 或其他大屏窗口达到断点后使用左侧状态/导航栏和右侧工作区。
- `WorkspaceLayoutMode` 负责按容器尺寸判断 portrait、landscapeCompact、landscapeRegular；case 名称保留历史兼容，但 v0.8 起含义是单栏、compact 双栏和 regular 大屏双栏。
- `WorkspaceLayoutMode.usesDetailedSidebar` 只在 regular 大屏双栏启用，用于让 Mac/iPad 大画布侧栏显示一行 workspace 用途说明；compact 双栏保持紧凑按钮。
- `ModelLibraryLayoutMode` 只控制模型页内部部署控制台的单栏/双栏；足够宽的 iPad/Mac 模型页显示“选择/部署/文件操作”和“模型详情”并列，窄屏继续单栏。
- `HeaderActionAccessibilityMetadata` 为全局头部主题切换、设置页外观主题按钮和打开模型工作区按钮生成 label/value/hint/input labels/identifier；文案说明当前主题、切换目标、本地 UI 外观边界、模型工作区跳转边界、不下载模型权重、不启动真实 runtime、不发送云端服务和不绕过 verified 门禁。
- `ModelCapsuleAccessibilityMetadata` 为顶部模型胶囊生成整体 label/value/hint/input labels/identifier；value 合并当前模型、参数量、量化、安装状态、SIM/REAL 标记、artifact availability、生成状态、后端、速度、内存和准备度，hint 说明它只展示本地状态摘要，不下载模型权重、不启动真实 runtime、不发送到云端服务、不绕过 verified 门禁。
- `ModelDetailAccessibilityMetadata` 为模型页详情右栏和窄屏详情段生成整体 label/value/hint/input labels/identifier；value 合并模型规格、artifact availability、validation summary、预计速度、内存预算、主后端、回退后端、KV cache、运行阻塞项和下一步，hint 说明它只展示本地模型详情，不下载模型权重、不启动真实 runtime、不发送到云端服务、不绕过 verified 门禁。
- `ModelDetailRowAccessibilityMetadata` 为模型详情参数行、性能行和建议行生成行级 label/value/hint/input labels/identifier；`ModelDetailColumn` 使用 `.contain` 保留整体详情摘要并让行级元素可达，hint 说明行级内容只展示本地模型详情，不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `ModelDeploymentControlAccessibilityMetadata` 为模型页选择器、部署电源按钮和 artifact 操作按钮生成 label/value/hint/input labels/identifier；文案明确切换模型不下载权重、不启动真实 runtime、模拟暂存不联网下载、未 verified 不运行真实权重，不改变 `ModelCatalog` 状态流。
- `ModelStatusBadgeAccessibilityMetadata` 为模型页安装状态、artifact 状态和部署状态徽章生成 label/value/hint/input labels/identifier；文案明确徽章只展示本地模型状态，不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `SessionSidebarLayoutPolicy` 只控制推理页内部大屏会话列表宽度；竖向会话栏按容器宽度 28% 计算，并限制在 240 到 310 之间，窄屏单栏返回 0。
- `WorkspaceTab.shortcutKey` 定义工作区键盘导航：`Command+1` 推理、`Command+2` 模型、`Command+3` 提示词、`Command+4` 设置。
- `WorkspaceNavigationAccessibilityMetadata` 为顶部工作区 tab 和大屏 sidebar 工作区按钮生成 label/value/hint/input labels/identifier；hint 复用 `WorkspaceTab.sidebarSubtitle`，说明 `Command 1...4` 快捷键和只切换本地工作区边界，不改变 `selectedTab` 状态流或 command menu 映射。
- `LocalGemmaApp` 的 `工作区` command menu 复用同一组 `WorkspaceTab` 映射；`ContentView` 只通过 focused scene binding 暴露 `selectedTab`，菜单命令不触碰模型、artifact、runtime 或会话状态；进入推理页时只请求 UI 层 composer focus。
- `LocalGemmaApp` 的 `会话` command menu 复用 `SessionCommandAction` 映射；`ChatWorkspace` 通过 `SessionCommandActions` focused value 暴露新建会话和导出当前会话动作，菜单不直接持有 `InferenceEngine` 或导出 sheet 状态。
- `SessionBarActionAccessibilityMetadata` 复用 `SessionCommandAction` 为会话栏可见的新建/导出按钮生成 label/value/hint/input labels/identifier；文案说明新建会话只请求 composer focus，导出使用本地 Markdown / 文本分享兜底且不发送到云端服务。
- `SessionChipActionAccessibilityMetadata` 为推理页单个会话 chip 的选择和删除动作生成 label/value/hint/input labels/identifier；选择动作只切换本地会话并请求 composer 输入焦点，不发送 prompt、不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁；删除动作只作用于本地会话列表，不删除模型 artifact 或权重，并为默认空白当前会话说明不可删除原因。
- `ChatMessageAccessibilityMetadata` 为推理页聊天消息气泡生成整体 label/value/hint/input labels/identifier；value 合并用户、本地模型或系统状态角色、正文或正在生成状态、token 数和本地会话边界，hint 说明消息气泡只展示本地会话内容，不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `ChatTranscriptAccessibilityMetadata` 为推理页聊天记录容器生成 label/value/hint/input labels/identifier；value 合并空记录、消息总数、最新消息角色和生成中摘要，hint 说明只浏览当前本地会话消息列表，不发送 prompt、不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `ExportSessionActionAccessibilityMetadata` 为导出弹层的分享 Markdown 文件、文本分享兜底和复制全文动作生成 label/value/hint/input labels/identifier；文案说明本地 Markdown、文本兜底、系统剪贴板和不发送到云端服务边界。
- `WallpaperPreferenceAccessibilityMetadata` 为设置页选择相册壁纸和恢复系统背景按钮生成 label/value/hint/input labels/identifier；文案说明系统相册、本地压缩、`AppStorage` 背景数据、系统背景恢复和不发送到云端服务边界。
- `OptimizationToggleAccessibilityMetadata` 为设置页和优化 dashboard 的运行策略开关生成 label/value/hint/input labels/identifier；文案说明开启/关闭状态、策略说明、只切换本地运行策略、不下载模型权重、不启动真实 runtime 和不发送到云端服务边界。
- `ChipReadinessAccessibilityMetadata` 为设置页和优化 dashboard 的芯片准备度卡片与圆环生成 label/value/hint/input labels/identifier；卡片摘要复用 `DeviceOptimizer.isOfflinePrivacyGuardEnabled`，随 `Offline privacy guard` 开关显示离线隐私保护开启或关闭，并说明本地芯片准备度、不下载模型权重、不启动真实 runtime 和不发送到云端服务边界。
- `OptimizerMetricAccessibilityMetadata` 为设置页和优化 dashboard 的 Apple Silicon 指标卡生成 label/value/hint/input labels/identifier；value 合并指标状态、进度百分比和 detail，hint 说明指标卡只展示本地优化摘要，不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `SelectionAccessibilityMetadata` 为 workspace 和会话选择生成 label/value，当前选中项通过 `.isSelected` trait 暴露给辅助技术，不改变业务状态。
- `PromptCategoryAccessibilityMetadata` 为提示词分类筛选 chip 生成 label/value/hint/input labels/identifier，当前筛选项通过 `.isSelected` trait 暴露给辅助技术，不改变模板筛选业务结果。
- `PromptTemplateActionAccessibilityMetadata` 为提示词模板卡片的“填入”和“发送”动作生成 label/value/hint/input labels/identifier；填入动作只写入 composer、切回推理页并聚焦输入框，不发送 prompt；发送动作走本地模拟 runtime，不下载模型权重、不启动真实 runtime、不发送到云端服务，也不绕过 verified 门禁。
- `ComposerFocusRequest`、`ComposerFocusPolicy` 和 `ComposerInputMetadata` 只管理 view 层输入焦点、输入框标识和发送/停止控件辅助语义；切回推理页、新建/切换会话、提示词模板填入或发送后会请求 composer 聚焦，不写入 `InferenceEngine` 业务状态；composer 输入框与发送/停止按钮暴露稳定 identifier、Voice Control input labels、`Command+Return` 语义、本地模拟 runtime 边界、不下载模型权重、不启动真实 runtime、不发送云端服务和不绕过 verified 门禁。
- `会话` command menu 支持 `Command+N` 新建会话、`Command+Shift+E` 导出当前会话；会话栏保留可见按钮入口；composer 支持 `Command+Return` 发送 prompt 或停止生成，普通 Return 继续保留给 vertical input。

### Mac Catalyst 本地运行入口

- `script/build_and_run.sh` 是项目内 Mac Catalyst 本地 build/run 入口，不属于 Swift app 源码目录。
- 脚本使用 `LocalGemma.xcodeproj`、`LocalGemma` scheme、`platform=macOS,variant=Mac Catalyst` destination 和 `.build/DerivedDataCodex-MacCatalystRun`。
- 默认模式会停止旧的 `LocalGemma` 进程、构建 Debug Mac Catalyst app，并通过 `/usr/bin/open -n` 启动 `.app`。
- `--build-only` 只构建并输出 app bundle 路径；`--verify` 启动后用进程检查确认运行；`--logs`、`--telemetry` 和 `--debug` 分别用于日志流和 lldb 调试。
- 当前没有提交 `.codex/environments/environment.toml`，因为当前 Codex 沙箱下项目内 `.codex` 路径不可写；Codex Run action 在 v1.0 结果包中标记为 `skipped`，原因是 `not-added-in-v1.0-cli-entrypoint-only`。
- 脚本不下载模型权重、不访问外部推理服务、不写入模型 artifact 目录。

### 壁纸

- 设置页使用 `PhotosPicker` 选择系统相册图片。
- `WallpaperImageProcessor` 将图片缩放和压缩为 JPEG。
- 压缩后的数据存入 `@AppStorage("customWallpaperImageData")`。
- `AppBackground` 使用壁纸并叠加主题遮罩，保证文字可读。
- `WallpaperPreferenceAccessibilityMetadata` 让选择相册壁纸和恢复系统背景控件暴露稳定辅助语义；它只描述系统背景、相册图片已启用、导入中、本地压缩和云端边界，不改变相册读取、压缩或 `AppStorage` 写入。

### 分享

- `InferenceEngine.exportActiveSessionText` 生成 Markdown 文本。
- `exportActiveSessionMarkdownFile` 写临时 `.md` 文件。
- `ExportPayload.existingFileURL` 检查文件是否真实存在。
- `ExportSessionView` 优先 `ShareLink(item: fileURL)`；否则 `ShareLink(item: payload.text)`。
- 复制全文使用系统剪贴板。
- `ExportSessionActionAccessibilityMetadata` 让底部分享、toolbar 分享和复制全文按钮暴露稳定辅助语义，不改变分享内容或剪贴板写入。

## 云端协作流

### 角色入口

- `agenta`、`a:`、`A:` 召唤 Agent A。
- `agentb`、`b:`、`B:` 召唤 Agent B。
- `agentc`、`c:`、`C:` 召唤 Agent C。
- `agentx`、`x:`、`X:` 召唤 Agent X。
- 没有角色前缀时按普通 Codex 任务处理；如任务需要 A/B/C/X 边界，应提醒人工指定角色或说明本轮按普通任务执行。

### Agent X 主控循环

Agent X 是未来用于总目标 X 的主控调度层，不直接替代 Agent A、Agent B 或 Agent C。它只负责拆轮次、调度顺序、读取每轮结果并决定下一步。

Agent X 循环的当前文档基线：

1. 人工用 `agentx`、`x:` 或 `X:` 给出总目标 X。
2. Agent X 将总目标拆成一个可独立验证的小轮次。
3. Agent X 调用 Agent A 写本轮版本化 Agent B 提示词。
4. Agent B 基于最新 `origin/main` 在 `main` 上实现、轻量检查、commit 并 push。
5. GitHub Actions 对最新 `origin/main` commit 运行 CI，并上传未加密结果包。
6. Agent C 下载最新 run 的 artifact，核对 manifest、`artifact-name.txt`、JUnit、日志和 `.xcresult` 或等价结果。
7. Agent X 根据 Agent C 结论判断：继续下一轮、退回 Agent B 修复、暂停等待人工确认，或宣布总目标完成。

Agent X 不能跳过 Agent C artifact 验收；失败时不能继续下一轮并伪装成功。若连续 3 轮遇到同一阻塞、连续 2 轮没有有效 diff、CI 连续失败且原因相同，或需要账号、权限、密钥、付费服务、人工决策和无法判断归属的工作区冲突，Agent X 必须暂停或停止并报告原因。

### Agent A

- 本地读取入口文档、核心流程、测试规范、prompt README、相关源码和 workflow。
- 把人工目标拆成版本化 Agent B 提示词。
- 提示词必须写清本地轻量检查、`main` push、GitHub Actions 结果包、Agent C 下载核对和禁止项。
- 提示词归档到 `md/prompt/v0（简要标题）/vX.Y（简要说明）.md`。

### Agent B

- 基于最新 `origin/main` 在 `main` 上实现。
- 本机默认只跑轻量检查，例如 `git diff --check`、`plutil -lint`、YAML 解析、Probe / Fast。
- 提交本轮相关文件，commit 主题使用 `<版本号>: <一句话概括>`。
- 直接 `git push origin main`，由 GitHub Actions 运行 build / test / 静态检查 / 项目探针。
- 如果 `origin` 不存在或没有 push 权限，必须报告阻塞，不能伪装云端验证。

### GitHub Actions

- `.github/workflows/ci-results.yml` 在 `main` push 和 `workflow_dispatch` 触发。
- CI 运行静态检查、逻辑烟测、iOS Simulator build-for-testing、Mac Catalyst build-for-testing、Mac Catalyst run script contract 和可用模拟器 XCTest。
- CI 上传未加密结果包，不复用任何带密码或私密发布包。
- 结果包至少包含：
  - `ci-artifact-manifest.json`
  - `artifact-name.txt`
  - `ci-failure-summary.md`
  - `junit.xml`
  - `environment.log`
  - `static-checks.log`
  - `logic-smoke.log`
  - `xcodebuild.log`
  - `test.log`
  - `mac-catalyst-build.log`
  - `mac-catalyst-run-script.log`
  - `mac-baseline-notes.md`
  - `.xcresult` 或等价 Xcode 结果包
- manifest 必须自描述 `artifactName`、`repository`、`commitSubject`、`runUrl`、`runId`、`runAttempt`、各阶段 outcome、自动选择的 `destination`、`macBaselineKind`、`macCatalystBuildOutcome`、`macCatalystRunEntrypoint`、`macCatalystRunScriptCheckOutcome`、`codexRunEnvironmentCheckOutcome` 和相关日志路径。

### Agent C

- 只验收 `origin/main` 最新 commit 对应的 run 和 artifact。
- 如需权限，先 `gh auth login`。
- 用 `gh run download` 把结果包下载到 `/private/tmp/localgemma-c-review-<run_id>/`。
- 核对 manifest 中的 `artifactName`、`branch`、`commitSha`、`commitSubject`、`repository`、`runUrl`、`runId`、`runAttempt`、`macBaselineKind`、`macCatalystBuildOutcome`、`macCatalystRunEntrypoint`、`macCatalystRunScriptCheckOutcome`、`codexRunEnvironmentCheckOutcome` 与 `artifact-name.txt`、本次下载 run 和 `origin/main` 最新状态一致。
- 打开 `ci-failure-summary.md`、`junit.xml`、主日志和 `.xcresult` 或等价结果。
- 有问题时退回 Agent B 在 `main` 上追加修复 commit；无问题时确认最新 run 通过。
- 如果 Agent C 自己补文档或修复小问题，也必须追加 commit、push、等待新 run，并重新下载最新结果包。

## 核心状态对象 / 模块

- `LocalModel`：模型定义、能力、artifact manifest、部署 profile。
- `ModelArtifactManifest`：模型文件名、tokenizer 文件名、格式、存储目录、SHA-256、下载策略。
- `ArtifactValidationResult`：artifact 状态和校验摘要。
- `ModelCatalog`：模型、artifact、部署状态的 source of truth。
- `InferenceEngine`：会话、输入、输出、导出、生成状态。
- `DeviceOptimizer`：Apple Silicon 优化指标和开关。
- `PromptTemplateLibrary`：内置提示词模板。
- `WorkspaceLayoutMode`：主界面容器尺寸断点，覆盖 iPhone 横屏、iPad 竖屏大画布、Mac Catalyst 和桌面大屏窗口。
- `ModelLibraryLayoutMode`：模型页内部单栏/双栏断点，覆盖窄屏回退和 Mac/iPad 宽屏部署工作流。
- `WorkspaceNavigationAccessibilityMetadata`：顶部工作区 tab 和大屏 sidebar 工作区按钮的辅助技术文案、Voice Control 输入标签、快捷键说明和稳定 identifier。
- `HeaderActionAccessibilityMetadata`：全局头部主题切换、设置页外观主题按钮和打开模型工作区按钮的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `ModelCapsuleAccessibilityMetadata`：顶部模型胶囊整体状态摘要的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `ModelDetailAccessibilityMetadata`：模型页详情右栏和窄屏详情段整体摘要的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `ModelDetailRowAccessibilityMetadata`：模型详情参数行、性能行和建议行的行级辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `ModelDeploymentControlAccessibilityMetadata`：模型选择器、部署电源和 artifact 操作按钮的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `ModelStatusBadgeAccessibilityMetadata`：模型页安装状态、artifact 状态和部署状态徽章的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `OptimizationToggleAccessibilityMetadata`：设置页和优化 dashboard 运行策略开关的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `ChipReadinessAccessibilityMetadata`：设置页和优化 dashboard 芯片准备度卡片/圆环的辅助技术文案、隐私保护状态摘要和稳定 identifier。
- `OptimizerMetricAccessibilityMetadata`：设置页和优化 dashboard Apple Silicon 指标卡的辅助技术文案、进度百分比、Voice Control 输入标签和稳定 identifier。
- `SessionSidebarLayoutPolicy`：推理页大屏会话列表宽度策略，覆盖 Mac/iPad 会话栏最小/最大宽度和窄屏回退。
- `SessionCommandAction` / `SessionCommandActions`：Mac/iPad 会话命令菜单元数据和 focused action bridge。
- `SessionBarActionAccessibilityMetadata`：推理页会话栏新建/导出可见按钮的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `SessionChipActionAccessibilityMetadata`：推理页单个会话 chip 选择/删除动作的辅助技术文案、删除禁用原因、Voice Control 输入标签和基于 UUID 前缀的稳定 identifier。
- `ChatMessageAccessibilityMetadata`：推理页聊天消息气泡的整体辅助技术文案、生成中状态、token 摘要、Voice Control 输入标签和稳定 identifier。
- `ChatTranscriptAccessibilityMetadata`：推理页聊天记录容器的辅助技术文案、消息总数、最新消息摘要、生成中状态、Voice Control 输入标签和稳定 identifier。
- `ExportSessionActionAccessibilityMetadata`：导出弹层分享 Markdown、文本兜底和复制全文动作的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `WallpaperPreferenceAccessibilityMetadata`：设置页选择相册壁纸和恢复系统背景控件的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `PromptCategoryAccessibilityMetadata`：提示词分类筛选的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `PromptTemplateActionAccessibilityMetadata`：提示词模板填入和发送动作的辅助技术文案、Voice Control 输入标签和稳定 identifier。
- `WallpaperImageProcessor`：壁纸数据压缩和尺寸控制。
- `script/build_and_run.sh`：项目内 Mac Catalyst 本地 build/run 入口。
- `.github/workflows/ci-results.yml`：云端重验证和 Agent C 结果包生成入口。
- `Agent X`：未来多轮总目标调度层，按 Agent A -> Agent B -> Agent C 闭环推进。

## 关键边界

- `ContentView` 不直接修改 artifact 文件系统；必须通过 `ModelCatalog` / `ModelArtifactStore`。
- `InferenceEngine` 不负责扫描或导入模型文件。
- `ModelArtifactStore` 不联网，不下载。
- `LocalArtifactValidator` 不根据 UI 状态判断，只根据 manifest 和文件/哈希判断。
- `RealGemmaRuntimePlaceholder` 不执行真实推理。
- README 和 UI 文案必须明确当前是模拟输出。
- GitHub Actions 只做 iOS/Catalyst 构建、测试、run script 静态契约检查和结果包，不下载模型权重，不执行云端推理，不启动 GUI app。
- Agent C 不能只看 Agent B 文字汇报，必须核对结果包。
- Agent X 不能跳过 Agent C 的最新 artifact 验收，不能把旧 run、旧 artifact 或本地输出冒充云端结果。
- CI artifact 和 Agent C 下载内容必须保持小数据量，只保留 manifest、JUnit 或摘要、关键日志、失败摘要和必要结果包。

## 用户入口

- 推理页：顶部模型胶囊汇总当前模型、artifact、SIM/REAL、后端、速度、内存和准备度并暴露整体辅助语义；会话列表、消息流、输入框、发送/停止、导出；单个会话 chip 的选择/删除动作向辅助技术说明本地会话切换、删除范围和默认空白当前会话不可删除原因；聊天记录容器向辅助技术合并消息总数、最新消息和生成中状态，聊天消息气泡向辅助技术合并角色、正文或生成中状态、token 数和本地边界；Mac/iPad 可通过 `会话` command menu 或会话栏可见按钮新建或导出当前会话，会话栏操作和导出弹层分享/复制动作向辅助技术暴露稳定语义。
- 模型页：选择模型、启动/关闭部署、模拟下载、导入文件、扫描本地、卸载；足够宽时内部双栏展示部署控制和模型详情，窄屏按顺序展示同一详情段；模型选择器、安装状态徽章、artifact 状态徽章、部署状态徽章、部署电源、模型文件操作、模型详情摘要和参数/性能/建议行级内容向辅助技术暴露稳定语义，并保留切换不下载权重、模拟下载、本地详情摘要和 verified 门禁边界。
- 提示词页：按分类筛选模板、填入输入框、直接发送；分类筛选 chip 和模板填入/发送动作暴露稳定辅助语义和 Voice Control 输入标签，填入不发送 prompt，发送走本地模拟 runtime 且不发送到云端服务。
- 设置页：主题切换、相册壁纸选择/恢复控件、Apple Silicon 优化开关；芯片准备度卡片随离线隐私保护开关动态显示开启/关闭并暴露中文辅助语义，优化指标卡暴露状态、进度和本地边界，运行策略开关向辅助技术暴露开启/关闭状态、本地策略边界和 Voice Control 输入标签。

## 层关系

- 前端层：`ContentView.swift` 中的 SwiftUI views。
- 状态层：`ModelCatalog`、`InferenceEngine`、`DeviceOptimizer`。
- 模型文件层：`ModelArtifactStore`、`ModelArtifactHasher`、`LocalArtifactValidator`。
- Runtime 层：`LocalInferenceRuntime`、`SimulatedGemmaRuntime`、`RealGemmaRuntimePlaceholder`。
- 测试层：`LocalGemmaTests.swift` 和 `Tools/LogicSmoke.swift`。
- 本地运行层：`script/build_and_run.sh` 负责 Mac Catalyst 本地 build/run/debug/logs 入口。
- 云端协作层：Agent X 多轮调度、GitHub Actions CI 结果包、`gh run download`、Agent C manifest / log / JUnit 核对。

## 已确认的铁律

- 不自动下载模型权重。
- 不发起云端推理。
- 未 verified 的 artifact 不能启用真实 runtime。
- 同一时间只有一个模型 deployment running。
- 导入文件必须匹配 manifest 必需文件名。
- `.mlmodelc` 目录 artifact 的 hash 必须稳定计算。
- 空 prompt 不创建新消息，不触发生成。
- 分享导出不能依赖不存在的文件。
- 大图壁纸必须压缩和限制尺寸。
- iPhone 横屏、iPad 大屏与 Mac Catalyst 桌面窗口布局断点必须有测试覆盖。
- 模型页内部宽屏双栏和窄屏单栏回退必须有测试覆盖。
- 工作区快捷键、工作区/会话 command menu、工作区导航辅助语义、顶部模型胶囊整体辅助语义、模型详情右栏与行级辅助语义、模型状态徽章辅助语义、头部主题与模型库入口辅助语义、会话栏操作辅助语义、会话 chip 动作语义、聊天消息气泡与聊天记录容器辅助语义、导出弹层分享/复制辅助语义、壁纸控件辅助语义、会话侧栏宽度、regular 侧栏说明、选择语义、composer 输入焦点/控件辅助语义、模型选择器与部署控件辅助语义、运行策略开关辅助语义、芯片准备度辅助语义、优化指标卡辅助语义、提示词分类筛选辅助语义和提示词模板动作辅助语义必须有测试覆盖，避免 Mac/iPad 导航退化。
- 默认协作验证以 `main` push 后的 GitHub Actions 结果包为准。
- Agent X 循环每轮仍以 Agent B 本地轻量检查、GitHub Actions artifact 和 Agent C 下载复判为准。

## 未来扩展点

- 将 `AppState.swift` 按模型、artifact、runtime、inference、optimizer 拆分。
- 将 `ContentView.swift` 按 workspace 和组件拆分。
- 接入真实 Core ML / ANE runtime。
- 支持 concrete SHA-256 的真实 Gemma artifact。
- 增加 UI Test target 覆盖相册、分享、iPad 大屏布局、导航。
- 增加持久化会话存储和隐私清理策略。
- 已配置远端仓库后，下一步是持续用最新 `origin/main` push、CI artifact 下载和 Agent C 结果包复判来闭环每个版本。

## 不允许破坏的行为

- 默认仍可在没有真实权重时运行模拟聊天。
- artifact 缺失时不崩溃、不联网、不误报 ready。
- staged 不能提升为 verified。
- 卸载 artifact 后必须停止部署。
- README、测试规范、核心流程图必须跟源码和 CI 流程同步。
