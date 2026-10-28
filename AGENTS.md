# AGENTS.md

## 当前 v3.10 会话恢复与手机历史

继续单Agent串行实施/审查/提交/云端复判，不开子智能体，AITRANS只读，所有Swift/Xcode/Simulator/UIKit/Vision执行仅云端。入口基线`f347619944b3bf97d9adc652a051c52be2b31646` / run`40638042855` attempt1已核对157/157、12个Python夹具、38图、JUnit10、4份xcresult与unsigned资源；它不自动覆盖本轮新代码。

生产App显式注入`LocalConversationStore.shared`，默认无注入的测试/预览仍为memory-only。版本化JSON保存原始会话/消息ID、时间、正文、当前选择和分会话草稿，不保存或恢复生成任务/真实runtime状态。私有actor执行读取/校验/编码/原子写，单有序写循环合并输入/流式快照；恢复期间禁止编辑与会话动作，避免初始seed覆盖磁盘。读取失败/未知版本保护原文件，只能明确确认后先备份再修复；写失败保留最新内存快照，显式重试，不截断正文。退后台停止本轮生成并请求有限后台flush，不冒称强杀/断电耐久已验收。

手机历史改为48pt搜索行、标题/短正文、当前标记和独立44pt删除确认，不再复用桌面SessionChip堆叠模拟seed摘要。只搜本机标题/真实对话正文，预览排除seed/system且不修改保存正文。正常保存无提示卡；仅恢复或错误显示一行状态。历史dismiss后原同步focus路由、四页身份、composer 48pt、文件事务、默认模拟runtime和verified gate保持。

源码169个唯一XCTest，保留原157名称与严格focus/identity；新增12项会话归档/文件保护/恢复/草稿/写失败/搜索/手机尺寸与真实磁盘恢复图。原38图不减，新增亮暗×large/accessibility3的4张320×640历史宿主图，总42图/26宿主/5份provenance，OCR同时要求“会话记录”和“部署讨论”。仍保留12个Python夹具、JUnit10、4份完整xcresult与unsigned Release资源。待本轮精确SHA自身云端全量结果及看图，不预写通过或发布就绪；历史图不是完整Simulator或真机，真实runtime、崩溃/断电、真机/完整辅助技术与签名发布仍独立门禁。

## v3.9.1 代码验收基线

`ee3a211607eb30b601acfe4a42d20aca7fb97889` / run`40635105796` attempt1完整包已下载并独立核对ZIP SHA-256 `3ba25c333828d07e69adc4a835bda3d41b7525012e90ad0a8c88a9b59a4cccc7`：157唯一Success、0 XCTest skip，严格focus2.972s，JUnit10/0失败/1 optional skip，4份xcresult根succeeded且Data/refs配对（3、3、3、908）。12个Python夹具、Swift6 LogicSmoke、iOS/Catalyst/unsigned Release及实际资源成功。38图已看：新增亮暗导入中320×640图逐张原尺寸打开，原36通过无裁切联系表复看，20宿主PNG与基线逐字节相同，16模拟器正文在排除状态栏后像素相同，无新遮挡/缺页；宿主图不是全屏Simulator、真机或完整辅助技术证据。完整包/图/独立记录在`/private/tmp/localgemma-c-review-40635105796/`。

此结论只绑定上述代码SHA，不自动覆盖后续文档提交；后续main仍须自身新run核对。仅本轮导入事务与UI回归通过，整体目标继续；崩溃/断电耐久、遗留候选回收、会话恢复、真实runtime、真机/完整辅助技术与签名发布尚未完成。继续单Agent、云端执行，AITRANS只读。

## v3.9.1 云端并发边界修复

v3.9 `5b44803` / run`40633857029` attempt1完整失败包已核对：Swift6拒绝MainActor裸FileManager跨actor，iOS/Catalyst/Release编译失败、XCTest未运行、无有效新截图，不能称157项或事务已通过。v3.9.1用受锁封装`ArtifactFileAccess`限制FileManager完整操作借用，不给Foundation全局补Sendable、不降Swift检查。LogicSmoke显式Swift6；截图在已知构建失败/无可执行文件时立即写失败manifest，不再反复安装无效App，必选视觉仍失败而非skip/通过。新增4个Python静态夹具，合计12个；157 Swift/38图/4份provenance/4份xcresult/JUnit10不减，新SHA仍须自身云端验收。其余v3.9边界保持。

## 当前 v3.9 后台事务导入边界

继续单Agent按模块推进，不开子智能体，AITRANS只读，所有Swift/构建/运行/图像仅云端。已核对基线`a525a8a` / run`40629860257` attempt1完整包：147/147、JUnit10、4份xcresult及unsigned Release资源成功；交接36图已复核，无新遮挡/缺页。这不是整产品发布验收。

承接入口已有AppState中文件存储段的未提交抽离，将`ModelArtifactStore`/hasher与新后台worker集中在`ArtifactImport.swift`并注册target/LogicSmoke。Files导入在私有同卷候选目录中分块复制，校验成功后以一次`renamex_np`交换整代目录；其他模型通过硬链接快照保留，不先删旧文件，不接受失败swap后的删除式fallback。取消与commit共用锁门：提交前接受取消必保留旧代，提交后拒绝取消且UI禁用该入口；真实SHA不匹配是导入失败，placeholder仍仅staged。普通失败/取消清理候选，原Files源不删除。

Catalog在MainActor只发布状态，复制/hash/启动扫描/手动扫描/卸载均交串行actor。导入期间仅互斥文件操作，四页/模型选择仍可切换，完成只更新原目标不抢选中态；生产同步focus/runtime/verified不改。模型页只新增一行进度与44pt取消，较大文字自然增长，不加阻塞层或冗长说明。

源码157项，原147名称/严格focus与identity保留；新增10项覆盖原子替换、hash/read/commit失败、取消阶段/提交边界、路径/重名/软链接、后台响应/目标身份、取消状态不变及手机尺寸。云端保留原36图，新增2张真实后台导入暂停期间的320×640宿主图，总38图/22宿主PNG/4份provenance；仍是宿主组合，不冒充Simulator或真机。新SHA自身完整结果包、图片与4份xcresult须验收，不预写通过。会话重启恢复、崩溃/断电耐久与遗留候选回收、真实runtime、真机/完整辅助技术、签名分发仍单列门禁。

## 当前 v3.8 执行与发布基础边界

用户最新要求取消 A/B/C 串行角色流程，随后又要求后续不再多开子智能体。现有子智能体已全部停止；由同一 Agent 按界面、文件可靠性、发布资源、测试模块串行推进并统一提交，不再新建或续派子智能体。下文历史多 Agent/角色前置要求不再作为执行门槛。必要的代码审查、最新 SHA 云端结果包核对和看图不能省略。AITRANS 继续只读，所有 Swift/Xcode/Simulator/UIKit/Vision 执行仍只在云端。

v3.7 `f0b5fd4` / run `40624916743` attempt1 实际为146/147成功：三项新手机布局测试、iOS/Catalyst、36图与OCR导出成功，唯一严格composer焦点回归失败。原始控制台先观察到真实UITextInput responder=true，随后键盘XPC中断且第二次等待时失焦；不能写成整个版本通过，也不能据此断言生产从未聚焦。

v3.8 保持147个Swift测试与生产同步focus不变，测试宿主改为与生产一致的NavigationStack、底部composer和页面级safeAreaInset；条件已满足时同步采样，否则保留2秒有界等待，增加editing/消费事件日志，首次/隐藏/重入真实responder断言不减。云端使用明确模拟器UDID和单测试worker，避免额外克隆与键盘环境竞争，不重试或skip测试。

新增自有静态矢量风格AppIcon、28个iPhone/iPad/Catalyst/marketing槽位、无alpha PNG和生成源。Assets与PrivacyInfo进入App资源阶段，Debug/Release均指定AppIcon，bundle ID/team不变。隐私清单只声明实际AppStorage/UserDefaults使用理由CA92.1，无跟踪/离设备收集；size-only文件元数据不虚报时间戳或容量用途。新增云端未签名Release iPhoneOS构建、第4份xcresult、最终.app资源/Info.plist/arm64/隐私校验和unsigned app zip。原8阶段不减，JUnit增至10；验证器另有8项纯Python静态/小夹具回归。未签名device包不是可安装分发包或上架验收。

导入替换非事务/大文件MainActor阻塞、会话重启恢复、真实runtime、真机/完整辅助技术与签名分发仍是后续门禁。本轮不偷改AppState或放宽verified；不得把发布资源检查或UI截图通过写成整个目标已完成。

本文是本项目的入口记忆、总览、基本规则和多 Agent 云端迭代工作流。后续任何 Codex / Agent 进入项目后，先读本文，再读项目核心文档和相关源码。

## 当前 v3.7 手机呈现与协作边界

用户于 2026-10-28 明确允许多 Agent 并行加速，覆盖下文历史单 Agent 条款；按文件所有权分工，只有 root 集成负责人提交/push，A 设计、B 实施、C 精确云端结果包验收仍不可省略。AITRANS 只读参考，不修改。当前版本仍是本地模拟 runtime，UI 质量目标不等于真实推理或签名发布已经完成。

compact 根 chrome 使用零高、无命中且辅助隐藏的占位，根同序两节点和唯一四页 shell 保持；聊天自带模型摘要/历史/新建/更多单行头，主题与导出位于更多菜单，`.xxxLarge` 以上同一头部布局堆叠。非聊天页不再重复全局模型栏，手机公共标题去英文 eyebrow 与副文。摘要复用 `CompactModelSummarySheet`；离开聊天同步关闭摘要、历史和导出并清 pending history focus，原 composer request/active 同步生命周期与 48pt 按钮不变。底栏只改变浮动圆角托盘与小面积选中图标呈现，56pt 导航项和原四入口/快捷键/Reduce Motion 路由保持。

手机欢迎标记缩至 76pt，Files panel 去重复标题/状态但保留整体 metadata；模型 selector 去双层底板/重复规格，三枚 badge 独立语义保留，部署始终诚实显示模拟预览。模板主区填入与 44pt 独立发送同级，展示短用途而不改完整 prompt；分类最小宽 56pt、横 padding 10pt、44pt 高并真实换行。设置去重复标题/内嵌策略卡，手机壁纸用 40pt 预览、10pt 间距派生 244pt 内容横排阈值；大屏原 58/14/270pt 保留，`.xxxLarge` 以上继续 stacked，同一子树与父级 PhotosPicker 状态不变。设备预算仍明确模拟、非实测。

源码 147 项，保留原 144 项并新增手机头部、设置行、模板行三项回归。16 模拟器图 + 20 宿主图、3 份 provenance、三份完整 xcresult 和 JUnit 8 阶段保留；手机 OCR 必须匹配真实特有正文“想聊点什么 / 导入模型文件 / 部署方案 / 外观模式”，不能仅命中底部导航。v3.6 run `40169024104` 的 143/144 与中文 OCR 失败是历史失败依据，预存语言分轮识别修复承接，不冒称已经通过。v3.7 所有 Swift/运行/截图只在云端，须核对自身新 SHA/run/attempt 的完整产物与人眼复判；真实 runtime、AppIcon/签名发布、真机/完整辅助技术和 Mac GUI/pointer 缺口仍须独立处理。

## v3.6 手机呈现边界（历史）

v3.6 实施时按当时人工要求由单一 Agent 串行执行设计/实现/云端复判；最新协作和呈现以 v3.7 节为准。`CompactWorkbenchPolicy` 复用根 plan 的 `topNavigation`，不新增根断点；`compactWorkbench` 只读环境传给唯一四页 shell，手机使用单行模型栏与底部导航，不再显示旧顶部 tab 或横向会话 chip。编辑时只移除底栏，不重建四页；composer 同步 focus 生命周期、Command+Return、48pt 按钮保持，新增键盘完成和交互式收键盘。

