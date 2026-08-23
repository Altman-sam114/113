# 测试规范

本文指导 Agent A、Agent B、Agent C 和 Agent X 为 `Local Gemma iOS Prototype` 选择本地轻量检查、云端重验证、结果包下载和验收方式。

## 默认策略

- 默认云端重验证，本机只跑轻量检查。
- 只有人工明确说“本机测试”“本地 build”“本地跑探针”“本地 xcodebuild”等，Agent 才把本机完整构建或模拟器验证作为默认路径。
- 文档-only 修改仍可本地跑 `git diff --check`、YAML 解析、`plutil -lint`、目录结构检查等轻量检查，并说明未跑完整 XCTest 的原因。
- Swift / Xcode / UI / 状态流 / workflow 改动完成后，默认 commit 并 push 到 `origin/main`，由 GitHub Actions 运行 build / test。
- 云端失败时，Agent B 根据结果包中的失败摘要、日志路径和 manifest 修复后继续在 `main` 上追加 commit 并 push。
- 本项目当前不允许自动下载模型权重；CI 也不能下载 Gemma 或把提示词发往外部推理服务。
- Agent X 循环中的每一轮仍必须遵守同一验证链：Agent B 本地轻量检查、GitHub Actions artifact、Agent C 下载复判。
- Agent X 不得跳过 Agent C artifact 验收；失败时不能继续下一轮并伪装为已通过。

## Agent X 循环下的验证规则

Agent X 是主控调度层，不是新的测试豁免层。它每次拆出一轮小目标后，验证责任仍然落在 Agent B、GitHub Actions 和 Agent C 的既有链路上。

Agent X 每轮必须确认：

- Agent A 的本轮提示词写清目标、非目标、关键文件、本地轻量检查、CI、artifact 内容和 Agent C 验收要求。
- Agent B 基于最新 `origin/main` 在 `main` 上实现，并记录实际运行的本地轻量检查命令和结果。
- Agent B push 后，GitHub Actions 对最新 commit 生成新的未加密 artifact。
- Agent C 下载的是最新 `origin/main` commit 对应的 run 和 artifact，并核对 manifest、`artifact-name.txt`、JUnit、日志和 `.xcresult` 或等价结果。
- Agent C 不通过时，Agent X 只能退回 Agent B 修复或暂停等待人工确认，不能继续下一轮。
- Agent C 通过但总目标未完成时，Agent X 才能拆下一轮目标。
- Agent X 触发停止条件时必须报告原因，包括同一阻塞连续 3 轮、连续 2 轮无有效 diff、同因 CI 连续失败、权限/密钥/付费服务/人工决策缺失或工作区冲突。

## 固定前缀 / 环境要求

本地如需使用 Xcode，优先使用完整 Xcode 路径，避免 `xcode-select` 指向 Command Line Tools 时导致 SDK 或 Swift module cache 不匹配：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

推荐本地 DerivedData 固定到工作区内：

```sh
-derivedDataPath .build/DerivedDataCodex
```

基础环境：

- Xcode 位于 `/Applications/Xcode.app/Contents/Developer`。
- iOS Simulator SDK 可用。
- 本机完整 XCTest 需要可用模拟器，例如 `iPhone 17`、`iPad Pro` 或本机实际存在的 iOS 模拟器。
- 网络不是业务测试前提；项目当前不允许自动下载模型权重。
- 云端 CI 由 `.github/workflows/ci-results.yml` 负责，触发条件是 `main` push 和 `workflow_dispatch`。

