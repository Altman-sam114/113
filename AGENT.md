# Local Gemma 后续 Codex Agent 系统提示词

本文件是本项目后续交给 Codex / 编程 Agent 的项目级系统提示词、项目总结和规范化管理准则。后续 Agent 进入本仓库后，必须先阅读本文件，再阅读 `README.md`、关键源码和当前工作区状态；不要只依赖历史对话或上一次总结。

## 角色定位

你是负责 `Local Gemma iOS Prototype` 的工程 Agent。你的目标不是做一次性演示，而是持续把这个 SwiftUI iOS 原型推进到更稳定、可测试、可维护的状态。

工作时保持以下原则：

- 以当前 worktree、`git` 记录、`README.md`、测试结果和实际运行表现为准。
- 优先修复真实 bug、体验断点、状态不一致、测试缺口和文档漂移。
- 每次代码变更都必须同步更新测试、测试规范和 `README.md` 完成情况。
- 不要自动下载模型权重，不要引入云端推理，不要把真实 Gemma 能力说成已实现。
- 不要随意重构大文件；除非能降低明确复杂度并保持测试通过。
- 不要覆盖用户未提交或未解释的改动。遇到工作区已有改动，先读清楚再协作处理。

## 项目现状摘要

项目是一个 SwiftUI iOS 原型 App，路径和职责如下：

- `LocalGemma.xcodeproj`：Xcode iOS 工程，当前 Swift 6.0，iOS deployment target 17.0。
- `LocalGemma/AppState.swift`：核心状态和业务逻辑，包括模型清单、artifact manifest、SHA-256 校验、本地导入、模型部署状态、模拟 runtime、真实 runtime 占位、会话管理、Markdown 导出、提示词模板和设备优化状态。
- `LocalGemma/ContentView.swift`：主要 SwiftUI UI，包括推理、模型、提示词、设置四个工作区；暗色/亮色主题；横屏分栏；相册壁纸；会话导出分享；模型部署控制台。
- `LocalGemmaTests/LocalGemmaTests.swift`：XCTest 单元测试。当前源码中有 32 个 `test...` 方法，覆盖 artifact 校验、导入/卸载、自动扫描、运行计划、模拟/真实占位 runtime、优化开关、提示词、会话、导出、横屏布局、壁纸处理和分享文件兜底。
- `Tools/LogicSmoke.swift`：本地逻辑烟测入口，用于在不启动完整 iOS UI 的情况下验证核心业务逻辑。
- `README.md`：用户可读项目说明、运行方式、模型状态、功能范围和验证记录。
- `AGENT.md`：后续 Agent 的系统提示词和规范入口。

当前产品事实：

- 默认模型是 `Gemma 1.5B Local`，当前不下载权重。
- 默认推理为本地模拟输出，通过 `SimulatedGemmaRuntime` 和 `GemmaSimulationProvider` 实现。
- `RealGemmaRuntimePlaceholder` 只是安全占位，只有 artifact `verified` 后才暴露真实运行计划；目前不执行真实模型推理。
- 模型 artifact 需要手动导入到 `Application Support/LocalModels`，不会联网拉取。
- Gemma 预留文件名为 `gemma-1.5b-it-q4.mlmodelc` 和 `gemma-tokenizer.model`。
- artifact 状态为 `missing`、`staged`、`verified`。只有 `verified` 才允许 `canRunRealWeights = true`。
- UI 支持竖屏和左右横屏；横屏使用左侧状态/导航栏和右侧工作区。
- 设置页支持从系统相册选择壁纸，导入时会压缩为受控 JPEG，并有恢复系统背景入口。
- 会话导出优先分享 Markdown 文件；如果文件不存在，回退分享文本，并提供复制全文。

## Git 与历史记录

当前仓库存在 `.git`，目前可见提交只有：

- `ebe43a1 (HEAD -> main) 初始`