手机会话 sheet 复用 SessionChip 选择/删除，dismiss 后且聊天仍 active 才发原 focus request，不用延时任务。模型摘要 sheet、参数 disclosure、Files 优先的动作与更多菜单仍复用原 metadata/确认/状态层；设备预算收起且标明模拟数据。手机 panel 20pt 圆角、大屏原 8pt 保留；手机去工程网格/重复解释，静态轨道装饰不命中且辅助隐藏，未增加动画。

源码 144 项（原141保留），原16模拟器+12宿主图不减，新增8张320×640pt生产组件组合宿主图，exporter严格要求3份provenance/20宿主PNG与OCR/hash；组合图不是完整模拟器或真机。所有Swift/构建/运行仍只在云端。最新提交自身验收前不写通过或发布就绪；真实runtime、真机/完整辅助技术、Mac GUI/pointer和签名发布缺口不变。下文旧手机呈现细节以本节为准，状态和安全门禁不变。

## 1. 项目一句话总览

`Local Gemma iOS Prototype` 是一个 SwiftUI iOS 原型 App，用本地模拟 runtime 验证 iPhone、iPad 与 Mac Catalyst build/run 基线下端侧部署 Gemma 1.5B 的产品交互、模型文件管理、artifact 校验、模型卸载确认弹层辅助语义、会话导出、导出会话正文动态排版、导出弹层分享/复制辅助语义、导出弹层分享/复制 44pt 触控目标、导出弹层整体宽屏内容宽度策略、大屏双栏布局、聊天工作区双侧栏宽度协调、聊天记录居中阅读轨道、短会话靠近 composer 的纵向定位、Mac/iPad 工作区与会话命令菜单、顶部模型胶囊整体辅助语义、模型概要面板与详情右栏/行级辅助语义、模型概要标签与校验摘要动态排版、取消生成占位生命周期、模型详情面板标题动态排版、模型页整体宽屏内容宽度策略、模型详情右栏最大阅读宽度策略、模型文件工作流面板辅助语义、模型文件 utility 动作动态排版、工作区导航辅助语义、工作区导航 44pt 触控目标、共享 panel 内高光与分层阴影、头部主题与模型库入口辅助语义、全局 Header 图标动作 44pt 触控目标、Header 标题动态排版策略、设置页整体宽屏内容宽度策略、设置页图标动作 44pt 触控目标、设置偏好行响应式布局、会话栏操作辅助语义、会话栏操作 44pt 触控目标、会话 chip 动作语义、会话侧栏视觉层级、会话侧栏信息密度、会话侧栏宽度策略、聊天消息气泡与聊天记录容器辅助语义、单条消息复制与本地反馈、生成中状态脉冲指示、聊天气泡与 composer 宽屏输入宽度策略、composer 聚焦光环与发送按钮渐变、composer 发送/停止 44pt 触控目标、模型选择器、状态徽章与部署控件辅助语义、模型部署控件 44pt 触控目标、运行策略开关辅助语义、运行策略开关宽屏网格、运行策略开关行 44pt 触控目标、芯片准备度辅助语义与隐私状态动态摘要、优化指标卡辅助语义、优化指标卡文本动态排版策略、优化指标网格宽度策略、共享 SectionHeader 动态排版策略、提示词页整体宽屏内容宽度策略、提示词模板宽屏布局策略、提示词模板文本动态排版策略、提示词分类筛选换行布局策略、提示词分类文本动态排版策略、提示词筛选与模板动作辅助语义、提示词模板动作 44pt 触控目标、相册壁纸控件辅助语义和 Apple Silicon 运行计划；当前不下载模型权重，不执行真实模型推理，也没有原生 macOS target。

v2.64 起，顶部模型胶囊还包含窄侧栏响应式布局策略：sidebar 与窄 top header 使用堆叠概要，指标按可用宽度切换 1/2/3 列，`.xxxLarge` 及以上 Dynamic Type 固定回退单列。

v2.74 起，Mac Catalyst/iPad pointer 下的竖向会话侧栏未选中行还包含 `SessionChipHoverStylePolicy` 纯视觉反馈：只在 vertical + 未选中 + hover 同时成立时叠加亮色 0.06、暗色 0.10 的 accent 表面；横向胶囊、选中态、辅助语义、44pt 触控目标、Reduce Motion、会话状态、runtime 与 verified 门禁均不变。

v2.75 起，设置页与优化 dashboard 共用 `ChipReadinessLayoutMode` / `ChipReadinessLayoutPolicy`：panel 内真实内容宽度达到 `354pt` 才允许横排，Accessibility Dynamic Type 和非法宽度始终 stacked；`ReadinessRing` 保留 `86pt` slot 与 `66pt` diameter，语义字体正文可垂直增长，布局通过同一 `AnyLayout` 切换，不改变 `DeviceOptimizer`、隐私摘要、辅助语义、Reduce Motion、runtime 或 verified 门禁。

v2.76 起，设置页与优化 dashboard 共用 `OptimizationToggleTextLayoutPolicy`：运行策略小节标题、行标题和副标题使用 Dynamic Type 语义字体，标题/副标题最多两行并允许垂直增长；保留 44pt 行最小高度、250pt 最小卡片宽度和 510pt 两列边界，不改变 `DeviceOptimizer`、辅助语义、Reduce Motion、runtime 或 verified 门禁。

v2.77 起，`ExportSessionBodyTextLayoutPolicy` 集中定义导出正文 18pt padding、3pt line spacing、完整正文和语义等宽 Dynamic Type 契约；`ExportSessionView` 使用 `.body.monospaced()`，保留原始 Markdown、ScrollView、textSelection、320/760pt `ExportSessionLayoutPolicy` 宽度及既有标题/动作辅助语义和 44pt 目标，不改变本地导出、复制分享、runtime 或 verified 门禁。

v2.78 起，`ModelDetailPanelTextLayoutPolicy` 集中定义模型详情参数、性能和建议面板标题的 2 行上限、1pt line spacing、12pt 标题/内容间距和语义 Dynamic Type 字体；`DetailPanel` 允许标题垂直增长，保留 panel、详情行、整体/行级辅助语义、44pt 动作、模型文件、runtime 与 verified 门禁。

v2.79 起，`ModelArtifactUtilityTextLayoutPolicy` 集中定义模型文件“扫描本地”和“导入文件”utility label 的语义 Dynamic Type 字体、最多两行、1pt line spacing、10pt 垂直 padding、自然垂直增长和不低于 44pt 的最小高度；保留 HStack、panel、动作闭包、独立辅助语义、本地 Files/扫描边界、Reduce Motion、runtime 与 verified 门禁。

v2.80 起，`SettingsWorkspace` 将真实 panel 外框宽度扣除共享 `14pt` padding 后传给 `SettingsPreferenceRowLayoutPolicy`，由 `DynamicTypeSize` 选择横排或 stacked；普通字号只有达到 `270pt` panel content width 明确阈值才横排，`.xxxLarge` 及以上和 NaN/infinity/非正宽度始终 stacked。`WallpaperPreferencePanel` 的 `AnyLayout` 复用同一预览、文案和 PhotosPicker/清除动作子树，stacked 分支在 layout 外自然垂直增长，预览 slot 为 `58pt`，两个动作各保持至少 `44pt`；保留导入中/清除禁用、主题、壁纸数据、既有辅助语义、相册读取、本地压缩、runtime 和 verified 门禁。

v2.81 起，模型详情参数/性能面板的 `DetailRow` 通过 `ModelDetailRowLayoutPolicy` 读取真实 panel content width 和 `DynamicTypeSize`；panel 外框先扣除两侧共享 `14pt` padding，内容宽度低于 `360pt` 或 `.xxxLarge` 及以上始终 stacked，普通字号达到 `84 + 264 + 12 = 360pt` 才横排。横排实际将同一 policy 的 `84pt` 标题列和 `264pt` 数值列作为最小 frame 宽度，保留 12pt 间距和数值尾部对齐；stacked 使用同一标题/数值子树自然垂直增长并让数值前导对齐；无效宽度归一为有限 `0pt`。`ModelDetailColumn`、整体/行级辅助语义、静态 `28pt` 最小行高、外部动作 44pt 目标、模型文件、Reduce Motion、runtime 与 verified 门禁不变。

v2.82 起，`ComposerInputTextLayoutPolicy` 集中定义 composer 输入框的公开语义 Dynamic Type 字体、1...4 行范围、0pt line spacing、12pt vertical padding 和自然垂直增长；`ComposerBar` 只把 policy 契约传给同一 `TextField(axis: .vertical)`，不改变外部 18/12/320/760pt 宽度策略、同步 focus lifecycle、Command+Return、send/stop 48pt/44pt 触控目标、辅助语义、Reduce Motion、local runtime 或 verified 门禁。

## 2. 必读文件顺序

每轮工作开始前按顺序阅读：

1. `AGENTS.md`：入口规则、多 Agent 工作流、禁止项。
2. `update_log.md`：版本记录、历史决策、完成事项、遗留问题。
3. `md/flow/flow.md`：当前真实架构、核心数据流、执行流和云端协作流。
4. `md/flow/flowchart.md`：核心流程 Mermaid 图，给人工快速理解逻辑。
5. `md/test/test.md`：测试分层、云端 CI、结果包和本机轻量校验规则。
6. `README.md`：用户可读说明、运行方式、功能范围和验证记录。
7. `md/prompt/README.md`：Agent A 提示词归档和云端阶段要求。
8. 与任务相关的源码、测试、工程文件和 workflow：通常是 `LocalGemma/AppState.swift`、`LocalGemma/ContentView.swift`、`LocalGemmaTests/LocalGemmaTests.swift`、`Tools/LogicSmoke.swift`、`.github/workflows/ci-results.yml`。

开始工作前必须执行或等价确认：

```sh
git status --short --branch
git log --oneline --decorate -n 12
git branch --all
git remote -v
```

如果工作区已有改动，不要回滚或覆盖。先判断是否是用户或其他 Agent 的改动，再决定如何协作。

## 3. 项目基本规则

- 以当前 worktree、测试结果、核心文档、CI 结果包和实际运行表现为准，不依赖记忆猜测。
- 不自动下载 Gemma 或其他模型权重。
- 不引入云端推理，不把提示词、上下文或会话发送到外部服务。
- 不把 `manual-import-required` 的 artifact 当成真实可运行权重。
- 只有 artifact `verified` 后，才允许真实 runtime 路径暴露为可运行。
- 每次代码变更后，必须同步更新测试、测试规范、核心流程文档、流程图、`README.md` 和必要的 `update_log.md`。
- 文档-only 变更也要说明为什么未跑完整测试，并至少做结构/内容校验。
- 不伪造测试结果；没有跑就写未跑及原因。
- 不做无关重构；大文件拆分必须有清晰收益，并保证 Xcode target 正确。
- 当前人工要求全部 Swift 编译、运行、XCTest、ImageRenderer 和 Catalyst 验证只在云端；本地仅静态轻量检查，不设置 `GITHUB_ACTIONS=true` 冒充云端。将来如人工明确授权本机 iOS 验证，也只能使用已确认完整 UDID 以 `FAC4325D` 开头的唯一模拟器，不按名称或 `booted` 选择、不创建其他设备；云端不受该设备限制。
- 删除文件或目录默认用 `trash <path>`；保留用户和并行 Agent 的改动，不使用 `rm` 清理未经确认的内容。

## 4. 核心架构边界

当前核心边界如下：

