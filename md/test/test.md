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

- `LocalGemmaTests.swift` 当前包含 119 个 `test...` 方法。
- v2.60 新增 `testChatWorkspacePaneLayoutPolicyCoordinatesGlobalAndSessionSidebars`，以真实根窗口先扣除 `WorkspaceLayoutMode` 全局侧栏，再验证聊天 pane：860pt 以下堆叠，分栏时会话栏保持 240...310pt、聊天面至少 620pt，并覆盖无效宽度、阈值和宽度守恒。
- v2.61 新增 `testAppMotionAccessibilityPolicyRespectsReduceMotion`，锁住五类 motion effect 的完整覆盖与互斥分类：普通模式全部保留动画，Reduce Motion 下工作区导航、聊天记录自动滚动和模型切换返回 `nil`，主题切换与复制确认保留 0.12 秒局部反馈。
- v2.62 新增 `testWorkspaceRootLayoutPolicyResolvesChromeAndAxisAtBoundaries`，锁住 699.99/700/979.99/980pt、iPad 尺寸、负值、NaN、Infinity 下的根布局 mode、axis、chrome 与精确侧栏 clamp；`testWorkspaceRootShellPreservesStatefulContentAcrossLayoutPlans` 将生产 `WorkspaceRootShell` 和稳定 `SessionCommandFocusModifier` 挂入 `UIHostingController`/`UIWindow`，在断点及聊天 active/inactive 往返时验证同一 `@State` UUID 持续存在、仅 appear 一次且中途不 disappear。现有 command/focus 测试同时锁住只有活动聊天页的 focused route 包装包含会话 actions。
- v2.63 新增 `testWorkspacePagesInteractionPolicyExposesOnlySelectedPage`，锁住每种 selection 恰有一个 opacity 1、可命中、启用、辅助可达且 z-index 1 的页面，并逐页锁住隐藏值为 0/false/true；`testWorkspacePagesShellPreservesEveryPageAcrossExplicitNavigation` 将生产 `WorkspacePagesShell` 与四个独立 `@State` UUID 挂入 `UIHostingController`/`UIWindow`，多轮 `.chat -> .models -> .prompts -> .settings` 往返时验证四页各只 appear 一次、中途不 disappear、token 不变、完整 selection 序列一致且 `isEnabled` 只对当前页为 true。既有 composer focus 测试再挂载生产 `ComposerBar`，通过 first-responder 探针验证 request 聚焦并消费后保持、隐藏聊天页释放、重新激活后可再次聚焦。
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
- 当前测试函数数：119。

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
- iPhone 横屏与 iPad 大屏布局由 `WorkspaceLayoutMode` 测试锁住，工作区侧栏文本动态排版由 `WorkspaceSidebarTextLayoutPolicy` 测试锁住，模型页整体宽屏内容宽度由 `ModelLibraryWorkspaceLayoutPolicy` 测试锁住，模型页内部宽屏/窄屏回退由 `ModelLibraryLayoutMode` 测试锁住，模型详情右栏最大阅读宽度由 `ModelDetailColumnLayoutPolicy` 测试锁住，模型详情行文本动态排版由 `ModelDetailRowTextLayoutPolicy` 测试锁住，模型概要标题文本动态排版由 `ModelSummaryTextLayoutPolicy` 测试锁住，模型文件操作触控目标由 `ModelArtifactActionLayoutPolicy` 测试锁住，模型文件动作按钮文本动态排版由 `ModelArtifactActionTextLayoutPolicy` 测试锁住，模型部署电源按钮文本动态排版由 `ModelDeploymentPowerTextLayoutPolicy` 测试锁住，模型选择器文本动态排版由 `ModelSelectorTextLayoutPolicy` 测试锁住，会话 chip 选择/删除触控目标由 `SessionChipActionLayoutPolicy` 测试锁住，会话 chip 标题文本动态排版由 `SessionChipTextLayoutPolicy` 测试锁住，导出弹层分享/复制触控目标由 `ExportSessionActionLayoutPolicy` 测试锁住，导出弹层整体宽屏内容宽度由 `ExportSessionLayoutPolicy` 测试锁住，导出弹层标题文本动态排版由 `ExportSessionTitleTextLayoutPolicy` 测试锁住，全局 Header 图标动作触控目标由 `HeaderActionLayoutPolicy` 测试锁住，Header 标题动态排版由 `HeaderTitleTextLayoutPolicy` 测试锁住，模型胶囊文本动态排版由 `ModelCapsuleTextLayoutPolicy` 测试锁住，设置页整体宽屏内容宽度由 `SettingsWorkspaceLayoutPolicy` 测试锁住，设置页图标动作触控目标由 `SettingsIconActionLayoutPolicy` 测试锁住，设置偏好行文本动态排版由 `SettingsPreferenceTextLayoutPolicy` 测试锁住，会话栏操作触控目标由 `SessionBarActionLayoutPolicy` 测试锁住，运行策略开关行触控目标由 `OptimizationToggleRowLayoutPolicy` 测试锁住，composer 发送/停止触控目标由 `ComposerInputActionLayoutPolicy` 测试锁住，共享 SectionHeader 动态排版由 `SectionHeaderTextLayoutPolicy` 测试锁住，优化指标卡文本动态排版由 `OptimizerMetricTextLayoutPolicy` 测试锁住，提示词页整体宽屏内容宽度由 `PromptTemplatesWorkspaceLayoutPolicy` 测试锁住，提示词分类筛选换行由 `PromptCategoryLayoutPolicy` 测试锁住，提示词分类文本动态排版由 `PromptCategoryTextLayoutPolicy` 测试锁住，提示词模板文本动态排版由 `PromptTemplateTextLayoutPolicy` 测试锁住；如能截图，应人工确认侧栏、工作区、会话 chip 选择/删除入口、导出弹层摘要/Markdown 预览/底部分享复制整体宽度、导出弹层底部分享/复制按钮和 toolbar 分享入口、模型文件扫描/导入按钮、全局 Header 主题/模型工作区图标动作、顶部 Header eyebrow/主标题在窄 split view 和较大文字设置下不压缩、不截断、composer 发送/停止按钮、设置页标题/外观/壁纸/芯片策略整体宽度、设置页主题/壁纸图标动作、设置偏好行标题/状态文本、运行策略开关行、会话栏操作按钮、共享 SectionHeader 标题/副标题、优化指标卡 label/value/detail、提示词页标题/分类/模板整体宽度、提示词筛选 chip 和模板卡片文本无遮挡。

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
