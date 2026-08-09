# Local Gemma iOS Prototype

一个 SwiftUI iOS 原型 App，主打 iPhone、iPad 与 Mac Catalyst 构建/本地运行基线下部署 Gemma 1.5B 的产品形态。当前版本不下载模型权重，使用本地模拟推理引擎验证 UI、模型管理、流式输出、停止生成和苹果芯片部署优化面板。

## 当前范围

- `LocalGemma.xcodeproj`：可用 Xcode 打开的 iOS 工程，当前 app/test target 支持 iPhone、iPad，并已启用 Mac Catalyst build-for-testing 基线和项目内本地 build/run 入口；本轮没有创建原生 macOS target。
- `LocalGemma/AppState.swift`：模型清单、`LocalInferenceRuntime` 协议、模拟/真实占位 runtime、会话管理、导出文本生成、设备优化状态、本地模型 artifact manifest、`ModelArtifactStore`、`ModelArtifactHasher`、`LocalArtifactValidator`、手动导入错误处理和 Apple Silicon 运行计划。
- `LocalGemma/LocalGemmaApp.swift`：SwiftUI app 入口，创建共享状态对象，并在 scene 层注册 `工作区` 和 `会话` command menu，让 Mac Catalyst 和 iPad 外接键盘用户可从系统菜单发现 workspace 切换、新建会话和导出当前会话。
- `LocalGemma/ContentView.swift`：支持暗色/亮色切换的 SwiftUI 界面，包含推理、模型、提示词、设置四个工作区；推理页改成极简会话界面，顶部 Gemma 模型胶囊集中展示运行状态、速度、内存、后端和权重状态，并以整体辅助语义合并当前模型、SIM/REAL、artifact、后端、速度、内存和准备度；全局 Header 主题切换和打开模型工作区图标动作按 `HeaderActionLayoutPolicy` 保持 44pt 触控目标，顶部 Header 标题按 `HeaderTitleTextLayoutPolicy` 使用 Dynamic Type 语义字体，eyebrow 保持单行，主标题允许两行；顶部模型胶囊按 `ModelCapsuleTextLayoutPolicy` 使用 Dynamic Type 语义字体，名称/状态允许两行；顶部工作区 tab 和大屏侧栏工作区按钮按 `WorkspaceNavigationActionLayoutPolicy` 保持 44pt 触控目标，侧栏标题/副标题按 `WorkspaceSidebarTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行；共享 `SectionHeader` 按 `SectionHeaderTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许标题/副标题多行；提示词模板独立成页，页面整体内容按 `PromptTemplatesWorkspaceLayoutPolicy` 在 iPad/Mac 超宽窗口居中并限制最大宽度，模板网格在窄屏单列、iPad/Mac 宽区域多列伸展之间自适应，模板卡片文本按 `PromptTemplateTextLayoutPolicy` 使用 Dynamic Type 语义字体、多行标题/副标题/正文和更高最小卡片高度，分类筛选 chip 会按 `PromptCategoryLayoutPolicy` 在窄屏换行并保持 44pt 触控高度，并按 `PromptCategoryTextLayoutPolicy` 使用 Dynamic Type 语义字体和两行文本策略，模板卡片填入和发送动作达到 44pt 触控目标；设置页整合外观、相册壁纸和芯片部署优化，页面整体内容按 `SettingsWorkspaceLayoutPolicy` 在 iPad/Mac 超宽窗口居中并限制最大宽度，外观主题、相册壁纸选择和恢复系统背景图标动作按 `SettingsIconActionLayoutPolicy` 保持 44pt 触控目标，外观/壁纸偏好行标题与状态按 `SettingsPreferenceTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，Apple Silicon 优化指标网格与运行策略开关网格在窄屏单列、iPad/Mac 宽区域双列之间自适应，运行策略小节标题、行标题和副标题按共享 `OptimizationToggleTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行垂直增长，单个运行策略开关行按 `OptimizationToggleRowLayoutPolicy` 保持 44pt 触控目标；iPhone 横屏、iPad 竖屏大画布和大屏窗口达到断点后会切换为左侧导航/模型状态栏、右侧工作区；regular 大屏侧栏显示工作区用途说明，compact 侧栏保持紧凑；推理页内部会话侧栏在大屏按 `SessionSidebarLayoutPolicy` 限制宽度，会话栏新建/导出图标按钮按 `SessionBarActionLayoutPolicy` 保持 44pt 触控目标，单个会话 chip 选择和删除入口按 `SessionChipActionLayoutPolicy` 保持 44pt 触控目标，会话 chip 标题按 `SessionChipTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，导出弹层会话摘要、Markdown 预览和底部动作按 `ExportSessionLayoutPolicy` 在 iPad/Mac 宽 sheet 居中并限制最大内容宽度，导出标题/摘要按 `ExportSessionTitleTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，底部分享/复制和 toolbar 分享入口按 `ExportSessionActionLayoutPolicy` 保持 44pt 触控目标，底部 composer 在 iPad/Mac 宽区域居中并限制最大输入行宽，composer 发送/停止按钮按 `ComposerInputActionLayoutPolicy` 保持 44pt 触控目标；模型页整体内容按 `ModelLibraryWorkspaceLayoutPolicy` 在 iPad/Mac 超宽窗口居中并限制最大宽度，足够宽时内部并列展示选择/部署/文件操作与模型详情，右侧详情栏按 `ModelDetailColumnLayoutPolicy` 限制最大阅读宽度，详情参数/建议行按 `ModelDetailRowTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许多行，模型选择器和部署电源按钮按 `ModelDeploymentControlLayoutPolicy` 保持 44pt 触控目标，模型选择器名称/规格按 `ModelSelectorTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，部署电源按钮标题/副标题按 `ModelDeploymentPowerTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，模型文件扫描本地和导入文件按钮按 `ModelArtifactActionLayoutPolicy` 保持 44pt 触控目标，文件动作按钮标题/副标题按 `ModelArtifactActionTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，窄屏保持单栏；Mac Catalyst 和 iPad 外接键盘可用 `Command+1...4` 或系统 `工作区` 菜单切换工作区，可用系统 `会话` 菜单及 `Command+N` / `Command+Shift+E` 新建或导出当前会话，也可点击会话栏可见按钮，`Command+Return` 发送或停止；工作区导航、会话选择、会话 chip 动作、顶部模型胶囊、模型概要面板（`ModelSummaryTextLayoutPolicy` 动态排版）、模型详情右栏与行级内容、模型文件工作流面板、模型卸载确认弹层、模型状态徽章、聊天记录容器、聊天消息气泡、头部主题与模型工作区入口、设置页图标动作、会话栏操作、导出弹层分享/复制、壁纸控件、模型选择器、模型部署控件、运行策略开关、芯片准备度卡片/圆环、优化指标卡、提示词分类筛选和提示词模板动作会向辅助技术暴露稳定语义，芯片准备度摘要会随离线隐私保护开关显示开启或关闭，切回推理页、新建/切换会话、提示词模板填入或发送后会请求聚焦输入框。
- v2.60 起，是否显示竖向会话栏由 `ChatWorkspacePaneLayoutPolicy` 按扣除全局侧栏后的真实 pane 宽度决定；`SessionSidebarLayoutPolicy` 只计算 240...310pt 偏好宽度，分栏必须保留至少 620pt 聊天面。
- v2.61 起，`AppMotionAccessibilityPolicy` 统一接管 10 个显式动画入口：系统开启“减弱动态效果”时，工作区导航、聊天记录自动滚动和模型切换立即更新，主题切换与复制确认保留 0.12 秒局部 ease-out 反馈；普通模式继续使用各入口原有动画。
- v2.62 起，`WorkspaceRootLayoutPolicy` 与生产 `WorkspaceRootShell` 用稳定的 chrome/content 两子节点和 `AnyLayout` 切换根布局轴；所有尺寸共享一个 page-style `workspacePages`，窗口跨越 700pt/regular 断点或切换工作区时不再因两套根页面树重建局部状态。`SessionCommandFocusPolicy` 同时使用结构恒定的 route 包装，只有活动聊天页在包装内提供会话 actions。
- v2.63 起，共享页面宿主改为 `WorkspacePagesShell` 的四个固定页面槽位，移除 page-style `TabView`；`WorkspacePagesInteractionPolicy` 只让当前工作区可见、可命中、启用并对辅助技术可达，隐藏页保留状态身份但不能响应快捷键或交互。顶部/侧栏导航、系统 `工作区` 菜单、`Command+1...4` 和既有状态路由仍是显式切换入口；composer 焦点任务同时受聊天活动态约束，离开聊天页会取消待处理聚焦并清空隐藏输入框焦点。
- v2.64 起，`ModelCapsuleLayoutPolicy` 按真实 chrome 可用宽度和 Dynamic Type 生成模型胶囊布局计划：sidebar 与窄 top header 使用堆叠概要，portrait 最多 3 列指标、sidebar 最多 2 列，`.xxxLarge` 及以上文字固定单列；两列/三列最小指标宽度分别为 108/132pt，2 列时后端/artifact 状态跨整行，readiness ring 使用真实 54pt 直径，完整模型胶囊辅助 value 和业务状态流不变。
- v2.65 起，`ChatBubbleTextLayoutPolicy` 让聊天气泡角色、正文与 token 元数据使用 Dynamic Type 语义字体并完整垂直增长；Accessibility Dynamic Type 下移除角色比例、40/24pt 左右保留空间和 8pt 相邻间距，让气泡使用真实可用宽度，同时继续遵守用户/本地模型/系统消息 520/680/600pt 最大阅读宽度，普通字号布局与消息状态流不变。
- v2.66 起，`ChatTranscriptTrackLayoutPolicy` 让聊天记录的全宽滚动区域承载居中的消息阅读轨道；窄屏保留 18pt 单侧边距，iPad/Mac 超宽窗口在 956pt 容器阈值后封顶 920pt，避免用户与本地模型消息分散到窗口两端。
- v2.67 起，`SessionChipVisualStylePolicy` 将 iPad/Mac 分栏中的竖向会话 chip 纳入工作台视觉层级：选中行改用 8pt 圆角、低饱和 accent 表面、主文字色、hairline 描边和 3pt 左侧指示条；横向 chip、会话状态流与辅助语义不变。
- v2.68 起，`ChatTranscriptVerticalLayoutPolicy` 让非空短会话在高 iPad/Mac 窗口中靠近 composer 底部显示，空记录保持顶部对齐，长记录继续自然滚动；不改变消息顺序、920pt 阅读轨道、VoiceOver 或现有自动滚动。
- v2.69 起，`GenerationIndicatorStylePolicy` 让空文本 assistant 占位从静态“正在生成...”文本升级为「正在生成」加 3 个 accent 圆点的脉冲指示：圆点 5pt 直径、4pt 间距，opacity 在 0.35 与 1.0 之间以 0.9 秒 easeInOut 往复脉冲并逐点延迟 0.15 秒；系统开启减弱动态效果时不启动任何 repeatForever 动画，圆点使用 0.35/0.65/1.0 静态梯度；气泡辅助语义、生成中朗读文案与消息状态流不变。
- v2.70 起，`ComposerFocusGlowStylePolicy` 为 composer 增加纯静态聚焦光环与发送按钮渐变：键盘聚焦时内场描边改 accent 0.55 透明度、1.5pt 线宽并在描边形状上加 10pt 柔和光环（暗 0.35 / 亮 0.20），未聚焦保持 `theme.border` 原状；发送/停止圆钮分别使用 accent 1.0/0.78 与 red 0.9/0.7 对角渐变，可用时加 8pt 光环（暗 0.45 / 亮 0.28），禁用时光环为 0；零动画、天然 Reduce Motion 免疫，外壳生成态描边、`Command+Return`、44/48pt 触控目标与辅助语义不变。
- v2.71 起，`WorkbenchVisualStylePolicy` 为 9 个共享 panel 增加主题感知 0.5pt 内高光，以及 1.5pt/1pt contact 与 8pt/3pt ambient 两层背景阴影；8pt 圆角、14pt padding、1pt hairline、`panelStyle` API、布局、辅助语义、触控目标和业务状态保持不变，panel 内控件不重复套卡片。
- v2.72 起，每条非空且已完成生成的聊天消息提供 44pt 本地复制按钮；trim 只用于判空，写入系统剪贴板的 payload 保留原始空白和换行，成功后 checkmark 持续到气泡身份消失。消息摘要与复制动作分别可达，空白消息和流式生成期间的最新 assistant 消息禁用复制，反馈复用既有 Reduce Motion 策略，不发送云端或改变 runtime。
- v2.73 起，Mac/iPad 竖向 240...310pt 会话侧栏通过 `SessionChipSidebarMetadataPolicy` 只读派生消息数量和数组顺序的最后一条归一化非空消息摘要；连续 whitespace、Tab、换行归一化为单 ASCII 空格，摘要按 `Character` 最多 40 个字符，空摘要回退为消息数，横向会话 chip 返回 hidden plan 并保持 title-only 160pt 胶囊。metadata 使用 Dynamic Type 语义字体自然增长，不改变会话选择/删除、44pt 动作、辅助语义、composer、runtime 或 verified 门禁。
- v2.74 起，Mac Catalyst/iPad pointer 下的竖向未选中会话行通过 `SessionChipHoverStylePolicy` 提供纯视觉反馈：hover 时叠加亮色 0.06、暗色 0.10 的 accent 表面，横向胶囊与选中态完全不变；装饰层不命中且从辅助树隐藏，不新增动画、focus、会话状态或 runtime 行为。`LocalGemmaTests.swift` 增加到 119 个测试函数，完整 build/test 仍交由本轮 GitHub Actions。
- v2.75 起，设置页与优化 dashboard 共用 `ChipReadinessCard` 的 `ChipReadinessLayoutPolicy`：panel 内真实内容宽度达到 `354pt` 才横排，窄内容、Accessibility Dynamic Type 和非法宽度 stacked；正文使用 Dynamic Type 语义字体并可垂直增长，ReadinessRing 保留 `86pt` slot 与 `66pt` diameter，辅助语义、隐私摘要、DeviceOptimizer 状态和本地模拟/runtime/verified 边界不变。`LocalGemmaTests.swift` 增加到 120 个测试函数；本地不下载模型、不运行真实推理，完整 build/test 仍交由本轮 GitHub Actions。
- v2.76 起，设置页与优化 dashboard 共用 `OptimizationToggleGrid` / `OptimizationToggleRow` 和 `OptimizationToggleTextLayoutPolicy`：运行策略小节标题、行标题和副标题改用 Dynamic Type 语义字体，标题/副标题最多两行并自然垂直增长；保留 44pt 行高、250pt 最小卡片宽度、510pt 两列边界、开关顺序/状态和辅助语义。本地只做轻量检查，`LocalGemmaTests.swift` 增加到 121 个测试函数，完整 build/test 仍待本轮 push 后 GitHub Actions。
- v2.77 起，导出会话正文由共享 `ExportSessionBodyTextLayoutPolicy` 控制 18pt padding、3pt line spacing、完整 Markdown 和语义等宽 Dynamic Type 字体；`ExportSessionView` 保留 ScrollView、textSelection、320/760pt 宽度、既有标题/动作辅助语义和 44pt 目标。新增真实生产 View 的公开 `ImageRenderer` 亮暗主题/320/390/834/1200pt/`.large`/`.xxxLarge`/`.accessibility3` 非空渲染契约，源码测试函数数为 122；本地只做轻量检查，完整 build/test 仍待本轮 push 后 GitHub Actions。
- v2.48 的优化指标卡按 `OptimizerMetricTextLayoutPolicy` 使用 Dynamic Type 语义字体，label、value 和 detail 允许多行，避免 iPad split view、Mac Catalyst 窄窗口和较大文字设置下缩放压缩，同时保留指标数据、进度、tint、辅助语义和网格列数。
- v2.49 的设置页外观/壁纸偏好行按 `SettingsPreferenceTextLayoutPolicy` 使用 Dynamic Type 语义字体，标题与状态允许两行，避免 iPad split view、Mac Catalyst 窄窗口和较大文字设置下固定小字号压缩，同时保留图标 44pt 触控目标、主题切换、相册壁纸动作和辅助语义。
- v2.50 的模型详情参数/建议行按 `ModelDetailRowTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许多行，移除 DetailRow 缩放压缩，改善 iPad/Mac 窄窗口和较大文字设置下的可读性。
- v2.51 的顶部模型胶囊与 HeaderMetricChip 按 `ModelCapsuleTextLayoutPolicy` 使用 Dynamic Type 语义字体，名称/状态允许多行，移除名称/状态/数值缩放压缩。
- v2.52 的模型部署电源按钮标题/副标题按 `ModelDeploymentPowerTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，移除主标题缩放压缩。
- v2.53 的会话 chip 标题按 `SessionChipTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，移除标题缩放压缩。
- v2.54 的模型选择器名称/规格按 `ModelSelectorTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，移除缩放压缩。
- v2.55 的模型概要名称/简介按 `ModelSummaryTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许多行，移除名称缩放压缩。
- v2.56 的模型文件动作按钮标题/副标题按 `ModelArtifactActionTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，移除缩放压缩。
- v2.57 的导出弹层标题/摘要按 `ExportSessionTitleTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，移除标题缩放压缩。
- v2.58 的大屏侧栏工作区标题/副标题按 `WorkspaceSidebarTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，移除副标题缩放压缩。
- v2.59 新增 `WorkbenchVisualStylePolicy`：紧凑工作区导航改为共享 material 托盘，大屏 sidebar 改为低饱和导航轨道和细选中指示器，共享 panel 改用主题感知表面、8pt 圆角与 hairline 描边；快捷键、44pt 触控目标、辅助语义和业务状态流保持不变。
- v2.60 新增 `ChatWorkspacePaneLayoutPolicy`：使用扣除全局工作区侧栏后的真实聊天 pane 宽度决定堆叠或分栏；pane 小于 860pt 时保留横向会话栏，分栏时至少保留 620pt 聊天面，`SessionSidebarLayoutPolicy` 只负责 240...310pt 会话栏偏好宽度。
- v2.61 新增 `AppMotionEffect` 与 `AppMotionAccessibilityPolicy`：集中区分大范围空间位移和局部状态反馈，响应系统 `accessibilityReduceMotion`，同时保持导航、焦点、主题、复制、模型选择和 verified 门禁状态流不变。
- v2.62 新增 `WorkspaceRootLayoutPlan`、`WorkspaceRootLayoutPolicy`、`WorkspaceRootShell` 与 `SessionCommandFocusPolicy`：根布局断点只改变轴和 chrome，共享工作区 `TabView` 保持同一结构身份；隐藏聊天页保留稳定 focused route 包装，但其 actions 为 `nil`。
- v2.63 新增 `WorkspacePagePresentation`、`WorkspacePagesInteractionPolicy` 与 `WorkspacePagesShell`：四个工作区固定同序存在，移除分页手势，只让选中页参与命中、控件启用和辅助访问。
- `LocalGemmaTests/LocalGemmaTests.swift`：覆盖默认 Gemma 模拟状态、artifact missing/staged/verified 校验、手动导入文件复制、`.mlmodelc` 目录导入、启动自动扫描、本地模型管理状态流转、模型卸载确认弹层状态流与辅助语义、模拟输出、运行计划、优化开关、运行策略开关辅助语义、运行策略开关宽屏网格、运行策略开关行 44pt 触控目标与 Dynamic Type 文本排版、芯片准备度辅助语义与隐私状态动态摘要、优化指标卡辅助语义、优化指标网格宽度策略、设置页整体宽屏内容宽度策略、共享 SectionHeader 动态排版策略、Header 标题动态排版策略、提示词页整体宽屏内容宽度策略、提示词模板宽屏布局策略、提示词模板文本动态排版策略、提示词分类筛选换行布局策略、提示词分类文本动态排版策略、提示词模板动作 44pt 触控目标、顶部模型胶囊整体辅助语义、模型概要面板辅助语义、模型详情右栏与行级辅助语义、模型详情右栏最大阅读宽度策略、模型文件工作流面板辅助语义、模型文件操作 44pt 触控目标、模型部署控件 44pt 触控目标、模型状态徽章辅助语义、会话 chip 动作语义、会话 chip 选择/删除 44pt 触控目标、聊天消息气泡与聊天记录容器辅助语义、聊天气泡宽屏宽度策略、composer 宽屏输入宽度策略、composer 发送/停止 44pt 触控目标、预设提示词模板、提示词分类筛选辅助语义、提示词模板动作辅助语义、会话管理、Markdown 会话导出、导出弹层分享/复制辅助语义、导出弹层分享/复制 44pt 触控目标、导出弹层整体宽屏内容宽度策略、工作区导航辅助语义、工作区导航 44pt 触控目标、头部主题与模型工作区入口辅助语义、全局 Header 图标动作 44pt 触控目标、设置页图标动作 44pt 触控目标、壁纸控件辅助语义、iPhone/iPad/Mac Catalyst 桌面窗口布局断点、模型页整体宽屏内容宽度策略、模型页内部宽屏布局策略、模型选择器辅助语义、模型部署控件辅助语义、会话栏操作辅助语义、会话栏操作 44pt 触控目标、会话侧栏宽度策略、工作区快捷键映射、工作区 command menu 映射、会话 command menu focused route、regular 侧栏说明、选择语义、composer 输入焦点、控件标识与辅助语义和空输入保护。
- v2.48 新增 `testOptimizerMetricTextLayoutPolicySupportsDynamicTypeCards`。
- v2.49 新增 `testSettingsPreferenceTextLayoutPolicySupportsDynamicTypeRows`。
- v2.50 新增 `testModelDetailRowTextLayoutPolicySupportsDynamicTypeRows`。
- v2.51 新增 `testModelCapsuleTextLayoutPolicySupportsDynamicTypeRows`。
- v2.52 新增 `testModelDeploymentPowerTextLayoutPolicySupportsDynamicTypeRows`。
- v2.53 新增 `testSessionChipTextLayoutPolicySupportsDynamicTypeTitles`。
- v2.54 新增 `testModelSelectorTextLayoutPolicySupportsDynamicTypeRows`。
- v2.55 新增 `testModelSummaryTextLayoutPolicySupportsDynamicTypeRows`。
- v2.56 新增 `testModelArtifactActionTextLayoutPolicySupportsDynamicTypeRows`。
- v2.57 新增 `testExportSessionTitleTextLayoutPolicySupportsDynamicTypeRows`。
- v2.58 新增 `testWorkspaceSidebarTextLayoutPolicySupportsDynamicTypeRows`。
- v2.59 新增 `testWorkbenchVisualStylePolicyDefinesNavigationAndPanelHierarchy`。
- v2.60 新增 `testChatWorkspacePaneLayoutPolicyCoordinatesGlobalAndSessionSidebars`。
- v2.61 新增 `testAppMotionAccessibilityPolicyRespectsReduceMotion`，当前测试函数总数为 104。
- v2.62 新增 `testWorkspaceRootLayoutPolicyResolvesChromeAndAxisAtBoundaries` 与 `testWorkspaceRootShellPreservesStatefulContentAcrossLayoutPlans`；前者覆盖根断点、非法尺寸与精确侧栏 clamp，后者用生产 shell、稳定 focused route modifier、`UIHostingController` 和 `@State` UUID 验证 699.99/700/979.99/980pt 及聊天 active/inactive 往返期间 content 只 appear 一次且不中途 disappear。当前测试函数总数为 106。
- v2.63 新增 `testWorkspacePagesInteractionPolicyExposesOnlySelectedPage` 与 `testWorkspacePagesShellPreservesEveryPageAcrossExplicitNavigation`；前者验证每种 selection 恰有一个可见、可命中、启用且辅助可达页面，后者用生产页面宿主与四个 `@State` UUID 验证多轮显式导航时四页各只 appear 一次且不重建。当前测试函数总数为 108。
- v2.64 新增 `testModelCapsuleLayoutPolicyAdaptsToNarrowChrome`；锁住模型胶囊 248/436pt 阈值、sidebar 上限、`.xxxLarge` 及以上单列、非法宽度、生产 `ImageRenderer` 多宽度渲染和 readiness ring 真实 54pt 尺寸。当前测试函数总数为 109。
- v2.65 新增 `testChatBubbleTextLayoutPolicySupportsAccessibleReading`；锁住语义文本行策略、普通/Accessibility 宽度计划、40/24pt reserve、三种消息角色最大阅读宽度、非法宽度和生产 `ImageRenderer` 多字号渲染。当前测试函数总数为 110。
- v2.66 新增 `testChatTranscriptTrackLayoutPolicyCentersWideConversations`；锁住 18/280/920pt 常量、956pt 封顶阈值、iPhone/iPad/Mac 宽度、非法宽度回退和三种角色气泡上限。当前测试函数总数为 111。
- v2.67 新增 `testSessionChipVisualStylePolicyAlignsWideSidebarHierarchy`；锁住竖向会话行几何、低饱和选中计划、横向胶囊回归和生产 `ImageRenderer` 的亮/暗主题、240/310pt 与 Accessibility Dynamic Type。当前测试函数总数为 112。
- v2.68 新增 `testChatTranscriptVerticalLayoutPolicyAnchorsShortConversations`；锁住空/非空纵向对齐、视口最小高度、无效高度回退、无消息数阈值，以及空/短/溢出生产 `ImageRenderer`。当前测试函数总数为 113。
- v2.69 新增 `testGenerationIndicatorStylePolicyPulsesOnlyWithoutReduceMotion`；锁住生成占位圆点数量/几何/脉冲参数、Reduce Motion 真值表、静态梯度单调递增，以及 280/680pt 与亮/暗主题、`.large`/`.accessibility3` 的生产 `ImageRenderer`。当前测试函数总数为 114。
- v2.70 新增 `testComposerFocusGlowStylePolicyHighlightsKeyboardFocus`；锁住聚焦描边 0.55 透明度、1.5/1pt 线宽、10/8pt 光环半径、glow/sendGlow 四值表、发送与停止渐变端点及单调性契约，并用生产 `ImageRenderer` 覆盖未聚焦 `ComposerBar` 的 360/680pt × 亮/暗主题 × 发送/停止态（`@FocusState` 不可注入，聚焦契约由纯值断言锁住）。当前测试函数总数为 115。
- v2.71 新增 `testWorkbenchPanelDepthStylePolicyAddsThemeAwareElevation`；锁住共享 panel 内高光和 contact/ambient 阴影的精确几何、亮暗主题 opacity 与层级关系，并用公开 `panelStyle` 的生产 modifier 覆盖 360/920pt × 亮/暗主题渲染。当前测试函数总数为 116。
- v2.72 新增 `testChatMessageCopyActionPolicyPreservesLocalPayloadAndAccessibility`；锁住三类消息复制 eligibility、分开的空格/Tab/换行判空、含首尾换行的原始 payload、44pt 动作、独立辅助语义、整个流式生成期间禁用和既有复制反馈 motion，并用生产 `ChatBubble` 覆盖 280/680pt、亮/暗主题与 `.large`/`.xxxLarge`/`.accessibility3`。当前测试函数总数为 117。
- v2.74 新增 `testSessionChipHoverStylePolicyRestrictsPointerFeedback`；锁住 pointer hover 纯视觉策略、亮暗主题 opacity 和真实 `SessionChip` 渲染，测试函数总数为 119。
- v2.75 新增 `testChipReadinessLayoutPolicyAdaptsToCardWidthAndAccessibilityDynamicType`；锁住真实 panel 宽度、Accessibility stacked 回退、ring 尺寸和真实 `ChipReadinessCard` 渲染，测试函数总数为 120。
- v2.76 新增 `testOptimizationToggleTextLayoutPolicySupportsDynamicTypeRows`；锁住共享 text policy 的两行/spacing 契约、44pt 行高、250/510pt 网格边界、DeviceOptimizer 状态不变和真实 `OptimizationToggleRow` / `OptimizationToggleGrid` 的 ImageRenderer 尺寸矩阵，测试函数总数为 121；本地仅执行轻量检查，完整云端 build/test/LogicSmoke 待本轮 push 后 GitHub Actions。
- v2.77 新增 `testExportSessionBodyTextLayoutPolicySupportsDynamicTypeReading`；锁住正文 policy 的 18pt padding、3pt line spacing、完整正文和语义等宽契约，回归 ExportSessionLayoutPolicy 的 320/390/834/1200pt 与非法宽度、导出动作 44pt 目标，并用真实 `ExportSessionView` 覆盖亮暗主题与 `.large`/`.xxxLarge`/`.accessibility3` 的公开 `ImageRenderer` 非空/正尺寸结果。源码测试函数总数为 122；固定 NavigationStack/GeometryReader 测试 viewport 使宿主高度保持稳定，Dynamic Type/full-text 约束由纯值契约和生产渲染非空断言共同锁住；本地未运行 XCTest、xcodebuild、Simulator、Catalyst 或视觉截图检查。
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