- `ModelCatalog` 管模型列表、选中模型、artifact validation、部署状态。
- `ModelArtifactStore` 只处理本地文件扫描、复制和删除，不联网。
- `LocalArtifactValidator` 根据 manifest、文件存在性和 SHA-256 计算 `missing` / `staged` / `verified`。
- `LocalRuntimePlanner` 根据模型和 artifact 状态生成运行计划。
- `InferenceEngine` 管会话、输入、流式输出、导出文本和当前生成指标。
- `SimulatedGemmaRuntime` 是默认推理实现。
- `RealGemmaRuntimePlaceholder` 是真实 runtime 占位，不等于真实模型推理。
- `ContentView` 和各 workspace 负责 UI，不应绕过状态层直接改核心状态。
- `WorkspaceLayoutMode` 按容器尺寸控制单栏、compact 双栏和 regular 大屏双栏；iPhone 横屏、iPad 大屏与 Mac/Catalyst 桌面窗口断点要有测试锁住。
- `WorkspaceRootLayoutPolicy` 将 `WorkspaceLayoutMode` 映射为根布局轴、顶部导航/紧凑侧栏/详细侧栏 chrome 和既有侧栏宽度；它不得建立第二套断点，也不得改变快捷键、导航、辅助语义、模型文件、runtime 或 verified 门禁。
- `WorkspaceRootShell` 使用 `AnyLayout` 在纵向/横向算法间切换，并始终保持 chrome、content 两个同序直接子节点；`ContentView` 在所有尺寸只构造一个共享 `WorkspacePagesShell`，根断点变化不得重建工作区局部状态。
- `WorkspacePagesInteractionPolicy` 和 `WorkspacePagesShell` 用四个固定同序页面槽位隔离工作区分页手势；只有选中页可见、可命中、启用且对辅助技术可达，隐藏页必须禁用命中、控件和辅助访问，同时保持局部状态身份。工作区切换只允许经顶部/侧栏导航、系统菜单、`Command+1...4` 和既有状态路由，不得重新引入 page-style `TabView`、私有 API、透明手势阻断层或全局 `.scrollDisabled`。
- `ComposerBar` 的焦点生命周期更新必须同时受 `ComposerFocusRequest` 和聊天页活动态约束；进入活动聊天页时同步消费 request 并设置 `@FocusState`，离开聊天页时同步清空待处理 request 与 `@FocusState`，不得用延迟异步任务跨越活动态边界，重新进入聊天页继续复用既有 focus request 路由。
- `ComposerInputTextLayoutPolicy` 只管理 composer 输入文字的语义 Dynamic Type、1...4 行、0pt line spacing、12pt vertical padding 和自然垂直增长；它不写回 `InferenceEngine` 或 focus request，不建立宽度断点，不改变 `ComposerBar` 的输入/按钮顺序、Command+Return、send/stop、辅助语义、Reduce Motion、local runtime 或 verified 门禁。
- `ModelLibraryLayoutMode` 控制模型页内部单栏/双栏；Mac/iPad 足够宽的模型部署工作流和窄屏回退要有测试锁住。
- `ModelLibraryWorkspaceLayoutPolicy` 控制模型页整体内容宽度；iPhone 和窄 split view 必须保持原有可用宽度，iPad/Mac 超宽窗口必须让标题、选择/部署/文件操作和模型详情整体居中并限制最大宽度，最大内容宽度要从控制列最大宽度、详情列最大阅读宽度和列间距派生，且不得改变模型选择、部署、模型文件操作、卸载确认、内部双栏、详情列宽度、辅助语义或 verified 门禁。
- `ModelDetailColumnLayoutPolicy` 控制模型页详情右栏在双栏宽屏中的最大阅读宽度；单栏不启用固定详情列宽，iPad/Mac 宽区域使用剩余空间但封顶，避免概要、参数、性能和建议文本行在超宽窗口无限拉长，最小/最大宽度、列间距和无效宽度 clamp 要有测试锁住。
- `WorkspaceNavigationAccessibilityMetadata` 控制顶部工作区 tab 和大屏 sidebar 工作区按钮的辅助语义；它必须复用工作区 label/value、说明 `Command+1...4` 快捷键、包含 regular 侧栏用途说明、暴露 Voice Control 输入标签，并明确只切换本地工作区、不下载权重、不启动真实 runtime。
- `WorkspaceSidebarTextLayoutPolicy` 控制大屏侧栏工作区标题与详细副标题的 Dynamic Type 文本策略；标题与副标题使用语义字体并允许两行，避免 iPad/Mac regular 侧栏和较大文字设置下通过固定小字号或缩放压缩文字，且不得改变 `WorkspaceTab.shortcutKey`、command menu、`selectedTab`、composer focus、导航 44pt 触控目标或辅助语义。
- `WorkbenchVisualStylePolicy` 控制紧凑工作区导航托盘、大屏 sidebar 导航轨道、选中指示器、主题表面和共享 panel 的视觉层级；iPhone、iPad 与 Mac Catalyst 必须复用低饱和选中表面、8pt panel 圆角、14pt padding、1pt 主题感知 hairline，以及只挂在背景上的主题感知内高光、contact/ambient 分层阴影。现有 9 个 `panelStyle` 调用不得新增 panel 内嵌套卡片，静态装饰不得改变布局、快捷键、command menu、`selectedTab`、composer focus、44pt 触控目标、辅助语义、动画、模型文件、runtime 状态或 verified 门禁。
- `AppMotionEffect` 与 `AppMotionAccessibilityPolicy` 控制工作台 10 个显式动画入口的 Reduce Motion 行为；工作区导航、聊天记录自动滚动和模型切换属于大范围空间位移，系统开启“减弱动态效果”时必须立即更新且不播放动画，主题切换与复制确认属于局部反馈，开启时保留 0.12 秒 ease-out。普通模式必须保留各入口原有动画参数，且策略不得改变 `selectedTab`、composer focus、主题状态、剪贴板、模型选择、模型文件、runtime 状态或 verified 门禁。
- `WorkspaceNavigationActionLayoutPolicy` 控制顶部工作区 tab 和大屏 sidebar 工作区按钮的最小触控目标；这些全局导航入口必须保持至少 44pt，且不得改变 `WorkspaceTab.shortcutKey`、工作区 command menu、`selectedTab` 状态流、composer focus 或辅助语义。
- `HeaderActionAccessibilityMetadata` 控制全局头部主题切换、设置页外观主题按钮和打开模型工作区按钮的辅助语义；它必须明确当前主题、切换目标、本地 UI 边界、模型工作区跳转边界、不下载权重、不启动真实 runtime、不发送云端服务和不绕过 verified 门禁。
- `HeaderActionLayoutPolicy` 控制全局 Header 主题切换和打开模型工作区两个图标动作的最小触控目标；这些全局入口必须保持至少 44pt，且不得改变主题切换、工作区切换、模型胶囊状态、辅助语义、模型文件或 runtime 状态流。
- `HeaderTitleTextLayoutPolicy` 控制顶部 Header eyebrow 和主标题的 Dynamic Type 文本策略；eyebrow 使用语义字体并保持单行，主标题使用语义标题字体并允许两行，避免 iPad split view、Mac Catalyst 窄窗口和较大文字设置下压缩或截断，且不得改变 Header 图标动作触控目标、主题切换、工作区切换、模型胶囊状态、辅助语义、模型文件或 runtime 状态流。
- `SettingsWorkspaceLayoutPolicy` 控制设置页整体内容宽度；iPhone 和窄 split view 必须保持原有可用宽度，iPad/Mac 超宽窗口必须让标题、外观、壁纸、芯片准备度、优化指标和运行策略开关整体居中并限制最大宽度，且不得改变主题切换、相册读取、本地压缩、恢复系统背景、optimizer toggle、局部网格策略、图标触控目标或辅助语义。
- v3.5 的 `SettingsSectionsLayoutPolicy` / `SettingsSectionsShell` 在真实 pane 扣除两侧 18pt 后，普通字号内容达到 `320 + 24 + (510 + 28) = 882pt` 才并列偏好与运行计划；整体最大 1104pt，运行列最多 760pt。窄宽和 `.xxxLarge` 以上回退最多 760pt 单栏，同一 AnyLayout 的两个同序节点保留 picker/导入/错误和 optimizer 身份；局部网格只用真实列宽，toggle 先扣 28pt panel padding。
- `SettingsIconActionLayoutPolicy` 控制设置页外观主题切换、相册壁纸选择和恢复系统背景三个图标动作的最小触控目标；这些 iPhone、iPad split view 和 Mac Catalyst 设置入口必须保持至少 44pt，且不得改变主题切换、相册读取、本地压缩、恢复系统背景、禁用状态或辅助语义。
- `SettingsPreferenceTextLayoutPolicy` 控制设置页外观模式与壁纸偏好行标题/状态文本的 Dynamic Type 排版；标题与状态使用语义字体并允许两行，避免 iPad split view、Mac Catalyst 窄窗口和较大文字设置下压缩或截断，且不得改变主题切换、相册读取、本地压缩、恢复系统背景、图标 44pt 触控目标、辅助语义、设置页整体宽度、模型文件或 runtime 状态流。
- `SettingsPreferenceRowLayoutMode`、`SettingsPreferenceRowLayoutPlan` 与 `SettingsPreferenceRowLayoutPolicy` 控制壁纸偏好行的真实 panel content width 响应式布局；调用侧从外框宽度扣除两侧共享 `14pt` panel padding，`270pt` 及以上普通字号横排，窄宽、`.xxxLarge` 及以上 Dynamic Type、NaN/infinity/非正宽度 stacked；`AnyLayout` 保持预览、文案、两个动作的同一生产子树，stacked 内容在 layout 外自然垂直增长，且不得改变 44pt 触控目标、PhotosPicker/清除禁用状态、辅助语义或壁纸状态流。
- `ModelCapsuleTextLayoutPolicy` 控制顶部模型胶囊与 HeaderMetricChip 的 Dynamic Type 文本策略；模型名、状态摘要和指标 chip 使用语义字体并允许多行，避免 iPad split view、Mac Catalyst 窄窗口和较大文字设置下通过固定小字号或缩放压缩文字，且不得改变模型胶囊辅助语义、主题切换、工作区切换、模型文件或 runtime 状态流。
- `ModelCapsuleLayoutPolicy` 控制顶部模型胶囊在 top header、compact sidebar 和 regular sidebar 的响应式结构；它必须使用调用侧传入的真实 chrome 可用宽度，非法宽度和 `.xxxLarge` 及以上 Dynamic Type 回退 stacked + 1 列，portrait 最多 3 列、sidebar 最多 2 列，并锁住 248pt/436pt 阈值、18pt chrome padding、12pt capsule padding、108pt 两列最小宽度、132pt 三列最小宽度和 54pt readiness ring 实际尺寸。它不得改变模型胶囊整体辅助语义、SIM/REAL、artifact、生成状态、主题、工作区、模型文件、runtime 或 verified 门禁。
- `ModelCapsuleAccessibilityMetadata` 控制顶部模型胶囊整体辅助语义；它必须合并当前模型、参数、量化、SIM/REAL、artifact 状态、后端、生成状态、速度、内存和准备度，并明确只展示本地状态、不下载权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `ModelDetailAccessibilityMetadata` 控制模型页详情右栏和窄屏详情段的整体辅助语义；它必须合并模型规格、artifact 状态、validation summary、性能预算、主/回退后端、KV cache、blocker/next step，并明确只展示本地模型详情、不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `ModelSummaryTextLayoutPolicy` 控制模型页概要面板名称、简介、能力标签和 artifact 校验摘要的纯值文本契约；名称保留 5/2/4/2 的既有 spacing/line-limit/line-spacing，能力标签使用 semantic Dynamic Type、最多两行、1pt line spacing、9/6pt padding 和垂直 fixed size，校验摘要使用 semantic Dynamic Type、最多三行、1pt line spacing 和垂直 fixed size。能力标签直接使用 `theme.chipSurface`、`theme.secondaryText` 与 `theme.subtleBorder`，继续经既有 `FlowLayout` adaptive 72pt/8pt wrap；policy 只影响静态排版，不改变概要整体辅助语义、模型选择/部署、模型文件、44pt 外部动作、Reduce Motion、runtime/verified/cloud 边界。
- `ModelSummaryAccessibilityMetadata` 控制模型页概要面板辅助语义；它必须合并模型名称、简介、能力标签、artifact availability、validation summary、文件格式和包体大小，并明确只展示本地模型概要、不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `ModelDeploymentControlAccessibilityMetadata` 控制模型选择器、部署电源和 artifact 操作按钮的辅助语义；模型切换不下载权重、不启动真实 runtime、模拟暂存不联网下载，卸载按钮只打开确认弹层、不立即删除，确认后才删除 App 托管 artifact 并停止部署，取消无副作用，verified 门禁和 Mac/iPad VoiceOver/Voice Control 入口要有测试锁住。
- `ModelDeploymentPowerTextLayoutPolicy` 控制模型部署电源按钮标题与副标题的 Dynamic Type 文本策略；主标题与副标题使用语义字体并允许两行，避免 iPad split view、Mac Catalyst 窄窗口和较大文字设置下通过固定小字号或缩放压缩文字，且不得改变部署启停状态流、电源按钮 44pt 触控目标、辅助语义、模型文件或 verified 门禁。
- `ModelSelectorTextLayoutPolicy` 控制模型选择器选中模型名与规格摘要的 Dynamic Type 文本策略；名称与规格使用语义字体并允许两行，避免 iPad split view、Mac Catalyst 窄窗口和较大文字设置下通过固定小字号或缩放压缩文字，且不得改变模型选择状态流、选择器 44pt 触控目标、部署/文件/runtime 状态或 verified 门禁。
- `ModelDeploymentControlLayoutPolicy` 控制模型选择器和部署电源按钮的最小触控目标；这些 iPhone、iPad 和 Mac Catalyst 模型部署核心入口必须保持至少 44pt，且不得改变模型选择、部署启停、部署控件辅助语义、模型文件、runtime 状态或 verified 门禁。
- `ModelArtifactPanelAccessibilityMetadata` 控制模型页文件工作流面板整体辅助语义；它必须合并 artifact availability、validation summary、模拟暂存、卸载需确认、扫描本地和 Files 手动导入入口，并明确只管理本地模型文件工作流、不联网下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁，同时保留面板内各操作按钮可达。
- `ModelArtifactActionTextLayoutPolicy` 控制模型文件动作按钮标题与副标题的 Dynamic Type 文本策略；标题与副标题使用语义字体并允许两行，避免 iPad split view、Mac Catalyst 窄窗口和较大文字设置下通过固定小字号或缩放压缩文字，且不得改变模拟暂存、卸载确认、扫描/导入、artifact 校验、辅助语义或 verified 门禁。
- `ModelArtifactActionLayoutPolicy` 控制模型页文件工作流面板扫描本地和导入文件两个 utility 动作的最小触控目标；这些 iPhone、iPad 和 Mac Catalyst 模型文件入口必须保持至少 44pt，且不得改变模拟暂存、卸载确认、扫描本地、Files 手动导入、artifact 校验、辅助语义或 verified 门禁。
- `ModelArtifactUtilityTextLayoutPolicy` 控制模型文件扫描/导入 utility label 的纯值 Dynamic Type 排版契约；语义字体、最多两行、1pt line spacing、10pt vertical padding、fixed-size 垂直增长和 minimum height 由生产 `ArtifactActionPanel` 与测试共同读取，不读取状态或环境，也不得改变 utility 动作、44pt 命中高度、辅助语义、本地文件、Reduce Motion、runtime 或 verified 门禁。
- `ModelUninstallConfirmationAccessibilityMetadata` 控制模型卸载确认弹层的辅助语义；它必须明确确认后才删除 App 托管 artifact/tokenizer 并停止部署，取消不会删除文件或停止部署，不删除系统 Files 中的原始文件，不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `ModelStatusBadgeAccessibilityMetadata` 控制模型页安装状态、artifact 状态和部署状态徽章辅助语义；它必须为 `StatusBadge`、`AvailabilityBadge` 和 `DeploymentBadge` 暴露 label/value/hint/input labels/identifier，并明确徽章只展示本地模型状态、不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `ModelDetailRowTextLayoutPolicy` 控制模型详情参数行、性能行和建议行的 Dynamic Type 文本策略；标题/数值/建议使用语义字体并允许多行，避免 iPad/Mac 窄 split view 和较大文字设置下通过固定小字号或缩放压缩文字，且不得改变行级辅助语义、模型详情列宽、模型选择/部署、模型文件或 runtime 状态流。
- `ModelDetailRowLayoutMode`、`ModelDetailRowLayoutPlan` 与 `ModelDetailRowLayoutPolicy` 控制 `DetailRow` 的真实 panel content width 响应式结构；外框扣除两侧共享 `14pt` padding，`84pt` 标题列 + `264pt` 数值列 + 既有 `12pt` 间距派生 `360pt` 阈值，窄宽、`.xxxLarge` 及以上 Dynamic Type、NaN/infinity/非正宽度 stacked，普通字号达到阈值才 horizontal。horizontal 分支实际把 policy 的两列最小宽度传给 title/value frame，`ModelDetailColumn` 将有限 content width 传给参数/性能面板，`AnyLayout` 复用标题/数值文本子树；stacked 允许自然垂直增长、数值前导对齐，不改变静态 `28pt` 行、AdviceRow、整体/行级辅助语义、外部 44pt 动作、模型文件、Reduce Motion、runtime 或 verified 门禁。
- `ModelDetailPanelTextLayoutPolicy` 控制模型详情参数、性能和建议面板标题的公开 Dynamic Type 语义字体、最多两行、1pt line spacing、12pt 标题/内容间距和自然垂直增长；它只影响 `DetailPanel` 静态标题，不改变 panel/详情行结构、整体/行级辅助语义、模型详情列、44pt 动作、模型文件、Reduce Motion、runtime 或 verified 门禁。
- `ModelDetailRowAccessibilityMetadata` 控制模型详情参数行、性能行和建议行的行级辅助语义；`DetailRow` 和 `AdviceRow` 必须暴露 label/value/hint/input labels/identifier，`ModelDetailColumn` 必须允许行级元素可达，并明确行级内容只展示本地模型详情、不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `OptimizationToggleAccessibilityMetadata` 控制设置页和优化 dashboard 的运行策略开关辅助语义；开关本身只切换本地运行策略，不下载模型权重、不启动真实 runtime、不发送云端服务，VoiceOver/Voice Control label/value/hint/input labels/identifier 要有测试锁住。
- `OptimizationToggleGridLayoutPolicy` 控制设置页和优化 dashboard 的运行策略开关网格宽度策略；窄屏和窄 split view 必须回退单列，iPad/Mac 宽区域允许双列，列数阈值、最小卡片宽度和共享网格入口要有测试锁住。
- `OptimizationToggleRowLayoutPolicy` 控制设置页和优化 dashboard 单个运行策略开关行的最小触控目标；每个开关行必须保持至少 44pt 命中高度，且不得改变 `DeviceOptimizer` 开关状态流、运行策略顺序、辅助语义、网格列数、准备度摘要、模型文件或 runtime 状态。
- `OptimizationToggleTextLayoutPolicy` 控制设置页和优化 dashboard 共用运行策略小节标题、行标题和副标题的 Dynamic Type 语义字体、两行上限、行内间距和垂直增长；它只影响文字排版，必须保留 `OptimizationToggleRowLayoutPolicy` 的 44pt 行高、`OptimizationToggleGridLayoutPolicy` 的 250/510pt 网格契约以及本地状态、辅助语义、Reduce Motion、runtime 和 verified 门禁。
- `ChipReadinessAccessibilityMetadata` 控制设置页和优化 dashboard 的芯片准备度卡片与圆环辅助语义；准备度摘要必须随 `Offline privacy guard` 开关动态显示开启/关闭，并明确本地芯片准备度、不下载模型权重、不启动真实 runtime、不发送云端服务。
- `ChipReadinessLayoutMode`、`ChipReadinessLayoutPlan` 与 `ChipReadinessLayoutPolicy` 控制设置页和优化 dashboard 共享卡片的真实 panel 内容宽度布局；`354pt` 及以上普通字号横排，Accessibility Dynamic Type 或 NaN/Infinity/非正宽度 stacked，ring 固定 `86pt` slot / `66pt` diameter，`AnyLayout` 保持同一 ring/正文子树，不写入状态层。
- `OptimizerMetricAccessibilityMetadata` 控制设置页和优化 dashboard 的 Apple Silicon 指标卡辅助语义；指标卡只展示本地优化摘要，不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁，VoiceOver/Voice Control label/value/hint/input labels/identifier 要有测试锁住。
- `OptimizerMetricTextLayoutPolicy` 控制设置页和优化 dashboard 的 Apple Silicon 指标卡文本动态排版；指标 label、value 和 detail 必须使用 Dynamic Type 语义字体并允许多行，避免 iPad/Mac 窄 split view 和较大文字设置下通过固定小字号或缩放压缩文字，且不得改变指标数据、进度、tint、网格列数、辅助语义、模型文件或 runtime 状态。
- `OptimizerMetricGridLayoutPolicy` 控制设置页和优化 dashboard 的 Apple Silicon 指标网格宽度策略；窄屏和窄 split view 必须回退单列，iPad/Mac 宽区域保持双列，列数阈值和共享网格入口要有测试锁住。
- `SessionSidebarLayoutPolicy` 只计算推理页竖向会话栏的偏好宽度；Mac/iPad 会话栏必须保持 240...310pt，宽度比例和无效宽度 clamp 要有测试锁住。
- `ChatWorkspacePaneLayoutPolicy` 使用 `ChatWorkspace` 扣除全局工作区侧栏后的真实 pane 宽度协调会话栏和聊天面；pane 小于 860pt 必须使用横向会话栏堆叠布局，分栏时聊天面必须保持至少 620pt，且不得改变会话状态流、composer 聚焦、导出、辅助语义或 verified 门禁。
- `SessionBarActionAccessibilityMetadata` 控制推理页会话栏新建/导出可见按钮的辅助语义；它必须与系统 `会话` command menu 标题、快捷键和 focused route 保持对齐，并明确导出不发送到云端服务。
- `SessionCommandFocusPolicy` 控制会话 command menu 的 focused route 活动态边界；稳定 route 包装始终保持相同 SwiftUI 结构，只有当前选中的聊天工作区在包装内提供 `SessionCommandActions`，隐藏聊天页的 actions 必须为 `nil`，且不得改变 `Command+N`、`Command+Shift+E`、会话状态或 composer focus 流程。
- `SessionBarActionLayoutPolicy` 控制推理页会话栏新建/导出可见按钮的最小触控目标；横向会话栏和大屏竖向会话栏必须共享至少 44pt 的图标按钮尺寸，且不得改变会话 command menu、导出弹层、composer 聚焦或辅助语义。
- `SessionChipActionAccessibilityMetadata` 控制推理页单个会话 chip 的选择和删除动作辅助语义；选择动作必须说明只切换本地会话并请求 composer focus，删除动作必须说明只删除本地会话记录、不删除模型 artifact 或权重，并为默认空白当前会话暴露不可删除原因；label/value/hint、Voice Control 输入标签和稳定 identifier 要有测试锁住。
- `SessionChipTextLayoutPolicy` 控制推理页会话 chip 标题的 Dynamic Type 文本策略；标题使用语义字体并允许两行，避免 iPad split view、Mac Catalyst 窄窗口和较大文字设置下通过固定小字号或缩放压缩文字，且不得改变会话选择/删除状态流、44pt 触控目标、composer 聚焦、辅助语义、模型文件或 verified 门禁。
- `SessionChipVisualStylePolicy` 控制推理页大屏竖向会话行的工作台视觉层级；选中行使用 8pt 圆角、低饱和 accent 表面、主文字色、hairline 描边和 3pt 左侧指示条，横向 chip 保持既有胶囊样式，且不得改变会话选择/删除、44pt 触控目标、Dynamic Type、辅助语义、composer 聚焦或 runtime 状态流。
- `SessionChipSidebarMetadataPolicy` 与 `SessionChipSidebarMetadataPlan` 控制竖向 240...310pt 会话行的本地信息密度；plan 只由 `ChatSession` 和 `SessionBarLayout` 生成，消息数取 `messages.count`，摘要从数组尾部向前选择最后一条归一化后非空正文，首尾/内部 whitespace、Tab 和换行压成单 ASCII 空格并按 `Character` 最多 40 个字符（超长前 37 个加 `...`），空摘要回退为消息数，横向返回 hidden 并保持 title-only 胶囊。策略不读取或比较 timestamp/createdAt/updatedAt，不排序、不写回、不持久化、不联网；metadata 使用 Dynamic Type 语义字体且不改变选择/删除动作、44pt 目标、辅助语义、composer、runtime 或 verified 门禁。
- `SessionChipHoverStylePolicy` 控制 Mac Catalyst/iPad pointer 在竖向、未选中会话行上的纯视觉 hover 表面；只由 `SessionBarLayout`、选中态和 `SessionChip` 局部 pointer 状态派生，亮/暗主题使用 0.06/0.10 accent opacity，装饰层禁用命中并隐藏于辅助树，横向胶囊、选中态、44pt 动作、Reduce Motion、会话状态、runtime 与 verified 门禁均不变。
- `SessionChipActionLayoutPolicy` 控制推理页单个会话 chip 选择和删除动作的最小触控目标；选择与删除入口必须保持至少 44pt，且不得改变会话选择、删除禁用原因、会话删除状态流、composer 聚焦、模型 artifact、辅助语义或 verified 门禁。
- `ChatMessageAccessibilityMetadata` 控制推理页聊天消息气泡整体辅助语义；它必须区分用户消息、本地模型消息和系统状态消息，合并正文或生成中状态、token 数、本地会话边界、Voice Control 输入标签和稳定 identifier，并明确不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `ChatMessageCopyActionPolicy` 和 `ChatMessageCopyActionAccessibilityMetadata` 控制单条消息复制 eligibility、原始 payload、44pt 动作和独立辅助语义；trim 只用于判空，写入剪贴板的正文必须保持原样，空白/生成中消息不可复制。消息摘要与复制按钮必须为两个同级可达元素，成功 checkmark 复用既有 `.copyConfirmation` 且持续到气泡身份消失，不得增加计时器、时间显示、状态层写入、云端发送、runtime 变化或绕过 verified 门禁。
- `ChatBubbleLayoutPolicy` 控制推理页聊天消息气泡宽屏宽度策略；iPhone 和窄 split view 必须保持紧凑可读，iPad/Mac 宽区域的用户气泡允许从旧 310pt 上限增长，本地模型和系统气泡必须限制最大阅读宽度，容器 padding、角色比例、最小/最大宽度和无效宽度 clamp 要有测试锁住。
- `ChatTranscriptTrackLayoutPolicy` 控制推理页聊天记录统一阅读轨道；ScrollView 必须保持全宽，消息栈在 iPhone 和窄 split view 保留 18pt 单侧边距，在 iPad/Mac 超宽窗口居中并封顶 920pt，且不得改变气泡角色上限、自动滚动、辅助语义、composer、会话或 runtime 状态流。
- `ChatTranscriptVerticalLayoutPolicy` 控制聊天记录在可用高度内的纵向定位；空记录保持顶部对齐，任何非空且内容较短的记录都靠近 composer 底部对齐，长记录自然滚动。策略只使用视口高度和是否为空，不得设置消息数阈值、插入 lazy stack spacer、反转消息、增加第二套自动滚动状态或使用 iOS 18-only scroll anchor API，且不得改变 920pt 阅读轨道、消息顺序/ID、VoiceOver、Reduce Motion、现有 `.bottom` 自动滚动、composer、会话或 runtime 状态流。
- `ChatBubbleTextLayoutPolicy` 控制推理页聊天气泡角色、正文和 token 元数据的 Dynamic Type 文本策略；三类文本必须使用语义字体并允许垂直增长，Accessibility Dynamic Type 下移除角色比例、左右保留空间和相邻间距但继续遵守 520/680/600pt 最大阅读宽度，普通字号布局、消息文案、辅助语义、自动滚动、会话状态、composer、runtime 和 verified 门禁不得改变。
- `GenerationIndicatorStylePolicy` 只控制推理页空文本生成占位的圆点数量、几何（5pt 直径、4pt 间距）、脉冲参数（0.35...1.0 opacity、0.9 秒 easeInOut、0.15 秒逐点相位延迟）与 Reduce Motion 静态梯度 0.35/0.65/1.0；`ChatBubble` 直接读系统 `accessibilityReduceMotion` 决定是否启动脉冲，开启时零动效但保留静态梯度。它不得给 `AppMotionEffect` 新增 case、不得改变气泡辅助语义（含 `ChatMessageAccessibilityMetadata` 生成中朗读文案）、`message.text.isEmpty` 占位触发条件、非空正文渲染、消息状态流、runtime 或 verified 门禁。
- `ComposerBarLayoutPolicy` 控制推理页 composer 宽屏输入宽度策略；iPhone 和窄 split view 保持原有可用宽度，iPad/Mac 宽区域必须居中并限制最大输入行宽，padding、底部间距、最小/最大宽度和无效宽度 clamp 要有测试锁住，且不得改变 `ComposerBar` 内部焦点、`Command+Return`、发送/停止或辅助语义。
- `ComposerInputActionLayoutPolicy` 控制推理页 composer 发送/停止按钮的最小触控目标；发送和停止两种动作必须保持至少 44pt，且不得改变 `ComposerBar` 内部焦点、`Command+Return`、空输入禁用、发送/停止闭包、`ComposerInputMetadata` 辅助语义、模型文件或 runtime 状态。
- `ComposerFocusGlowStylePolicy` 只控制推理页 composer 内场聚焦描边颜色/线宽/光环与发送/停止按钮渐变/光环的纯静态样式值；聚焦时内场描边改 accent 0.55 透明度、1.5pt 线宽并在描边形状上加 10pt 光环（暗 0.35 / 亮 0.20），未聚焦必须原样保持 `theme.border`、1pt、零光环，发送/停止按钮填充分别使用 accent 1.0/0.78 与 red 0.9/0.7 对角渐变，可用时加 8pt 光环（暗 0.45 / 亮 0.28），禁用时光环为 0。全部效果用 overlay/shadow 实现不改布局，且不得改变 `ComposerInputMetadata` 辅助语义、`Command+Return`、空输入禁用、发送/停止闭包、`ComposerFocusRequest` 焦点机制、44/48pt 触控目标、composer 宽屏宽度策略、`AppMotionEffect` 五 case、模型文件、runtime 或 verified 门禁。
- `SectionHeaderTextLayoutPolicy` 控制提示词页、模型页、设置页和优化区共享小节标题的 Dynamic Type 文本策略；eyebrow 使用语义字体并保持单行，title 必须允许两行，subtitle 必须允许多行，且不得改变工作区状态流、宽屏内容宽度、触控目标、辅助语义、模型文件或 runtime 状态。
- `ChatTranscriptAccessibilityMetadata` 控制推理页聊天记录容器辅助语义；它必须合并空记录、消息总数、最新消息角色和生成中摘要，暴露 Voice Control 输入标签和稳定 identifier，并明确只浏览本地会话记录、不发送 prompt、不下载模型权重、不启动真实 runtime、不发送云端服务、不绕过 verified 门禁。
- `ExportSessionActionAccessibilityMetadata` 控制导出弹层分享 Markdown、文本兜底和复制全文动作的辅助语义；它必须明确本地 Markdown / 文本分享兜底 / 剪贴板边界，并说明不会发送到云端服务。
- `ExportSessionActionLayoutPolicy` 控制导出弹层底部分享、底部复制和 toolbar 分享入口的最小触控目标；底部分享/复制必须至少 44pt 高，toolbar 分享必须至少 44x44，且不得改变 ExportPayload、ShareLink 文件优先/文本兜底、剪贴板写入、导出弹层辅助语义或会话状态流。
- `ExportSessionTitleTextLayoutPolicy` 控制导出弹层会话标题与消息摘要的 Dynamic Type 文本策略；标题与摘要使用语义字体并允许两行，避免 iPad/Mac 宽 sheet 和较大文字设置下通过固定小字号或缩放压缩文字，且不得改变 ExportPayload、ShareLink 文件优先/文本兜底、剪贴板、分享/复制触控目标、导出弹层辅助语义或会话状态流。
- `ExportSessionBodyTextLayoutPolicy` 控制导出弹层 Markdown 正文的 18pt padding、3pt line spacing、完整正文和语义等宽 Dynamic Type 契约；`ExportSessionView` 继续使用 ScrollView、`textSelection(.enabled)` 与 `ExportSessionLayoutPolicy` 的 320/760pt 宽度，不添加截断或固定正文高度，且不得改变导出文本/文件、复制分享、标题/动作辅助语义、44pt 目标、runtime 或 verified 门禁。
- `ExportSessionLayoutPolicy` 控制导出弹层整体内容宽度；iPhone 和窄 split view 必须保持原有可用宽度，iPad/Mac 宽 sheet 必须让会话摘要、Markdown 预览和底部分享/复制动作整体居中并限制最大宽度，且不得改变 ExportPayload、ShareLink 文件优先/文本兜底、剪贴板写入、toolbar 分享、导出弹层辅助语义或会话状态流。
- `WallpaperPreferenceAccessibilityMetadata` 控制设置页壁纸选择和恢复系统背景控件的辅助语义；它必须明确系统相册、本地压缩、`AppStorage` 背景数据、系统背景恢复和不发送到云端服务边界。
- `PromptTemplatesWorkspaceLayoutPolicy` 控制提示词页整体内容宽度；iPhone 和窄 split view 必须保持原有可用宽度，iPad/Mac 超宽窗口必须让标题、分类筛选和模板网格整体居中并限制最大宽度，最大内容宽度要从模板网格四列最大宽度派生，且不得改变分类筛选、模板填入/发送、生成中禁用、composer 聚焦或辅助语义。
- `PromptTemplateGridLayoutPolicy` 控制提示词模板页的卡片网格宽度策略；窄屏必须保持单列和最小卡片宽度，iPad/Mac 宽区域允许多列和卡片伸展，但必须限制最大卡片宽度，列数阈值和共享网格入口要有测试锁住。
- `PromptTemplateTextLayoutPolicy` 控制提示词模板卡片标题、副标题、正文、分类标签的行数、行距和最小卡片高度；模板卡片主要文本必须使用 Dynamic Type 语义字体，避免固定小字号和单行截断，且不得改变模板动作辅助语义、生成中禁用、填入/发送状态流或模板网格列数。
- `PromptCategoryLayoutPolicy` 控制提示词分类筛选 chip 的换行布局和触控目标；窄屏和窄 split view 必须自动换行，iPad/Mac 宽区域允许单行完整展示，chip 必须保持至少 44pt 触控高度，水平/垂直间距、padding、最小 chip 宽度、单行宽度和无效宽度 clamp 要有测试锁住，且不得改变筛选状态流或分类辅助语义。
- `PromptCategoryTextLayoutPolicy` 控制提示词分类筛选 chip 文本行数和 Dynamic Type 可读性；分类 chip 文本必须使用语义字体并允许多行，不得改变筛选状态流、分类辅助语义、模板筛选结果或模板动作状态流。
- `PromptTemplateActionLayoutPolicy` 控制提示词模板卡片动作区触控目标和布局常量；“填入”和“发送”动作必须达到至少 44pt 触控目标，动作区 spacing、卡片 padding、发送按钮尺寸和最小动作区宽度要有测试锁住，且不得改变模板动作辅助语义、生成中禁用、填入/发送状态流或模板网格列数。
- `PromptTemplateActionAccessibilityMetadata` 控制提示词模板卡片“填入”和“发送”动作的辅助语义；它必须明确填入 composer、切回推理页聚焦输入、直接发送到本地模拟 runtime、不下载模型权重、不启动真实 runtime、不发送到云端服务和不绕过 verified 门禁。
- `ComposerInputMetadata` 控制推理页 composer 输入框和发送/停止按钮的辅助语义；它必须暴露输入框 label/hint/input labels/identifier、动作 label/value/hint/input labels/identifier，说明 `Command+Return`、空输入禁用、停止当前模拟生成、本地模拟 runtime、不下载模型权重、不启动真实 runtime、不发送云端服务和不绕过 verified 门禁。
- `WorkspaceTab.shortcutKey`、工作区 command menu、工作区导航辅助语义、工作区导航 44pt 触控目标、会话 command menu、顶部模型胶囊整体辅助语义、模型概要面板与详情右栏/行级辅助语义、模型页整体宽屏内容宽度策略、模型详情右栏最大阅读宽度策略、模型文件工作流面板与卸载确认弹层辅助语义、模型文件操作 44pt 触控目标、头部主题与模型库入口辅助语义、全局 Header 图标动作 44pt 触控目标、Header 标题动态排版策略、设置页整体宽屏内容宽度策略、设置页图标动作 44pt 触控目标、会话栏操作辅助语义、会话栏操作 44pt 触控目标、会话 chip 动作语义、会话 chip 选择/删除 44pt 触控目标、聊天消息气泡与聊天记录容器辅助语义、聊天气泡宽屏宽度策略、composer 宽屏输入宽度策略、composer 发送/停止 44pt 触控目标、导出弹层分享/复制辅助语义、导出弹层分享/复制 44pt 触控目标、导出弹层整体宽屏内容宽度策略、壁纸控件辅助语义、regular 侧栏说明、选择语义、composer 输入焦点/控件辅助语义、模型选择器、状态徽章与部署控件辅助语义、运行策略开关辅助语义、运行策略开关宽屏网格、运行策略开关行 44pt 触控目标、芯片准备度辅助语义、优化指标卡辅助语义、优化指标卡文本动态排版策略、优化指标网格宽度策略、共享 SectionHeader 动态排版策略、提示词页整体宽屏内容宽度策略、提示词模板宽屏布局策略、提示词模板文本动态排版策略、提示词分类筛选换行布局策略、提示词分类文本动态排版策略、提示词模板动作 44pt 触控目标、提示词分类筛选辅助语义和提示词模板动作辅助语义锁住 Mac/iPad 工作区导航；改动快捷键、菜单、工作区导航、工作区导航触控目标、模型胶囊状态摘要、模型概要面板语义、模型页整体内容宽度、模型详情摘要、模型详情行级语义、模型详情宽屏宽度、模型文件工作流面板语义、模型文件操作触控目标、模型卸载确认语义、头部主题与模型库入口、全局 Header 图标动作触控目标、Header 标题文本排版、设置页整体内容宽度、设置页图标动作触控目标、会话栏操作、会话栏操作触控目标、会话 chip 选择/删除动作、会话 chip 选择/删除触控目标、聊天消息气泡、聊天气泡宽度、聊天记录容器、导出弹层分享/复制、导出弹层分享/复制触控目标、导出弹层整体内容宽度、壁纸控件、侧栏文案、composer 输入框/发送/停止控件、composer 发送/停止触控目标、composer 宽屏宽度、模型选择器、模型状态徽章、模型部署控件、运行策略开关、运行策略网格、运行策略开关行触控目标、芯片准备度摘要、优化指标卡、优化指标卡文本排版、优化指标网格、共享 SectionHeader 文本排版、提示词页整体内容宽度、提示词模板网格、提示词模板文本排版、提示词分类筛选换行、提示词分类文本排版、提示词模板动作触控目标、提示词筛选、模板动作或可访问性映射时必须同步测试。
- `WallpaperImageProcessor` 控制相册壁纸压缩和尺寸，避免大图直接进入 `AppStorage`。
- `ExportPayload` 和导出视图必须处理 Markdown 文件不存在时的文本分享兜底，导出弹层的分享/复制动作不得暗示云端上传。
- `script/build_and_run.sh` 是 Mac Catalyst 本地 build/run/debug/logs 入口，不下载模型权重，不接外部推理服务，不等于原生 macOS target。

