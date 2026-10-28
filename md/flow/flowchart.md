# 项目核心流程图

## v3.8 单Agent模块迭代与发布包门禁

读图说明：不再依赖A/B/C队列或子智能体，由同一Agent集成模块后提交云端。新增发布资源和未签名device包检查与原147项/36图并存；任何必选失败均继续修复，而不是宣布发布完成。

```mermaid
flowchart TD
    %% 用户最新要求单Agent按模块推进
    Work[同一Agent / UI 文件可靠性 发布资源 测试模块] --> Static[静态检查 / 28槽图标 / 8个Python夹具]
    Static --> Push[main提交 / 精确SHA]
    %% 所有Swift与UI只在云端执行
    Push --> Existing[原iOS与Catalyst构建 / 147 XCTest / 36图]
    Push --> Release[云端unsigned iPhoneOS Release构建]
    Release --> Bundle[实际.app / arm64 / 图标 / 隐私 / 版本]
    Existing --> Evidence[完整结果包 / JUnit10 / 4份xcresult / 人眼复判]
    Bundle --> Evidence
    %% 未签名构建不能代替真机与签名发布
    Evidence --> Verdict{所有必选门禁通过?}
    Verdict -- 否 --> Work
    Verdict -- 是 --> Next[核对仍未完成的导入可靠性 / runtime / 真机 / 签名门禁]
```

## v3.7 iPhone 单头界面与云端门禁

读图说明：根窄屏 chrome 保留零高槽位，聊天自己呈现唯一集成头部，其他页面直接显示标题与内容；四页身份不变。隐藏聊天同步关闭模态，历史关闭后仍受活动态焦点门禁约束。用户允许按文件分工并行，但所有编译、运行与图片验证仍在云端，最新结果包不通过就退回修复。

```mermaid
flowchart TD
    %% 不引入第二套根断点，不重建四页
    Root[原根布局 plan] --> Compact{topNavigation?}
    Compact -- 是 --> Empty[零高chrome占位 / 无命中 / 辅助隐藏]
    Compact -- 否 --> Sidebar[原大屏 sidebar]
    Empty --> Pages[同一个 WorkspacePagesShell]
    Sidebar --> Pages
    Pages --> Chat[聊天单头 / 模型摘要 历史 新建 更多]
    Pages --> Other[模型 模板 设置 / 中文主标题与内容]
    Chat --> More[更多菜单 / 主题与导出]
    Chat --> Summary[原ModelCapsule摘要 / 原模型路由]
    Pages --> Nav[浮动底部四入口 / 56pt导航项]
    %% 只读编辑反馈控制底栏，原同步聚焦保持
    Focus[原 ComposerBar FocusState] --> Editing[编辑状态向上传递]
    Editing --> NavRule[仅活动聊天编辑时收起底栏]
    NavRule --> Nav
    Focus --> Dismiss[键盘完成 / 记录交互式收键盘]
    %% sheet 关闭后才请求聚焦，不跨越活动态边界
    Chat --> History[会话抽屉 / 原SessionChip]
    History --> Select[原选择或新建 / 保存UI focus reason]
    Select --> Closed[sheet onDismiss / 清reason]
    Closed --> Active{聊天仍active?}
    Active -- 是 --> Request[原requestComposerFocus同步路由]
    Active -- 否 --> None[不请求焦点]
    Active -- 离页 --> Clear[同步清pending / 关闭历史 摘要 导出]
    %% 渐进披露不改模型文件与runtime门禁
    Other --> Files[单层模型选择 / 导入主操作 / 模拟预览]
    Files --> Confirm[原卸载确认 / verified gate保持]
    Other --> Prompt[模板主区填入 / 同级44pt发送 / 原payload]
    Other --> Settings[壁纸244pt手机内容阈值 / 分隔式策略行]
    Settings --> Detail[模型参数与模拟设备预算按需展开]
    %% 并行实施统一提交，所有重验证只在真实云端
    Parallel[A设计 / B按文件并行 / root统一集成] --> Cloud[云端147项 / 16模拟器图 / 20宿主图]
    Pages --> Cloud
    Cloud --> OCR[特有正文OCR / 逐页诊断 / 任意失败仍失败]
    OCR --> Review
    Cloud --> Review[精确SHA-run-attempt完整包和实际图片复判]
    Review --> Result{C是否通过?}
    Result -- 否 --> Parallel
    Result -- 是 --> Scope[仅本轮UI回归 / 真实runtime与签名仍独立验收]
```

本文是 `md/flow/flow.md` 的 Mermaid 可视化版本。每张图前先给人工读图说明，图中节点使用中文注释，方便快速理解当前真实逻辑。

## 1. App 启动与全局状态

读图说明：这张图展示 App 启动时如何创建状态对象、扫描本地模型文件，并把状态注入 SwiftUI 界面。重点看 `ModelCatalog` 如何成为模型和 artifact 状态的入口。