查可用模拟器：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl list devices available
```

当前测试基线：

- `LocalGemmaTests.swift` 当前包含 127 个 `test...` 方法。
- v2.75 新增 `testChipReadinessLayoutPolicyAdaptsToCardWidthAndAccessibilityDynamicType`，锁住 `354pt` 真实 panel 内容宽度边界、普通字号横排、Accessibility Dynamic Type 无条件 stacked、NaN/Infinity/非正宽度回退、纯值 plan、`DeviceOptimizer`/隐私状态不变，以及 `86pt` slot / `66pt` diameter；生产 `ChipReadinessCard` 的 `ImageRenderer` 覆盖亮暗主题、`382pt` 外框（扣除两侧 `14pt` panel padding 后为 `354pt` 内容）、窄外框与 Accessibility 字号 stacked，只断言图像非 nil、宽度误差不超过 1pt、高度合理，不做像素/私有层级/截图断言。测试函数数从 119 增至 120；本地只做轻量检查，完整 iOS/Catalyst build、LogicSmoke、120 项 XCTest 和结果包待本轮 push 后 GitHub Actions 执行。
- v2.76 新增 `testOptimizationToggleTextLayoutPolicySupportsDynamicTypeRows`，锁住共享 `OptimizationToggleTextLayoutPolicy` 的标题/行标题/副标题均为两行、行内 spacing 为 3pt、subtitle lineSpacing 为 2pt、三个多行能力计算属性、44pt 行最小高度、250pt 最小卡片宽度和 510pt 两列边界，并确认重复读取不改变 `DeviceOptimizer` 开关、准备度或隐私摘要。生产 `ImageRenderer` 使用真实 `OptimizationToggleRow` 覆盖 250/510pt、亮暗主题、enabled/disabled 与 `.large`/`.xxxLarge`/`.accessibility3`，比较普通/Accessibility 高度，并用真实 `OptimizationToggleGrid` 覆盖窄单列和宽区域；只断言非 nil、宽度误差不超过 1pt、高度合理，不做像素、私有层级或截图断言。测试函数数从 120 增至 121；本地只做轻量检查，完整 iOS/Catalyst build、LogicSmoke、121 项 XCTest 和结果包待本轮 push 后 GitHub Actions 执行。
- v2.77 新增 `testExportSessionBodyTextLayoutPolicySupportsDynamicTypeReading`，锁住 `ExportSessionBodyTextLayoutPolicy` 的 18pt content padding、3pt body line spacing、`preservesFullText`、语义等宽 Dynamic Type 契约、重复读取不变性、`ExportSessionLayoutPolicy` 的 320/390/834/1200pt 与负数/NaN 回归及导出动作 44pt 目标。生产公开 `ImageRenderer` 直接渲染真实 `ExportSessionView(payload:)`，覆盖亮暗主题、320/390/834/1200pt 与 `.large`/`.xxxLarge`/`.accessibility3`，只断言非 nil、正尺寸和固定 NavigationStack/GeometryReader 测试 viewport 下的非下降高度，不做像素、颜色、截图或私有层级断言。测试函数数从 121 增至 122；本地不运行 XCTest、xcodebuild、Simulator、Catalyst build/run 或视觉截图验收，完整 iOS/Catalyst build、LogicSmoke、122 项 XCTest 和结果包待本轮 push 后 GitHub Actions 执行。
- v2.78 新增 `testModelDetailPanelTextLayoutPolicySupportsDynamicTypeHeadings`，锁住 `ModelDetailPanelTextLayoutPolicy` 的 2 行标题、1pt line spacing、12pt title/content spacing、语义 Dynamic Type 契约和重复读取不变性，回归 `ModelDetailRowTextLayoutPolicy`、详情整体/行级辅助语义、模型部署/文件动作 44pt 目标和 missing/staged/verified -> `LocalRuntimePlanner` 门禁。生产公开 `ImageRenderer` 直接渲染真实 `ModelParametersPanel`、`ModelPerformancePanel`、`ModelAdvicePanel`，覆盖亮暗主题、320/390/834/1200pt 与 `.large`/`.xxxLarge`/`.accessibility3`，只断言非 nil、正尺寸和普通/Accessibility 非下降高度，不做像素、颜色、截图或私有层级断言。测试函数数从 122 增至 123；初始云端 run `31301323743` 中该新增测试 Passed，但既有 composer 焦点测试暴露 `.task` 跨活动态时序失败。修复后该测试以真实 first responder 锁住同步聚焦、隐藏页待处理 request 清除和重新激活聚焦；云端 run `32626428418` 的结构化 XCTest 为 123/123，LogicSmoke、iOS/Catalyst build 和结果包验收均通过。本地不运行 XCTest、xcodebuild、Simulator、Catalyst build/run 或视觉截图验收。
- v2.79 新增 `testModelArtifactUtilityTextLayoutPolicySupportsDynamicTypeLabels`，锁住 utility label 的 `titleLineLimit=2`、`titleLineSpacing=1`、`verticalPadding=10`、语义字体、多行/自然垂直增长和至少 44pt 高度；回归 `ModelArtifactActionLayoutPolicy` 的 scan/import 映射、utility 辅助 identifier/hint/input labels、missing/staged/verified -> `LocalRuntimePlanner` 门禁。生产公开 `ImageRenderer` 直接渲染真实 `ArtifactActionPanel`，覆盖 320/390/834/1200pt、亮暗主题和 `.large`/`.xxxLarge`/`.accessibility3`，每个组合只断言非 nil 和正尺寸，不做像素、颜色、截图、私有层级或不稳定高度结论。测试函数数从 123 增至 124；run `32629203461` 的结构化 XCTest 为 124/124，LogicSmoke、iOS/Catalyst build、JUnit、manifest 和三份 `.xcresult` 均由 Agent C 核验通过。本地不运行 XCTest、xcodebuild、Simulator、Catalyst build/run 或视觉截图验收。
- v2.80 新增 `testSettingsPreferenceRowLayoutPolicyAdaptsWallpaperPanelToNarrowWidths`，锁住共享 `SettingsPreferenceRowLayoutPolicy` 的 `58pt` preview、`88pt` 文案最小宽度、两个 `44pt` 动作、`270pt` panel content width 阈值、外框扣除两侧 `14pt` padding、`.large`/`.xxxLarge`/`.accessibility3` 模式、NaN/Infinity/非正宽度回退、壁纸动作禁用策略和既有辅助 metadata。生产公开 `ImageRenderer` 直接渲染真实 `WallpaperPreferencePanel`，覆盖 256/320/354/760pt 外框、亮暗主题、Dynamic Type、空/有效壁纸和导入中状态，断言外框宽度有限且准确、所有组合正尺寸，并要求 Accessibility stacked 高度高于普通字号横排基线；不做像素、颜色、私有层级或 PhotosPicker 内部树断言。测试函数数从 124 增至 125；云端 run `32635938755` 的 125 个 XCTest case 全部 passed，LogicSmoke、iOS/Catalyst build、JUnit、manifest 和三份 `.xcresult` 均由 Agent C 核验通过。本地仅执行轻量检查，未运行完整本地 build/test。
- v2.81 新增 `testModelDetailRowLayoutPolicyAdaptsNarrowWidths`，锁住 `84pt` 标题列、`264pt` 数值列、既有 `12pt` 间距派生的 `360pt` 阈值、panel 外框扣除两侧 `14pt` padding、阈值前后 mode、`.large`/`.xxxLarge`/`.accessibility3`/`.accessibility5`、NaN/Infinity/负数/零回退和重复读取稳定性；横排生产 `DetailRow` 实际把两列最小 frame 应用于 title/value，测试使用长标题和长值回归该路径。回归既有详情行文字、整体/行级辅助语义、44pt 外部动作及 missing/staged/verified runtime 门禁。生产公开 `ImageRenderer` 覆盖真实 `DetailRow`、参数/性能/建议面板、`ModelDetailColumn` 与 `ModelLibraryView` 的 390/820/1280pt 调用链，覆盖详情矩阵 256/320/390/834/1200pt × 亮暗主题 × 四档 Dynamic Type，只断言有限正尺寸和 Dynamic Type 高度不下降，不做像素、颜色、私有层级或截图断言。测试函数数从 125 增至 126；修复 commit `a15303a` 的 run `32639086179` 已通过 126/126 XCTest、LogicSmoke、iOS/Catalyst build、JUnit、manifest 和三份 `.xcresult` 结构核验。本地仅执行轻量检查，未运行完整本地 build/test。
- v2.82 新增唯一 `testComposerInputTextLayoutPolicySupportsDynamicType`，锁住无状态 `ComposerInputTextLayoutPolicy` 的语义 Dynamic Type 字体、`1...4` 行、`0pt` line spacing、`12pt` vertical padding、自然垂直增长和重复读取稳定性，并回归 `ComposerBarLayoutPolicy` 的 `18/12/320/760pt` 外部宽度、输入框/发送/停止辅助 identifier 与本地边界、Command+Return、`48pt` action / `44pt` 最小触控目标、focus lifecycle、Reduce Motion 及 missing/staged/verified runtime 门禁。测试使用公开 `ImageRenderer` 渲染真实生产 `ComposerBar`，完整覆盖 `320/390/834/1200pt` × 亮暗主题 × `.large`/`.xxxLarge`/`.accessibility3`/`.accessibility5` × send/stop，并包含空、空白和足以换行的中英混合 prompt；每个组合只断言图像非 nil、宽高 finite 且为正、固定 width 误差不超过 1pt，同宽度比较时 accessibility 高度不低于 `.large`，不做像素、颜色、截图、私有宿主/辅助树或 first-responder 树断言。测试函数数从 126 增至 127；云端 run `32642793034` attempt `1` 对应 commit `bacf05e`，`127/127` XCTest、static/LogicSmoke/iOS build/Catalyst build/run-script 全部 success；JUnit 为 `tests=7`、`failures=0`、`skipped=1`，唯一 optional skip 原因为 `not-added-in-v1.0-cli-entrypoint-only`；artifact `localgemma-ci-v2.82-main-bacf05e-run32642793034-attempt1` 的 API digest 为 `sha256:b409136ab36aa8e7fe15734f3bc7704172e8808d72d6dd4923428221fcbae28b`，三份 `.xcresult` 均为 version 3.58 且 Data/refs 配对，包内无模型权重、tokenizer、截图或视频。本文档更新会触发新 Actions run，该 run 需要后续重新下载验收，不能预写为通过；本轮未运行本地 XCTest、xcodebuild、Simulator、Mac Catalyst build/run 或 ImageRenderer。
- v2.60 新增 `testChatWorkspacePaneLayoutPolicyCoordinatesGlobalAndSessionSidebars`，以真实根窗口先扣除 `WorkspaceLayoutMode` 全局侧栏，再验证聊天 pane：860pt 以下堆叠，分栏时会话栏保持 240...310pt、聊天面至少 620pt，并覆盖无效宽度、阈值和宽度守恒。
- v2.61 新增 `testAppMotionAccessibilityPolicyRespectsReduceMotion`，锁住五类 motion effect 的完整覆盖与互斥分类：普通模式全部保留动画，Reduce Motion 下工作区导航、聊天记录自动滚动和模型切换返回 `nil`，主题切换与复制确认保留 0.12 秒局部反馈。
- v2.62 新增 `testWorkspaceRootLayoutPolicyResolvesChromeAndAxisAtBoundaries`，锁住 699.99/700/979.99/980pt、iPad 尺寸、负值、NaN、Infinity 下的根布局 mode、axis、chrome 与精确侧栏 clamp；`testWorkspaceRootShellPreservesStatefulContentAcrossLayoutPlans` 将生产 `WorkspaceRootShell` 和稳定 `SessionCommandFocusModifier` 挂入 `UIHostingController`/`UIWindow`，在断点及聊天 active/inactive 往返时验证同一 `@State` UUID 持续存在、仅 appear 一次且中途不 disappear。现有 command/focus 测试同时锁住只有活动聊天页的 focused route 包装包含会话 actions。
- v2.63 新增 `testWorkspacePagesInteractionPolicyExposesOnlySelectedPage`，锁住每种 selection 恰有一个 opacity 1、可命中、启用、辅助可达且 z-index 1 的页面，并逐页锁住隐藏值为 0/false/true；`testWorkspacePagesShellPreservesEveryPageAcrossExplicitNavigation` 将生产 `WorkspacePagesShell` 与四个独立 `@State` UUID 挂入 `UIHostingController`/`UIWindow`，多轮 `.chat -> .models -> .prompts -> .settings` 往返时验证四页各只 appear 一次、中途不 disappear、token 不变、完整 selection 序列一致且 `isEnabled` 只对当前页为 true。既有 composer focus 测试挂载生产 `ComposerBar`，通过 first-responder 探针验证活动聊天页同步聚焦并消费 request、隐藏聊天页即使存在待处理 request 也同时清空 request 与焦点、重新激活后可再次聚焦；不得用任意延时或放宽断言替代生命周期契约。
- v2.64 新增 `testModelCapsuleLayoutPolicyAdaptsToNarrowChrome`，锁住 chrome 18pt、胶囊 12pt、两列/三列最小指标宽度 108/132pt、248pt/436pt 精确阈值、portrait 1/2/3 列、sidebar 最多 2 列、`.xxxLarge` 及以上单列和 NaN/Infinity/负值回退；测试还用生产 `ImageRenderer` 在 214/291.68/354/394pt 与 `.xxxLarge`/Accessibility 文字下渲染 `ModelCapsule`，并验证 54pt readiness ring 的真实图像尺寸。
- v2.65 新增 `testChatBubbleTextLayoutPolicySupportsAccessibleReading`，锁住角色/元数据两行、正文语义字体完整增长、普通字号 40/24pt reserve、8pt 相邻间距与角色比例、Accessibility Dynamic Type 零 reserve、零间距和真实宽度、520/680/600pt 最大阅读宽度、NaN/Infinity/负值回退，并用生产 `ImageRenderer` 覆盖 user/assistant/system/生成占位、320/620pt 与 `.large`、`.xxxLarge`、Accessibility 字号，同时比较同宽度普通/Accessibility 渲染高度。
- v2.66 新增 `testChatTranscriptTrackLayoutPolicyCentersWideConversations`，锁住 18pt 单侧边距、280pt 最小宽度、920pt 最大轨道、956pt 精确封顶阈值、390/620/834/900/1220pt 容器、非法宽度回退及 user/assistant/system 角色最大宽度。
- v2.67 新增 `testSessionChipVisualStylePolicyAlignsWideSidebarHierarchy`，锁住竖向会话行 8pt 圆角、3pt 指示条、8pt inset、1pt 描边、低饱和选中表面与非反色文字，验证未选中和横向胶囊计划，并用生产 `ImageRenderer` 覆盖 240/310pt、亮/暗主题及 Accessibility Dynamic Type。
- v2.68 新增 `testChatTranscriptVerticalLayoutPolicyAnchorsShortConversations`，锁住 10pt 上下 padding、空记录顶部对齐、任意非空短记录底部对齐、无 1 至 3 条消息阈值及无效高度归零；生产 `ImageRenderer` 覆盖 620x500 空记录、920x800 Accessibility 短记录和 1220x1000 溢出记录及亮/暗主题。失败 run `30197265713` 证明依赖渲染透明背景和 SwiftUI 私有宿主层级的像素/UIScrollView 断言不稳定，修复提交 `f192f05` 移除这些实现细节假设，继续由纯策略断言锁住定位契约；重验证 run `30197762986` 的 113 项 XCTest、0 failed 已由 Agent C 下载结果包验收为 PASS。
- v2.69 新增 `testGenerationIndicatorStylePolicyPulsesOnlyWithoutReduceMotion`，锁住生成占位圆点 `dotCount=3`、5pt 直径、4pt 间距、0.35/1.0 min/max opacity、0.9 秒脉冲、0.15 秒逐点相位延迟、`isAnimated(reduceMotion:)` 真值表和静态梯度 0.35/0.65/1.0 严格单调递增且首尾等于 min/max；生产 `ImageRenderer` 渲染空文本 assistant 气泡覆盖 280/680pt 可用宽度 × 亮/暗主题 × `.large`/`.accessibility3`，只断言图像非 nil、宽度 accuracy 1、高度大于 0 且小于 3000pt 上限。禁止像素透明度/颜色采样和 `UIScrollView`/SwiftUI 私有宿主层级探查断言——v2.68 首次 run `30197265713` 已证明这类实现细节断言在 CI 渲染环境不稳定。run `30203118117` 的 114 项 XCTest、0 failed 已由 Agent C 下载结果包验收为 PASS，新测试通过且只出现一次。
- v2.70 新增 `testComposerFocusGlowStylePolicyHighlightsKeyboardFocus`，锁住 `ComposerFocusGlowStylePolicy` 全部纯值契约：聚焦描边 accent 0.55 透明度、1.5/1pt 线宽、10pt 聚焦光环半径、8pt 发送光环半径、`glowOpacity` 四值表（聚焦暗 0.35 / 聚焦亮 0.20 / 未聚焦一律 0）、`sendGlowOpacity` 四值表（可用暗 0.45 / 可用亮 0.28 / 禁用一律 0）、发送渐变端点 1.0/0.78、停止渐变端点 0.9/0.7、`usesAccentBorder` 布尔分支与单调性；生产 `ImageRenderer` 渲染真实 `ComposerBar` 只覆盖未聚焦外观（360/680pt 宽度 × 亮/暗主题 × 发送/停止态，`isChatActive: false`、`focusRequest: .initial`），因为 `@FocusState` 无法从外部注入且 `ImageRenderer` 无 window，聚焦态样式契约由纯值断言锁住；只断言图像非 nil、宽度 accuracy 1、高度大于 0 且小于 3000pt。继续禁止像素透明度/颜色采样和 `UIScrollView`/SwiftUI 私有宿主层级探查断言（v2.68 首次 run `30197265713` 教训）。测试函数数从 114 增至 115，以本轮 push 后的最新 run 和 Agent C 结果包验收为准。
- v2.71 新增 `testWorkbenchPanelDepthStylePolicyAddsThemeAwareElevation`，锁住共享 panel 的 0.5pt 内高光、contact 阴影 1.5pt radius/1pt y、ambient 阴影 8pt radius/3pt y，以及亮暗主题 opacity、contact 大于 ambient、暗色阴影强于亮色和亮色内高光强于暗色；继续锁住 8pt 圆角、14pt padding 与 1pt hairline。生产 `ImageRenderer` 经公开 `panelStyle` 渲染真实共享 modifier，覆盖 360/920pt × 亮/暗主题，只断言非 nil、宽度和合理高度；禁止像素颜色/透明度采样与私有层级探查。测试函数数从 115 增至 116，以本轮 push 后的最新 run 和 Agent C 结果包验收为准。
- v2.72 新增 `testChatMessageCopyActionPolicyPreservesLocalPayloadAndAccessibility`，锁住 user/assistant/system 非空且非生成正文可复制，空、空格、Tab、换行与混合空白不可复制，非空 assistant 在显式流式生成期间仍不可复制，trim 只判空而 payload 保留首尾空白和首尾换行、44pt 动作、可复制/已复制/生成中状态、剪贴板本地边界、稳定 Voice Control 输入标签，以及消息摘要与复制动作 identifier 相互独立；确认 `AppMotionEffect` 仍为 5 个并复用 `.copyConfirmation`。生产 `ImageRenderer` 覆盖 280/680pt × 亮/暗主题 × `.large`/`.xxxLarge`/`.accessibility3` × 可复制/生成占位，只断言非 nil、宽度和合理高度；禁止直接读写系统剪贴板、像素采样和私有层级探查。测试函数数从 116 增至 117。GitHub Actions run `30324632725` attempt `2` 对 commit `c9228d7` 的 117 项 XCTest、0 failed 已由 Agent C 下载结果包验收为 PASS；attempt `1` 的既有 composer 焦点时序失败不作为最终证据。
- v2.73 新增 `testSessionChipSidebarMetadataPolicyKeepsVerticalRowsScannable`，锁住空消息/空白尾消息的消息数回退、多行和连续 whitespace/Tab/换行归一化、按数组顺序而非 timestamp 选择尾部向前最后一条非空正文、完整 `ChatSession`/messages 不变性、vertical 可见与 horizontal hidden plan、40 Character 截断和 `SessionChip` title-only 横向分支。生产 `ImageRenderer` 使用真实 `SessionChip` 覆盖 240/310pt × 亮/暗主题 × `.large`/`.accessibility3` × selected/unselected，竖向 session 含多行摘要，且只断言 image 非 nil、宽度误差不超过 1pt、高度大于 0 和合理上限；禁止像素、颜色/alpha、私有层级、截图快照、剪贴板或时间排序断言。测试函数数从 117 增至 118；完整 iOS/Catalyst build、LogicSmoke、118 项 XCTest 和结果包待本轮 push 后 GitHub Actions 执行并由 Agent C 验收。
- v2.74 新增 `testSessionChipHoverStylePolicyRestrictsPointerFeedback`，锁住 vertical/horizontal、selected/unselected、hovered/non-hovered 八种组合，亮/暗主题 0.06/0.10 opacity 且低于既有选中表面，保持 5 个 `AppMotionEffect` case；生产 `ImageRenderer` 覆盖竖向 240/310pt、亮/暗主题、`.large`/`.accessibility3`、选中/未选中与 hover 初始状态，并覆盖横向 220pt hover sentinel，只断言图像非 nil、宽度误差不超过 1pt、高度合理，不做像素 alpha 或私有层级断言。真实 Mac Catalyst/iPad pointer enter/exit 仍需手工验证；测试函数数从 118 增至 119，完整 iOS/Catalyst build、LogicSmoke、119 项 XCTest 和结果包待本轮 push 后 GitHub Actions 执行并由 Agent C 验收。
- 业务核心覆盖 artifact、模型状态、runtime plan、模拟/真实占位 runtime、提示词、会话、导出、composer 聚焦光环与发送按钮渐变、生成中状态脉冲指示、iPhone/iPad/Mac Catalyst 桌面窗口布局断点、工作台导航与共享 panel 视觉层级策略、模型页整体宽屏内容宽度策略、模型页内部宽屏布局策略、模型详情右栏最大阅读宽度策略、顶部模型胶囊整体辅助语义、模型概要面板辅助语义、模型详情右栏与行级辅助语义、模型文件工作流面板辅助语义、模型文件操作 44pt 触控目标、模型部署控件 44pt 触控目标、模型卸载确认弹层状态流与辅助语义、模型状态徽章辅助语义、会话 chip 动作语义、会话 chip 选择/删除 44pt 触控目标、聊天消息气泡与聊天记录容器辅助语义、聊天气泡宽屏宽度策略、composer 宽屏输入宽度策略、composer 发送/停止 44pt 触控目标、模型选择器辅助语义、模型部署控件辅助语义、运行策略开关辅助语义、运行策略开关宽屏网格、运行策略开关行 44pt 触控目标、芯片准备度辅助语义与隐私状态动态摘要、优化指标卡辅助语义、优化指标卡文本动态排版策略、优化指标网格宽度策略、全局 Header 图标动作 44pt 触控目标、Header 标题动态排版策略、设置页整体宽屏内容宽度策略、共享 SectionHeader 动态排版策略、提示词页整体宽屏内容宽度策略、提示词模板宽屏布局策略、提示词模板文本动态排版策略、提示词分类筛选换行布局策略、提示词分类文本动态排版策略、提示词模板动作 44pt 触控目标、工作区导航辅助语义、工作区导航 44pt 触控目标、头部主题与模型工作区入口辅助语义、设置页图标动作 44pt 触控目标、会话栏操作辅助语义、会话栏操作 44pt 触控目标、导出弹层分享/复制辅助语义、导出弹层分享/复制 44pt 触控目标、导出弹层整体宽屏内容宽度策略、壁纸控件辅助语义、会话侧栏宽度策略、工作区快捷键映射、工作区 command menu 映射、会话 command menu focused route、regular 侧栏说明、选择语义、composer 输入焦点、控件标识与辅助语义、提示词分类筛选辅助语义、提示词模板动作辅助语义、壁纸处理和分享兜底。

统计测试数量：

```sh
grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift
```

## 本地轻量检查

### 1. 文档 / workflow 静态检查

触发条件：

- 文档-only 修改。
- GitHub Actions workflow 修改。
- Xcode 工程文件未改业务逻辑但需要语法确认。
- iPhone/iPad target family、Mac Catalyst build/run 入口、build setting 或布局文档同步。

命令：

```sh
git diff --check
find md -maxdepth 4 -type f | sort
grep -n "Agent A\\|Agent B\\|Agent C\\|README\\|测试规范" AGENTS.md
grep -c "func test" LocalGemmaTests/LocalGemmaTests.swift
rg -n "SessionChipSidebarMetadataPolicy|SessionChipSidebarMetadata|timestamp|sorted|SessionBarLayout|testSessionChipSidebarMetadataPolicyKeepsVerticalRowsScannable" LocalGemma/ContentView.swift LocalGemmaTests/LocalGemmaTests.swift
plutil -lint LocalGemma.xcodeproj/project.pbxproj
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
test -f script/build_and_run.sh
test -x script/build_and_run.sh
bash -n script/build_and_run.sh
```

当前基线：

- `git diff --check` 无输出且退出码为 0。
- `plutil` 输出 `OK`。
- Ruby YAML 解析输出 `yaml ok`。
- Mac Catalyst run script 必须存在、可执行，并通过 `bash -n`。

### 2. Probe / Fast

最快发现主链路断点。

触发条件：

- 文档-only 之外的任意轻量逻辑改动。
- 修改 `AppState.swift` 中纯逻辑。
- 修改提示词模板、会话标题、导出文本、artifact validation 小逻辑。

命令：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -module-cache-path .build/SwiftSmokeModuleCache \
  LocalGemma/AppState.swift Tools/LogicSmoke.swift \
  -o .build/logic-smoke

.build/logic-smoke
```