当前工程已允许 iPhone、iPad 和 Mac Catalyst build-for-testing。iPhone 竖屏保持单栏；iPhone 横屏、iPad Pro 竖屏大画布、Mac Catalyst 和足够大的桌面窗口达到 `WorkspaceLayoutMode` 断点后，App 主界面会切换为左侧状态/导航栏、右侧工作区；regular 大屏侧栏显示工作区用途说明，compact 双栏保持紧凑；全局 Header 主题切换和打开模型工作区图标动作由 `HeaderActionLayoutPolicy` 保持 44pt 触控目标，顶部 Header eyebrow 和主标题由 `HeaderTitleTextLayoutPolicy` 使用 Dynamic Type 语义字体，主标题在 iPad split view、Mac Catalyst 窄窗口和较大文字设置下允许两行，顶部工作区 tab 和大屏侧栏工作区按钮由 `WorkspaceNavigationActionLayoutPolicy` 保持 44pt 触控目标；推理页由 `ChatWorkspacePaneLayoutPolicy` 按真实 pane 宽度决定横向会话栏堆叠或竖向会话栏分栏，`SessionSidebarLayoutPolicy` 只把竖向会话栏偏好宽度限制在 240 到 310，分栏至少保留 620pt 聊天面；会话栏可见新建/导出按钮由 `SessionBarActionLayoutPolicy` 保持 44pt 触控目标；模型页整体内容由 `ModelLibraryWorkspaceLayoutPolicy` 在 iPad/Mac 超宽区域居中并限制最大宽度，内部由 `ModelLibraryLayoutMode` 按内容宽度选择单栏或双栏，足够宽的 iPad/Mac 高窗口会并列展示选择/部署/文件操作与模型详情，右侧详情栏由 `ModelDetailColumnLayoutPolicy` 使用剩余空间并限制最大阅读宽度，模型选择器和部署电源按钮由 `ModelDeploymentControlLayoutPolicy` 保持 44pt 触控目标，扫描本地和导入文件 utility 按钮由 `ModelArtifactActionLayoutPolicy` 保持 44pt 触控目标，窄屏仍按原顺序单栏展示；提示词页整体内容由 `PromptTemplatesWorkspaceLayoutPolicy` 在 iPad/Mac 超宽区域居中并限制最大宽度，提示词模板网格在窄屏保持单列，在 iPad/Mac 宽区域多列伸展并限制最大卡片宽度，模板卡片文本由 `PromptTemplateTextLayoutPolicy` 控制多行可读性和最小高度，提示词分类筛选 chip 由 `PromptCategoryLayoutPolicy` 保持 44pt 触控目标并在窄屏换行，分类 chip 文本由 `PromptCategoryTextLayoutPolicy` 允许两行并使用 Dynamic Type 语义字体；设置页整体内容由 `SettingsWorkspaceLayoutPolicy` 在 iPad/Mac 超宽区域居中并限制最大宽度，设置页外观主题、相册壁纸选择和恢复系统背景图标动作由 `SettingsIconActionLayoutPolicy` 保持 44pt 触控目标，外观/壁纸偏好行标题与状态由 `SettingsPreferenceTextLayoutPolicy` 使用 Dynamic Type 语义字体并允许两行，设置页和优化 dashboard 的 Apple Silicon 指标网格与运行策略开关网格在窄屏/窄 split view 下回退单列，在 iPad/Mac 宽区域保持双列，单个运行策略开关行由 `OptimizationToggleRowLayoutPolicy` 保持 44pt 触控目标，composer 发送/停止按钮由 `ComposerInputActionLayoutPolicy` 保持 44pt 触控目标。Mac Catalyst 和 iPad 外接键盘可用 `Command+1...4` 或系统 `工作区` 菜单切换工作区，可用系统 `会话` 菜单及 `Command+N` / `Command+Shift+E` 新建或导出当前会话，也可点击会话栏可见按钮，`Command+Return` 发送或停止；顶部模型胶囊、模型概要面板、模型详情右栏与行级内容、模型文件工作流面板、模型卸载确认弹层、模型状态徽章、会话 chip 选择/删除动作、聊天记录容器、聊天消息气泡、工作区导航、头部主题切换、模型工作区入口、设置页图标动作、会话栏操作、壁纸控件、模型选择器、模型部署电源和模型文件操作按钮、运行策略开关、芯片准备度卡片/圆环、优化指标卡、提示词分类筛选 chip、提示词模板填入和发送按钮暴露 label、value、hint、Voice Control 输入标签和稳定 identifier；芯片准备度摘要随 `Offline privacy guard` 开关动态显示离线隐私保护开启或关闭；切回推理页、新建/切换会话、提示词模板填入或发送后会请求聚焦输入框。当前没有原生 macOS target。

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