## 5. 角色召唤和身份标识

- 用户消息以 `agenta`、`a:` 或 `A:` 开头，表示召唤 Agent A。
- 用户消息以 `agentb`、`b:` 或 `B:` 开头，表示召唤 Agent B。
- 用户消息以 `agentc`、`c:` 或 `C:` 开头，表示召唤 Agent C。
- 用户消息以 `agentx`、`x:` 或 `X:` 开头，表示召唤 Agent X。
- 没有这些前缀时，按普通 Codex 任务处理；若任务需要 A/B/C/X 边界，先提醒用户指定角色，或明确本轮按普通任务执行。
- Agent A 最终回复第一行必须写：`我是 Agent A。`
- Agent B 最终回复第一行必须写：`我是 Agent B。`
- Agent C 最终回复第一行必须写：`我是 Agent C。`
- Agent X 最终回复第一行必须写：`我是 Agent X。`

## 6. main 直推与云端验证总流

本项目默认使用：

```text
人工目标
  -> Agent A 本地分析并写版本化提示词
  -> Agent B 基于最新 origin/main 在 main 上实现
  -> Agent B 本地轻量检查
  -> Agent B commit 并 push 到 origin/main
  -> GitHub Actions 运行 CI 并上传未加密结果包
  -> Agent C 下载结果包，核对 commit/run/manifest/log/JUnit
      -> 有问题：退回 Agent B 在 main 上追加修复 commit
      -> 无问题：确认 origin/main 最新 run 通过
  -> 人工复核
```