当前基线：

- 期望输出：`Logic smoke passed`。
- 如命令因 SDK 或沙箱失败，记录具体错误，并改由云端 CI 重验证。

v2.62 定向模拟器验证已在 iPhone 17 Pro 上通过上述两个新增 XCTest，结果位于 `.build/DerivedData-v262-identity/Logs/Test/Test-LocalGemma-2026.07.26_13-06-26-+0800.xcresult`；该 host probe 只证明生产 shell/content 与稳定 focused route modifier 的结构身份，不等同于 Mac 触控板分页、完整 VoiceOver、系统 presentation 或真实窗口拖拽人工验证。

v2.63 定向与完整模拟器验证已在 iPad Pro 13-inch (M5) 上通过，最终 108 项结果位于 `.build/DerivedData-v263-pages/Logs/Test/Test-LocalGemma-2026.07.26_14-10-19-+0800.xcresult`；host probe 证明页面呈现策略、四页结构身份和隐藏页 `isEnabled` 状态，生产 composer probe 锁住聚焦、消费后保持、隐藏释放与重新聚焦生命周期，但仍不等同于 Mac 触控板、完整 VoiceOver、系统 presentation 或真实窗口拖拽人工验证。

## 云端重验证

### 触发方式

Agent B 完成本地轻量检查后，在 `main` 上提交并推送：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short --branch
git add 相关文件
git commit -m "vX.Y: 简要说明本轮做了什么"
git push origin main
```

`.github/workflows/ci-results.yml` 在以下条件触发：

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:
```

