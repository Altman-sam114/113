# 测试规范

## 手机日常任务入口

新增 3 个直接 XCTest 覆盖日常/技术模板全集与唯一 ID、完整提示词和填入不发送、两分组的辅助语义、直接发送展示边界、260pt 双列阈值和 `.xxxLarge` 单列回退、窄屏亮暗/大字自然增长，以及真实生产欢迎/模板界面的 6 张新增宿主图。源码原有测试不删除；云端结果与源方法集核对，不将进场未提交的截图 readiness 测试混入本轮提交。

完整图像合同为原 42 张不减，增加亮暗主题下的欢迎页 AX3、日常模板 AX3、进阶模板普通字号，共 48 张（16 Simulator + 32 宿主）和 6 份 provenance。新增宿主仍明确不是完整 Simulator、实际点按或真机证据；OCR 同时要求真实任务正文，欢迎页标题单独出现不能通过。exporter 的 4 个纯 Python 小夹具覆盖缺正文、错分组/字号/尺寸/名称及简繁字形，不运行 Swift/UI。验收必须绑定本轮新 SHA 的实际结果并看图，未运行前不写通过。

## v3.10.1 内容无关搜索自然高度（待最终新SHA）

`56b8a28` / run`40648305362` attempt1完整109014457字节ZIP独立SHA-256 `e297368f8841dd63ae03987a14d9e9ebca38e88ecc01250f2d8d7c99aaf833b6`与API一致、安全路径/CRC通过。summary/SQLite169唯一168 Success/1 Failure，原全字号矩阵AX2/AX3中文/英文各两态差1.667pt，共16断言，同一方法只执行一次。ScaledMetric下限没有稳定原生高度，不能称通过；搜索方法不在最慢8项中，主要云端时间不是该矩阵本身。

改生产布局而不减测试：不可见单行`.body` Text轨道+8pt垂直间距自然测量父尺寸，唯一真实TextField在overlay+6pt间距且至少44pt，plain清除44pt/整行48pt。hidden strut不显示、不命中、不进入辅助树，无第二个输入控件、无固定字号/最大高度；内容状态不参与父测量。原DynamicTypeSize.allCases×亮暗×两宽×中英文query的1pt断言、自然高度与旧focus/169方法/42图等门禁保持，新SHA须完整云端与看图。

## v3.10.1 搜索字体/控件高度回归（待最终新SHA）

`2cf7b63` / run`40646708156` attempt1完整98498647字节ZIP独立SHA-256 `3c93dde127ef497504743ffb82bfe5fecbde6e1338231250f50635fac7bef4ff`匹配API，安全路径/CRC通过。summary/SQLite169唯一中168 Success/1 Failure，唯一手机尺寸用例内亮暗×284/366的4个AX3断言分别60/61.667pt，未过原1pt容差；不是测试重试，不能凭42图或旧5e绿色称通过。

修生产`@ScaledMetric(relativeTo: .body)`22pt最低文字槽（不是固定行高或缩字），清除buttonStyle plain/44pt，仍48pt最小整行/6pt文字padding。原1pt等高断言不放宽，扩展到DynamicTypeSize.allCases×亮暗×两宽，空query分别对中文“部署”和英文“Gemma 1.5B”；自然高度/最小48pt/原行和notice断言保留。169方法名、42图/5provenance、12Python、JUnit10/4xcresult/unsigned门禁不减，新SHA必须重新云端全量与看图。

## v3.10.1 核心修复验收与最后搜索回归

`5e0eec3e5dca6d9ea71df9a80d66a28826f18f67` / run`40643812543` attempt1完整99467041字节ZIP独立SHA-256 `7bb9bc7d1b133e5f53296fc14d5a1fbe84bc28d5f95ca526d725b8775009cffc`与API匹配，安全路径/CRC通过。summary/tree/源码/SQLite严格169唯一Success、0 failure/skip/进程重启，恢复期64次拒绝0.0015s，严格focus4.923s，实际磁盘恢复图12.085s。JUnit10仅optional Codex skip，12Python/Swift6 smoke/iOS/Catalyst/unsigned资源成功，4份xcresult根succeeded且Data/refs 3、3、3、906配对；App zip CRC/资源hash/实际arm64/Info/隐私再核对。

42图/5provenance身份/尺寸/hash/OCR完整，4新历史图原尺寸及6张全部图片无裁切联系表已看，无新遮挡/缺页。对入口f347619，21/22原宿主字节一致，另1导入亮图变化仅spinner `(17,84)-(40,105)`，16模拟器正文排除状态栏后像素相同。记录`/private/tmp/localgemma-c-review-40643812543/`。这只验收上述SHA的普通重启/界面回归，不是真机/完整辅助技术、系统sheet操作或签名发布证明。

最后小修将生产搜索框抽出独立View，TextField自身6pt垂直padding而非整行padding；原`testConversationHistoryRowsAndNoticesGrowOnSmallPhones`追加两态尺寸：亮暗×284/366pt×large/accessibility3，空query与“部署”query自然高度相等（1pt容差）、最小48pt。44pt清除与query所有权/过滤不变，169方法/42图等全链路不减。此小修仍待自身新SHA完整云端，不沿用上段结论。

`01c1000` / run`40642098350` attempt1完整100983923字节ZIP独立SHA-256 `8a9ef4fec7af55f84d4fab971731f9939c514d9b29429132ac6644b4c2a9be16`与API一致，169方法中168成功、1真实SIGSEGV。ips写明栈溢出，`inputText.didset/setter`重复；Xcode在崩溃后启动剩余测试不等于失败用例重试成功。42图/5provenance、12个Python、LogicSmoke和三个平台构建/unsigned资源成功不改变整轮失败。

生产rollback用内部旗标阻止Published重入，不放开loading编辑。原失败测试增强64次非法输入加apply/use template/usePrompt，继续断言空seed未覆盖、真实archive草稿恢复和0次保存。169方法不减，不延时/skip/测试重试。实际看图另修大字装饰抢宽，仍由原亮暗/284/366pt/large/accessibility3自然高度与320×640四图/OCR检查；44pt删除、语义正文和旧严格focus不改。修复必须自身新SHA完整包/看图，不能沿用失败包图片宣称整体通过。

## v3.10 会话与手机历史门禁（待自身云端）

保护用例额外使用POSIX 000目录模拟真实不可访问：load必须报错而非缺失，恢复700权限后未重新load的save仍拒绝，旧字节不变。只接受明确NoSuchFile为缺失，不用`fileExists`误判授权；169方法数不变，不跳过权限断言。

源码169个唯一XCTest，保留入口157名称、严格真实responder/页面identity和文件事务断言；新增12项：归档原始正文/ID/时间/草稿round-trip；未知版本/重复/无效归属/负tokens拒绝；坏档保护与明确备份修复；磁盘失败与32MiB上限不覆盖旧字节；新engine恢复选择/逐会话草稿/停止占位；删除/reset/陈旧session保护；有界人工hold的恢复期动作拒绝；写失败后最新快照重试；60次输入合并单写；本机搜索/预览排除seed且不裁剪保存正文；亮暗×284/366pt×large/accessibility3行/错误自然高度；真实JSON落盘后新engine的历史图。异步断言先await取值，不在XCTest autoclosure中await，不用固定sleep凑测试，不重试或skip。

