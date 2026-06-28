# 项目核心流程文档

一句话总览：本项目是一个 SwiftUI iOS 原型，通过本地模拟 runtime 和严格 artifact 校验流程，验证 iPhone 端侧部署 Gemma 1.5B 的 UI、状态管理、文件导入、会话导出和 Apple Silicon 运行计划。

本文只写当前真实链路，不写历史流水账。

## 当前核心数据流

1. App 启动。
2. `LocalGemmaApp` 创建三个共享状态对象：
   - `ModelCatalog(autoScanLocalArtifacts: true)`
   - `InferenceEngine()`
   - `DeviceOptimizer()`
3. `ContentView` 通过 `EnvironmentObject` 读取共享状态。
4. `ModelCatalog` 初始化默认模型列表，并扫描 `Application Support/LocalModels`。
5. `LocalArtifactValidator` 根据 manifest、必需文件和 SHA-256 产出 artifact 状态。
6. UI 顶部模型胶囊展示当前模型、速度、内存、后端、artifact 状态和模拟/真实标记。
7. 用户在推理页输入 prompt。
8. `InferenceEngine.send(using:availability:)` 创建用户消息和 assistant 占位消息。
9. `SimulatedGemmaRuntime.generate` 根据 prompt 和模型生成模拟回答。
10. `InferenceEngine` 分 chunk 流式写回 messages，并同步 active session。
11. 用户可导出当前会话，生成 Markdown 文本和临时 `.md` 文件。
12. 分享视图优先分享真实存在的 Markdown 文件；文件不存在时分享文本。

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
- 竖屏使用顶部 header、tab picker 和分页工作区。
- 横屏使用左侧状态/导航栏和右侧工作区。
- `WorkspaceLayoutMode` 负责判断 portrait、landscapeCompact、landscapeRegular。

### 壁纸

- 设置页使用 `PhotosPicker` 选择系统相册图片。
- `WallpaperImageProcessor` 将图片缩放和压缩为 JPEG。
- 压缩后的数据存入 `@AppStorage("customWallpaperImageData")`。
- `AppBackground` 使用壁纸并叠加主题遮罩，保证文字可读。

### 分享

- `InferenceEngine.exportActiveSessionText` 生成 Markdown 文本。
- `exportActiveSessionMarkdownFile` 写临时 `.md` 文件。
- `ExportPayload.existingFileURL` 检查文件是否真实存在。
- `ExportSessionView` 优先 `ShareLink(item: fileURL)`；否则 `ShareLink(item: payload.text)`。
- 复制全文使用系统剪贴板。

## 核心状态对象 / 模块

- `LocalModel`：模型定义、能力、artifact manifest、部署 profile。
- `ModelArtifactManifest`：模型文件名、tokenizer 文件名、格式、存储目录、SHA-256、下载策略。
- `ArtifactValidationResult`：artifact 状态和校验摘要。
- `ModelCatalog`：模型、artifact、部署状态的 source of truth。
- `InferenceEngine`：会话、输入、输出、导出、生成状态。
- `DeviceOptimizer`：Apple Silicon 优化指标和开关。
- `PromptTemplateLibrary`：内置提示词模板。
- `WorkspaceLayoutMode`：主界面布局断点。
- `WallpaperImageProcessor`：壁纸数据压缩和尺寸控制。

## 关键边界

- `ContentView` 不直接修改 artifact 文件系统；必须通过 `ModelCatalog` / `ModelArtifactStore`。
- `InferenceEngine` 不负责扫描或导入模型文件。
- `ModelArtifactStore` 不联网，不下载。
- `LocalArtifactValidator` 不根据 UI 状态判断，只根据 manifest 和文件/哈希判断。
- `RealGemmaRuntimePlaceholder` 不执行真实推理。
- `README.md` 和 UI 文案必须明确当前是模拟输出。

## 用户入口

- 推理页：会话列表、消息流、输入框、发送/停止、导出。
- 模型页：选择模型、启动/关闭部署、模拟下载、导入文件、扫描本地、卸载。
- 提示词页：按分类筛选模板、填入输入框、直接发送。
- 设置页：主题切换、相册壁纸、恢复背景、Apple Silicon 优化开关。

## 层关系

- 前端层：`ContentView.swift` 中的 SwiftUI views。
- 状态层：`ModelCatalog`、`InferenceEngine`、`DeviceOptimizer`。
- 模型文件层：`ModelArtifactStore`、`ModelArtifactHasher`、`LocalArtifactValidator`。
- Runtime 层：`LocalInferenceRuntime`、`SimulatedGemmaRuntime`、`RealGemmaRuntimePlaceholder`。
- 测试层：`LocalGemmaTests.swift` 和 `Tools/LogicSmoke.swift`。

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
- 横屏断点必须有测试覆盖。

## 未来扩展点

- 将 `AppState.swift` 按模型、artifact、runtime、inference、optimizer 拆分。
- 将 `ContentView.swift` 按 workspace 和组件拆分。
- 接入真实 Core ML / ANE runtime。
- 支持 concrete SHA-256 的真实 Gemma artifact。
- 增加 UI Test target 覆盖相册、分享、横屏、导航。
- 增加持久化会话存储和隐私清理策略。

## 不允许破坏的行为

- 默认仍可在没有真实权重时运行模拟聊天。
- artifact 缺失时不崩溃、不联网、不误报 ready。
- staged 不能提升为 verified。
- 卸载 artifact 后必须停止部署。
- README、测试规范、核心流程图必须跟源码同步。