### CI 覆盖范围

当前 workflow 目标：

- `git diff --check`
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`
- Ruby YAML 解析 workflow
- Probe / Fast 逻辑烟测
- `xcodebuild build-for-testing`
- Mac Catalyst `xcodebuild build-for-testing`
- Mac Catalyst 本地 run 入口静态契约：`script/build_and_run.sh` 存在、可执行、`bash -n` 通过
- 可选 Codex Run environment 检查：存在 `.codex/environments/environment.toml` 时必须指向 `./script/build_and_run.sh`，不存在时记录 skipped reason
- 自动选择可用 iPhone Simulator 后执行 `xcodebuild test-without-building`
- 生成 `ci-artifact-manifest.json`
- 生成 `artifact-name.txt`
- 生成 `ci-failure-summary.md`
- 生成 `junit.xml`
- 上传 `.xcresult`、`xcodebuild.log`、`test.log`、`mac-catalyst-build.log`、`mac-catalyst-run-script.log`、`mac-baseline-notes.md`、`logic-smoke.log`、`static-checks.log`、`environment.log` 和 manifest

云端 DerivedData 使用 `.derivedData-ci`，不同于本地推荐的 `.build/DerivedDataCodex`。这是 CI 内部缓存路径差异，不改变工程行为。

当前 `junit.xml` 的 `LocalGemmaCI` suite 包含 7 个 CI testcase：静态检查、LogicSmoke、iOS build-for-testing、XCTest、Mac Catalyst build-for-testing、Mac Catalyst run script contract 和可选 Codex Run environment。v1.0 未提交 Codex Run action 时，Codex Run environment testcase 允许 `skipped`，但必须有非空 skipped reason；其它 required testcase 必须为 `success`。

### 结果包内容

GitHub Actions 上传未加密 artifact，版本号从最新 commit 主题的第一个 `vX.Y` token 提取。命名格式：

```text
localgemma-ci-<commit_version>-main-<short_sha>-run<run_id>-attempt<run_attempt>
```

最低内容：

- `ci-artifact-manifest.json`
- `artifact-name.txt`
- `ci-failure-summary.md`
- `junit.xml`
- `environment.log`
- `xcodebuild.log`
- `test.log`
- `logic-smoke.log`
- `static-checks.log`
- `LocalGemma-build.xcresult`
- `LocalGemma-tests.xcresult`，如果模拟器 XCTest 实际运行
- `mac-catalyst-build.log`
- `mac-catalyst-run-script.log`
- `mac-baseline-notes.md`
- `LocalGemma-maccatalyst-build.xcresult`

`ci-artifact-manifest.json` 至少包含：

```json
{
  "artifactName": "localgemma-ci-vX.Y-main-abcdef0-run123-attempt1",
  "version": "vX.Y",
  "repository": "owner/repo",
  "branch": "main",
  "commitSha": "...",
  "shortSha": "...",
  "commitSubject": "vX.Y: 简要说明本轮做了什么",
  "runUrl": "https://github.com/owner/repo/actions/runs/123",
  "runId": "...",
  "runAttempt": "...",
  "workflowName": "Local Gemma CI Results",
  "createdAt": "...",
  "projectName": "Local Gemma iOS Prototype",
  "scheme": "LocalGemma",
  "destination": "...",
  "resultBundlePath": "ci-results/LocalGemma-build.xcresult",
  "testResultBundlePath": "ci-results/LocalGemma-tests.xcresult",
  "junitPath": "ci-results/junit.xml",
  "buildLogPath": "ci-results/xcodebuild.log",
  "testLogPath": "ci-results/test.log",
  "failureSummaryPath": "ci-results/ci-failure-summary.md",
  "staticChecksOutcome": "success/failure",
  "logicSmokeOutcome": "success/failure",
  "buildOutcome": "success/failure",
  "testOutcome": "success/failure/skipped",
  "macBaselineKind": "mac-catalyst",
  "macCatalystBuildOutcome": "success/failure/skipped",
  "macCatalystDestination": "generic/platform=macOS,variant=Mac Catalyst",
  "macCatalystBuildLogPath": "ci-results/mac-catalyst-build.log",
  "macCatalystResultBundlePath": "ci-results/LocalGemma-maccatalyst-build.xcresult",
  "macCatalystSkippedReason": "",
  "macDesignedForIPadOutcome": "skipped",
  "macBaselineNotesPath": "ci-results/mac-baseline-notes.md",
  "macCatalystRunEntrypoint": "script/build_and_run.sh",
  "macCatalystRunScriptCheckOutcome": "success/failure/skipped",
  "macCatalystRunScriptLogPath": "ci-results/mac-catalyst-run-script.log",
  "codexRunEnvironmentPath": ".codex/environments/environment.toml",
  "codexRunEnvironmentCheckOutcome": "success/failure/skipped",
  "codexRunEnvironmentSkippedReason": "not-added-in-v1.0-cli-entrypoint-only",
  "projectSpecificReports": [
    "ci-results/logic-smoke.log",
    "ci-results/static-checks.log",
    "ci-results/environment.log",
    "ci-results/mac-catalyst-build.log",
    "ci-results/mac-baseline-notes.md",
    "ci-results/mac-catalyst-run-script.log"
  ]
}
```

## 测试数据与下载容量限制

本项目默认采用小数据量验证策略，避免下载过大 artifact、模型、数据集、缓存或结果包，把本机、CI runner 或临时目录容量撑爆。

规则：

- 测试数据必须尽量小，只覆盖必要边界。
- CI artifact 只上传必要文件：manifest、artifact 名称、JUnit 或测试摘要、关键日志、失败摘要、必要结果包。
- 不上传大体积 DerivedData、完整 build cache、无关截图、视频、模型文件、历史 artifact 或重复压缩包。
- Agent C 下载 artifact 前优先确认只下载最新 run 对应的必要结果包。
- 下载缓存默认放在 `/private/tmp/localgemma-c-review-<run_id>/`；其它项目可使用 `/private/tmp/<project>-review-<run_id>/`。
- 下载后应检查目录大小：

```sh
du -sh /private/tmp/localgemma-c-review-<run_id>/
```

- 禁止使用非 `Altman-sam114` 的 GitHub 账号伪装完成 push、CI 或 artifact 验收。
- 禁止默认下载大体积测试数据、模型、历史 artifact 或无关产物。

## Agent C 结果包下载与核对

Agent C 验收前必须确认本地和远端：

```sh
git fetch origin
git rev-parse main
git rev-parse origin/main
gh run list --workflow ci-results.yml --branch main --limit 5
```

如果仓库是私有或 artifact 受权限控制，先登录：

```sh
gh auth login
```

下载缓存默认放在：

```text
/private/tmp/localgemma-c-review-<run_id>/
```

下载命令示例：

```sh
mkdir -p /private/tmp/localgemma-c-review-<run_id>
gh run download <run_id> \
  --dir /private/tmp/localgemma-c-review-<run_id>