```mermaid
flowchart TD
    A[用户启动 App] --> B[LocalGemmaApp 创建 WindowGroup<br/>注册工作区/会话 CommandMenu]
    B --> C[创建 ModelCatalog<br/>模型列表 + artifact 状态]
    B --> D[创建 InferenceEngine<br/>会话 + 输入输出状态]
    B --> E[创建 DeviceOptimizer<br/>芯片指标 + 优化开关<br/>准备度 + 隐私保护状态]
    C --> F[启动自动扫描本地 LocalModels 目录]
    F --> G[ModelArtifactStore 读取 manifest 必需文件]
    G --> H[LocalArtifactValidator 判断 missing/staged/verified]
    H --> I[更新 selectedModel 与 artifact validation]
    C --> J[注入 ContentView EnvironmentObject]
    D --> J
    E --> J
    J --> K[WorkspaceRootLayoutPolicy<br/>复用 WorkspaceLayoutMode<br/>解析 axis + chrome + sidebar width]
    K --> L[WorkspaceRootShell<br/>AnyLayout 切换 VStack/HStack<br/>稳定 chrome + content 两个直接子节点]
    L --> M{chrome 呈现}
    M -- top navigation --> N[Header + tab picker]
    M -- compact sidebar --> O[紧凑侧栏]
    M -- detailed sidebar --> P[详细侧栏 + 用途说明]
    L --> Q[同一个 WorkspacePagesShell<br/>四个固定同序页面槽位<br/>根断点往返不替换 content 节点]
    Q --> Q1[WorkspacePagesInteractionPolicy<br/>选中页可见/可命中/启用/辅助可达<br/>隐藏页禁用但保持身份]
    Q --> R{selectedTab 是否为推理}
    R -- 是 --> S[SessionCommandFocusPolicy<br/>发布会话 focused route]
    R -- 否 --> T[隐藏 ChatWorkspace<br/>稳定 route 包装内 actions 为 nil]
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
    D --> L[ArtifactActionPanel<br/>扫描本地 + 导入文件 utility]
    F --> L
    I --> L
    L --> M[ModelArtifactUtilityTextLayoutPolicy<br/>语义 Dynamic Type 字体<br/>最多两行 + 1pt line spacing<br/>10pt padding + 自然垂直增长<br/>utility 至少 44pt]
    M --> N[扫描/Files 本地动作<br/>独立辅助语义<br/>不联网、不写回状态、不启动 runtime]
```

## 3. 模型卸载确认流

读图说明：这张图展示模型页破坏性卸载动作的确认边界。点击卸载只打开确认弹层；取消不会改文件或部署状态；确认后才进入 `ModelCatalog` 删除 App 托管 artifact/tokenizer 并停止部署。

```mermaid
flowchart TD
    A[用户点击卸载模型<br/>卸载按钮辅助语义说明打开确认] --> B[ModelLibraryView 设置 pendingUninstallModel]
    B --> C[显示卸载确认弹层<br/>标题/消息/确认/取消辅助语义]
    C --> D{用户选择}
    D -- 取消卸载 --> E[关闭弹层<br/>不删除文件<br/>不停止部署]
    D -- 确认卸载 --> F[调用 ModelCatalog.uninstallArtifacts]
    F --> G[ModelArtifactStore 删除 App 托管 manifest 必需文件]
    G --> H[停止当前模型部署]
    H --> I[刷新 validation<br/>missing + notDownloaded]
```

## 4. 推理与会话流

读图说明：这张图展示用户输入如何变成一轮模拟流式回答。当前默认 runtime 是模拟器，不会调用真实权重。

```mermaid
flowchart TD
    A[用户在 Composer 输入 prompt<br/>输入框与发送/停止控件有辅助标识<br/>发送/停止按钮保持 44pt 触控目标<br/>宽屏输入行宽受 ComposerBarLayoutPolicy 限制<br/>聚焦光环与发送渐变（纯静态）受 ComposerFocusGlowStylePolicy 控制] --> L[ComposerInputTextLayoutPolicy<br/>公开 semantic Dynamic Type 字体<br/>TextField axis: vertical<br/>lineLimit 1...4<br/>0pt line spacing + 12pt vertical padding<br/>允许自然垂直增长<br/>不写回状态/不触发网络或 runtime]
    L --> B{输入是否为空}
    B -- 是 --> C[忽略，不创建消息]
    B -- 否 --> D[InferenceEngine 创建用户消息]
    D --> E[创建 assistant 占位消息]
    E --> F[构造 InferenceRequest<br/>prompt + model + artifact availability]
    F --> G[SimulatedGemmaRuntime.generate]
    G --> H[LocalRuntimePlanner 生成运行计划]
    H --> I[GemmaSimulationProvider 生成模拟文本]
    I --> J[按 chunk 流式写回 assistant 消息]
    J --> K[同步 active session<br/>聊天记录容器辅助语义<br/>聊天消息气泡整体辅助语义]
    K --> M{用户复制单条消息}
    M -- 正文非空 --> N[原始正文写入本机剪贴板<br/>44pt 动作 + 持久 checkmark<br/>不发送云端]
    M -- 空白或生成中 --> O[复制禁用<br/>保留生成指示与摘要语义]
    K --> L[更新速度、内存、后端、SIM/REAL 标记<br/>顶部模型胶囊整体辅助语义<br/>ModelCapsuleLayoutPolicy<br/>窄侧栏堆叠 + 指标 1/2/3 列]
```

## 5. UI 布局与工作区流