模型选择器、安装状态徽章、artifact 状态徽章、部署状态徽章、部署电源、模拟暂存、卸载确认入口、确认卸载/取消卸载按钮、扫描、导入按钮、模型文件工作流面板、模型概要面板、模型详情区域和详情参数/性能/建议行都暴露稳定的辅助技术 label/value/hint、Voice Control 输入标签和 identifier；模型选择器和部署电源按钮保持至少 44pt 触控目标；辅助文案会明确切换模型不下载权重、不启动真实 runtime、状态徽章只展示本地模型状态、模拟暂存不联网下载，卸载按钮只打开确认弹层，确认后只删除 App 托管模型文件并停止部署，取消不会删除文件或停止部署，也不会删除用户 Files 中的原始文件，模型文件工作流只管理本地文件、扫描只读取本地 manifest 必需文件、Files 导入只复制用户选择的本地文件，概要面板只读取本地模型简介、能力标签和 artifact 校验摘要，详情摘要和行级内容只读取本地模型规格、artifact 状态、后端和运行计划，未 verified 的 artifact 不会运行真实权重。

App 启动时会自动扫描 `Application Support/LocalModels`，如果用户之前已经手动导入过 manifest 指定文件，会恢复到 `staged` 或 `verified` 状态；单元测试仍用注入目录隔离真实用户目录。聊天页会把当前选中模型的 artifact availability 传入 `InferenceRequest`，并在 `InferenceEngine.lastPreparationReport` 记录本次生成使用的端侧运行计划，同时在顶部 Gemma 模型胶囊显示本次响应是 `SIM` 还是 `REAL`、计划后端、速度、内存和权重状态；模型胶囊整体辅助语义会合并当前模型、参数、量化、artifact missing/staged/verified、后端、生成状态、速度、内存和准备度，并说明只展示本地状态、不下载权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。