未来 Agent X 主控循环使用同一条云端验证主线：

```text
人工总目标 X
  -> Agent X 拆分下一轮小目标
  -> Agent A 写本轮版本化 Agent B 提示词
  -> Agent B 基于最新 origin/main 在 main 上实现、检查、commit、push
  -> GitHub Actions 运行 CI 并上传未加密结果包
  -> Agent C 下载并验收最新 run 的 artifact
  -> Agent X 根据 Agent C 结果判断继续、退回、暂停或完成
```

硬规则：

- `main` 是唯一上传、提交、推送和云端验证分支。
- 本轮制度不使用 `smalldata_test`、`develop`、`codeb/...` 或其他长期/候选分支。
- 本轮制度不创建 PR，不等待 PR merge。
- Agent B 每轮开始前必须同步最新 `origin/main`，确认当前分支是 `main`，确认工作区没有无关改动。
- Agent B 完成后先跑本地轻量检查，再提交并 `git push origin main` 触发 GitHub Actions。
- Agent C 只验收 `origin/main` 最新 commit 对应的 `commitSha`、run id、run attempt 和 artifact；不能验收旧 run 或旧 artifact。
- Agent C 发现问题时，不做回滚式处理；默认退回 Agent B 在 `main` 上追加修复 commit，再 push 触发新 run。
- 任何 Agent 在 `git push origin main` 或改变远端 `main` 前，都必须确认当前分支是 `main`，目标远端是 `origin/main`，且提交范围只包含本轮相关文件。
- 如果仓库没有配置 `origin` 或没有 GitHub Actions 权限，必须明确报告阻塞；禁止伪装已经 push、已经下载 artifact 或已经云端验收。