读图说明：这张图展示 `ContentView` 如何把容器尺寸解析成根布局计划，再由生产 `WorkspaceRootShell` 在不替换工作区 content 的前提下切换布局轴与 chrome。iPhone 横屏、iPad 竖屏大画布、Mac Catalyst 和桌面窗口都复用 `WorkspaceLayoutMode` 尺寸断点；所有尺寸始终共享同一个 `WorkspacePagesShell`，四页固定同序存在且没有横向分页手势，只有当前页可交互和辅助可达；shell 直接子节点固定为 chrome、content，跨断点和显式导航时页面局部状态不重建。只有活动聊天页通过 `SessionCommandFocusPolicy` 发布会话 focused route。`WorkbenchVisualStylePolicy`、`AppMotionAccessibilityPolicy`、工作区快捷键、44pt 触控目标、辅助语义、模型文件与 verified 门禁保持既有边界。

```mermaid
flowchart TD
    A[ContentView 获取 GeometryReader 尺寸] --> B[WorkspaceRootLayoutPolicy.resolve<br/>复用 WorkspaceLayoutMode]
    B --> C[WorkspaceRootLayoutPlan<br/>axis + chrome + sidebar width]
    C --> D[WorkspaceRootShell<br/>AnyLayout 切换 VStack/HStack<br/>直接子节点固定 chrome + content]
    D --> E{chrome presentation}
    E -- top navigation --> N[Header + 共享导航托盘<br/>顶部工作区 tab 44pt 触控目标<br/>模型胶囊按可用宽度横向/堆叠]
    E -- detailed sidebar --> O[详细侧栏<br/>标题 + 用途说明 + 选中语义<br/>模型胶囊堆叠 + 最多 2 列指标]
    E -- compact sidebar --> P[紧凑侧栏<br/>标题 + 选中语义<br/>模型胶囊堆叠 + 最多 2 列指标]
    O --> X[工作区导航辅助语义<br/>44pt 触控目标<br/>hint + Voice Control 输入标签<br/>用途说明 + Command 快捷键]
    P --> X
    X --> V[WorkbenchVisualStylePolicy<br/>导航托盘/轨道 + 主题感知 panel<br/>8pt 圆角 + hairline 描边<br/>内高光 + contact/ambient 分层阴影]
    V --> R[AppMotionAccessibilityPolicy<br/>10 个显式动画入口<br/>空间位移在 Reduce Motion 下立即更新<br/>主题/复制反馈 0.12 秒 ease-out]
    R --> T[同一个 WorkspacePagesShell<br/>四个页面固定同序存在<br/>无横向分页手势]
    N --> X
    T --> F{当前 selectedTab}
    F --> Y[WorkspacePagesInteractionPolicy<br/>仅当前页可见/命中/启用/辅助可达<br/>隐藏页保持身份]
    K[键盘导航<br/>Command+1/2/3/4 切换工作区] --> F
    M[系统菜单<br/>工作区 CommandMenu + 会话 CommandMenu<br/>复用 focused 映射] --> F
    F --> Q{聊天工作区是否活动}
    Q -- 是 --> S[SessionCommandFocusPolicy<br/>发布会话 focused actions]
    Q -- 否 --> U[隐藏 ChatWorkspace<br/>focused actions 为 nil]
    L[会话/输入焦点<br/>Command+N 新建<br/>Command+Shift+E 导出<br/>Command+Return 发送或停止<br/>活动聊天页同步消费 request 并聚焦<br/>离开聊天页同步清 request 与焦点] --> G
    F -- 推理 --> G[ChatWorkspace<br/>顶部模型胶囊整体辅助语义<br/>会话 chip 动作语义<br/>会话 chip 选择/删除 44pt 触控目标<br/>竖向会话行低饱和视觉层级<br/>SessionBar -> SessionChipSidebarMetadataPolicy<br/>只读 ChatSession + SessionBarLayout<br/>vertical 按数组尾部找归一化后最后非空消息<br/>消息数 + 40 Character 摘要<br/>空摘要回退消息数<br/>horizontal hidden / title-only 160pt 胶囊<br/>会话 + 消息 + 输入<br/>聊天记录容器辅助语义<br/>聊天消息气泡辅助语义<br/>生成中状态脉冲指示<br/>Reduce Motion 静态梯度占位<br/>聊天气泡宽屏宽度策略<br/>聊天记录 920pt 居中阅读轨道<br/>空记录顶部对齐<br/>非空短记录靠近 composer<br/>长记录自然滚动<br/>聊天气泡文本 Dynamic Type<br/>Accessibility 宽度扩展<br/>composer 宽屏输入宽度策略<br/>composer 发送/停止 44pt 触控目标<br/>SessionSidebarLayoutPolicy 偏好宽度<br/>ChatWorkspacePaneLayoutPolicy<br/>pane 小于 860pt 堆叠<br/>分栏至少保留 620pt 聊天面<br/>AnyLayout 共享响应式子树<br/>会话栏操作辅助语义<br/>会话栏操作 44pt 触控目标<br/>导出弹层分享/复制辅助语义<br/>导出弹层分享/复制 44pt 触控目标<br/>导出弹层整体宽屏内容宽度策略]
    F -- 模型 --> H[ModelLibraryView<br/>SectionHeader 动态排版策略<br/>整体宽屏内容宽度策略<br/>ModelLibraryLayoutMode<br/>窄屏单栏 / 宽屏内部双栏<br/>ModelDetailColumnLayoutPolicy<br/>详情右栏最大阅读宽度<br/>ModelCatalog + LocalRuntimePlanner 结果<br/>ModelDetailColumn<br/>DetailPanel 标题语义 Dynamic Type<br/>标题最多两行 + 1pt line spacing<br/>标题/内容 12pt 间距 + 自然垂直增长<br/>参数/性能/建议面板共用 policy<br/>panel 外框扣除两侧 14pt padding<br/>ModelDetailRowLayoutPolicy<br/>84 + 264 + 12 = 360pt 内容阈值<br/>窄宽或 xxxLarge 及以上 stacked<br/>同一 title/value 子树 AnyLayout 切换<br/>stacked 数值前导对齐并自然增长<br/>AdviceRow icon/text 继续自然增长<br/>选择器/状态徽章/部署控件辅助语义<br/>模型部署控件 44pt 触控目标<br/>模型文件工作流面板辅助语义<br/>utility label 语义字体 + 最多两行<br/>1pt line spacing + 自然垂直增长<br/>模型文件操作 44pt 触控目标<br/>卸载确认弹层辅助语义<br/>模型概要面板 + 详情右栏/行级辅助语义<br/>不新增网络/权重/异步任务/状态]
    G --> GHover[SessionChipHoverStylePolicy<br/>仅 vertical + 未选中 + pointer hover<br/>亮/暗 accent opacity 0.06/0.10<br/>装饰层不命中且辅助隐藏<br/>横向胶囊/选中态/状态流不变]
    F -- 提示词 --> I[PromptTemplatesWorkspace<br/>SectionHeader 动态排版策略<br/>整体宽屏内容宽度策略<br/>模板网格宽屏布局策略<br/>模板文本动态排版策略<br/>分类筛选换行布局策略<br/>分类文本动态排版策略<br/>模板筛选/填入/发送<br/>模板动作 44pt 触控目标<br/>分类筛选辅助语义<br/>模板动作辅助语义]
    F -- 设置 --> J[SettingsWorkspace<br/>SectionHeader 动态排版策略<br/>整体宽屏内容宽度策略<br/>主题按钮辅助语义<br/>设置页图标动作 44pt 触控目标<br/>设置偏好行文本动态排版策略<br/>壁纸控件/芯片策略<br/>运行策略开关辅助语义<br/>运行策略开关宽屏网格<br/>运行策略开关行 44pt 触控目标<br/>OptimizationToggleGrid -> OptimizationToggleRow<br/>两个调用点共用 OptimizationToggleTextLayoutPolicy<br/>语义字体 + 标题/副标题最多两行<br/>文字允许垂直增长<br/>44pt 行高不变<br/>250pt 最小卡片宽度 / 510pt 两列边界不变<br/>芯片准备度辅助语义 + 隐私状态<br/>优化指标网格宽度策略<br/>优化指标卡辅助语义<br/>指标 label/value/detail<br/>Dynamic Type 多行策略]
    J --> CR[SettingsWorkspace / OptimizerDashboard<br/>panel 外框扣两侧各14pt后传入<br/>共享 ChipReadinessCard 无卡内GeometryReader<br/>354pt 内容宽度及以上普通字号 horizontal<br/>Accessibility 或非法宽度 stacked<br/>AnyLayout 复用 ring + 正文并自然报高<br/>ring slot 86pt / diameter 66pt<br/>DeviceOptimizer 状态与隐私摘要不变]
    J --> WP[WallpaperPreferencePanel<br/>SettingsWorkspace 传入真实 panel 外框宽度<br/>扣除两侧 14pt panel padding 得到 content width<br/>SettingsPreferenceRowLayoutPolicy<br/>270pt 及以上普通字号 horizontal<br/>窄宽或 xxxLarge 及以上 stacked<br/>AnyLayout 复用预览/文案/动作子树<br/>stacked 自然垂直增长<br/>PhotosPicker/清除动作各 44pt]
```