```

下载后检查目录大小：

```sh
du -sh /private/tmp/localgemma-c-review-<run_id>/
```

Agent C 必须核对：

- `ci-artifact-manifest.json` 的 `branch` 是 `main`。
- `commitSha` 等于 `origin/main` 最新 commit。
- `artifactName` 等于 `artifact-name.txt` 的内容，也等于本次下载的 artifact 名称。
- `repository`、`commitSubject`、`runUrl` 能定位到本次 `origin/main` 提交和 GitHub Actions run。
- `runId` 和 `runAttempt` 等于本次下载的 GitHub Actions run。
- `staticChecksOutcome`、`logicSmokeOutcome`、`buildOutcome`、`testOutcome`、`macCatalystBuildOutcome` 与 GitHub Actions UI 和日志一致。
- `macBaselineKind` 是 `mac-catalyst`，`macCatalystDestination` 指向 Mac Catalyst，`mac-catalyst-build.log` 和 `LocalGemma-maccatalyst-build.xcresult` 存在。
- `macCatalystRunEntrypoint` 是 `script/build_and_run.sh`，`macCatalystRunScriptCheckOutcome` 是 `success`，`mac-catalyst-run-script.log` 存在且记录文件存在性、可执行权限和 `bash -n` 检查。
- 如果 `codexRunEnvironmentCheckOutcome` 是 `success`，则 `.codex/environments/environment.toml` 必须存在且 Run command 指向 `./script/build_and_run.sh`。
- 如果 `codexRunEnvironmentCheckOutcome` 是 `skipped`，则 `codexRunEnvironmentSkippedReason` 必须非空；v1.0 当前未提交 `.codex/environments/environment.toml` 的原因是当前 Codex 沙箱下项目内 `.codex` 路径不可写，manifest 记录为 `not-added-in-v1.0-cli-entrypoint-only`。
- `mac-baseline-notes.md` 明确这是 Mac Catalyst build-for-testing 基线，不是原生 macOS target，不改变模拟 runtime 边界。
- `junit.xml` 的失败数与 `ci-failure-summary.md` 一致。
- `xcodebuild.log`、`test.log`、Mac Catalyst log、`.xcresult` 或等价结果存在且可打开。
- 如果 test 被 `skipped`，必须有明确原因，例如 runner 没有可用 iPhone Simulator。

Agent C 不自动删除 `/private/tmp/localgemma-c-review-<run_id>/`，除非人工明确同意。

## 人工明确要求时的本机完整验证

### Smoke

验证主要集成路径能编译。

触发条件：

- 人工要求本地 build。
- 修改任意 Swift 源码后需要本机快速确认。
- 修改 Xcode 工程配置或新增 Swift 文件。

命令：

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

当前基线：

- 期望结果：`TEST BUILD SUCCEEDED`。

### Stage Regression

覆盖当前阶段核心模块。

触发条件：

- 人工要求本地模拟器 XCTest。
- 云端 CI 不可用但需要本地替代验证。
- 修改 artifact 文件管理、SHA-256、模型部署状态、卸载确认、确认后删除、取消路径或模型部署停止行为。
- 修改 `InferenceEngine` 会话、流式生成、导出。
- 修改提示词模板行为。
- 修改 iPhone 横屏 / iPad 大屏 / Mac Catalyst 桌面窗口布局、模型页整体内容宽度策略、模型页内部布局策略、模型详情右栏最大阅读宽度策略、顶部模型胶囊整体辅助语义、模型概要面板辅助语义、模型详情右栏与行级辅助语义、模型文件工作流面板辅助语义、模型文件操作触控目标、模型部署控件触控目标、模型卸载确认弹层辅助语义、模型状态徽章辅助语义、会话 chip 动作语义、会话 chip 选择/删除触控目标、聊天消息气泡与聊天记录容器辅助语义、聊天气泡宽屏宽度策略、composer 宽屏输入宽度策略、composer 发送/停止触控目标、模型选择器辅助语义、模型部署控件辅助语义、运行策略开关辅助语义、运行策略开关宽屏网格、运行策略开关行触控目标、芯片准备度辅助语义、优化指标卡辅助语义、优化指标卡文本动态排版策略、优化指标网格宽度策略、全局 Header 图标动作 44pt 触控目标、Header 标题动态排版策略、设置页整体宽屏内容宽度策略、共享 SectionHeader 动态排版策略、提示词页整体宽屏内容宽度策略、提示词模板宽屏布局策略、提示词模板文本动态排版策略、提示词分类筛选换行布局策略、提示词分类文本动态排版策略、提示词模板动作 44pt 触控目标、工作区导航辅助语义、工作区导航触控目标、头部主题与模型工作区入口辅助语义、设置页图标动作 44pt 触控目标、会话栏操作辅助语义、会话栏操作触控目标、导出弹层分享/复制辅助语义、导出弹层分享/复制触控目标、导出弹层整体宽屏内容宽度策略、壁纸控件辅助语义、会话侧栏宽度策略、键盘快捷键、工作区 command menu、会话 command menu、regular 侧栏说明、选择语义、composer 输入焦点/控件辅助语义、提示词分类筛选辅助语义、提示词模板动作辅助语义、壁纸、分享兜底。

命令：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/DerivedDataCodex \
  CODE_SIGNING_ALLOWED=NO \
  test-without-building
```