推理页交互已做简化：

- 顶部只保留一个 Gemma 模型胶囊，速度、内存、后端和权重状态都收进这里，避免重复显示模型名。
- 会话栏参考 ChatGPT 网页端的历史列表结构，支持新建会话、切换会话、删除会话；系统 `会话` 菜单和会话栏可见按钮通过同一组 action 语义覆盖新建和导出当前会话动作；单个会话 chip 的选择和删除动作会向辅助技术说明本地会话切换、composer 聚焦、删除范围、默认空白当前会话不可删除原因、Voice Control 输入标签和稳定 identifier；会话栏按钮会向辅助技术说明快捷键、本地会话焦点流和本地 Markdown / 文本分享兜底，不会把会话发送到云端服务；会话会根据首条用户输入自动生成名字。
- 聊天记录容器会向辅助技术说明当前本地会话消息总数、最新消息角色、生成中状态、Voice Control 输入标签和稳定 identifier；单条消息气泡继续说明角色、正文或生成中状态、token 数和本地边界。
- 导出按钮会生成当前会话的 `.md` 文件，导出弹层显示会话摘要、正文预览、底部分享/复制按钮和 toolbar 分享入口；会话摘要、Markdown 预览和底部动作由 `ExportSessionLayoutPolicy` 在 iPad/Mac 宽 sheet 中居中并限制最大内容宽度，iPhone 和窄 split view 保持原有可用宽度；底部分享/复制至少 44pt 高，toolbar 分享至少 44x44；分享 Markdown、文本兜底和复制全文动作会向辅助技术说明本地文件、文本兜底、剪贴板和不发送云端服务边界。
- 输入区以 `问本地模型任何问题` 为主入口，只保留发送/停止一个核心动作按钮；输入框和发送/停止按钮有稳定的辅助技术 label/value/hint、Voice Control 输入标签和 identifier，按钮按 `ComposerInputActionLayoutPolicy` 保持 44pt 触控目标，保留 `Command+Return`，hint 明确本地模拟 runtime、不下载权重、不启动真实 runtime、不发送云端服务且不绕过 verified 门禁；切回推理、新建/切换会话或使用模板后会请求聚焦。