`testRestoredConversationHistoryProducesPhoneEvidence`新增4张`workbench-history-{light|dark}-{large|accessibility3}`，同一生产history，320×640pt，`UIView.drawHierarchy`，OCR必须同时有“会话记录”标题和“部署讨论”正文，记录restoredFromDisk=true。预存中文简繁等价归一仅做字形对应，不替代正文门禁。exporter保留原4provenance/22PNG并要求history第5份与4图，总26宿主+16Simulator=42；重复/缺图/身份或尺寸不符仍失败。宿主图不是系统sheet交互、完整Simulator或真机证据，尺寸测量不等于真实点按/完整辅助技术。

云端Swift6 LogicSmoke新纳入ConversationStore并实际写小归档、新engine恢复正文/选择/逐会话草稿与已停止导出，不编译UI；原12个Python夹具、JUnit10、4份完整xcresult和unsigned Release资源不减。新SHA完整ZIP必须独立对API digest、CRC/安全路径、manifest/源码名称/tree/SQLite/四份根状态、5provenance/42图及实际资源hash并人眼复判。入口`f347619` / run`40638042855` attempt1的157/157与38图仅是历史基线，不能当新版本通过。

本地仅`git diff --check`、plutil、YAML/shell、Python AST/12个纯小夹具、169名称与target/文档结构/hash检查，不运行Swift、Xcode、Simulator、UIKit/Vision或ImageRenderer。强杀/断电、后台到期和多场景/系统故障交互仍需后续独立验收；本轮不冒称可上架。

## v3.9.1 代码验收结果

代码`ee3a211607eb30b601acfe4a42d20aca7fb97889` / run`40635105796` attempt1，完整artifact `localgemma-ci-v3.9.1-main-ee3a211-run40635105796-attempt1`（97500545字节）已下载并对原ZIP独立算SHA-256，与API `3ba25c333828d07e69adc4a835bda3d41b7525012e90ad0a8c88a9b59a4cccc7`一致。结构化tree/summary、源码名称与原始SQLite逐一匹配157唯一Success，0 failure/skip/retry；新10项全部成功，后台/真实进度截图用例7.737s，严格focus2.972s。JUnit10/0失败/1 optional Codex skip；4份xcresult根succeeded、Data/refs为3/3、3/3、3/3、908/908。12个Python小夹具、Swift6 LogicSmoke、iOS/Catalyst与实际unsigned Release资源均成功；App archive CRC与6项实际资源hash已独立匹配。

38图尺寸/hash/provenance完整；新增2张导入中图原尺寸打开，原36以无裁切联系表逐图复看，20宿主PNG与v3.8字节相同，16模拟器正文排除iPhone顶部150px/iPad100px状态栏后像素相同。无新遮挡/缺页；滚动边缘的部分行不视为永久不可达，也不声称已实际点按/完整辅助技术或真机通过。23m14s中新增事务用例约8s，其余时间主要云端既有测试/截图；iPad暗模型首张OCR空白后有界第2次采集正文成功，未重试XCTest。完整包/联系表/记录在`/private/tmp/localgemma-c-review-40635105796/`。

结论仅绑定上述代码；验收回录文档或后续main仍必须自己的SHA/run/attempt结果核对，不能自动继承绿色。整体目标继续，发布缺口不变。

## v3.9.1 云端失败回归

`5b44803` / run`40633857029` attempt1完整包确认：Swift6四处裸FileManager跨actor错误，iOS/Catalyst/Release失败，XCTest因build失败未执行，JUnit10含5失败/2skip，无有效新图。CLI此前未指定Swift6不能充当Xcode并发门禁；本轮显式`-swift-version 6`并用受锁FileAccess，不改/skip/重试157项。

新增`Tools/tests/test_capture_preflight.py`四个纯小夹具：合法成功输入、失败build即使有残缺目录也拒绝、空/缺可执行文件、缺Info/非法路径名。与原8资源夹具共12个，由`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Tools/tests -p 'test_*.py' -v`本地静态与云端静态阶段共同执行，不启动App。生产capture失败必须先写精确SHA/run/attempt、expected16与失败原因后非零退出，不能跳过后伪称截图通过。157项/38图/4份provenance/4份xcresult/JUnit10契约保持，修复版待自身最新SHA云端全量结果与看图。

## v3.9 当前验收要求

源码157个唯一XCTest方法，原147名称及严格focus/identity断言保留；两个原Catalog扫描/卸载用例改async，必须等待真实初始扫描完成，不移除旧断言。LogicSmoke入口改async并纳入`ArtifactImport.swift`，新增hash失败/取消保留旧字节检查；本地不执行Swift。

新增10项：`testArtifactImportReplacesWholeSetAndPreservesOtherModels`、`testArtifactImportHashFailureKeepsPreviousGeneration`、`testArtifactImportReadFailureKeepsPreviousGeneration`、`testArtifactImportCancellationKeepsPreviousGeneration`、`testArtifactImportRejectsAmbiguousAndUnsafeSources`、`testArtifactImportCommitGateCannotReportLateCancellation`、`testArtifactImportAtomicCommitFailureKeepsPreviousGeneration`、`testArtifactImportCatalogRemainsResponsiveAndKeepsTargetIdentity`、`testArtifactImportCatalogCancellationKeepsValidationAndDeployment`、`testArtifactOperationRowKeepsPhoneActionsReachable`。覆盖整组替换/源与其他模型保留、复制后半段读失败、hash不匹配、准备/中途复制/校验前取消、重名/路径/软链接、真正原子rename失败、晚取消拒绝、后台非主线程、互斥/选中身份和取消后状态不变。手机行亮暗×284/366pt×全阶段×large/accessibility3测自然高度，取消不低于44pt，不以测量冒充实际点按。

响应性用例在真实后台复制暂停时挂生产ModelLibraryView，额外导出亮暗2张320×640pt导入中宿主图。`workbench-import-provenance`绑定同一用例，OCR必须有取消与导入模型文件正文，标注实际importing/copying和非Simulator；exporter要求4份provenance与22唯一PNG。原16模拟器+20宿主不减，总38图；JUnit10、4份完整xcresult与Release包资源门禁不减。不重试/skip测试，不在本地运行UIKit/Vision。

基线`a525a8a` / run`40629860257` attempt1已核对147/147、JUnit10、4份xcresult、unsigned资源及36图；新版本必须核对自身最新SHA/run/attempt完整包与全部图片，不能沿用旧绿色结果。崩溃/断电耐久和遗留候选回收、会话持久化、真实runtime、真机辅助技术、签名发布仍单列。单Agent，无子智能体，AITRANS只读；本地仅diff/plutil/YAML/AST/Python资源小夹具等静态检查。

## v3.8 当前验收要求

147项XCTest名称不变，原36张图、20宿主PNG/3provenance和3份xcresult不减。v3.7 `f0b5fd4` / run `40624916743` attempt1实际146/147：新手机三项及全部视觉通过，严格focus失败；已读完整包与原始日志，不用旧绿色状态覆盖。本轮生产focus代码不改，测试宿主对齐NavigationStack、底部composer和页面级底栏，条件已满足先同步判断，其余仍2秒；增加editing/请求事件，保留首次/隐藏/重入/清理全部断言。XCTest云端锁定明确UDID、关闭并行克隆，仍完整执行一次，不增加测试重试。