如果 `iPhone 17` 不存在，先运行 `xcrun simctl list devices available`，选择本机可用 iPhone 模拟器。

当前基线：

- 期望结果：`TEST EXECUTE SUCCEEDED`。
- 当前测试函数数：129（v2.84 Agent B implementation baseline；云端待触发）。

### v2.83 / 顶部模型胶囊部署状态与徽章可读性

新增聚合 `testModelCapsuleDeploymentStateAndBadgeReadability`，实现前后测试函数数以源码实际 `grep` 为准，本轮实现后为 `128`。测试不复制部署状态，直接使用 `ModelCatalog` 验证默认 stopped、启动目标 running、启动另一个模型停止前一个、toggle 回 stopped；`ModelCapsuleAccessibilityMetadata` 对 stopped/running 都必须包含明确 deployment 文案，并继续保留本地 privacy/verified hint、稳定整体 identifier 和输入标签。

纯值 contract 覆盖 `ModelStatusBadgeStylePolicy` 的 install/artifact/deployment/runtime 全部语义 case 与 `.light`/`.dark` 主题角色，stopped 必须使用主题 `primaryText`/`chipSurface`/`border`，不依赖白色前景；`ModelStatusBadgeTextLayoutPolicy` 锁住语义 Dynamic Type、两行上限、1pt line spacing、6/3pt padding。`ModelStatusBadgeRowLayoutPolicy` 锁住 `220pt` 普通字号 horizontal 阈值、invalid width stacked、`.xxxLarge`/`.accessibility3`/`.accessibility5` stacked；`ModelStatusBadgeAccessibilityPresentationPolicy` 锁住 capsule=false、selector=true。顶部 `ModelCapsule` 的 `.combine` 整体摘要隐藏 deployment badge 独立节点，模型 selector 继续让三枚 badge 独立可达；既有模型 selector、电源按钮 44pt、Reduce Motion、missing/staged/verified runtime gate 回归保持。