## 6. 相册壁纸流

读图说明：这张图展示从相册选择图片后，项目如何压缩图片再保存为 App 背景，避免大图直接写入 AppStorage；设置页选择相册壁纸和恢复系统背景控件通过辅助语义说明系统背景、相册图片已启用、正在处理和不发送云端服务边界，并共享 44pt 图标动作触控目标。

```mermaid
flowchart TD
    R[SettingsPreferenceRowLayoutPolicy<br/>外框扣除两侧 14pt panel padding<br/>270pt panel content width 阈值<br/>窄宽或 xxxLarge 及以上 stacked<br/>AnyLayout 共享预览/文案/动作子树<br/>stacked 自然垂直增长] --> A[用户点击设置页壁纸按钮<br/>选择动作辅助语义<br/>44pt 触控目标]
    A --> B[PhotosPicker 打开系统相册]
    B --> C{是否选择图片}
    C -- 否 --> D[保持当前背景]
    C -- 是 --> E[读取 PhotosPickerItem Data]
    E --> F{Data 是否能解码为 UIImage}
    F -- 否 --> G[显示壁纸导入失败]
    F -- 是 --> H[WallpaperImageProcessor 缩放到 maxPixel]
    H --> I[压缩为 JPEG]
    I --> J[写入 customWallpaperImageData]
    J --> K[AppBackground 展示壁纸并叠加主题遮罩]
    K --> L[用户可一键清空恢复系统背景<br/>恢复动作辅助语义]
```

## 7. 会话导出与分享流