新增8项纯Python资源/验证器回归：28槽不透明icon、合法device夹具、Simulator拒绝、iPad图标声明缺失、隐私契约变化、非arm64、空Assets.car、损坏PNG。这些仅解析源文件和临时小夹具，不运行App，不能当作实际Release包通过。可本地执行：`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Tools/tests -p test_release_bundle.py -v`；`python3 Tools/verify_release_bundle.py --source-only`。静态素材生成不是Swift/ImageRenderer或模拟器运行。

云端新增两个必选阶段：`unsignedIPhoneOSReleaseBuild`、`releaseBundleResources`，JUnit由8增10且旧阶段不减，只有原optional Codex environment允许skip。完整包新增`LocalGemma-release-build.xcresult`、`release-build.log`、`release-bundle.log`、`release-bundle.json`、`release-source.json`、`LocalGemma-unsigned-iphoneos.app.zip`。bundle JSON必须绑定精确SHA/run/attempt/branch，检查iPhoneOS而非Simulator、arm64 Mach-O、最低17.0、两设备族/图标声明、版本/照片说明、非空Assets.car、实际图标与精确PrivacyInfo；签名验证明确false。原三份xcresult和147结构化名称/36图仍独立核对，不能被新包检查替代。

执行方式以最新人工要求为准：单Agent按模块推进，不新开子智能体、不走ABC队列。所有Swift编译、设备构建、XCTest与图片生成仍在云端。v3.8尚未跑自身云端，未预写通过。

本文指导 Agent A、Agent B、Agent C 和 Agent X 为 `Local Gemma iOS Prototype` 选择本地轻量检查、云端重验证、结果包下载和验收方式。

## v3.7 当前测试与证据基线

当前源码 147 个唯一 XCTest 方法，保留 v3.6 原144项，新加以下3项；测试内容已经落盘，不代表已经云端执行。用户最新允许多 Agent 按文件所有权并行，由统一集成负责人 push；本地仍只能做静态检查，不能启动 Swift、Xcode、模拟器、Vision 或 ImageRenderer。

- `testCompactChatHeaderReclaimsSpaceWithoutChangingRuntimeState`：全 Dynamic Type 的 `.xxxLarge` 堆叠契约；亮暗 × 320/390pt × large/xxxLarge/accessibility3 的生产集成头部自然尺寸，普通高度不超过76pt，大字增高，600/1600pt提议保持自然高度，动作与catalog/inference状态不变。真实页面marker的等义繁简归一必须匹配，底部四入口文字不能冒充正文。
- `testCompactSettingsRowsReclaimPhoneHeightAndKeepDynamicType`：手机40pt预览/10pt间距派生244pt内容阈值，大屏58/14/270pt保持；全字号、非法宽度、243.99/244/256/269.99/270边界、284pt panel扣28得到256pt。真实壁纸panel亮暗 × 284/366pt普通高度不超过120pt，大字增长，导入/清除禁用规则和44pt保持，测量不执行动作。
- `testCompactPromptRowsPreservePayloadAndActionBoundaries`：分类56pt最小宽/10pt横padding/真实44pt目标、模板76pt最小行高；普通284/366pt筛选两行不超过104pt，首末真实模板普通行不超过140pt，大字均增长。独立填入/发送identifier保留，summary的空白subtitle回退原prompt且不改首尾空白/换行；逐个apply得到完整原prompt，不发送、不改会话。

保留首次/隐藏/重返的严格 composer first-responder、root/四页/设置两节点 identity、会话/卸载/导出/runtime/verified 与既有自然高度测试。新增测量与状态断言不是实际点按或完整辅助技术测试，不能把它们报告成手势/VoiceOver 已通过。

云端继续输出16张iPhone/iPad亮暗四页模拟器图、8张宽屏+4张readiness+8张320×640pt compact宿主图，共36张；三份provenance、20唯一宿主PNG、原附件索引/结构化summary/tests与三份完整xcresult不减。compact组合移除旧外部Header，使用页面自身chrome和底栏，ChatWorkspace显式接收实际themeMode/readiness；组合图仍不是完整模拟器截图。

手机/compact OCR正文统一为“想聊点什么 / 导入模型文件 / 部署方案 / 外观模式”，宽屏英文marker不变。只归一同义繁简“點麼導觀”，中文先单语识别并保留逐pass全文，不能用底部导航同名词、添加测试生产文案或取消marker门禁。capture脚本每页保留尝试次数、JSON/stdout/stderr；失败后继续其他页收集诊断，manifest记录expectedCaptureCount=16与failures，最终任何页/尺寸/文件/正文失败仍使必选visual失败。JUnit保持8阶段，只有既有optional Codex environment可跳过。

历史v3.6 commit `3adaef7` / run `40169024104` 的review为143/144成功，唯一compact暗聊天中文OCR误读，真实图有正文；预存4处识别/诊断修改在本轮保留并增量修正，不将历史失败写成通过。v3.7必须验收自身最新SHA/run/attempt的完整包、日志、测试名集合、PNG尺寸/hash和实际手机图，不能用旧绿色run、OCR或结构断言代替人眼。真实runtime、AppIcon/签名分发、真机/完整辅助技术和Mac GUI/pointer不在本轮自动通过范围。

## 默认策略

- 默认云端重验证，本机只跑轻量检查。
- 只有人工明确说“本机测试”“本地 build”“本地跑探针”“本地 xcodebuild”等，Agent 才把本机完整构建或模拟器验证作为默认路径。
- 文档-only 修改仍可本地跑 `git diff --check`、YAML 解析、`plutil -lint`、目录结构检查等轻量检查，并说明未跑完整 XCTest 的原因。
- Swift / Xcode / UI / 状态流 / workflow 改动完成后，默认 commit 并 push 到 `origin/main`，由 GitHub Actions 运行 build / test。
- 云端失败时，Agent B 根据结果包中的失败摘要、日志路径和 manifest 修复后继续在 `main` 上追加 commit 并 push。
- 本项目当前不允许自动下载模型权重；CI 也不能下载 Gemma 或把提示词发往外部推理服务。
- Agent X 循环中的每一轮仍必须遵守同一验证链：Agent B 本地轻量检查、GitHub Actions artifact、Agent C 下载复判。
- Agent X 不得跳过 Agent C artifact 验收；失败时不能继续下一轮并伪装为已通过。
- 当前人工明确要求所有 Swift/SwiftC、Probe/Fast、Xcode、Simulator、XCTest、ImageRenderer 和 Catalyst 只在云端；不得本机运行或设置 `GITHUB_ACTIONS=true` 绕过。以下本机命令仅是未来明确获准后的入口，不是本轮步骤。

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
- 将来如人工明确授权本机 iOS 验证，也只能使用已确认完整 UDID 以 `FAC4325D` 开头的唯一模拟器；不按名称/`booted` 选择，不创建或替换设备。云端不受这个设备限制。
- 网络不是业务测试前提；项目当前不允许自动下载模型权重。
- 云端 CI 由 `.github/workflows/ci-results.yml` 负责，触发条件是 `main` push 和 `workflow_dispatch`。

未来本机入口必须先由人工确认完整 UDID；本轮不查询、启动或创建本机模拟器：

```sh
: "${LOCAL_SIMULATOR_UDID:?Set the confirmed full FAC4325D-prefixed UDID first}"
case "$LOCAL_SIMULATOR_UDID" in FAC4325D*) ;; *) exit 1 ;; esac
```

v3.6 测试基线（历史实施记录）：