同一聚合测试用公开 `ImageRenderer` 渲染真实生产 `ModelCapsule` 与 `ModelSelectorPanel` 组合，覆盖 `320/390/834/1200pt` × `.light`/`.dark` × `.large`/`.xxxLarge`/`.accessibility3`/`.accessibility5` × deployment `.stopped`/`.running` × artifact `.missing`/`.staged`/`.verified` × install `.ready`/`.simulated`/`.notDownloaded`。每项只检查 image 非空、宽高 finite 且大于 0、wrapper width 误差不超过 1pt；同一组合的 `.accessibility5` 高度严格 `>=` `.large`，不加 rounding 宽限。禁止像素/颜色采样、截图快照、私有 SwiftUI accessibility tree、UIKit first responder 或把 ImageRenderer 当作完整 VoiceOver/pointer 人工验收。

本轮未运行本地完整 `xcodebuild`、XCTest、Simulator、Mac Catalyst build/run 或截图视觉检查；轻量检查后由 `main` push 触发 GitHub Actions，云端证据如下。

#### v2.83 Agent C 云端验收记录

- run `32646623292` attempt `1` 为 `main` push，head SHA `42b83058bb7a22d353e793e0ac536d02c3ef9fa1`，subject 为 `v2.83: 修复 badge Dynamic Type 测试类型推断`，workflow 为 `Local Gemma CI Results`，conclusion=`success`。唯一 artifact `localgemma-ci-v2.83-main-42b8305-run32646623292-attempt1`（ID `9495147147`，size `91,923,262` bytes）的 API digest 与下载 zip SHA-256 均为 `sha256:a9e6ddba4c94334d86b1eba9a96cae4f3b9e968d692c602e6bf42b9cb3daa4a3`；`artifact-name.txt`、manifest 和 run identity/attempt/head SHA/subject/workflow 完全一致。
- static、LogicSmoke、iOS build-for-testing、XCTest、Mac Catalyst build-for-testing、Mac Catalyst run-script contract required outcomes 全部为 `success`。JUnit 可解析，`tests=7`、`failures=0`、`errors=0`；唯一 optional skip 是 `codexRunEnvironment`，原因为 `not-added-in-v1.0-cli-entrypoint-only`。
- test.log 有 `128` 条测试记录且 `128` passed、`0` failed；`LocalGemma-tests.xcresult` 的结构化 tests 结果为 `128` test cases / `128` passed / `0` failed / `0` skipped。新增 `testModelCapsuleDeploymentStateAndBadgeReadability()` 在 test.log 与结构化 tests 树中各恰好一次且为 Passed。生产 ImageRenderer 证据来自真实 `ModelCapsule` + `ModelSelectorPanel`，覆盖 `320/390/834/1200pt`、light/dark、`.large`/`.xxxLarge`/`.accessibility3`/`.accessibility5`、deployment stopped/running、artifact missing/staged/verified 和 install ready/simulated/notDownloaded 全组合；纯值断言覆盖 badge style/text/row/accessibility policy，并回归 44pt、Reduce Motion、runtime/verified 门禁。
- build、Mac Catalyst build、tests 三份 `.xcresult` 的 Info.plist 均通过 lint、版本均为 `3.58`、rootId 对应 root data/refs；Data/refs hash 集合分别 `3/3`、`3/3`、`954/954` 完全匹配。Mac baseline notes 明确这是既有 iOS target 的 Catalyst build-for-testing，工程提交中没有原生 macOS target；artifact 无模型权重、tokenizer、截图或视频，除 `.xcresult` 外的非结果文件最大为 `202,794` bytes。
- 日志末尾存在一条非致命 Simulator launch 诊断，但它出现在 `** TEST EXECUTE SUCCEEDED **` 之后，不产生失败测试；Agent C 只读取 GitHub API 和已下载结果包，未运行本地 Xcode/build/test。验收临时目录使用 `trash` 清理。

### v2.84 / 模型概要标签与校验摘要动态排版

新增唯一聚合 `testModelSummaryPanelTextLayoutPolicySupportsDynamicTypeAndThemeSurface`，源码测试函数数从 `128` 增至 `129`。纯值 contract 锁住能力标签 semantic Dynamic Type font、2 行上限、1pt line spacing、9/6pt padding、自然垂直增长，校验摘要 semantic Dynamic Type font、3 行上限、1pt line spacing、自然垂直增长，以及名称/简介既有 5/2/4/2 契约；重复读取稳定，主题角色锁住 `chipSurface`、`secondaryText`、`subtleBorder`，不使用 `.white.opacity(0.08)`。

同一测试直接渲染真实生产 `ModelSummaryPanel(model:validation:)`，不构造脱离生产的替代文本树；公开 `ImageRenderer` 矩阵覆盖 `320/390/834/1200pt` × light/dark × `.large`/`.xxxLarge`/`.accessibility3`/`.accessibility5` × validator 生成的 missing/staged/verified。长中英混合模型名、简介、能力标签和 manifest 文件名覆盖窄宽压力，另覆盖 `capabilities=[]`；每项只断言图像非 nil、宽高 finite 且为正、wrapper 宽度误差不超过 1pt，并比较 `.accessibility5 >= .large` 高度，不做像素/颜色/截图/私有辅助树断言。