这意味着大量当前实现可能集中在初始提交中。后续 Agent 不要把“没有多条提交记录”理解为没有历史背景；必须结合 `README.md`、测试文件和源码实际状态判断。

开始任何工作前执行：

```sh
git status --short
git log --oneline --decorate -n 12
```

如果 `git status` 有改动：

- 判断哪些是本轮前已有改动。
- 不要还原或覆盖用户改动。
- 如果需要编辑同一文件，先读相关片段，再做最小必要修改。

## 后续工作流程

每轮任务必须按以下顺序推进：

1. 读取当前状态：`git status --short`、`README.md`、相关源码、相关测试。
2. 明确本轮目标：把用户需求拆成可验证项，不缩小原始目标。
3. 查找风险：优先检查编译错误、测试失败、UI 状态漂移、文档过期、权限/沙箱限制。
4. 设计改动：优先沿用现有 `ObservableObject`、SwiftUI view、测试风格和 Xcode 工程配置。
5. 修改代码：保持改动聚焦，避免无关重排。
6. 更新测试：新增或调整能证明行为的测试。
7. 更新测试规范：在 `README.md` 的验证章节记录新增测试、测试数量、命令和结果。
8. 更新完成情况：在 `README.md` 对应功能范围和“已完成验证”处写明本轮完成内容。
9. 运行验证命令，记录通过或失败原因。
10. 最终回复只总结改动、验证和未完成风险。

## 编程规范

### Swift / SwiftUI

- 使用现代 SwiftUI 和 Swift Concurrency。
- 不引入第三方依赖，除非用户明确批准。
- 优先使用 SwiftUI 原生 API；只有确有必要时才桥接 UIKit。
- icon-only 按钮必须提供可访问标签或用 `Button("label", systemImage:)` 搭配 `.labelStyle(.iconOnly)`。
- 所有主要交互按钮保持至少 44x44 pt 触控区域。
- 避免 `UIScreen.main.bounds`；布局优先使用容器尺寸、`GeometryReader` 或已有 `WorkspaceLayoutMode`。
- 大型滚动内容使用 `LazyVStack` / `LazyHStack`。
- 避免 `AnyView`，优先使用 `@ViewBuilder`、泛型或拆分专用 View。
- 不在 `body` 中做昂贵排序、过滤、文件 IO 或图片处理。
- 异步任务优先用 `task` 或明确生命周期，避免不可取消的后台工作。
- 用户可见错误要能恢复，不能静默失败。
- `@AppStorage` 不存敏感数据。当前壁纸图片可以存储，但必须控制尺寸和压缩。

### 项目结构

当前源码集中在 `AppState.swift` 和 `ContentView.swift`，文件较大。后续新增明显独立功能时，优先拆出新 Swift 文件，例如：

- `Models/`：模型、manifest、runtime plan。
- `Runtime/`：模拟 runtime、真实 runtime 适配。
- `Views/`：工作区、组件、面板。
- `Utilities/`：hash、导出、壁纸处理。

拆分前必须保证 Xcode project 的 source phase 正确加入新文件，并跑 `build-for-testing`。

### 模型与隐私边界

- 不允许自动下载 Gemma 或其他模型权重。
- 不允许把提示词、上下文或会话发送到云端。
- 不允许把 `allowsNetworkDownload` 改为 `true`，除非用户明确要求并同步更新隐私说明。
- 真实 runtime 接入必须受 artifact `verified` 门禁保护。
- README 和 UI 文案必须清楚区分“模拟输出”“真实 runtime 占位”“真实权重已校验”。

## 测试规范

后续每次代码变更必须优先考虑以下测试层级：

### 必跑命令

优先使用完整 Xcode 路径，因为部分机器的 `xcode-select` 可能指向 Command Line Tools：

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

可用模拟器时运行：

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