提示词页提供 `部署方案`、`隐私评审`、`芯片优化`、`技术总结`、`产品文案`、`排障清单` 六个模板，并支持按部署、隐私、性能、写作、产品、排障筛选。提示词页标题、分类筛选和模板网格作为整体在 Mac/iPad 超宽窗口中居中并限制最大内容宽度；模板网格在窄屏保持单列，在 iPad/Mac 宽区域多列伸展并限制最大卡片宽度，避免旧固定宽度浪费宽屏空间。筛选 chip 会向 VoiceOver 和 Voice Control 暴露当前筛选、动作提示、输入标签和稳定 identifier。模板可先填入输入框再编辑，也可以通过卡片内发送按钮直接作为当前模型输入发送；模板动作会说明填入只写入 composer 且不发送 prompt，发送走本地模拟 runtime，不下载模型权重、不启动真实 runtime、不发送到云端服务，也不绕过 verified 门禁。

设置页集中放置外观和芯片策略：

- 太阳/月亮图标用于在暗色和亮色 UI 之间切换。
- 壁纸面板可以从系统相册选择图片作为 App 背景，也可以一键恢复系统背景；选择相册和恢复系统背景按钮会向辅助技术说明系统背景、相册图片已启用、正在处理、本地压缩和不发送云端服务边界；背景会叠加主题遮罩，保证文字可读。
- 设置页标题、外观、壁纸、芯片准备度、优化指标和运行策略开关作为整体在 Mac/iPad 超宽窗口中居中并限制最大内容宽度，窄屏和窄 split view 保留原有可用宽度。
- 原芯片工作区已整合到设置页，继续展示 A17 Pro / M 系列准备度、Metal 预热、KV cache、热状态和离线隐私保护；优化指标网格和运行策略开关网格窄屏单列、宽屏双列，单个运行策略开关行保持 44pt 触控目标；优化指标卡会向辅助技术说明指标状态、进度、detail 和本地边界，不会下载权重、启动真实 runtime 或发送云端服务。

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

v2.48 本轮增加优化指标卡文本动态排版策略：设置页和优化 dashboard 的指标卡由 `OptimizerMetricTextLayoutPolicy` 控制，label、value 和 detail 使用 Dynamic Type 语义字体并允许多行，移除 label/value 的单行缩放压缩，改善 iPad split view、Mac Catalyst 窄窗口和较大文字设置下的可读性，同时保留指标数据、进度、tint、辅助语义、网格列数、本地模拟 runtime 和 verified 门禁边界；`LocalGemmaTests.swift` 当前测试函数数为 91。

```sh
git diff --check
test -x script/build_and_run.sh
bash -n script/build_and_run.sh
plutil -lint LocalGemma.xcodeproj/project.pbxproj
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift
```

结果：`git diff --check` 无输出；脚本可执行且 `bash -n` 通过；`plutil` 输出 `LocalGemma.xcodeproj/project.pbxproj: OK`；Ruby YAML 解析输出 `yaml ok`；测试函数数为 91；`Logic smoke passed`；SwiftUI 源码 typecheck、测试模块生成和测试源码 typecheck 均通过。新增 `testOptimizerMetricTextLayoutPolicySupportsDynamicTypeCards` 锁住优化指标卡文本动态排版策略。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.49 本轮增加设置偏好行文本动态排版策略：设置页 `ThemePreferencePanel` / `WallpaperPreferencePanel` 由 `SettingsPreferenceTextLayoutPolicy` 控制，标题与状态使用 Dynamic Type 语义字体并允许两行，移除固定小字号，改善 iPad split view、Mac Catalyst 窄窗口和较大文字设置下的可读性，同时保留图标 44pt 触控目标、主题切换、相册壁纸、辅助语义、设置页整体宽度、本地模拟 runtime 和 verified 门禁边界；`LocalGemmaTests.swift` 当前测试函数数为 92。