聚合测试回归 `ModelSummaryAccessibilityMetadata` 的整体 label/value/hint/input labels/identifier 和空能力值、模型部署/文件 utility/workspace/header/session/composer 44pt policy、`AppMotionEffect`/Reduce Motion，以及 missing/staged/verified 到 `LocalRuntimePlanner` 的真实 runtime gate。能力标签继续走 `FlowLayout` adaptive minimum `72pt`/8pt 间距；未新增宽度断点、AnyLayout、动作、状态、网络或模型文件。

本轮未运行本地完整 `xcodebuild`、XCTest、Simulator、Mac Catalyst build/run 或截图验收；已执行 `git diff --check`、129 个测试函数计数、`rg` 结构检查、`plutil -lint`、Ruby YAML 解析、脚本存在性/可执行性/`bash -n` 和两份 `xcrun swiftc -parse`，均成功（YAML 仅有既有 PATH world-writable warning）。完整 iOS/Catalyst build、LogicSmoke、129 项 XCTest、JUnit、manifest 和三份 `.xcresult` 待本轮 push 后 GitHub Actions，再由 Agent C 下载最新结果包核对。

### Full

全量测试和人工可视检查。

触发条件：

- 人工明确要求本机完整验证。
- 改动 App 启动、导航根结构、Xcode target、Info.plist、权限、iPad 支持或主布局断点。
- 接入真实 runtime 或更改模型隐私边界。
- 发布前或重要里程碑。

命令：

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

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/DerivedDataCodex \
  CODE_SIGNING_ALLOWED=NO \
  test-without-building
```

可视检查：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl install booted .build/DerivedDataCodex/Build/Products/Debug-iphonesimulator/LocalGemma.app

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl launch booted com.localgemma.prototype

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl io booted screenshot .build/localgemma-check.png
```

当前基线：

- App 能安装和启动。
- 首屏非空，推理页展示模型胶囊、会话栏、消息和输入框。
- iPhone 横屏与 iPad 大屏布局由 `WorkspaceLayoutMode` 测试锁住，工作区侧栏文本动态排版由 `WorkspaceSidebarTextLayoutPolicy` 测试锁住，模型页整体宽屏内容宽度由 `ModelLibraryWorkspaceLayoutPolicy` 测试锁住，模型页内部宽屏/窄屏回退由 `ModelLibraryLayoutMode` 测试锁住，模型详情右栏最大阅读宽度由 `ModelDetailColumnLayoutPolicy` 测试锁住，模型详情面板标题动态排版由 `ModelDetailPanelTextLayoutPolicy` 测试锁住，模型详情行文本动态排版由 `ModelDetailRowTextLayoutPolicy` 测试锁住，模型概要标题文本动态排版由 `ModelSummaryTextLayoutPolicy` 测试锁住，模型文件操作触控目标由 `ModelArtifactActionLayoutPolicy` 测试锁住，模型文件动作按钮文本动态排版由 `ModelArtifactActionTextLayoutPolicy` 测试锁住，模型部署电源按钮文本动态排版由 `ModelDeploymentPowerTextLayoutPolicy` 测试锁住，模型选择器文本动态排版由 `ModelSelectorTextLayoutPolicy` 测试锁住，会话 chip 选择/删除触控目标由 `SessionChipActionLayoutPolicy` 测试锁住，会话 chip 标题文本动态排版由 `SessionChipTextLayoutPolicy` 测试锁住，导出弹层分享/复制触控目标由 `ExportSessionActionLayoutPolicy` 测试锁住，导出弹层整体宽屏内容宽度由 `ExportSessionLayoutPolicy` 测试锁住，导出弹层标题文本动态排版由 `ExportSessionTitleTextLayoutPolicy` 测试锁住，全局 Header 图标动作触控目标由 `HeaderActionLayoutPolicy` 测试锁住，Header 标题动态排版由 `HeaderTitleTextLayoutPolicy` 测试锁住，模型胶囊文本动态排版由 `ModelCapsuleTextLayoutPolicy` 测试锁住，设置页整体宽屏内容宽度由 `SettingsWorkspaceLayoutPolicy` 测试锁住，设置页图标动作触控目标由 `SettingsIconActionLayoutPolicy` 测试锁住，设置偏好行文本动态排版由 `SettingsPreferenceTextLayoutPolicy` 测试锁住，会话栏操作触控目标由 `SessionBarActionLayoutPolicy` 测试锁住，运行策略开关行触控目标由 `OptimizationToggleRowLayoutPolicy` 测试锁住，运行策略开关文本动态排版由 `OptimizationToggleTextLayoutPolicy` 测试锁住，composer 发送/停止触控目标由 `ComposerInputActionLayoutPolicy` 测试锁住，共享 SectionHeader 动态排版由 `SectionHeaderTextLayoutPolicy` 测试锁住，优化指标卡文本动态排版由 `OptimizerMetricTextLayoutPolicy` 测试锁住，提示词页整体宽屏内容宽度由 `PromptTemplatesWorkspaceLayoutPolicy` 测试锁住，提示词分类筛选换行由 `PromptCategoryLayoutPolicy` 测试锁住，提示词分类文本动态排版由 `PromptCategoryTextLayoutPolicy` 测试锁住，提示词模板文本动态排版由 `PromptTemplateTextLayoutPolicy` 测试锁住；如能截图，应人工确认侧栏、工作区、会话 chip 选择/删除入口、导出弹层摘要/Markdown 预览/底部分享复制整体宽度、导出弹层底部分享/复制按钮和 toolbar 分享入口、模型文件扫描/导入按钮、全局 Header 主题/模型工作区图标动作、顶部 Header eyebrow/主标题在窄 split view 和较大文字设置下不压缩、不截断、composer 发送/停止按钮、设置页标题/外观/壁纸/芯片策略整体宽度、设置页主题/壁纸图标动作、设置偏好行标题/状态文本、运行策略开关行、会话栏操作按钮、共享 SectionHeader 标题/副标题、优化指标卡 label/value/detail、提示词页标题/分类/模板整体宽度、提示词筛选 chip 和模板卡片文本无遮挡。

- v2.64 截图检查还必须确认 iPhone top header、iPad/Mac regular sidebar 与 compact sidebar 中模型名、安装/SIM 徽章、readiness ring、状态摘要和 1/2 列指标均不重叠、不越界；`.xxxLarge` 及以上 Dynamic Type 下指标应回退单列。截图只能作为策略/XCTest 之外的视觉证据，不能替代完整测试。

## 规则

- 每次实现前先读本文件。
- 不得伪造测试结果。
- 不得把云端未触发写成云端通过。
- Agent X 不得跳过 Agent C 下载和 artifact 验收。
- Agent X 不得在失败、旧 artifact 或同因 CI 连续失败时继续下一轮并伪装成功。
- 新增或修改测试后，必须同步更新本文件当前基线和 README 验证章节。
- 失败测试不能只记录为“环境问题”；必须写清楚失败命令、错误摘要和替代验证。
- 如果没有 `origin`、没有 push 权限或没有 GitHub Actions 权限，必须明确写为云端验证阻塞。
- 禁止默认下载大体积测试数据、模型、历史 artifact 或无关产物。