读图说明：这张图展示导出时为什么有文件分享和文本分享两条路径。目标是避免分享一个不存在的临时文件，同时让分享与复制动作向辅助技术说明本地 Markdown、文本兜底、剪贴板和不发送云端的边界，并让底部分享/复制与 toolbar 分享入口保持 44pt 触控目标；`ExportSessionView` 的完整正文预览使用语义等宽 Dynamic Type 字体、ScrollView 和文本选择，宽度继续由 `ExportSessionLayoutPolicy` 的 320/760pt 轨道控制。

```mermaid
flowchart TD
    A[用户点击会话导出] --> B[InferenceEngine 生成 Markdown 文本]
    B --> C[尝试写入临时 .md 文件]
    C --> D[创建 ExportPayload]
    D --> W[ExportSessionLayoutPolicy<br/>摘要 + Markdown 预览 + 底部动作<br/>窄屏用可用宽度<br/>宽 sheet 居中封顶<br/>320/760pt 宽度轨道]
    W --> P[ExportSessionView 正文预览<br/>ExportSessionBodyTextLayoutPolicy<br/>语义等宽 Dynamic Type<br/>3pt line spacing + 18pt padding<br/>ScrollView + textSelection<br/>保留完整 Markdown 原文]
    P --> E{existingFileURL 是否存在}
    E -- 是 --> F[ShareLink 分享 Markdown 文件<br/>分享动作辅助语义<br/>底部/toolbar 44pt 触控目标]
    E -- 否 --> G[ShareLink 分享文本内容<br/>文本兜底辅助语义<br/>底部/toolbar 44pt 触控目标]
    F --> H[系统分享面板]
    G --> H
    D --> I[复制全文按钮<br/>剪贴板动作辅助语义<br/>底部 44pt 触控目标]
    I --> J[写入 UIPasteboard]
    P -.-> N[只影响正文排版<br/>不新增状态/网络/模型权重/runtime/artifact 流]
```

## 7.1 v2.83 顶部模型胶囊与模型 selector badge 流

读图说明：这张图只描述 v2.83 的本地只读 UI 链路。顶部胶囊的 deployment 状态直接来自 `ModelCatalog`，selector 与胶囊使用同一主题感知 badge/style/text 契约；顶部整体摘要和 selector 行级入口的辅助树范围不同。图中没有新增下载、网络或真实推理节点。

```mermaid
flowchart LR
    A[ModelCatalog.selectedModel] --> B[deploymentState(for: selectedModel)]
    C[validation(for: selectedModel)] --> D[artifact availability]
    B --> E[ContentView.headerView]
    E --> F[HeaderView]
    F --> G[ModelCapsule]
    G --> H[Running / Stopped<br/>overall accessibility summary]
    D --> G
    B --> I[ModelSelectorPanel]
    D --> I
    I --> J[StatusBadge<br/>install state]
    I --> K[AvailabilityBadge<br/>missing / staged / verified]
    I --> L[DeploymentBadge<br/>running / stopped]
    J --> M[ModelStatusBadgeStylePolicy<br/>light / dark roles]
    K --> M
    L --> M
    G --> M
    M --> N[ModelStatusBadgeTextLayoutPolicy<br/>Dynamic Type]
    N --> O[ModelStatusBadgeRowLayoutPolicy<br/>220pt / invalid / xxxLarge stacked]
    H -. no download / no real runtime .-> P[Local privacy and verified gate]
    J --> Q[selector independent accessibility]
    K --> Q
    L --> Q
```

## 7.2 v2.85 取消生成占位生命周期流

读图说明：这张图只描述本地模拟生成的空 assistant placeholder 在 active 与 stop 后 cancelled 两个呈现状态之间的差异。stop 不删除消息、不替换 UUID、不重排 session；视觉 indicator 与 VoiceOver value 必须由同一无状态 policy 决定。

```mermaid
flowchart LR
    A[InferenceEngine.send] --> B[追加 user + 空 assistant placeholder]
    B --> C[syncActiveSession<br/>保留 session ID/title 与消息顺序]
    C --> D[ChatWorkspace<br/>messages + isGenerating]
    D --> E[ChatTranscript<br/>latest assistant + isGenerating]
    E --> F{ChatGenerationPlaceholderPresentationPolicy}
    F -->|active| G[空 assistant<br/>GenerationIndicatorView<br/>VoiceOver 正在生成]
    F -->|completed| H[非空 assistant<br/>正文/原有 copy metadata]
    F -->|cancelled| I[stop 后空 assistant<br/>隐藏 indicator<br/>VoiceOver 已停止/无正文]
    J[InferenceEngine.stop<br/>cancel task + isGenerating=false] --> F
    G --> K[ChatMessageAccessibilityMetadata]
    I --> K
    H --> K
    K --> L[稳定 role/hint/input labels/identifier<br/>本地 privacy + verified gate]
    I -. 保留同一 message ID/order .-> C
    L -. 不改变 copy 44pt / Reduce Motion / composer focus .-> M[既有 UI 状态边界]
```

## 7.3 v2.84 模型概要标签与校验摘要动态排版流

读图说明：这张图只描述模型页概要的本地只读排版链路。`validation.summary` 和能力标签来自同一个本地 `model + validation` 输入；policy 只提供静态文字契约，verified 门禁、整体辅助语义和外部动作保持既有边界。