- 源码144个唯一方法，保留v3.5.2原141项。基线`63a9766` / run`39892914886` attempt1完整包已下载，核对141项Passed、JUnit8/0失败/1 optional skip、三份xcresult成功与Data/refs完整、28图hash；两张旧空白/桌面问题对应的新图已实际复看。不是整产品发布验收，v3.6仍需自己的云端结果。
- 新增`testCompactWorkbenchPolicyKeepsNavigationReachableAndRuntimeHonest`，覆盖原根plan映射、底栏编辑真值表、四入口别名/原快捷键、文件三态、中文策略映射、状态不变与verified门禁。
- 新增`testCompactWorkbenchControlsPreserveNaturalSizingAndState`，使用公开UIHostingController.sizeThatFits，覆盖284/320/366/394pt、亮暗、large/xxxLarge/accessibility3、八个真实手机控件；600/1600pt提议不得注入空白，header大字自然增高，动作闭包和状态不变。
- 新增`testCompactWorkbenchProductionPagesProduceSmallPhoneEvidence`，真实云端UIKit宿主绘制320×640pt四页亮暗8图，包含生产手机header/页面/bottom navigation。中文聊天标题与原页面marker通过公开Vision OCR识别。keepAlways图与独立compact provenance严格标注组件组合，不冒充完整Simulator截图。
- 原严格composer焦点测试新增编辑回调/底栏呈现，首次、离页和重进同时要求真实UITextInput first responder、原request消费以及isEditing真值；不放宽2秒条件，不重试/直接设first responder。
- exporter保留原8wide+4readiness并要求新增8compact、三份provenance、20个唯一PNG及来源/OCR/尺寸/hash；compact同主题四页hash必须不同。原16张全屏模拟器图仍必选，iPhone聊天正文marker改为真实可见“想聊点什么”，不新增测试专用生产文案。JUnit8阶段/三份完整xcresult/review小包契约不减。
- 本地仅静态检查，所有Swift/SwiftC、Probe/Fast、iOS/Catalyst build、XCTest、Vision、UIKit/ImageRenderer和模拟器采集只在云端。此处及下列历史基线保留作追溯，不代表当前v3.7的147项已执行。

历史测试基线：

- `LocalGemmaTests.swift` 在v3.4.2时包含138个`test...`方法；v3.4新增6项、v3.4.2新增1项。当时已验收代码提交`1601bd6` / run `39825340832` attempt1为138/138，完整结果包和28图回归已核对，呈现/布局修复限定通过；不是发布或Mac GUI验收。新增契约和产物见文末小节；既有严格焦点与 identity 不弱化、不跳过。
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
  LocalGemma/AppState.swift LocalGemma/ArtifactImport.swift Tools/LogicSmoke.swift \
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
- 真实 iPhone/iPad × 亮暗 × 四工作区共 16 张生产模拟器截图
- 云端公开 `xcresulttool get test-results summary/tests` 与 `export attachments`：结构化 JSON、8 张真实剩余 pane 工作区渲染、4 张窄 readiness 组件图和 provenance；导出失败纳入必选 visual
- 生成 `ci-artifact-manifest.json`
- 生成 `artifact-name.txt`
- 生成 `ci-failure-summary.md`
- 生成 `junit.xml`
- 上传 `.xcresult`、`xcodebuild.log`、`test.log`、`mac-catalyst-build.log`、`mac-catalyst-run-script.log`、`mac-baseline-notes.md`、`logic-smoke.log`、`static-checks.log`、`environment.log` 和 manifest

云端 DerivedData 使用 `.derivedData-ci`，不同于本地推荐的 `.build/DerivedDataCodex`。这是 CI 内部缓存路径差异，不改变工程行为。

当前 `junit.xml` 的 `LocalGemmaCI` suite 包含 8 个 CI testcase：生产截图/布局证据、静态检查、LogicSmoke、iOS build-for-testing、XCTest、Mac Catalyst build-for-testing、Mac Catalyst run script contract 和可选 Codex Run environment。Codex Run environment 允许带非空原因的 `skipped`；其它 7 个 required testcase 必须为 `success`。附件/结构化导出失败先写 outcome、并入 visual，保留 manifest/JUnit/日志生成，最后 Evaluate 统一失败；不能让新步骤硬退出跳过结果描述。

### 结果包内容

GitHub Actions 上传未加密 artifact，版本号从最新 commit 主题的第一个 `vX.Y` token 提取。命名格式：

```text
localgemma-ci-<commit_version>-main-<short_sha>-run<run_id>-attempt<run_attempt>
```

同名加 `-review` 的轻量 artifact 保留可读身份、日志、结构化摘要和图片，不含三份 xcresult；它用于先读，不代替完整包。`artifact-name.txt`/manifest `artifactName` 始终指完整包，`review-artifact-name.txt`/`reviewArtifactName` 指小包。

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
- `visual-capture.log`、`visuals/manifest.json` 与 16 张真实模拟器生产图
- `evidence-export.log`、`xctest-summary.json`、`xctest-tests.json`
- `layout-renders/manifest.json`、`layout-renders/attachments/manifest.json` 原始附件索引、8 张工作区与 4 张 readiness 渲染 PNG/测试 provenance

`ci-artifact-manifest.json` 至少包含：

```json
{
  "artifactName": "localgemma-ci-vX.Y-main-abcdef0-run123-attempt1",
  "reviewArtifactName": "localgemma-ci-vX.Y-main-abcdef0-run123-attempt1-review",
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
  "visualCaptureOutcome": "success/failure",
  "visualManifestPath": "ci-results/visuals/manifest.json",
  "layoutEvidenceOutcome": "success/failure",
  "layoutEvidenceManifestPath": "ci-results/layout-renders/manifest.json",
  "testSummaryPath": "ci-results/xctest-summary.json",
  "testTreePath": "ci-results/xctest-tests.json",
  "evidenceExportLogPath": "ci-results/evidence-export.log",
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
- `xctest-summary.json`/`xctest-tests.json` 与完整 xcresult 的测试集合、状态一致，新增 6 项和原 focus/identity 均实际执行。轻量包不豁免完整 xcresult 核对。
- 真实截图 manifest 精确 SHA/run/attempt 与 16 张图片齐全。新增 `layout-renders/manifest.json` 明确 ImageRenderer 来源、非 Simulator screenshot/非 Mac GUI，原附件索引与 PNG SHA-256/尺寸相符，工作区 8 图、readiness 4 图不缺失/重复。
- 宽屏 root `1366x1024pt` 先由生产 policy 分配 288pt 全局 sidebar，实际 pane 为 1078pt；chat 再 split 且阅读面至少 620pt，manifest 记录真实 pane/外框/内部宽度。readiness 4 图是 320pt panel、292pt content、亮暗及 `.large`/`.accessibility3` 自然高度组件渲染，不能冒充全工作区截图。
- 必须实际看图，尤其检查 iPhone 设置 panel 完整包住 ring/正文、欢迎不混 seed/不被 composer 遮挡、宽屏 split 和模型/提示词动作层级；ImageRenderer 非 nil 不等于视觉验收。
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
  -destination "platform=iOS Simulator,id=$LOCAL_SIMULATOR_UDID" \
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
  -destination "platform=iOS Simulator,id=$LOCAL_SIMULATOR_UDID" \
  -derivedDataPath .build/DerivedDataCodex \
  CODE_SIGNING_ALLOWED=NO \
  test-without-building
```

如果未由人工确认唯一 `FAC4325D` 前缀完整 UDID，则不执行本机验证，不查询/选择替代设备；当前轮全部交云端。

