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

读图说明：这张图展示 ContentView 如何根据容器尺寸选择单栏、compact 双栏或 regular 大屏双栏布局，然后进入具体工作区。iPhone 横屏、iPad 竖屏大画布、Mac Catalyst 和桌面窗口都走同一套尺寸断点。

```mermaid
flowchart TD
    A[ContentView 获取 GeometryReader 尺寸] --> B[WorkspaceLayoutMode.resolve]
    B --> C{是否达到双栏、大屏或桌面窗口断点}
    C -- 否 --> D[单栏布局<br/>Header + TabPicker + Page TabView]
    C -- 是 --> E[双栏布局<br/>左侧状态/导航栏 + 右侧工作区]
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

## 7. main 直推与云端结果包验收流

读图说明：这张图展示新的协作闭环。重点是 Agent B 必须在 `main` 上提交并推送，GitHub Actions 生成带自描述 manifest 的未加密结果包，Agent C 只能验收 `origin/main` 最新 commit 对应的 artifact name、run URL、run id 和 run attempt；失败时通过追加修复 commit 回到同一条主线。

```mermaid
flowchart TD
    A[人工提出目标] --> B{是否使用角色前缀}
    B -- agenta / a: / A: --> C[Agent A<br/>本地分析目标和架构]
    B -- agentb / b: / B: --> D[Agent B<br/>基于已有提示词实现]
    B -- agentc / c: / C: --> E[Agent C<br/>验收最新结果包]
    B -- agentx / x: / X: --> X0[Agent X<br/>主控多轮目标]
    B -- 无前缀 --> F[普通 Codex 任务<br/>必要时提醒指定角色]
    X0 --> X1[进入 Agent X 循环图<br/>拆轮次并调度 A/B/C]

    C --> G[写版本化 Agent B 提示词<br/>md/prompt/v0.../vX.Y...md]
    G --> D
    D --> H[git fetch origin<br/>git switch main<br/>git pull --ff-only origin main]
    H --> I{当前是否为 main 且无无关改动}
    I -- 否 --> J[报告阻塞<br/>不伪装云端流程]
    I -- 是 --> K[小步实现 + 更新测试和文档]
    K --> L[本地轻量检查<br/>diff / plutil / YAML / Probe]
    L --> M[commit 到 main<br/>主题含版本号]
    M --> N[git push origin main]
    N --> O[GitHub Actions<br/>ci-results workflow]
    O --> P[生成未加密 CI 结果包<br/>artifact name + manifest + failure summary + JUnit + logs + xcresult]
    P --> E
    E --> Q[gh auth login 如需权限<br/>gh run download 到 /private/tmp/localgemma-c-review-run_id]
    Q --> R{manifest 是否匹配 artifact-name.txt<br/>origin/main 最新 commit / run URL / run / attempt / Mac baseline}
    R -- 否 --> S[验收不通过<br/>退回 Agent B]
    R -- 是 --> T{outcome / 日志 / JUnit / xcresult 是否通过}
    T -- 否 --> S
    T -- 是 --> U[Agent C 确认 main 最新 run 通过]
    S --> V[Agent B 在 main 上追加修复 commit]
    V --> N
    U --> W[人工复核<br/>进入下一轮]
```

## 8. Agent X 主控循环迭代流

读图说明：这张图展示未来人工用 `agentx`、`x:` 或 `X:` 给出总目标后，Agent X 如何拆分轮次并调度 Agent A、Agent B、GitHub Actions 和 Agent C。重点是 Agent X 只能根据 Agent C 对最新 artifact 的验收结论继续、退回、暂停或完成，不能跳过云端结果包复判。

```mermaid
flowchart TD
    A[人工给 Agent X 总目标 X] --> B[Agent X 梳理目标边界<br/>确认停止条件]
    B --> C[Agent X 拆分下一轮小目标]
    C --> D[Agent A 写版本化提示词<br/>本轮目标 + 非目标 + 验证 + CI + artifact + Agent C 标准]
    D --> E[Agent B 基于最新 origin/main<br/>在 main 上实现并本地轻量检查]
    E --> F[Agent B commit 并 push origin main]
    F --> G[GitHub Actions 运行 ci-results workflow]
    G --> H[生成小体积未加密 artifact<br/>manifest + artifact-name + JUnit + 关键日志 + 必要 xcresult]
    H --> I[Agent C 下载最新 run artifact<br/>核对 manifest / JUnit / 日志 / xcresult / Mac baseline]
    I --> J{Agent C 验收是否通过}
    J -- 不通过 --> K[Agent X 退回 Agent B 修复<br/>同一目标追加修复 commit]
    K --> E
    J -- 通过 --> L{总目标 X 是否完成}
    L -- 是 --> M[Agent X 宣布完成<br/>报告版本 / commit / run / artifact]
    L -- 否 --> N{是否触发停止条件}
    N -- 是 --> O[Agent X 暂停等待人工确认<br/>报告阻塞原因]
    N -- 否 --> C
```