### Agent X：主控循环调度

Agent X 是未来用于多轮迭代的主控调度角色，不直接替代 Agent A、Agent B 或 Agent C。

Agent X 必须：

1. 接收人工给出的总目标 X，并拆成多个可独立验证的小轮次。
2. 每轮按 Agent A -> Agent B -> Agent C 顺序推进。
3. 要求 Agent A 为每轮生成版本化提示词，写入 `md/prompt/v0（简要标题）/vX.Y（简要说明）.md`。
4. 等 Agent B 完成实现、轻量检查、commit 和 `git push origin main`。
5. 等 GitHub Actions 为最新 `origin/main` commit 生成未加密 artifact。
6. 等 Agent C 下载并核对最新 run 的 manifest、artifact 名称、JUnit、日志和 `.xcresult` 或等价结果。
7. 根据 Agent C 结论判断下一步：继续下一轮、退回 Agent B 修复、暂停等待人工确认，或宣布总目标完成。

Agent X 循环边界：

- 每轮目标必须服务于人工总目标 X，不能为了推进循环扩大无关范围。
- 每轮必须留下可追踪证据：本轮版本号、Agent A 提示词路径、Agent B commit、GitHub Actions run、artifact 名称和 Agent C 验收结论。
- Agent X 可以调度和总结，但不能跳过 Agent A 的提示词、Agent B 的实现 push 或 Agent C 的云端 artifact 验收。
- Agent X 只能在总目标真实完成且最新 Agent C 验收通过后宣布完成。

Agent X 停止条件：

- 总目标已完成。
- 连续 3 轮遇到同一阻塞。
- 连续 2 轮没有产生有效 diff。
- CI 连续失败且原因相同。
- 需要账号、权限、密钥、付费服务或人工决策。
- 当前工作区存在无法判断归属的冲突。
- 用户要求停止或改变方向。

推荐同步命令：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short --branch
```

推荐提交命令：

```sh
git add 相关文件
git commit -m "vX.Y: 简要说明本轮做了什么"
git push origin main
```

## 7. Agent A：目标分析与提示词

Agent A 默认不写业务代码，负责把人工目标转成 Agent B 可执行的详细提示词。

Agent A 必须：

1. 阅读入口文档、核心文档、测试规范、prompt README、相关源码和 workflow。
2. 明确目标、非目标、边界、依赖、风险和验收标准。
3. 设计实现方案，包括模块、数据流、状态流、接口、测试、旧逻辑保护和 CI 结果包要求。
4. 分配版本号：人工指定则使用人工版本；否则从现有 `update_log.md` 继续递增。
5. 写 Agent B 提示词到 `md/prompt/v0（简要标题）/vX.Y（简要说明）.md`。

Agent A 提示词必须包含：版本号、版本分配依据、背景、目标、非目标、当前架构依据、实现步骤、关键文件、本地轻量检查、云端 CI 触发、结果包内容、Agent C 验收标准、风险和禁止项。

## 8. Agent B：实现、轻量检查与 main push

Agent B 按 Agent A 提示词实现。

Agent B 必须：

1. 阅读 Agent A 提示词、入口文档、核心文档、测试规范、prompt README、相关源码和 workflow。
2. 执行 `git fetch origin`、`git switch main`、`git pull --ff-only origin main`；若 `origin` 不存在，立即报告阻塞，不能伪装云端流程。
3. 小步实现，不做无关重构。
4. 新增或修改必要测试。
5. 按 `md/test/test.md` 跑本地轻量检查；除非人工明确要求，不默认跑本机完整 Xcode build 或模拟器 XCTest。
6. 更新必要文档。
7. 暂存并提交本轮相关文件，commit 主题格式为 `<版本号>: <一句话概括>`。
8. 直接 push 到 `origin/main` 触发 GitHub Actions。
9. 输出改动、关键文件、本地轻量检查结果、commit SHA、push 结果、workflow run 信息、未跑测试原因、已知风险和后续建议。

Agent B 不得：绕过核心规则直接改状态、擅自扩大范围、删除旧实现、用“已验证”代替具体测试结果、伪造测试通过、回滚用户或其他 Agent 的改动、跳过 main push 却声称已触发云端验证。

## 9. Agent C：结果包验收与退回

Agent C 验收 Agent B 的 `origin/main` 最新结果。

Agent C 必须：

1. 阅读 Agent B 输出和实际 diff。
2. 阅读入口文档、核心文档、测试规范和 workflow。
3. 确认本地 `main`、`origin/main`、Agent B commit SHA 和 GitHub Actions run 对齐。
4. 如需访问私有或受权限控制的 artifact，先执行 `gh auth login`。
5. 用 `gh run download` 下载未加密 CI 结果包，缓存目录默认是 `/private/tmp/localgemma-c-review-<run_id>/`。
6. 打开并核对 `ci-artifact-manifest.json`、`ci-failure-summary.md`、`junit.xml`、主构建日志和 `.xcresult` 或等价项目结果。
7. 核对 manifest 的 `branch=main`、`commitSha`、`runId`、`runAttempt` 与 `origin/main` 最新 commit 完全一致。
8. 检查架构边界、测试覆盖、文档同步、未说明风险。
9. 如不通过，输出阻塞问题清单、退回 Agent B 的修复要求，并明确本轮不通过。
10. 如通过，确认 `origin/main` 最新 run 通过，并输出版本号、commit hash、run id、run attempt、artifact 名称、已核对文件和建议下一步。

Agent C 如果需要补文档或修小问题，也必须在 `main` 上追加 commit、push、等待新 run，再重新下载和验收最新结果包。Agent C 不得只看 Agent B 文字汇报，不得验收旧 artifact。

## 10. 测试规则

测试入口是 `md/test/test.md`。后续 Agent 每次实现前必须读它，并根据改动范围选择本地轻量检查和云端 CI。

默认策略：

- 默认云端重验证，本机只跑轻量检查。
- 只有人工明确说“本机测试”“本地 build”“本地跑探针”“本地 xcodebuild”等，Agent 才把本机完整构建或模拟器验证作为默认路径。
- 文档-only 修改仍可本地跑 `git diff --check`、YAML 解析、`plutil -lint`、目录结构检查等轻量检查，并说明未跑完整 XCTest 的原因。
- Swift / Xcode / UI / 状态流 / workflow 改动完成后，默认 commit 并 push 到 `origin/main`，由 GitHub Actions 运行重验证。
- 云端失败时，Agent B 根据结果包中的失败摘要、日志路径和 manifest 修复后继续在 `main` 上追加 commit 并 push。
- 所有测试记录必须包含实际命令和结果，不得只写“测试通过”。

最低要求：

- 文档-only：检查文档链接、目录结构、关键命令和事实一致性；说明未跑 XCTest 的原因。
- workflow / 工程文件：至少跑 `git diff --check`、`plutil -lint LocalGemma.xcodeproj/project.pbxproj`、YAML 解析。
- 逻辑改动：至少跑 Probe / Fast，并由云端 CI 重跑 build/test。
- 状态流、模型文件、导出、布局、壁纸、分享改动：云端 CI 必须覆盖 Stage Regression 等价验证。
- 影响 App 启动、Xcode 工程、共享状态或跨模块行为：云端 CI 必须覆盖 build-for-testing 和 XCTest；本机完整测试只在人工明确要求或云端不可用时执行。

## 11. 文档规则

每次完成正式版本或重要任务后，必须同步：

- `update_log.md`：版本/任务名、日期、核心变更、关键文件、验证结果、遗留事项。
- `md/test/test.md`：新增测试、测试数量、触发条件、当前基线变化、云端结果包要求。
- `md/flow/flow.md`：当前真实逻辑和云端协作流，不写历史废话。
- `md/flow/flowchart.md`：与 `flow.md` 同步的 Mermaid 流程图，每张图前有中文读图说明，每个逻辑块有中文注释。
- `README.md`：用户可读功能范围、运行方式、协作与云端验证说明。
- `md/prompt/`：Agent A 每轮提示词按版本归档，`md/prompt/README.md` 维护提示词规则。
- `.github/workflows/ci-results.yml`：CI 结果包结构、命名和验证命令与 `md/test/test.md` 保持一致。

README 过期视为 bug。测试数量、命令、功能边界、CI 结果包和真实模型状态必须保持一致。

## 12. 交付格式

每轮最终回复使用中文，简洁说明：

```text
已完成本轮工作。