当前基线：

- 期望结果：`TEST EXECUTE SUCCEEDED`。
- 本节历史测试函数数：138；当前v3.7源码为147，尚待自身云端验收。v3.4.2代码提交`1601bd6` / run `39825340832`已核对138/138，详见文末限定验收记录。已核对的 v3.3.1 基线为 `9ccf8b9` / run `38343587295` attempt `1` 的 `131/131 Success`，只证明焦点/构建回归基线；v3.4 新增及视觉修复必须由自己的新 run 验证。

### v2.85 / 取消生成占位生命周期

唯一新增聚合测试为 `testStoppingInferenceDoesNotPresentStaleGenerationPlaceholder`，源码函数数从 129 增至 130。测试先通过公开 `InferenceEngine.send(using:availability:)` 建立真实 assistant placeholder，再立即 stop；断言 stop 前后消息 ID、数组位置、角色顺序、active session ID/title 和 session messages 保持不变，placeholder 仍为空且 `isGenerating == false`，重复 stop 不增加消息，下一轮 send 使用新的 assistant ID 并保留旧 placeholder 位置。测试不等待流式 cadence、不依赖时间/随机值、不添加测试钩子。

同一测试锁住无状态 `ChatGenerationPlaceholderPresentationPolicy`：最新空 assistant + active generation 为 `active`、显示 `GenerationIndicatorView` 且辅助 value 含既有“正在生成”文案；stop 后为 `cancelled`、无指示器且 metadata/`ChatTranscriptAccessibilityMetadata` 不含 stale 生成文案；非空 assistant 为 `completed`，用户/系统空消息不显示 generation indicator，历史空 assistant 不能 active。它同时回归 `ChatMessageAccessibilityMetadata` 的稳定 label/hint/input labels/identifier、本地隐私与 verified 文案、空正文复制门禁和 44pt copy target、`GenerationIndicatorStylePolicy`/Reduce Motion、5 个 `AppMotionEffect`、transcript/bubble/composer/layout 常量以及 missing/staged/verified runtime gate。

测试还直接渲染真实生产 `ChatBubble(message:availableWidth:isGenerating:)`，公开 `ImageRenderer` 覆盖 `320/390/834/1200pt`、light/dark、`.large`/`.xxxLarge`/`.accessibility3`/`.accessibility5` 和 active/cancelled/completed/user/system 五类输入；每项只断言图像非空、尺寸 finite/positive 和 wrapper 宽度误差不超过 1pt，不使用私有 SwiftUI tree、UIKit accessibility tree、像素/颜色采样或截图快照。完整 iOS build-for-testing、XCTest、Mac Catalyst build-for-testing、LogicSmoke、run-script contract 和结果包仍只由 GitHub Actions 执行；本地只允许轻量 diff/parse/plist/YAML/脚本检查。

本轮未修改 `InferenceEngine.stop()`、工程文件、workflow、模型文件或历史 prompt；无模型下载、无云端 inference。云端证据由下方 Agent C 独立下载复判，不使用本地 build/test 代替。

#### v2.85 Agent C 云端验收记录