结果：`git diff --check` 无输出；脚本可执行且 `bash -n` 通过；`plutil` 输出 `LocalGemma.xcodeproj/project.pbxproj: OK`；Ruby YAML 解析输出 `yaml ok`；测试函数数为 92；`Logic smoke passed`；SwiftUI 源码 typecheck、测试模块生成和测试源码 typecheck 均通过。新增 `testSettingsPreferenceTextLayoutPolicySupportsDynamicTypeRows` 锁住设置偏好行文本动态排版策略。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.50 本轮增加模型详情行文本动态排版策略：`DetailRow` / `AdviceRow` 由 `ModelDetailRowTextLayoutPolicy` 控制，标题/数值/建议使用 Dynamic Type 语义字体并允许多行，移除 DetailRow `minimumScaleFactor`；`LocalGemmaTests.swift` 当前测试函数数为 93。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.51 本轮增加模型胶囊文本动态排版策略：`ModelCapsule` / `HeaderMetricChip` 由 `ModelCapsuleTextLayoutPolicy` 控制，名称/状态/指标使用 Dynamic Type 语义字体并允许多行，移除缩放压缩；`LocalGemmaTests.swift` 当前测试函数数为 94。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.52 本轮增加模型部署电源按钮文本动态排版策略：`DeploymentPowerButton` 由 `ModelDeploymentPowerTextLayoutPolicy` 控制，主标题/副标题使用 Dynamic Type 语义字体并允许两行，移除主标题 `minimumScaleFactor`；`LocalGemmaTests.swift` 当前测试函数数为 95。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.53 本轮增加会话 chip 标题文本动态排版策略：`SessionChip` 由 `SessionChipTextLayoutPolicy` 控制，标题使用 Dynamic Type 语义字体并允许两行，移除 `minimumScaleFactor`；`LocalGemmaTests.swift` 当前测试函数数为 96。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.54 本轮增加模型选择器文本动态排版策略：`ModelSelectorPanel` 由 `ModelSelectorTextLayoutPolicy` 控制，名称/规格使用 Dynamic Type 语义字体并允许两行，移除 `minimumScaleFactor`；`LocalGemmaTests.swift` 当前测试函数数为 97。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.55 本轮增加模型概要标题文本动态排版策略：`ModelSummaryPanel` 由 `ModelSummaryTextLayoutPolicy` 控制，名称/简介使用 Dynamic Type 语义字体并允许多行，移除名称 `minimumScaleFactor`；`LocalGemmaTests.swift` 当前测试函数数为 98。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.56 本轮增加模型文件动作按钮文本动态排版策略：`ArtifactActionButton` 由 `ModelArtifactActionTextLayoutPolicy` 控制，标题/副标题使用 Dynamic Type 语义字体并允许两行，移除 `minimumScaleFactor`；`LocalGemmaTests.swift` 当前测试函数数为 99。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.57 本轮增加导出弹层标题文本动态排版策略：`exportHeader` 由 `ExportSessionTitleTextLayoutPolicy` 控制，标题/摘要使用 Dynamic Type 语义字体并允许两行，移除标题 `minimumScaleFactor`；`LocalGemmaTests.swift` 当前测试函数数为 100。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.58 本轮增加工作区侧栏文本动态排版策略：`sidebarTabPicker` 由 `WorkspaceSidebarTextLayoutPolicy` 控制，标题/副标题使用 Dynamic Type 语义字体并允许两行，移除副标题 `minimumScaleFactor`；`LocalGemmaTests.swift` 当前测试函数数为 101。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.59 本轮建立工作台视觉层级系统：`WorkbenchVisualStylePolicy` 统一紧凑导航托盘、大屏 sidebar 轨道、选中指示器和共享 panel 的几何与主题透明度；`panelStyle` 改为读取当前主题的 modifier；`LocalGemmaTests.swift` 当前测试函数数为 102。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.60 本轮协调聊天工作区双侧栏宽度：`ChatWorkspacePaneLayoutPolicy` 使用全局侧栏分配后的真实 pane 宽度选择堆叠或分栏，860pt 以下不启用竖向会话栏，分栏时至少保留 620pt 聊天面；`ChatWorkspace` 用 `AnyLayout` 复用同一组会话栏和聊天面子视图；`LocalGemmaTests.swift` 当前测试函数数为 103。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

v2.61 本轮增加工作台 Reduce Motion 策略：`AppMotionAccessibilityPolicy` 覆盖 10 个显式 `withAnimation` 入口，减弱动态效果开启时取消工作区导航、聊天记录自动滚动和模型切换的大范围动画，并把主题切换和复制确认收敛为 0.12 秒局部 ease-out；`LocalGemmaTests.swift` 当前测试函数数为 104。完整 iOS XCTest 与 Mac Catalyst 云端重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

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

v2.63 本轮已完成本地逻辑烟测：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -module-cache-path .build/v263/SwiftSmokeModuleCache \
  LocalGemma/AppState.swift Tools/LogicSmoke.swift \
  -o .build/v263/logic-smoke

.build/v263/logic-smoke
```

结果：`Logic smoke passed`。

v2.63 本轮已完成 Swift 编译器验证：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -typecheck \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path .build/v263/ModuleCache \
  LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift
```

结果：通过。

v2.63 当时已生成可测试导入的 `LocalGemma.swiftmodule`，并用 iPhone Simulator 的 XCTest framework 对测试源码做 API 层 typecheck。当前测试源码静态包含 122 个 `XCTestCase` 测试函数（v2.71 编译与运行已由 GitHub Actions run `30322522109` 对 commit `3c6b1c3` 验证通过，116 项 XCTest、0 failed；v2.72 的第 117 项测试已由 run `30324632725` attempt `2` 对 commit `c9228d7` 验证通过，117 项 XCTest、0 failed；v2.74/v2.75 的新增测试已加入源码并由对应历史记录说明；v2.76 新增测试等待本轮 push 后 GitHub Actions 与 Agent C 结果包验收；v2.77 新增测试等待本轮 push 后 GitHub Actions 与 Agent C 结果包验收），覆盖单条消息本地复制、共享 panel 内高光与分层阴影、composer 聚焦光环与发送按钮渐变、生成中状态脉冲指示、短会话纵向定位、竖向会话侧栏视觉层级与信息密度、聊天记录居中阅读轨道、聊天气泡文本 Dynamic Type 与 Accessibility 宽度、模型胶囊窄侧栏响应式布局、工作区根布局纯策略、生产 shell 结构身份、工作区页面显式导航与交互隔离、活动聊天 focused route、提示词模板库、工作台导航与共享 panel 视觉层级、聊天工作区双侧栏宽度协调、工作台 Reduce Motion 动画分类、工作区导航 44pt 触控目标、导出弹层分享/复制 44pt 触控目标、导出弹层整体宽屏内容宽度策略、会话 chip 选择/删除 44pt 触控目标、模型文件操作 44pt 触控目标、模型部署控件 44pt 触控目标、全局 Header 图标动作 44pt 触控目标、Header 标题动态排版策略、设置页整体宽屏内容宽度策略、共享 SectionHeader 动态排版策略、优化指标卡文本动态排版策略、设置偏好行文本动态排版策略、提示词页整体宽屏内容宽度策略、提示词模板宽屏布局策略、提示词模板文本动态排版策略、提示词分类筛选换行布局策略、提示词分类文本动态排版策略、提示词模板动作 44pt 触控目标、提示词分类筛选辅助语义、提示词模板动作辅助语义、模板填入输入框、模板直接发送、会话创建/切换/删除、会话 command menu focused route、工作区导航辅助语义、设置页图标动作 44pt 触控目标、会话栏操作辅助语义、会话栏操作 44pt 触控目标、会话 chip 动作语义、聊天消息气泡与聊天记录容器辅助语义、聊天气泡宽屏宽度策略、composer 宽屏输入宽度策略、composer 发送/停止 44pt 触控目标、Markdown 会话导出、导出弹层分享/复制辅助语义、头部主题与模型工作区入口辅助语义、壁纸控件辅助语义、iPhone/iPad/Mac Catalyst 桌面窗口布局断点、模型页整体宽屏内容宽度策略、模型页内部宽屏布局策略、模型详情右栏最大阅读宽度策略、顶部模型胶囊整体辅助语义、模型概要面板辅助语义、模型详情右栏与行级辅助语义、模型文件工作流面板辅助语义、模型卸载确认弹层状态流与辅助语义、模型选择器辅助语义、模型状态徽章辅助语义、模型部署控件辅助语义、运行策略开关辅助语义、运行策略开关宽屏网格、运行策略开关行 44pt 触控目标、芯片准备度辅助语义与隐私状态动态摘要、优化指标卡辅助语义、优化指标网格宽度策略、会话侧栏宽度策略、工作区快捷键映射、工作区 command menu 映射、会话侧栏信息密度、regular 侧栏说明、选择语义、composer 输入焦点、控件标识与辅助语义、壁纸处理和分享兜底：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -emit-module \
  -emit-module-path .build/v263/Typecheck/LocalGemma.swiftmodule \
  -module-name LocalGemma \
  -enable-testing \
  -parse-as-library \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path .build/v263/ModuleCache \
  LocalGemma/AppState.swift LocalGemma/ContentView.swift LocalGemma/LocalGemmaApp.swift