```mermaid
flowchart LR
    A[ModelCatalog.validation(for: selectedModel)] --> B[ModelLibraryView]
    B --> C[ModelDetailColumn]
    C --> D[ModelSummaryPanel<br/>model + validation]
    D --> E[FlowLayout<br/>adaptive minimum 72pt<br/>8pt horizontal/vertical spacing]
    E --> F[能力标签<br/>semantic Dynamic Type<br/>2 lines + 1pt spacing<br/>9/6pt padding + vertical growth<br/>theme.chipSurface<br/>theme.secondaryText<br/>theme.subtleBorder]
    D --> G[validation.summary<br/>semantic Dynamic Type<br/>3 lines + 1pt spacing<br/>vertical growth]
    D --> H[ModelSummaryAccessibilityMetadata<br/>single combined element]
    A --> I{artifact availability}
    I --> J[missing / staged / verified<br/>local display only]
    J --> K[LocalRuntimePlanner verified gate<br/>only verified can run real weights]
    F -. static layout only .-> L[No action / animation / network / weight download]
    G -. static layout only .-> L
```

## 8. main 直推与云端结果包验收流

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
    O --> P[生成未加密 CI 结果包<br/>artifact name + manifest + failure summary + JUnit + logs + xcresult + run script contract]
    P --> E
    E --> Q[gh auth login 如需权限<br/>gh run download 到 /private/tmp/localgemma-c-review-run_id]
    Q --> R{manifest 是否匹配 artifact-name.txt<br/>origin/main 最新 commit / run URL / run / attempt / Mac baseline / run script}
    R -- 否 --> S[验收不通过<br/>退回 Agent B]
    R -- 是 --> T{outcome / 日志 / JUnit / xcresult 是否通过}
    T -- 否 --> S
    T -- 是 --> U[Agent C 确认 main 最新 run 通过]
    S --> V[Agent B 在 main 上追加修复 commit]
    V --> N
    U --> W[人工复核<br/>进入下一轮]
```

## 9. Agent X 主控循环迭代流

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

## 10. Mac Catalyst 本地运行入口流

读图说明：这张图展示 v1.0 新增的项目内 Mac Catalyst 本地 build/run 入口。重点是脚本只负责本机构建、启动、日志和调试，不下载模型权重、不调用外部推理服务；云端 CI 只检查脚本静态契约，不尝试启动 GUI App。

```mermaid
flowchart TD
    A[人工或 Agent 执行<br/>./script/build_and_run.sh] --> B{选择脚本模式}
    B -- 默认 run --> C[停止旧 LocalGemma 进程]
    B -- --build-only --> D[只构建 Debug Mac Catalyst App]
    B -- --verify --> C
    B -- --logs / --telemetry --> C
    B -- --debug --> E[lldb 调试入口]
    C --> F[xcodebuild project LocalGemma.xcodeproj<br/>scheme LocalGemma<br/>destination Mac Catalyst]
    D --> F
    F --> G[DerivedData 写入<br/>.build/DerivedDataCodex-MacCatalystRun]
    G --> H[定位 Build/Products 下的 LocalGemma.app]
    H --> I{是否需要启动}
    I -- 否 --> J[输出 app bundle 路径]
    I -- 是 --> K[/usr/bin/open -n 启动 .app]
    K --> L{--verify 是否要求进程检查}
    L -- 是 --> M[pgrep -x LocalGemma<br/>确认进程存在]
    L -- 否 --> N[进入日志流或普通运行]
    M --> O[成功或输出签名/窗口服务/沙箱失败原因]
    E --> F
```

## v3.0 工作台与云端视觉验收

读图说明：共享状态进入拆分后的工作区，截图由云端生产 App 生成，必须核对版本身份后人工查看。

~~~mermaid
flowchart TD
    %% 保留现有状态边界
    State[ModelCatalog / InferenceEngine / DeviceOptimizer] --> Shell[ContentView 稳定页面壳]
    Shell --> Pages[聊天 / 模型 / 提示词 / 设置]
    Theme[WorkbenchTheme / WorkbenchComponents] --> Pages
    %% 单代理与云端验证链路
    Main[main 提交] --> CI[云端 LogicSmoke / iOS XCTest / Catalyst]
    CI --> Visual[iPhone / iPad 四页亮暗截图]
    Visual --> Manifest[SHA / run / attempt / 截图 manifest]
    Manifest --> Review[结果包核对与视觉检查]
~~~


## v3.1 大屏宽度契约

读图说明：收窄后的全局导航和会话分栏使用真实剩余宽度，测试同步生产设计。

```mermaid
flowchart LR
    %% 根尺寸决定导航形式与宽度
    Root[窗口尺寸] --> Global[compact 224至256 / regular 260至288]
    Global --> Pane[窗口减全局侧栏]
    %% 聊天侧栏保留既有可读宽度门槛
    Pane --> Threshold{pane 至少 860pt}
    Threshold -- 是 --> Split[会话与聊天分栏 / 聊天至少620pt]
    Threshold -- 否 --> Stack[横向会话栏]
    Split --> Cloud[云端回归与截图验收]
    Stack --> Cloud
```


## v3.1 云端验收结果

读图说明：布局回归修复后，最新 main commit 由同一云端 run 完成代码、构建、测试和视觉截图验收。

```mermaid
flowchart LR
    Commit[592aa1c main] --> Build[iOS + Catalyst build]
    Build --> Test[131 XCTest + LogicSmoke]
    Test --> Visual[16 张 iPhone/iPad 亮暗截图]
    Visual --> Package[manifest / JUnit / artifact]
    Package --> Pass[run 36309087049 attempt 2 success]