- 2026-09-08，GitHub API 复查远端 `main` 为 `a093e03df54cb205c62658d8a383f31a80ba9d05`，与验收前本地 HEAD/`origin/main` 一致；最新 [run 32653672941](https://github.com/Altman-sam114/113/actions/runs/32653672941) attempt `1`、job `97229009203` 均 `completed/success`，subject=`v2.85: 修复取消生成占位生命周期`，workflow=`Local Gemma CI Results`。artifact 未过期，无 rerun。
- 使用 `gh run download 32653672941 --repo Altman-sam114/113 --name localgemma-ci-v2.85-main-a093e03-run32653672941-attempt1 --dir /private/tmp/localgemma-c-review-32653672941/attempt1` 下载结果，并通过 artifact API 下载原始 ZIP；唯一 artifact ID `9496999466`、size `81,944,208` bytes。API digest 与 `shasum -a 256` 均为 `sha256:d2f69e4b06385f331c9ddd02577e3d44d4435d7ee6f73831debd13239ee3d7ba`，`unzip -tq` 无错误；ZIP 内 1,965 个唯一文件逐项 SHA-256 与解压内容一致，无路径越界。结果读取工具另生成的 `LocalGemma-tests.xcresult/database.sqlite3` 索引不属于云端 ZIP。
- manifest/name、repository、branch、完整/短 SHA、subject、run URL/ID/attempt、workflow、destination、结果/日志路径与 API、`artifact-name.txt` 和实际文件一致。required outcomes `static/logic/build/test/macCatalyst/macRunScript=success`；JUnit XML 可解析，7 testcase、0 failure/error、1 skipped，唯一 optional skip 为 `codexRunEnvironment`，reason=`not-added-in-v1.0-cli-entrypoint-only`；failure summary 为 `All required checks passed.`。
- 使用 `/Applications/Xcode.app/Contents/Developer/usr/bin/xcresulttool`，分别执行 `get test-results summary` 和 `get test-results tests`，`--path` 指向已下载的 `LocalGemma-tests.xcresult`，只读取结果：`130` total/unique、`130` Passed、`0` failed/skipped/unknown/duplicate，与 `git show a093e03:LocalGemmaTests/LocalGemmaTests.swift` 提取的测试名称集合完全一致。新增 `testStoppingInferenceDoesNotPresentStaleGenerationPlaceholder()` 在结构化树和日志各恰一次且 Passed，耗时约 `1.230s`。`test.log` 有 130 个 case 起点和 passed 标记、0 failed、一次 `TEST EXECUTE SUCCEEDED`；`testWorkspaceSidebarTextLayoutPolicySupportsDynamicTypeRows()` 名称在 `Ro`/`ws()` 间被 xcodebuild 诊断插入，不能用简单整行正则误报缺测。
- 三份 `.xcresult` 的 `Info.plist` 均通过 `plutil -lint`、版本 `3.58`；iOS build/Catalyst build/tests 的 Data/refs hash 集合分别 `3/3`、`3/3`、`963/963` 完全配对，rootId 均存在于两侧，`xcresulttool get object --legacy --format json` 均可读取。两个 build 的 `buildResult=succeeded/actionResult=notRequested`，tests 为 `actionResult=succeeded/buildResult=notRequested`，符合各自执行阶段；无 error/failure summary。Catalyst 有 2 条 Metal search-path warning，tests 有 2 条既有 composer FocusState warning；日志另有 AppIntents warning 和成功 marker 后的非致命 Simulator launch 诊断。
- iOS XCTest destination 为 `platform=iOS Simulator,name=iPhone 17 Pro`；Mac destination 为 `generic/platform=macOS,variant=Mac Catalyst`，baseline notes 明确非原生 macOS target，run-script 日志记录存在/可执行/`bash -n` 契约。LogicSmoke 与 iOS/Catalyst 成功 marker 均存在；artifact 无模型权重、tokenizer、GGUF/Core ML 模型、缓存、截图或视频，最大非 xcresult 文件为 `mac-catalyst-build.log`（`202,787` bytes）。
- 源码复核同一 policy/生产调用链、stop 后 ID/order/session 保留、copy 44pt、Reduce Motion、composer focus 和 verified gate；云端新增测试含真实 `ChatBubble` 的 `4` 宽度 × `2` 主题 × `4` Dynamic Type × `5` 输入矩阵（160 组合），不是完整人工 VoiceOver/视觉验收。已知非目标：`InferenceEngine.exportActiveSessionText` 仍将空消息标为“（生成中）”，包括 stopped 空 assistant，本轮未修复导出语义。
- 本次只更新三份 v2.85 验收记录，使用 `git diff --check`、Markdown fence/链接/目录与 v2.85 内容一致性检查；未运行本地 build/test、Simulator、Catalyst 或 ImageRenderer，因人工禁止且本次为文档-only。`github.com:443` Git 连接失败而官方 API 正常；按最新人工分工仅本地 commit，远端同步与文档 CI 交主控完成，尚不宣称该文档 commit 的 CI 通过。临时证据保留在上述目录，用户 dirty 工程文件和未跟踪 prompt 不动。

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

本轮未运行本地完整 `xcodebuild`、XCTest、Simulator、Mac Catalyst build/run 或截图验收；已执行 `git diff --check`、129 个测试函数计数、`rg` 结构检查、`plutil -lint`、Ruby YAML 解析、脚本存在性/可执行性/`bash -n` 和两份 `xcrun swiftc -parse`，均成功（YAML 仅有既有 PATH world-writable warning）。完整 iOS/Catalyst build、LogicSmoke、129 项 XCTest、JUnit、manifest 和三份 `.xcresult` 均已由本轮 GitHub Actions 云端结果覆盖并由 Agent C 核对。

最新实现 commit `aa68e1c95f611dc975ab882a5c0188a13fff6068` 对应 GitHub Actions run `32649219866` attempt `1`，branch=`main`、subject=`v2.84: 校准测试基线`、workflow=`Local Gemma CI Results`、conclusion=`success`。唯一 artifact 为 `localgemma-ci-v2.84-main-aa68e1c-run32649219866-attempt1`（ID `9495868226`，size `79,490,132` bytes），GitHub API digest 为 `sha256:4b52870abac765cd0ab07c9e94d69cccd57bc2be28d03cf1a5ffbd351851c284`；artifact name、`artifact-name.txt` 与 manifest identity 一致。

static、LogicSmoke、iOS build-for-testing、XCTest、Mac Catalyst build-for-testing、Mac Catalyst run-script contract 全部 success。JUnit 为 `tests=7`、`failures=0`、`errors=0`、`skipped=1`，唯一 optional skip 为 `codexRunEnvironment`，原因为 `not-added-in-v1.0-cli-entrypoint-only`；`test.log` 为 `129` passed、`0` failed，并有一次 `** TEST EXECUTE SUCCEEDED **`。新增测试在日志中恰一次且 Passed，结构化 XCTest 结果为 `129/129`，无 duplicate、Failure 或 Unknown。

iOS build、Mac Catalyst build、XCTest 三份 `.xcresult` 的 Data/refs 分别为 `3/3`、`3/3`、`922/922`，rootId 均同时存在于对应 Data 和 refs，root action status 均 succeeded。Mac baseline 是既有 iOS target 的 Mac Catalyst build-for-testing，不是原生 macOS target；artifact 无模型权重、tokenizer、GGUF、Core ML 模型、截图或视频。Agent C 未运行本地 Xcode/build/test，本轮完整验证全部来自云端。

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
  -destination "platform=iOS Simulator,id=$LOCAL_SIMULATOR_UDID" \
  -derivedDataPath .build/DerivedDataCodex \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$LOCAL_SIMULATOR_UDID" \
  -derivedDataPath .build/DerivedDataCodex \
  CODE_SIGNING_ALLOWED=NO \
  test-without-building
```

可视检查：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl install "$LOCAL_SIMULATOR_UDID" .build/DerivedDataCodex/Build/Products/Debug-iphonesimulator/LocalGemma.app

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl launch "$LOCAL_SIMULATOR_UDID" com.localgemma.prototype

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl io "$LOCAL_SIMULATOR_UDID" screenshot .build/localgemma-check.png
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

## v3.3.1 首次焦点宿主回归（2026-10-13）

- 失败依据：commit `2417687`、run `36314940076`、attempt `1` 的结构化 XCTest 为 131 total / 130 passed / 1 failed。唯一失败是 `testComposerInputMetadataAndFocusPolicyDescribeEntryPoints` 初次 attachment 后的非 nil responder 断言；旧包没有足够窗口状态诊断，不能宣称已经证明生产焦点丢失。
- 受测场景不变：挂载前已有 `.applyTemplate` request；初始活动页消费并聚焦；非活动页收到 `.selectSession` request 后同时清 request 与焦点；重返活动页 `.openChatWorkspace` 再次聚焦。原非 nil/nil 与 request 断言全部保留，聚焦还要求公开 `UITextInput`，不匹配私有 UIKit/SwiftUI 类名。
- 宿主改用已有 foreground-active `UIWindowScene`，`ComposerFocusHostingController` 记录公开 `viewDidAppear`。就绪检查与焦点结果检查分离，`XCTNSPredicateExpectation` 经异步 `XCTWaiter.fulfillment` 在主 actor 观察条件，每阶段 timeout 为 2 秒、条件满足即完成；这不是固定 sleep，也不重发 request、重建 view、直接调用 `becomeFirstResponder()` 或重试测试。
- `defer` 始终结束编辑、隐藏 window、移除 root controller、恢复原 key window，并断言 responder/window/root 已移除且原 key window 已恢复。阶段日志前缀为 `[ComposerFocusLifecycle]`，包含 scene、key/hidden/attached/appeared、active/request 和 responder/textInput；超时诊断进入 XCTest failure。
- 本轮测试数量仍为 131。完整云端必须通过 static、LogicSmoke、iOS build、XCTest、Catalyst build、脚本契约、16 张生产截图；JUnit 8 stages 与既有 optional skip 规则不变，workflow 不修改。Agent C 必须核对最新 SHA/run/attempt 的 manifest、日志和结构化 xcresult，不以 v3.3 截图或历史绿色 run 替代。
- 本地仅运行 `git diff --check`、`plutil -lint`、Ruby YAML 解析、`bash -n`、测试计数及文档结构检查；用户要求只云端构建，因此不运行本地 Swift/Probe/Fast、xcodebuild、XCTest、Simulator、ImageRenderer 或 Catalyst。修复后的云端结果待提交后验证。

## v3.4 呈现、自然高度与可审计视觉证据

### 已核对的实施基线

2026-10-22，Agent C 实际下载 `9ccf8b91a25c90242cd733a2da6cb3e4230844fa` 对应 run `38343587295` attempt `1` 的完整 artifact `localgemma-ci-v3.3.1-main-9ccf8b9-run38343587295-attempt1`。ZIP/API SHA-256 一致（`892fe0286c1cb8daa03b82f9520f048e3bac6bab7eb642e2eb1f5ccc9f256992`），JUnit 为 8 阶段/0 failure/error/1 optional skip；三份 xcresult root 状态与 Data/refs 有效（3/3、3/3、898/898），131 个唯一结构化 Success 与源码名称集合匹配，严格 focus 测试恰一次成功。Xcode 26.6 / 17F113，C 未运行本地 Xcode。

C 看图发现 iPhone 设置页 readiness 圆环和正文越出 panel，因此只给出焦点/构建回归基线 PASS、允许本轮修复，不给整产品视觉或发布 PASS。v3.4 必须检查自己的最新 SHA/run/attempt 和完整产物，不能沿用该基线结果。

### 新增 6 项 XCTest

- `testWorkbenchChatPresentationPreservesSessionAndExportData`：空消息/seed/system/assistant/空 user/已有 user/停止 placeholder × starter/生成开关真值表；重复只读决定不改变 messages/session/UUID/title。导出比对仅排除每次调用新生成的时间行，正文与 seed 保留；真实 send 后立即 stop 的会话仍 transcript。锁住 welcome 0...680pt clamp、辅助摘要、无 starter 旧行为和真实 transcript bottom policy。
- `testSessionBarLayoutPolicyCoordinatesCompactActions`：`180 + 2*44 + 8 + 12 = 288pt`，287.99/288 边界、320/390/600/834/1200、NaN/infinity/非正值，横向大字 stacked、竖向 sidebar、有限宽度和 heading 契约；默认不可删/非当前可删/长标题可删、稳定动作 metadata 与 Command+N/Shift+E/44pt 不变。
- `testWorkbenchSemanticActionAndCategoryColorsHaveReadableContrast`：生产亮暗三角色六字段重复读取、六分类；用公开 `UIColor(Color).getRed` 读取分量，按真实 alpha 合成后做 sRGB/WCAG。正常前景、prominent 配对、模型副标题与分类 0.10 wash 目标 4.5:1，必要 icon 前景/背景目标 3:1；不采样截图像素，不对 disabled 0.5 opacity 声称满足对比。另锁背景辅助偏好真值、40pt/四格网格及既有 panel 几何。
- `testWorkbenchProductionControlsSupportDynamicType`：真实 welcome、seed/无 starter/已有 user 的 ChatTranscript、部署启停、暂存/卸载、全部模板分类/生成中禁用、分类 selector 和 0/1/多会话横向区域；宽度/字号用 320/large、390/xxxLarge、600/large、834/accessibility3、1200/large 的亮暗组合，检查有限正尺寸和外框宽度。额外比较 320pt welcome 大字高度增长，真实 AppBackground 只用公开默认系统环境渲染；辅助开关组合由前项纯 policy 真值表覆盖，实际系统切换仍待人工实测。不写只读 EnvironmentValues，不构造测试替身 UI、不探查私有层级。
- `testWorkbenchWideProductionViewsProduceReviewEvidence`：先用生产 root policy 分配参考 `1366x1024pt` 的 288pt 全局 sidebar，再将真实 1078pt pane 交给四个生产工作区。chat 确认 split、会话栏/阅读面守恒、阅读面至少 620pt；两主题共 8 张 keepAlways PNG 与测试生成 JSON provenance，记录实际 pane、内部宽度、图像尺寸和来源。这不是 Simulator screenshot 或 Mac GUI 实测。
- `testChipReadinessCardReportsNaturalStackedHeight`：真实生产卡自然尺寸，panel 320/354/381.99/382/834 × 亮暗 × large/xxxLarge/accessibility3；显式区分 354pt content 与 382pt panel 横排阈值。stacked 高度必须严格大于 `86slot + 12gap + 28padding`，原固定 114pt 会失败；381.99 stacked 高于 382 horizontal 普通字基线，大字同宽自然增长，optimizer/隐私/热状态不变。320pt 大小字两主题额外保留 4 张组件 PNG/provenance，不能只凭非 nil 宣布高度修复。

既有严格焦点、根/四页 identity、文件/卸载/导出、Reduce Motion、44pt 与 verified 门禁测试保留。源码总数 137；这里描述测试内容，尚未预写本轮执行结果。

### 结果包与视觉失败规则

`Tools/export_workbench_evidence.py` 只允许 GitHub Actions，使用公开命令，不在本机运行：

```sh
xcrun xcresulttool get test-results summary --path ci-results/LocalGemma-tests.xcresult --compact
xcrun xcresulttool get test-results tests --path ci-results/LocalGemma-tests.xcresult --compact
xcrun xcresulttool export attachments --path ci-results/LocalGemma-tests.xcresult --output-path ci-results/layout-renders/attachments
```

原始导出索引保留，派生 `layout-renders/manifest.json` 记录 SHA/run/attempt、来源测试、生产 View/组件类型、真实 viewport/pane/panel/content 数值、PNG IHDR 尺寸和文件 SHA-256；要求完整唯一 8+4 矩阵且新增渲染单边不超过 1600px。结构化 summary/tests JSON 同包保存，完整三份 xcresult 不减项。

导出/结构化读取失败写 `layout-evidence=failure` 并使原必选 visual 失败，但步骤仍返回给后续 manifest/JUnit 生成，最后 Evaluate 统一判失败。JUnit 仍 8 阶段；16 张真实模拟器截图不取消，不新增 optional skip。`-review` 包只便于快速看身份、日志和图，C 仍要核完整 xcresult 和实际生产图。

本机只运行 diff/plutil/YAML/bash-n/Python AST、方法计数及 Markdown 结构检查；Swift、XCTest、ImageRenderer、Simulator 和 Catalyst 全部交云端。新增 137 项与 12 张附件是否执行成功、readiness panel 是否完整包住内容、欢迎/动作/宽屏是否达到视觉门槛，必须等待本轮精确提交的 CI 与 Agent C 复判。

## v3.4.1 真实宿主截图与内容门禁

v3.4 `3911a3f` / run `39805938317` attempt `1` 已实际核对137/137 Success、JUnit 8阶段/0失败、三份xcresult和28图。16张模拟器图无新增阻塞，但8张ImageRenderer宽屏图缺失滚动正文、三页同主题hash相同；4张组件图的progress也是占位。因此宽屏视觉证据退回，原图不能作为大屏通过依据。

本轮不新增或删除测试（仍137），不改生产代码和既有focus/identity断言：

- `testWorkbenchWideProductionViewsProduceReviewEvidence` 改为 async，真实foreground scene挂载公开UIHostingController子控制器；固定1078×1024pt pane，不依赖iPhone屏幕宽度，保留1366−288、split/620pt和会话不变。等待viewDidAppear、key/visible/attached与实际bounds，5秒有界条件，不用sleep或重试。UIView.drawHierarchy保存8张keepAlways图；退出detach并恢复原key window。
- 公开Vision OCR要求每图出现生产已有英文标题：ON-DEVICE WORKSPACE / MODEL LIBRARY / PROMPTS / SETTINGS；仅归一化标点与大小写，失败保留图片及识别文本，不改UI或添加截图专用标记。不读取SwiftUI私有树、不采样颜色，不把OCR当完整视觉验收。
- `testChipReadinessCardReportsNaturalStackedHeight` 保留原ImageRenderer尺寸矩阵/阈值/增长/optimizer断言；选定320pt大小字两主题的4张附件改为相同自然尺寸的UIKit宿主截图，避免ProgressView占位被误当真实外观。
- exporter仍用公开xcresulttool，验证8+4、PNG尺寸/hash/provenance；新来源为uihostingcontroller-production-view/component，captureMethod必须UIView.drawHierarchy。宽屏必须带实际OCR标记，同主题四工作区hash均不同。导出失败仍使必选visual失败，JUnit仍8阶段、16张全屏模拟器图与三份xcresult不减。

待新SHA自身云端结果核对全部137项及28图。宿主viewport图不是全屏Simulator screenshot或Mac GUI；依旧缺少桌面GUI/pointer、实际系统辅助偏好组合、真机/VoiceOver和签名发布验收。本地只做静态检查，Vision/宿主/Swift/Xcode执行均只在云端。

## v3.4.2 动作自然高度压力回归

实施基线`37e3b3b` / run `39816180114` attempt1的完整包已核对：137/137、JUnit8/0失败/1 optional skip、三份xcresult Data/refs 3/3、3/3、978/978，64公共文件一致，28图亲看。v3.4.1证据修复PASS，但宽屏模型页两个动作被拉至约515pt而退回界面修复；不能据此宣称产品视觉或发布通过。

新增唯一`testModelArtifactActionsKeepNaturalHeightUnderTallProposals`，总数138。直接使用生产ArtifactActionButton/Panel，公开UIHostingController.sizeThatFits比较600/1400pt提议高度，同宽同字自然高度必须一致，普通字单动作<240pt、panel<350pt（测试合理上限，不作为生产硬上限）；亮暗、146/170/250/360pt、large/xxxLarge/accessibility3、长中英标题副标题和两种动作，Accessibility自然高度须大于普通字。panel还覆盖320pt、从1366−288=1078真实pane进一步推导的控制列宽、760pt；验证动作闭包不执行、validation/deployment不变。

生产只移除Spacer并固定垂直理想尺寸，保留86pt minimum/12pt padding/8pt spacing/两行/44pt和所有动作辅助语义。原137项、严格focus/identity、16模拟器图+12宿主图、OCR/hash来源门禁及三份完整xcresult不减；待新SHA自身云端138项及宽屏亮暗模型图复核。本机仅静态检查。

### v3.4.2 代码验收（2026-10-22）

- 精确代码SHA `1601bd63bd2527e10fd01a44d006d09842299bdc`，run `39825340832` attempt1；完整包`localgemma-ci-v3.4.2-main-1601bd6-run39825340832-attempt1`及同名review包均已实际下载，不是只看workflow绿色。
- 独立Python/zstd/SQLite读取三份xcresult root均succeeded，Data/refs 3/3、3/3、926/926；138个唯一Success与源码/现代test tree名单匹配，0 failed/skipped。新自然高度测试0.197s、严格focus5.666s、wide宿主26.614s均恰一次Success。JUnit仍8阶段/0 failure/error/1 optional Codex environment skip。
- 64公共文件字节/hash一致，12附件来源/OCR/PNG尺寸/hash及16模拟器图身份均有效。28图逐项回归比对：2张改变的宽屏模型宿主图和6张有正文像素差异的模拟器图已重新打开；其余10宿主PNG与上一轮亲看图字节完全相同，10模拟器图在仅排除系统状态栏（phone180px/pad60px）后正文像素相同。此为读取新产物做内容比较，不以旧SHA结果替代新测试。
- 宽屏亮暗模型动作约110pt，图标/文字连续、scan/import紧邻，无原515pt空条；窄屏及readiness自然增长不退化。本轮呈现/布局回归限定PASS，不声称Mac GUI、真机、完整辅助技术、真实推理或签名发布通过。Metal toolchain搜索路径、未依赖AppIntents的metadata及Actions Node版本迁移警告仍有记录，不作虚假清零。

本验收记录是文档-only追加，不改Swift、工程、脚本或workflow。本地仅静态结构/链接/计数与diff检查；没有本地Xcode/Swift/UI执行。文档提交本身仍由main push触发新的完整云端run，结论必须再对齐其精确SHA，不能把上述代码run称作新的文档run。

## v3.5 设置工作台双栏回归

实施基线是最新`fc3d4a9` / run `39830013497` attempt1，完整包已下载核对138唯一Success、JUnit8/0failure/error/1 optional skip和三份xcresult（Data/refs 3/3、3/3、1068/1068）。这不是新代码的执行结果。本轮新增3项到141，原138项保留；设置整体宽度旧断言按新1104pt上限更新，既有toggle真实生产渲染补显式宽度参数。

- `testSettingsWorkspaceColumnsUseRealPaneWidthAndDynamicType`：所有DynamicTypeSize × 非法/窄宽/881.99/882/1042/4000，有限归零、单栏760上限、双栏320+24+至少538/最多760和守恒；918pt pane阈值、1366−288真实pane的1042/320/698、toggle扣28pt后仍可双列，大字回退。
- `testSettingsSectionsShellPreservesBothSectionIdentities`：真实foreground scene挂载生产shell，8组宽度/字号layout plan顺序切换；两节点的@State UUID各唯一、每次plan都被观察且各只appear一次、不disappear。条件expectation有界3秒，退出detach并恢复原key window；不sleep、不重试、不访问私有层级。
- `testSettingsSectionsReportNaturalHeightAndPreserveLocalState`：真实appearance/runtime section，亮暗 × 284/320/538/698/760pt × large/xxxLarge/accessibility3，偏好含导入中/普通态，公开UIHostingController.sizeThatFits的600/1800pt提议应得到同一自然高度，大字运行section严格增长；动作未调用、optimizer开关/准备度不变。旧readiness和动作自然高度矩阵不削弱。

宽屏宿主仍为真实1078×1024pt，设置provenance与exporter新增columns/1042/320/24/698守恒门禁；同一28图、OCR/hash、三份完整xcresult、JUnit8阶段及review小包不减。本轮云端要实际核对设置亮暗双栏、iPhone与iPad窄pane单栏、大字不裁剪和运行开关完整可达，不以尺寸或OCR单独宣布视觉通过。宿主图不是Mac GUI。

本地只跑diff/plutil/YAML/bash-n/Python AST、141唯一方法/文档链接/fence/预存prompt hash和范围检查；不运行Swift/Probe/Fast、Xcode、XCTest、Simulator、ImageRenderer、Vision或Catalyst。完整执行及本轮图片验收等待本提交自己的main云端run。


## v3.5.1 焦点测试宿主窗口就绪（2026-10-23，待自身云端验收）

v3.5 `a28ac41` / run `39885347849` attempt1 的结果包为140/141成功，唯一失败是首次composer request已消费但实际UITextInput未聚焦；设置三项新增测试、iOS/Catalyst构建及28图成功，整轮退回。测试宿主由600x120pt改用已有foreground scene的真实bounds，先以普通container建立key/visible窗口，再以公开child containment挂载带预存request的原生产ComposerBar；内容随可用宽度收缩、最多560pt。保持2秒有界条件、首次/离页/重进严格first-responder及清理断言，增加窗口与宿主尺寸诊断，不改生产同步焦点、设置状态或runtime/verified边界。

单Agent串行，无子智能体；本地仅diff/工程/YAML/结构检查，141项及全部构建运行截图只交GitHub Actions。最新SHA自身manifest、JUnit、完整三份xcresult和28图须复判，不提前宣称通过或发布就绪。


## v3.5.2 云端模拟器截图正文门禁（2026-10-23，待自身云端验收）

人工复看v3.5完整包发现iPhone亮色设置图空白、iPad暗色聊天图为桌面，旧固定3秒采集不能作为通过证据。`Tools/ValidateWorkbenchScreenshot.swift`作为独立CLI仅在真实GitHub Actions编译运行，公开Vision OCR要求目标工作区正文marker；`capture_workbench.py`在launch后有界5次/每次2秒采集并验证，失败使必选visual失败，manifest保留识别全文、marker、次数、PNG尺寸和SHA-256。原16模拟器图、12宿主图、141项及三份xcresult不减少；OCR后仍需人眼检查。无生产UI/状态/runtime/verified变更，AITRANS不修改，无子智能体，本地仅静态检查。
