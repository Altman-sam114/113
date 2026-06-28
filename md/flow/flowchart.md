# 项目核心流程图

本文是 `md/flow/flow.md` 的 Mermaid 可视化版本。每张图前先给人工读图说明，图中节点使用中文注释，方便快速理解当前真实逻辑。

## 1. App 启动与全局状态

读图说明：这张图展示 App 启动时如何创建状态对象、扫描本地模型文件，并把状态注入 SwiftUI 界面。重点看 `ModelCatalog` 如何成为模型和 artifact 状态的入口。

```mermaid
flowchart TD
    A[用户启动 App] --> B[LocalGemmaApp 创建 WindowGroup]
    B --> C[创建 ModelCatalog<br/>模型列表 + artifact 状态]
    B --> D[创建 InferenceEngine<br/>会话 + 输入输出状态]
    B --> E[创建 DeviceOptimizer<br/>芯片指标 + 优化开关]
    C --> F[启动自动扫描本地 LocalModels 目录]
    F --> G[ModelArtifactStore 读取 manifest 必需文件]
    G --> H[LocalArtifactValidator 判断 missing/staged/verified]
    H --> I[更新 selectedModel 与 artifact validation]
    C --> J[注入 ContentView EnvironmentObject]
    D --> J
    E --> J
    J --> K[SwiftUI 展示推理/模型/提示词/设置工作区]
```

## 2. 模型 artifact 校验流

读图说明：这张图展示本项目最重要的安全边界。模型文件存在不等于可真实运行，只有 concrete SHA-256 匹配后才进入 verified。

```mermaid
flowchart TD
    A[用户导入或扫描本地文件] --> B[读取 ModelArtifactManifest<br/>模型文件 + tokenizer 文件]
    B --> C{必需文件是否都存在}
    C -- 否 --> D[missing<br/>缺文件，继续模拟]
    C -- 是 --> E{manifest 是否有 concrete SHA-256}
    E -- 否 --> F[staged<br/>文件存在但无法官方校验]
    E -- 是 --> G[ModelArtifactHasher 计算模型 artifact SHA-256]
    G --> H{observed 是否等于 expected}
    H -- 否 --> F
    H -- 是 --> I[verified<br/>允许真实 runtime 计划]
    D --> J[RuntimePreparationReport<br/>canRunRealWeights=false]
    F --> J
    I --> K[RuntimePreparationReport<br/>canRunRealWeights=true]
```

## 3. 推理与会话流

读图说明：这张图展示用户输入如何变成一轮模拟流式回答。当前默认 runtime 是模拟器，不会调用真实权重。

```mermaid
flowchart TD
    A[用户在 Composer 输入 prompt] --> B{输入是否为空}
    B -- 是 --> C[忽略，不创建消息]
    B -- 否 --> D[InferenceEngine 创建用户消息]
    D --> E[创建 assistant 占位消息]
    E --> F[构造 InferenceRequest<br/>prompt + model + artifact availability]
    F --> G[SimulatedGemmaRuntime.generate]
    G --> H[LocalRuntimePlanner 生成运行计划]
    H --> I[GemmaSimulationProvider 生成模拟文本]
    I --> J[按 chunk 流式写回 assistant 消息]
    J --> K[同步 active session]
    K --> L[更新速度、内存、后端、SIM/REAL 标记]
```

## 4. UI 布局与工作区流

读图说明：这张图展示 ContentView 如何根据屏幕尺寸选择竖屏或横屏布局，然后进入具体工作区。

```mermaid
flowchart TD
    A[ContentView 获取 GeometryReader 尺寸] --> B[WorkspaceLayoutMode.resolve]
    B --> C{是否横屏且宽度足够}
    C -- 否 --> D[竖屏布局<br/>Header + TabPicker + Page TabView]
    C -- 是 --> E[横屏布局<br/>左侧状态/导航栏 + 右侧工作区]
    D --> F{当前 selectedTab}
    E --> F
    F -- 推理 --> G[ChatWorkspace<br/>会话 + 消息 + 输入]
    F -- 模型 --> H[ModelLibraryView<br/>部署控制台]
    F -- 提示词 --> I[PromptTemplatesWorkspace<br/>模板筛选/填入/发送]
    F -- 设置 --> J[SettingsWorkspace<br/>主题/壁纸/芯片策略]
```

## 5. 相册壁纸流

读图说明：这张图展示从相册选择图片后，项目如何压缩图片再保存为 App 背景，避免大图直接写入 AppStorage。

```mermaid
flowchart TD
    A[用户点击设置页壁纸按钮] --> B[PhotosPicker 打开系统相册]
    B --> C{是否选择图片}
    C -- 否 --> D[保持当前背景]
    C -- 是 --> E[读取 PhotosPickerItem Data]
    E --> F{Data 是否能解码为 UIImage}
    F -- 否 --> G[显示壁纸导入失败]
    F -- 是 --> H[WallpaperImageProcessor 缩放到 maxPixel]
    H --> I[压缩为 JPEG]
    I --> J[写入 customWallpaperImageData]
    J --> K[AppBackground 展示壁纸并叠加主题遮罩]
    K --> L[用户可一键清空恢复系统背景]
```

## 6. 会话导出与分享流

读图说明：这张图展示导出时为什么有文件分享和文本分享两条路径。目标是避免分享一个不存在的临时文件。

```mermaid
flowchart TD
    A[用户点击会话导出] --> B[InferenceEngine 生成 Markdown 文本]
    B --> C[尝试写入临时 .md 文件]
    C --> D[创建 ExportPayload]
    D --> E{existingFileURL 是否存在}
    E -- 是 --> F[ShareLink 分享 Markdown 文件]
    E -- 否 --> G[ShareLink 分享文本内容]
    F --> H[系统分享面板]
    G --> H
    D --> I[复制全文按钮]
    I --> J[写入 UIPasteboard]
```