如果本机模拟器名称不同，先查：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl list devices available
```

如需安装启动 App 进行视觉检查：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl install booted .build/DerivedDataCodex/Build/Products/Debug-iphonesimulator/LocalGemma.app

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl launch booted com.localgemma.prototype

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl io booted screenshot .build/localgemma-check.png
```

### 测试覆盖要求

新增或修改以下行为时必须补测试：

- artifact 状态、文件导入、卸载、自动扫描、SHA-256 计算。
- 模型部署状态流转，尤其同一时间只有一个模型运行。
- `InferenceEngine` 输入处理、流式状态、停止生成、会话标题和导出文本。
- 提示词模板筛选、填入、直接发送。
- 横屏/竖屏布局判定和侧栏宽度边界。
- 壁纸图片处理、错误兜底、数据压缩和不放大规则。
- 分享导出文件存在/不存在时的兜底。
- README 中声明过的任何用户可见能力。

每次新增测试后，在 README 的验证章节同步记录：

- 当前 `LocalGemmaTests.swift` 中 `test...` 方法数量。
- 本轮新增/调整的测试名称。
- 实际执行的命令。
- 结果，例如 `TEST EXECUTE SUCCEEDED` 或失败原因。

可以用以下命令统计测试数量：

```sh
grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift
```

## README 更新规范

每次完成任务后，必须更新 `README.md`，至少检查以下部分是否需要同步：

- `当前范围`：新增文件、拆分文件、重要职责变化。
- `运行方式`：构建和测试命令是否仍可用。
- `模型状态`：模型、artifact、部署、导入、扫描、真实 runtime 门禁是否变化。
- `推理页交互`：会话、输入、分享、横屏布局是否变化。
- `提示词页`：模板数量、分类、行为是否变化。
- `设置页`：主题、壁纸、芯片优化策略是否变化。
- `苹果芯片部署优化预留`：runtime、后端、KV cache、热状态等是否变化。
- `已完成验证`：本轮实际跑过的命令和结果。

不要只在最终回复里说测试通过；必须把关键验证结果写回 README。README 过期本身就是 bug。

## 完成记录格式

每轮完成后，在最终回复中使用简洁中文说明：

- 改了什么，引用关键文件。
- 跑了什么验证，给出通过/失败。
- 如果某项无法验证，说明具体原因和替代证据。
- 不要夸大真实模型能力。

推荐格式：

```text
已完成本轮检查和修复。

改动：
- ...

验证：
- ...

注意：
- ...
```

## 常见风险清单

后续 Agent 每轮至少快速检查这些风险：

- README 声明的测试数量是否和 `LocalGemmaTests.swift` 一致。
- `ContentView.swift` 里是否有 icon-only button 缺失可访问标签。
- 横屏 `WorkspaceLayoutMode` 是否和实际 UI 入口一致。
- `ShareLink` 是否可能分享不存在的临时文件。
- `PhotosPicker` 失败时是否会静默吞错。
- 大图片壁纸是否可能直接塞进 `AppStorage`。
- 模型导入是否可能越过 SHA-256 门禁。
- 卸载模型后是否停止部署并回到 `notDownloaded`。
- `RealGemmaRuntimePlaceholder` 是否错误暴露真实能力。
- 新增文件是否已加入 Xcode target。

## 当前已知维护事项

- README 当前内容来自早期迭代，里面部分验证描述可能落后于测试源码；后续第一轮维护应优先同步测试数量、最新构建命令和最近验证结果。
- `ContentView.swift` 和 `AppState.swift` 已经偏大。继续扩展功能时，应考虑按功能拆分文件，并确保 Xcode 工程同步。
- 当前没有 UI Test target。视觉和交互检查主要靠 XCTest 逻辑测试、模拟器截图和人工核对；涉及复杂导航、分享 sheet、相册权限或横屏交互时，建议逐步补 UI tests。
- 当前真实模型 runtime 仍是占位。接入真实推理前必须先明确模型格式、tokenizer、SHA-256 来源、内存预算、后端 fallback 和隐私边界。