```


## v3.2 提示词网格

读图说明：模板网格使用真实剩余宽度选择列数，避免宽屏单列空白。

```mermaid
flowchart LR
    Root[工作区真实宽度] --> Content[扣除横向 padding]
    Content --> Policy[PromptTemplateGridLayoutPolicy]
    Policy --> Columns[1 / 2 / 3 / 4 列]
    Columns --> Cards[统一模板卡片与 44pt 动作]
```


## v3.3 云端截图重试

读图说明：视觉采集只对 simctl 瞬态失败做有界重试，最终错误仍使阶段失败。

```mermaid
flowchart LR
    Action[boot / install / launch / screenshot] --> Retry{simctl 成功?}
    Retry -- 否且未超3次 --> Backoff[2秒退避]
    Backoff --> Action
    Retry -- 否且已达上限 --> Fail[保留 stderr 并失败]
    Retry -- 是 --> Record[写入截图 manifest]
```

## v3.3.1 焦点测试宿主与同步生产边界

读图说明：首次 pending request 仍在挂载前设置，测试分别验证公开窗口生命周期和真实文本焦点；任何条件失败都会留下诊断并执行清理，生产逻辑没有延迟任务。

```mermaid
flowchart TD
    %% 测试宿主使用已有活跃场景，不创建新的场景
    Scene[等待现有 foreground-active scene] --> Save[保存原 key window]
    Save --> Attach[scene-aware window 挂载真实 ComposerBar<br/>保留预先 pending request]
    Attach --> Ready[有界 expectation<br/>key + visible + attached + viewDidAppear]
    %% 生产路径保持同步，测试只观察结果
    Ready --> Focus[同步 updateFocus 消费 request<br/>验证真实 UITextInput first responder]
    Focus --> Hide[隐藏聊天页且有 pending request<br/>验证 request 与焦点均清空]
    Hide --> Enter[重新进入活动聊天页<br/>验证新请求再次聚焦]
    %% 任一失败保留诊断，成功与失败路径都恢复窗口环境
    Ready -- 超时 --> Fail[记录 scene/window/request/responder 并失败]
    Focus -- 超时 --> Fail
    Hide -- 超时 --> Fail
    Enter -- 超时 --> Fail
    Enter --> Cleanup[defer 结束编辑 / 隐藏 / 移除宿主<br/>恢复原 key window 并断言]
    Fail --> Cleanup
```

## v3.4 互斥呈现、自然高度与语义动作

读图说明：欢迎只选择可见子树，不改 seed 或会话数据；真实会话仍完整显示。布局和颜色都是本地只读呈现，readiness 高度由真实内容自然上报，不再让卡内 GeometryReader 固定高度造成越界。

```mermaid
flowchart TD
    %% 呈现决策只读既有输入，不删除默认消息
    Input[messages / isGenerating / hasStarter] --> Choice{有starter 且非生成且无user?}
    Choice -- 是 --> Welcome[顶部自然高度 welcome<br/>独立可见内容辅助摘要]
    Choice -- 否 --> Transcript[完整原数组 transcript<br/>UUID顺序不变 / 短会话bottom]
    Welcome -. 不改写 .-> State[会话 / seed / 标题 / 导出保持]
    Transcript -. 不改写 .-> State
    %% 会话工具基于实际剩余内容宽度，不新增根断点
    Width[SessionBar真实content width] --> Bar[288pt普通文字inline<br/>窄宽或大字stacked / 竖向sidebar]
    Bar --> Shared[单一sessionList + actions<br/>选择删除新建导出均保留44pt]
    %% panel只包裹真实自然高度
    Panel[设置页或dashboard panel外框] --> Content[扣两侧各14pt<br/>传真实content width]
    Content --> Card[354pt边界 / 原AnyLayout<br/>86slot和66ring / 自然报高]
    %% 风格映射与业务状态分离
    Theme[AppThemePalette] --> Actions[主次危险及prominent配对<br/>分类小面积tint]
    Theme --> Grid[静态40pt工程网格<br/>辅助显示偏好开启时移除装饰]
```

## v3.4.1 云端产物与真实宽度证据

读图说明：完整 XCTest 与 16 张模拟器截图仍是必选。v3.4 的 ImageRenderer 宽屏图缺正文而退回，改用公开 UIKit 宿主截图和标题 OCR；固定 viewport 图不声称 Mac GUI 已测。C 要同时读结构化结果、完整 xcresult 和实际图片，不能仅依赖 OCR。

```mermaid
flowchart TD
    %% 参考窗口先扣除生产全局侧栏，不能把root宽度冒充pane
    Root[1366x1024参考root] --> Global[生产root policy分配288pt sidebar]
    Global --> Pane[1078pt真实workspace pane<br/>chat再分会话栏与至少620pt阅读面]
    Pane --> Render[云端XCTest真实UIKit宿主<br/>drawHierarchy四工作区亮暗8图]
    Card[窄readiness大小字亮暗] --> Component[ImageRenderer仅测自然高度<br/>UIKit宿主组件截图4图]
    %% 原始附件和结构化结果来自同一个本轮xcresult
    Render --> OCR[Vision OCR识别已有页面标题<br/>缺正文不能仅靠尺寸通过]
    OCR --> Result[keepAlways PNG + JSON provenance<br/>LocalGemma-tests.xcresult]
    Component --> Result
    Result --> Export[公开xcresulttool导出<br/>summary / tests / 附件原索引]
    Export --> Manifest[校验12矩阵 / PNG尺寸hash / SHA-run-attempt<br/>OCR标记 + 同主题工作区hash不同]
    Export -- 失败 --> Failure[记录outcome并入visual失败<br/>仍生成manifest和JUnit]
    Screens[16张真实模拟器生产截图] --> Visual[现有必选visual阶段]
    Manifest --> Visual
    Visual --> Full[完整包保留三份xcresult]
    Visual --> Review[review小包辅助先读<br/>不是完整包替代]
    Full --> C[Agent C核对精确身份与结构化结果<br/>并实际看图决定PASS或退回]
    Review --> C