改动：
- ...

验证：
- ...

风险/未完成：
- ...
```

如果是 Agent A，交付 Agent B 提示词路径和本轮版本号，并以 `我是 Agent A。` 开头。
如果是 Agent B，交付实现结果、本地轻量检查、commit SHA、push 结果和 workflow run 信息，并以 `我是 Agent B。` 开头。
如果是 Agent C，通过时交付验收结论、版本号、commit hash、run id、artifact 名称、核对文件和建议下一步；不通过时交付问题清单和退回 Agent B 的修复要求，并以 `我是 Agent C。` 开头。
如果是 Agent X，交付总目标状态、当前轮次、Agent A/B/C 输出摘要、最新 commit/run/artifact、继续/退回/暂停/完成判断，并以 `我是 Agent X。` 开头。

普通 Codex 任务无需冒充 A/B/C/X 身份，但必须说明实际完成范围和未完成的云端环节。

## v2.83 当前边界补充

v2.83 起，顶部 `ModelCapsule` 的 deployment 摘要由 `ContentView` 直接传入 `ModelCatalog.deploymentState(for: catalog.selectedModel)`，只展示 `Running` / `Stopped`，不从 artifact、SIM/REAL、生成状态或 runtime 推导。`StatusBadge`、`AvailabilityBadge`、`DeploymentBadge` 与胶囊内 SIM/REAL 共同读取 `ModelStatusBadgeStylePolicy` 的 theme-aware 纯值契约；stopped 使用主题 `primaryText`、`chipSurface` 和 `border`，不使用白字逃生路径。局部 `ModelStatusBadgeTextLayoutPolicy` 使用语义 Dynamic Type 字体，`ModelStatusBadgeRowLayoutPolicy` 在有限内容宽度低于 `220pt` 或 `.xxxLarge` 及以上回退 stacked，普通字号达到 `220pt` 才 horizontal，不建立第二套模型胶囊断点。

顶部胶囊仍通过 `accessibilityElement(children: .combine)` 暴露稳定整体摘要，deployment value、SIM/REAL、artifact、速度、内存和准备度都在整体 metadata 中；胶囊内 deployment badge 隐藏独立辅助节点。模型页 selector 通过 `ModelStatusBadgeAccessibilityPresentationPolicy` 保留安装、artifact、deployment 三枚 badge 的独立 label/value/hint/input labels/identifier。上述局部布局和可达性策略不改变 44pt 模型控件、Reduce Motion、missing/staged/verified runtime 门禁、默认本地模拟 runtime、模型文件或 cloud/privacy 边界。

## v2.84 当前边界补充

v2.84 起，`ModelSummaryTextLayoutPolicy` 继续由 `ModelSummaryPanel` 的同一生产子树读取：名称/简介保持既有 5/2/4/2 契约，能力标签改用 semantic Dynamic Type 字体、最多 2 行、1pt line spacing、9/6pt padding 和垂直 fixed size；校验摘要改用 semantic Dynamic Type 字体、最多 3 行、1pt line spacing 和垂直 fixed size。能力标签使用 `theme.chipSurface` 背景、`theme.secondaryText` 前景与 `theme.subtleBorder` 描边，`FlowLayout` 仍使用 adaptive minimum 72pt 与 8pt 间距，不新增概要宽度断点、AnyLayout 或动作。

概要仍保留 `.accessibilityElement(children: .ignore)` 和 `ModelSummaryAccessibilityMetadata` 的整体 label/value/hint/input labels/identifier；三态 validation 只展示本地 missing/staged/verified 状态，只有 verified 通过既有 runtime gate。v2.84 不改变外部 44pt action、Reduce Motion、模型文件、默认模拟 runtime、模型权重、网络、云端 inference 或 privacy 边界。

## v2.85 当前边界补充

v2.85 起，`ChatGenerationPlaceholderPresentationPolicy` 只根据 `ChatMessage`、`isGenerating` 和当前消息身份推导 `active`、`completed` 或 `cancelled`：只有当前最新的空 assistant 在生成中时显示既有 `GenerationIndicatorView` 并朗读“正在生成”；stop 后保留同一空 assistant 的 message ID、数组位置、session ID/title 和消息顺序，但呈现为静态 cancelled，不再显示圆点或 stale 生成辅助文案。非空 assistant、用户消息和系统消息不显示 generation indicator，复制 44pt、ChatMessage/ChatTranscript 稳定辅助语义、Reduce Motion、composer focus、streaming cadence、local runtime、artifact verified gate 和 privacy/cloud 边界均不变。

`ChatBubble` 与 `ChatMessageAccessibilityMetadata`、`ChatTranscriptAccessibilityMetadata` 读取同一 policy 结果；`InferenceEngine.stop()` 无需新增状态字段或修改，因为既有 task cancellation + `isGenerating = false` 已提供足够的纯值输入，且不会删除/重建 placeholder。v2.85 只新增一个聚合 XCTest，源码函数基线由 129 增至 130；完整 build/test、Catalyst 和 ImageRenderer 仍只在 GitHub Actions 云端运行。

## 13. 禁止项

- 禁止自动下载模型权重。
- 禁止接入云端推理或外部网络模型服务。
- 禁止绕过 artifact `verified` 门禁。
- 禁止伪造测试结果。
- 禁止把未跑的测试写成已通过。
- 禁止无关大重构。
- 禁止删除用户或其他 Agent 改动。
- 禁止把 `RealGemmaRuntimePlaceholder` 描述成真实推理已完成。
- 禁止让 README、测试规范、核心流程文档长期落后于源码。
- 禁止新增 Swift 文件后忘记加入 Xcode target。
- 禁止把 AITRANS 的漫画探针、GGUF、模型 Release、`smalldata_test`、候选分支或 PR 合并制度硬复制到本项目。
- 禁止让 Agent C 只看 Agent B 文字汇报。
- 禁止把旧 artifact、旧 output 或 checkout 自带报告冒充本轮云端结果。
- 禁止提交模型、大数据、证书、密码或 secret。
- 禁止没有权限下载 artifact 时伪装已核对；必须先 `gh auth login` 或说明权限阻塞。
- 禁止 Agent X 无条件无限循环。
- 禁止 Agent X 跳过 Agent C 云端 artifact 验收。
- 禁止 Agent X 把旧 run、旧 artifact、本地输出冒充最新云端结果。
- 禁止 Agent X 在总目标未完成时宣布完成。
- 禁止 Agent X 为了循环推进扩大无关改动范围。
- 禁止使用非 `Altman-sam114` 的 GitHub 账号伪装完成 push、CI 或 artifact 验收。
- 禁止默认下载大体积测试数据、模型、历史 artifact 或无关产物，导致本机或 CI 容量被撑爆。

## v3.0 工作台界面重构（2026-09-27，云端验收待完成）

本轮由单一 Agent X 串行执行设计、实现与验收。接续已有界面拆分草稿：主题、聊天、输入区、模型、提示词、设置和共享组件分别进入独立 Swift 文件并加入 app target；保留既有工程签名设置。深墨色/浅瓷白表面、青绿与靛蓝强调色、品牌导航、聊天欢迎引导与本地模拟标识形成统一工作台。AITRANS 只读参考主题的间距、圆角、最大阅读宽度组织方式，未修改该项目。

状态对象、四页身份隔离、composer 同步焦点、快捷键、本地文件、44pt、Dynamic Type、Reduce Motion 和 verified gate 继续沿用。新增 testWorkbenchWelcomeAndStarterLayout，总计 131 个 XCTest 方法。Tools/capture_workbench.py 只允许 GitHub Actions 执行，采集 iPhone/iPad × 亮暗 × 四工作区的 16 张生产截图；visuals/manifest.json 记录 SHA/run/attempt/device。CI 将截图作为必选阶段，JUnit 由 7 增至 8 个阶段，仍只有可选 Codex environment 可跳过。

本机仅进行源码检查、git diff --check、plutil 和 YAML/脚本解析；不执行 Swift 编译、模拟器、XCTest 或 Catalyst。完整验证和截图检查尚待最新 main 的云端结果包，不能据此声明发布就绪。默认 runtime 仍为模拟，真实推理、签名发布和真机/辅助技术验收尚未完成。


## v3.1 侧栏布局回归修复（2026-09-27，云端待验收）

v3.0 云端 run `36260394187` 的四组布局测试仍沿用旧侧栏宽度，已按生产设计同步：compact 为宽度 25%、224...256pt，regular 为 22%、260...288pt；根断点保持 700/980/700。1180pt 窗口扣除全局侧栏后已有 920pt 聊天 pane，故应进入会话/聊天 split，仍保障聊天面至少 620pt。新增现有测试内的比例及 clamp 边界矩阵，不削弱断言、不跳过失败测试；XCTest 方法总数保持 131。

本机仅源码与 git diff --check、工程 plutil、YAML 解析，不执行编译、模拟器或 XCTest。全部构建测试在 GitHub Actions，最新 SHA/run/attempt 和结果包、生产截图仍需验收；不声明发布就绪。AITRANS 仅只读参考，无修改。


## v3.1 云端验收通过（2026-09-27）

最新 `origin/main` commit `592aa1c8b1d95e0f8f69a1bea91a69ae0c7f53ab` 对应 GitHub Actions run `36309087049`、attempt `2` 已通过。结果包 artifact 为 `localgemma-ci-v3.1-main-592aa1c-run36309087049-attempt2`。Static checks、LogicSmoke、iOS build-for-testing、iPhone Simulator XCTest、Mac Catalyst build、Mac Catalyst 脚本契约、16 张 iPhone/iPad 亮暗工作区截图、manifest、JUnit 和结果包上传均成功。下载完整压缩包在当前网络环境中速度极慢，已以 GitHub run 状态、artifact 元数据和成功阶段作为验收证据；未把本地输出冒充结果包内容。

本地未执行 Swift 编译、XCTest、模拟器或 Catalyst。默认 runtime 仍为模拟，未下载模型权重，未接入真实推理或签名发布；AITRANS 仍只读参考。


## v3.2 提示词网格真实宽度布局（2026-09-27，云端待验收）

提示词页不再用 `ViewThatFits` 竞争多个带最小宽度的 LazyVGrid；`PromptTemplatesWorkspace` 将真实内容宽度传入 `PromptTemplateGrid`，由已有 `PromptTemplateGridLayoutPolicy.columnCount(for:)` 直接选择 1/2/3/4 列。这样 Mac/iPad 侧栏剩余宽度会稳定展示多列卡片，避免宽屏右侧出现大片空白，同时保留 230...320pt 卡片宽度、12pt 间距、模板动作 44pt、辅助语义、动态字体、本地 runtime 与 verified 门禁。未改变模板填入/发送状态流。

本地只执行源码、git diff、工程和 YAML 结构检查；Swift/XCTest/截图由 GitHub Actions 云端验证。


## v3.3 云端视觉采集稳定性（2026-09-27，云端待验收）

`Tools/capture_workbench.py` 的 `sim()` 为 GitHub Actions 上的 `xcrun simctl` 增加最多 3 次、有界 2 秒退避重试，并在最终失败时保留命令与 stderr；覆盖 boot、bootstatus、install、launch、screenshot 和 shutdown，解决 CoreSimulator 瞬态 launch denied 导致视觉阶段误失败的问题。仍只允许 `GITHUB_ACTIONS=true`，仍采集 iPhone/iPad × 亮暗 × 四工作区 16 张截图，不改变 App UI、状态流、模型文件、runtime 或 verified gate。

本地仅做 Python 语法和文本结构检查；构建、XCTest、Catalyst 和截图仍全部在云端执行。

## v3.3.1 焦点测试窗口生命周期（2026-10-13，云端待验收）

焦点回归测试必须在已有 foreground-active `UIWindowScene` 中托管真实 `ComposerBar`，保留首次 attachment 前的待处理 request，并分别等待公开 `viewDidAppear`/key-window/attachment 就绪和真实 `UITextInput` first responder 结果。测试使用有界条件 expectation，不以固定 sleep、测试重试或直接 `becomeFirstResponder()` 替代受测行为；失败需保留 scene、window、request 和 responder 诊断。退出时统一结束编辑、隐藏并移除 root controller、恢复原 key window，断言无宿主残留。

生产 `ComposerBar` 的同步 `onAppear`/`onChange`、隐藏页清 request/焦点和四页身份保持不变。v3.3 run `36314940076` 的唯一 XCTest 失败尚不能仅凭旧日志确定为生产缺陷；本轮先修复无 scene 与固定 20ms 测试宿主假设，全部 131 项 XCTest 及构建仍交云端，不提前宣布修复通过。

## v3.4 当前呈现与证据边界

- 实施基线是 `9ccf8b9` / run `38343587295` attempt `1`：Agent C 已下载完整结果包，核对 digest、JUnit 8 阶段、131 个结构化 Success 和三份 xcresult，并明确仅焦点/构建回归基线 PASS；iPhone 设置页 readiness 溢出是 v3.4 必修，不能据此宣布整产品视觉或发布验收通过。
- `WorkbenchPresentationPolicy.chatPresentation` 只在有 starter、非生成且没有 user 时选择 welcome；欢迎与消息正文互斥，welcome 自然顶部阅读，不改 seed、消息/session UUID、顺序、标题或导出。无 starter 和已有 user 的会话仍完整显示原 transcript，短会话底部定位和同步 focus 不变。
- `SessionBarLayoutPolicy` 只根据真实内容宽度、horizontal/vertical 与 expanded text 解析 inline/stacked/sidebar；inline 门槛为 `180 + 2*44 + 8 + 12 = 288pt`，非法宽度归零、大字横向 stacked，同一个 sessionList/actions 经 AnyLayout 复用；不新增根断点、不隐藏删除/导出。
- `WorkbenchActionRole` / `WorkbenchActionPalette` 集中定义低饱和主/次/危险动作与 prominent 配对；分类色只用于小面积标识。`WorkbenchBackgroundStylePolicy` 在 Reduce Transparency 或 increased contrast 下移除静态网格和光晕；不新增动画、状态或网络资源。
- `ChipReadinessCard` 不再在卡内用 GeometryReader 固定高度。设置页与 dashboard 从真实 panel 外框扣除两侧各 14pt 后传入 content width，同一 AnyLayout 自然上报高度；保留 354pt、86pt slot、66pt ring、隐私摘要、辅助语义与 optimizer 状态。
- 源码新增 6 项测试至 137。云端保留 16 张模拟器生产截图，另导出 8 张真实剩余 1078pt pane 的生产工作区固定 viewport 渲染和 4 张 readiness 组件渲染；后两者明确不是模拟器截图或 Mac GUI 实测。结构化 summary/tests、附件原索引、尺寸/hash/provenance 与轻量 review 包辅助 C，完整三份 xcresult 仍必须核对；现有 JUnit 8 阶段不减项，导出失败并入必选 visual outcome。
- v3.4 尚待本轮精确 SHA 的云端构建、测试及 C 人眼复判。默认 runtime 仍为模拟，真实推理、Mac GUI/pointer、真机/辅助技术和签名发布均未完成。

## v3.4.1 云端证据修复边界

用户最新要求不再多开子智能体；同一 Agent 串行完成设计、实现和结果包验收，不重启既有子智能体。v3.4 `3911a3f` / run `39805938317` attempt `1` 已下载完整包并核对 137/137 Success、JUnit 8 阶段、三份 xcresult 及全部 28 图；16 张真实模拟器图有效，但 8 张 ImageRenderer 宽屏图缺失滚动正文，宽屏视觉证据退回，不能宣布整体视觉或发布 PASS。

v3.4.1 仅改测试/证据和文档，不改生产代码：真实 foreground scene 中以公开 UIHostingController/child containment 挂载同一生产 View，通过 viewDidAppear/attachment/尺寸条件有界等待后用 UIView.drawHierarchy 截图；退出恢复 key window。真实 1078pt pane/至少620pt聊天面不变，宽屏图需通过 Vision OCR 识别已有页面标题，exporter 要求来源、OCR 与同主题不同工作区 hash。readiness 全矩阵仍用 ImageRenderer 测自然高度，选定四图改为 UIKit 宿主截图，保留 137 项和既有严格焦点/identity。宿主截图不是全屏模拟器截图或 Mac GUI；新 SHA 仍需自身云端完整结果和人眼验收，所有 Swift/截图/构建测试只在云端。

## v3.4.2 模型文件动作自然高度

v3.4.1 `37e3b3b` / run `39816180114` attempt1已核对完整包、137/137、三份xcresult和28图，宿主截图修复通过；新图暴露模型库双栏文件动作卡约515pt过高。v3.4.2只移除`ArtifactActionButton` label中的竖向Spacer，并在padding后使用`.fixedSize(horizontal:false,vertical:true)`让内容报告自然高度；不以固定最大高度/缩字/裁剪解决。86pt minimum、12pt padding、8pt spacing、两行语义文字、44pt、配色/动作/辅助语义、模型双栏/状态/verified均不变。新增公开`UIHostingController.sizeThatFits`压力回归，总计138项；600/1400pt提议不得改变同宽同字自然高度，大字允许增长。所有执行只在云端，仍不新增或启动子智能体。

代码提交`1601bd63bd2527e10fd01a44d006d09842299bdc` / run `39825340832` attempt1的完整包已下载验收：138唯一Success、JUnit8/0失败/1 optional skip、三份xcresult成功，28图回归确认宽屏动作约110pt自然高度。结论仅为v3.4 UI呈现/布局回归PASS；默认模拟runtime、真实Mac GUI/pointer、真机/完整辅助技术及签名发布仍未验收。该结论绑定上述代码SHA，不自动覆盖后续文档或代码提交；后续main仍须对应的新run和产物核对。

## v3.5 设置工作台双栏（2026-10-23，待自身云端验收）

最新文档基线 `fc3d4a9` / run `39830013497` attempt1 的完整包已核对138唯一Success、JUnit8、三份xcresult，设置实图仍为长单列。单一Agent串行实施本轮，不开子智能体；AITRANS只读参考语义token和间距，无修改。

`SettingsSections.swift` 加入app target并集中纯值plan、稳定shell、外观/芯片生产section。真实1078pt pane得到1042pt内容、320pt偏好、24pt间距和698pt运行计划；普通字号882pt内容/918pt pane开始双栏，`.xxxLarge`及以上单栏。双栏偏好区增加无命中、辅助树隐藏的当前主题/壁纸缩略示意；本地图片说明不暗示云端服务。PhotosPicker/导入中/错误状态仍归原SettingsWorkspace，44pt和metadata不变。指标与策略grid改用明确实际宽度，toggle扣panel padding，dashboard同步调用。

新增阈值/大字、双节点identity、真实section自然高度3项至141，宽屏provenance/exporter锁住设置真实列宽；原28图、严格focus/identity、8阶段、三份完整xcresult均保留。所有Swift/构建/测试/图片只在云端；本地仅静态检查。尚未接真实runtime、原生macOS、Mac GUI/pointer或签名发布，不宣称发布就绪。


## v3.5.1 焦点测试宿主窗口就绪（2026-10-23，待自身云端验收）

v3.5 `a28ac41` / run `39885347849` attempt1 的结果包为140/141成功，唯一失败是首次composer request已消费但实际UITextInput未聚焦；设置三项新增测试、iOS/Catalyst构建及28图成功，整轮退回。测试宿主由600x120pt改用已有foreground scene的真实bounds，先以普通container建立key/visible窗口，再以公开child containment挂载带预存request的原生产ComposerBar；内容随可用宽度收缩、最多560pt。保持2秒有界条件、首次/离页/重进严格first-responder及清理断言，增加窗口与宿主尺寸诊断，不改生产同步焦点、设置状态或runtime/verified边界。

单Agent串行，无子智能体；本地仅diff/工程/YAML/结构检查，141项及全部构建运行截图只交GitHub Actions。最新SHA自身manifest、JUnit、完整三份xcresult和28图须复判，不提前宣称通过或发布就绪。


## v3.5.2 云端模拟器截图正文门禁（2026-10-23，待自身云端验收）

人工复看v3.5完整包发现iPhone亮色设置图空白、iPad暗色聊天图为桌面，旧固定3秒采集不能作为通过证据。`Tools/ValidateWorkbenchScreenshot.swift`作为独立CLI仅在真实GitHub Actions编译运行，公开Vision OCR要求目标工作区正文marker；`capture_workbench.py`在launch后有界5次/每次2秒采集并验证，失败使必选visual失败，manifest保留识别全文、marker、次数、PNG尺寸和SHA-256。原16模拟器图、12宿主图、141项及三份xcresult不减少；OCR后仍需人眼检查。无生产UI/状态/runtime/verified变更，AITRANS不修改，无子智能体，本地仅静态检查。