/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -typecheck \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  -module-cache-path .build/v263/TestModuleCache \
  -I .build/v263/Typecheck \
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

说明：当前 Codex 沙箱内的 CoreSimulator 访问受限；v2.49 本轮未默认重跑本机完整模拟器 XCTest。本轮在工作区内执行 `git diff --check`、`plutil -lint`、workflow YAML 解析、92 个测试函数统计、逻辑烟测和 Swift typecheck；完整 iOS XCTest 与云端 Mac Catalyst 重验证以本轮 push 后的 GitHub Actions run 和 Agent C 下载结果包验收为准。

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

v2.34 优化设置页整体宽屏内容宽度：设置页新增 `SettingsWorkspaceLayoutPolicy`，标题、外观、壁纸、芯片准备度、优化指标和运行策略开关在 iPad/Mac 超宽窗口中整体居中并限制最大内容宽度；新增设置页整体宽屏内容宽度测试，`LocalGemmaTests.swift` 增加到 78 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.35 优化全局 Header 图标动作触控目标：新增 `HeaderActionLayoutPolicy`，主题切换和打开模型工作区两个全局 Header 图标按钮统一达到 44pt 触控目标；新增全局 Header 图标动作触控目标测试，`LocalGemmaTests.swift` 增加到 79 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.36 优化模型文件操作触控目标：新增 `ModelArtifactActionLayoutPolicy`，模型页文件工作流面板中的扫描本地和导入文件 utility 按钮统一达到 44pt 触控目标；新增模型文件操作触控目标测试，`LocalGemmaTests.swift` 增加到 80 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.37 优化会话 Chip 删除触控目标：新增 `SessionChipActionLayoutPolicy`，推理页单个会话 chip 的删除图标按钮统一达到 44pt 触控目标；新增会话 chip 删除触控目标测试，`LocalGemmaTests.swift` 增加到 81 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.38 优化导出弹层分享复制触控目标：新增 `ExportSessionActionLayoutPolicy`，导出弹层底部分享/复制按钮至少 44pt 高，toolbar 分享入口至少 44x44；新增导出弹层分享复制触控目标测试，`LocalGemmaTests.swift` 增加到 82 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.39 优化工作区导航触控目标：新增 `WorkspaceNavigationActionLayoutPolicy`，顶部工作区 tab 和大屏侧栏工作区按钮统一达到 44pt 触控目标；新增工作区导航触控目标测试，`LocalGemmaTests.swift` 增加到 83 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.42 限制导出弹层宽屏内容宽度：新增 `ExportSessionLayoutPolicy`，让会话摘要、Markdown 预览和底部分享/复制动作在 iPad/Mac 宽 sheet 中居中并封顶；新增导出弹层宽屏内容宽度测试，`LocalGemmaTests.swift` 增加到 85 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.43 优化运行策略开关行触控目标：新增 `OptimizationToggleRowLayoutPolicy`，让设置页和优化 dashboard 的单个运行策略开关行保持 44pt 最小命中高度；新增运行策略开关行触控目标测试，`LocalGemmaTests.swift` 增加到 86 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.44 优化 Composer 发送停止触控目标：新增 `ComposerInputActionLayoutPolicy` 和 `ComposerInputAction`，让推理页 composer 发送/停止按钮保留 48pt 视觉尺寸并锁住至少 44pt 触控目标；新增 composer 发送/停止触控目标测试，`LocalGemmaTests.swift` 增加到 87 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.45 优化共享 SectionHeader 动态排版：新增 `SectionHeaderTextLayoutPolicy`，提示词页、模型页、设置页和优化区的小节标题改用 Dynamic Type 语义字体，主标题允许两行，副标题允许多行；新增共享 SectionHeader 动态排版测试，`LocalGemmaTests.swift` 增加到 88 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.46 优化模型部署控件触控目标：新增 `ModelDeploymentControlLayoutPolicy`，模型选择器和部署电源按钮保持至少 44pt 触控目标，部署电源按钮保留 92pt 当前视觉高度；新增模型部署控件触控目标测试，`LocalGemmaTests.swift` 增加到 89 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.47 优化 Header 标题动态排版：新增 `HeaderTitleTextLayoutPolicy`，顶部 Header eyebrow 和主标题改用 Dynamic Type 语义字体，eyebrow 保持单行，主标题允许两行，减少 iPad split view、Mac Catalyst 窄窗口和较大文字设置下压缩或截断；新增 Header 标题动态排版测试，`LocalGemmaTests.swift` 增加到 90 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.48 优化指标卡文本动态排版：新增 `OptimizerMetricTextLayoutPolicy`，设置页和优化 dashboard 的指标 label、value 和 detail 改用 Dynamic Type 语义字体并允许多行，移除 label/value 单行缩放压缩；新增优化指标卡文本动态排版测试，`LocalGemmaTests.swift` 增加到 91 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.49 优化设置偏好行文本动态排版：新增 `SettingsPreferenceTextLayoutPolicy`，设置页外观/壁纸偏好行标题与状态改用 Dynamic Type 语义字体并允许两行；新增设置偏好行文本动态排版测试，`LocalGemmaTests.swift` 增加到 92 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.50 优化模型详情行文本动态排版：新增 `ModelDetailRowTextLayoutPolicy`，模型详情参数/建议行改用 Dynamic Type 语义字体并允许多行，移除 DetailRow 缩放压缩；新增模型详情行文本动态排版测试，`LocalGemmaTests.swift` 增加到 93 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.51 优化模型胶囊文本动态排版：新增 `ModelCapsuleTextLayoutPolicy`，顶部模型胶囊名称/状态与 HeaderMetricChip 改用 Dynamic Type 语义字体并允许多行，移除缩放压缩；新增模型胶囊文本动态排版测试，`LocalGemmaTests.swift` 增加到 94 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.52 优化模型部署电源按钮文本动态排版：新增 `ModelDeploymentPowerTextLayoutPolicy`，部署电源按钮主标题/副标题改用 Dynamic Type 语义字体并允许两行，移除主标题缩放压缩；新增测试，`LocalGemmaTests.swift` 增加到 95 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.53 优化会话 chip 标题文本动态排版：新增 `SessionChipTextLayoutPolicy`，会话标题改用 Dynamic Type 语义字体并允许两行，移除缩放压缩；新增测试，`LocalGemmaTests.swift` 增加到 96 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.54 优化模型选择器文本动态排版：新增 `ModelSelectorTextLayoutPolicy`，选中模型名/规格摘要改用 Dynamic Type 语义字体并允许两行，移除缩放压缩；新增测试，`LocalGemmaTests.swift` 增加到 97 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.55 优化模型概要标题文本动态排版：新增 `ModelSummaryTextLayoutPolicy`，模型概要名称/简介改用 Dynamic Type 语义字体并允许多行，移除名称缩放压缩；新增测试，`LocalGemmaTests.swift` 增加到 98 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.56 优化模型文件动作按钮文本动态排版：新增 `ModelArtifactActionTextLayoutPolicy`，文件动作按钮标题/副标题改用 Dynamic Type 语义字体并允许两行，移除缩放压缩；新增测试，`LocalGemmaTests.swift` 增加到 99 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.57 优化导出弹层标题文本动态排版：新增 `ExportSessionTitleTextLayoutPolicy`，导出会话标题/摘要改用 Dynamic Type 语义字体并允许两行，移除标题缩放压缩；新增测试，`LocalGemmaTests.swift` 增加到 100 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.58 优化工作区侧栏文本动态排版：新增 `WorkspaceSidebarTextLayoutPolicy`，侧栏标题/副标题改用 Dynamic Type 语义字体并允许两行，移除副标题缩放压缩；新增测试，`LocalGemmaTests.swift` 增加到 101 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.59 重构工作台视觉层级：新增 `WorkbenchVisualStylePolicy`，紧凑导航使用共享托盘，大屏 sidebar 使用低饱和轨道和选中指示器，共享 panel 使用主题感知表面、8pt 圆角与 hairline 描边；新增测试，`LocalGemmaTests.swift` 增加到 102 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.60 协调聊天工作区双侧栏宽度：新增 `ChatWorkspacePaneLayoutPolicy`，按实际聊天 pane 宽度选择堆叠/分栏，860pt 以下堆叠，分栏至少保留 620pt 聊天面；新增测试，`LocalGemmaTests.swift` 增加到 103 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.61 适配工作台减弱动态效果：新增 `AppMotionEffect` 与 `AppMotionAccessibilityPolicy`，覆盖 10 个显式动画入口，大范围空间位移在 Reduce Motion 下立即更新，主题/复制局部反馈收敛为 0.12 秒；新增测试，`LocalGemmaTests.swift` 增加到 104 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.62 稳定工作区响应式结构身份：新增 `WorkspaceRootLayoutPolicy` 与生产 `WorkspaceRootShell`，用稳定 chrome/content 两子节点和单一 page-style `workspacePages` 跨根断点复用工作区；新增活动聊天 focused route gate、纯布局策略测试和 `UIHostingController` 身份探针，`LocalGemmaTests.swift` 增加到 106 个测试函数。本轮未把 host probe 解释为 Mac 触控板分页或完整人工 UI 验证，仍没有原生 macOS target，不接真实模型，不下载权重。
v2.63 隔离工作区分页手势：以四个固定页面槽位的 `WorkspacePagesShell` 替换 page-style `TabView`，只有选中页可见、可交互且辅助可达，隐藏页禁用但保留状态身份；新增策略与生产宿主身份测试，`LocalGemmaTests.swift` 增加到 108 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.64 优化模型胶囊窄侧栏响应式布局：新增 `ModelCapsuleLayoutPolicy`，按真实 chrome 可用宽度和 Accessibility Dynamic Type 切换横向/堆叠概要及 1/2/3 列指标，修正 readiness ring 54/66pt 尺寸不一致；新增策略与生产 `ImageRenderer` 测试，`LocalGemmaTests.swift` 增加到 109 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.65 优化聊天气泡文本动态排版：新增 `ChatBubbleTextLayoutPolicy`，角色、正文和 token 元数据改用 Dynamic Type 语义字体；Accessibility 文字下移除角色比例与左右 reserve，继续锁住各角色最大阅读宽度；新增纯值与生产 `ImageRenderer` 测试，`LocalGemmaTests.swift` 增加到 110 个测试函数。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.66 优化聊天记录统一阅读轨道：新增 `ChatTranscriptTrackLayoutPolicy`，保持 ScrollView 全宽，将消息栈在宽屏居中并封顶 920pt；旧气泡内容宽度入口转发到统一策略，测试函数增加到 111。本轮仍没有原生 macOS target，不接真实模型，不下载权重。
v2.67 统一会话侧栏视觉层级：新增 `SessionChipVisualStylePolicy`，竖向选中会话改用低饱和工作台行、主文字色和左侧指示条，横向胶囊保持不变；新增策略与生产渲染测试，测试函数增加到 112。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.68 优化短会话纵向定位：新增 `ChatTranscriptVerticalLayoutPolicy`，空记录顶部对齐，非空短记录靠近 composer 底部，长记录自然滚动；新增纯策略与空/短/溢出生产渲染测试，测试函数增加到 113。首次 GitHub Actions run `30197265713` 因新增测试依赖渲染透明背景和 SwiftUI 私有宿主层级的像素/UIScrollView 断言失败，修复提交 `f192f05` 移除这些实现细节假设后，run `30197762986` 全部通过并由 Agent C 下载结果包验收为 PASS。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.69 增加生成中状态脉冲指示：空文本 assistant 占位改用「正在生成」加 3 个 accent 圆点的专用视图，新增纯值 `GenerationIndicatorStylePolicy` 锁住圆点几何、脉冲参数与 Reduce Motion 静态梯度；Reduce Motion 开启时零动效，运行时切换经 `.task(id:)` 取消旧任务；新增策略与生产渲染测试，测试函数增加到 114。GitHub Actions run `30203118117` 对 commit `cd0c26e` 一次性全部通过并由 Agent C 下载结果包验收为 PASS。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.70 增加 Composer 聚焦光环与发送按钮渐变：新增纯值 `ComposerFocusGlowStylePolicy`，键盘聚焦时 composer 内场描边改 accent 0.55 透明度、1.5pt 线宽并加 10pt 柔和光环，未聚焦保持 `theme.border` 原状；发送/停止圆钮改对角渐变并在可用时加 8pt 光环；零动画、纯静态实现，外壳生成态描边与既有焦点机制不变；新增策略与未聚焦生产渲染测试，测试函数增加到 115。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.71 增强共享 panel 层次：`WorkbenchVisualStylePolicy` 新增主题感知内高光与 contact/ambient 两层背景阴影，9 个既有 `panelStyle` 调用统一生效，不增加卡片嵌套，也不改变 8pt 圆角、14pt padding、1pt hairline、布局、辅助语义或状态流；新增纯策略与生产 modifier 渲染测试，测试函数增加到 116。完整构建与测试仅由 GitHub Actions 执行，本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.72 增加单条消息复制动作：`ChatMessageCopyActionPolicy` 对正文 trim 判空但保留原始 payload，`ChatWorkspace` 将实时生成状态传到最新 assistant 气泡，整个流式生成期间保持复制禁用；`ChatBubble` 增加 44pt 本地剪贴板按钮与持久 checkmark，消息摘要和复制动作分别可达；复用既有 `.copyConfirmation`，不加时间、定时器或状态层写入；新增策略、辅助语义与生产渲染测试，测试函数增加到 117。GitHub Actions run `30324632725` attempt `2` 对 commit `c9228d7` 的 117 项 XCTest、0 failed、iOS/Mac Catalyst build、LogicSmoke 和脚本契约已由 Agent C 下载结果包验收为 PASS；attempt `1` 的既有 composer 焦点时序失败已单独记录。本轮仍没有原生 macOS target，不接真实模型，不下载权重。

v2.73 提升会话侧栏信息密度：新增 `SessionChipSidebarMetadataPolicy` 与 `Equatable` plan，竖向行从 `ChatSession + SessionBarLayout` 只读派生消息数和数组尾部向前的最后一条归一化非空摘要；摘要按 `Character` 最多 40 个字符，空摘要回退消息数，horizontal hidden 保持 title-only 160pt 胶囊。新增 `testSessionChipSidebarMetadataPolicyKeepsVerticalRowsScannable`，覆盖空/空白/多行归一化、数组顺序而非时间戳、不变性、vertical/horizontal plan、40 Character 截断及 240/310pt × 亮/暗主题 × `.large`/`.accessibility3` × 选中/未选中的生产 `ImageRenderer`，仅断言非 nil、宽度和合理高度；测试函数增加到 118。本轮只做轻量检查，完整 iOS/Catalyst build、LogicSmoke、118 项 XCTest 和结果包待本轮 push 后 GitHub Actions 执行并由 Agent C 验收；本轮仍没有原生 macOS target，不接真实模型，不下载权重。