```

## v3.4.2 模型文件动作自然高度

读图说明：新宿主图揭示宽屏动作竖向拉伸，修复只收敛label高度，不改变模型文件或部署链。大字号继续自然增长，完整云端截图验证不取消。

```mermaid
flowchart TD
    %% 右列不能把空白高度注入左侧动作内容
    Pane[1078pt真实pane] --> Columns[生产模型双栏<br/>控制列 + 长详情列]
    Columns --> Panel[ArtifactActionPanel同一HStack]
    Panel --> Label[同一生产Button label<br/>移除竖向Spacer<br/>padding后fixedSize vertical]
    Label --> Height[图标标题副标题连续自然报高<br/>86pt minimum / 大字自然增长]
    %% 只测布局，不调用动作或写入状态
    Height --> Test[公开UIHostingController.sizeThatFits<br/>600/1400pt提议高度一致]
    Test --> Cloud[138项 + 28图 + 三份xcresult<br/>精确SHA云端验收]
    %% 已验收代码身份不冒充后续main文档提交
    Cloud --> Accepted[1601bd6 / run39825340832 attempt1<br/>呈现与布局回归限定PASS<br/>不是Mac GUI或发布验收]
    Label -. 不改变 .-> Boundary[44pt / metadata / 本地文件<br/>卸载确认 / runtime verified gate]
```

## v3.5 设置页双栏与自然回退

读图说明：设置页只使用根侧栏之后的真实pane，不建立第二套根断点；两块生产section在同一个shell中切换布局算法，状态与动作不变。宽屏图仍须实际复核，不以宽度断言替代人眼。

```mermaid
flowchart TD
    %% 根侧栏先分配，设置页再扣自己的padding
    Pane[真实workspace pane] --> Width[扣左右各18pt page padding]
    Width --> Choice{内容至少882pt<br/>且字号小于xxxLarge?}
    Choice -- 是 --> Columns[320pt偏好 + 24pt间距 + 运行计划<br/>运行列538至760pt / 整体最多1104pt]
    Choice -- 否 --> Stacked[同序单栏 / 最多760pt<br/>大字自然垂直增长]
    %% 两个直接子节点固定，只改变AnyLayout算法
    Columns --> Shell[同一个SettingsSectionsShell<br/>preferences + runtime身份保持]
    Stacked --> Shell
    Shell --> Preferences[相册binding / 导入中 / 错误仍归父级<br/>原主题与清除动作 / 44pt和metadata]
    Shell --> Runtime[真实运行列宽传给readiness与grid]
    %% panel内容宽度不能冒充外框宽度
    Runtime --> Grid[toggle扣28pt panel padding<br/>510pt内容阈值 / 指标350pt阈值]
    Grid --> State[原DeviceOptimizer状态流<br/>不启动runtime或联网]
    %% 所有执行只在云端，本机仅静态检查
    Shell --> Cloud[141项 + 16模拟器图 + 12宿主图<br/>三份xcresult / 精确SHA验收]
```


## v3.5.1 焦点宿主顺序

读图说明：首次request仍在挂载前存在，改变的是公开测试窗口的尺寸和就绪顺序；生产同步焦点不新增延迟。

```mermaid
flowchart TD
    %% 测试窗口先以真实场景尺寸接受焦点
    Scene[已有foreground scene] --> Key[真实bounds窗口 + container先key/visible]
    Key --> Mount[公开child containment挂载原ComposerBar
预存pending request仍在]
    %% 只观察生产同步焦点，不代替其设置first responder
    Mount --> Focus[同步onAppear消费request
严格观察真实UITextInput]
    Focus --> Lifecycle[离页清焦点和request / 重进再次聚焦]
    Lifecycle --> Cleanup[移除child和window / 恢复原key window]
    Cleanup --> Cloud[云端141项 + 三份xcresult + 28图复判]
```


## v3.5.2 模拟器正文门禁

读图说明：launch返回只代表系统接受请求，真实截图必须出现对应页面正文，避免把桌面或空白记为成功。

```mermaid
flowchart TD
    %% 独立验证CLI仅在真实云端编译
    Cloud[GitHub Actions] --> Tool[编译Vision截图验证CLI]
    Tool --> Launch[原App launch到指定工作区和主题]
    %% 每轮重新采集，最多五次，不降低marker要求
    Launch --> Shot[等待2秒 / 真实simctl截图]
    Shot --> OCR{目标正文marker被识别?}
    OCR -- 否且未满5次 --> Shot
    OCR -- 否且已满5次 --> Fail[必选visual失败 / 保留诊断]
    OCR -- 是 --> Manifest[识别全文 + marker + 次数 + 尺寸 + hash]
    Manifest --> Review[原16张矩阵 / 完整包人工看图复判]
```
