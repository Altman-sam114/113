# AGENTS.md

本文是本项目的入口记忆、总览、基本规则和多 Agent 迭代工作流。后续任何 Codex / Agent 进入项目后，先读本文，再读项目核心文档和相关源码。

## 1. 项目一句话总览

`Local Gemma iOS Prototype` 是一个 SwiftUI iOS 原型 App，用本地模拟 runtime 验证 iPhone 端侧部署 Gemma 1.5B 的产品交互、模型文件管理、artifact 校验、会话导出、横屏布局、相册壁纸和 Apple Silicon 运行计划；当前不下载模型权重，不执行真实模型推理。

## 2. 必读文件顺序

每轮工作开始前按顺序阅读：

1. `AGENTS.md`：入口规则、多 Agent 工作流、禁止项。
2. `update_log.md`：版本记录、历史决策、完成事项、遗留问题。
3. `md/flow/flow.md`：当前真实架构、核心数据流和执行流。
4. `md/flow/flowchart.md`：核心流程 Mermaid 图，给人工快速理解逻辑。
5. `md/test/test.md`：测试分层、命令、触发条件、当前基线。
6. `README.md`：用户可读说明、运行方式、功能范围和验证记录。
7. 与任务相关的源码和测试：通常是 `LocalGemma/AppState.swift`、`LocalGemma/ContentView.swift`、`LocalGemmaTests/LocalGemmaTests.swift`、`Tools/LogicSmoke.swift`。

开始工作前必须执行或等价确认：

```sh
git status --short
git log --oneline --decorate -n 12
```

如果工作区已有改动，不要回滚或覆盖。先判断是否是用户或其他 Agent 的改动，再决定如何协作。

## 3. 项目基本规则

- 以当前 worktree、测试结果、核心文档和实际运行表现为准，不依赖记忆猜测。
- 不自动下载 Gemma 或其他模型权重。
- 不引入云端推理，不把提示词、上下文或会话发送到外部服务。
- 不把 `manual-import-required` 的 artifact 当成真实可运行权重。
- 只有 artifact `verified` 后，才允许真实 runtime 路径暴露为可运行。
- 每次代码变更后，必须同步更新测试、测试规范、核心流程文档、流程图、`README.md` 和必要的 `update_log.md`。
- 文档-only 变更也要说明为什么未跑完整测试，并至少做结构/内容校验。
- 不伪造测试结果；没有跑就写未跑及原因。
- 不做无关重构；大文件拆分必须有清晰收益，并保证 Xcode target 正确。

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
- `WorkspaceLayoutMode` 控制竖屏/横屏主布局；横屏逻辑要有测试锁住。
- `WallpaperImageProcessor` 控制相册壁纸压缩和尺寸，避免大图直接进入 `AppStorage`。
- `ExportPayload` 和导出视图必须处理 Markdown 文件不存在时的文本分享兜底。

## 5. 标准迭代工作流

本项目按“人工目标 -> Agent A 设计提示词 -> Agent B 实现测试 -> Agent C 验收并更新核心逻辑文档 -> 人工复核 -> 下一轮”循环推进。

### 人工

人工提出目标，可以同时给出功能、算法框架、禁止项、验收标准、性能要求、UI/交互要求和测试要求。人工把当前目标交给 Agent A。

### Agent A：目标分析与提示词

Agent A 默认不写代码，负责把人工目标转成 Agent B 可执行的详细提示词。

Agent A 必须：

1. 阅读 `AGENTS.md`、`update_log.md`、`md/flow/flow.md`、`md/flow/flowchart.md`、`md/test/test.md`。
2. 阅读相关源码、测试和 README。
3. 明确目标、非目标、边界、依赖、风险和验收标准。
4. 设计实现方案，包括模块、数据流、状态流、接口、测试、旧逻辑保护。
5. 分配版本号：人工指定则使用人工版本；否则从 `v0.1` 开始递增。小修小补用 `v0.2`、`v0.3`，里程碑用 `v1.0`。
6. 写 Agent B 提示词到 `md/prompt/v0（简要标题）/v0.1（简要说明）.md`。

Agent A 提示词必须包含：版本号、版本分配依据、背景、目标、非目标、当前架构依据、实现步骤、关键文件、测试要求、文档更新要求、验收标准、风险和禁止项。

### Agent B：实现与测试

Agent B 按 Agent A 提示词实现。

Agent B 必须：

1. 阅读 Agent A 提示词。
2. 阅读 `AGENTS.md`、`update_log.md`、`md/flow/flow.md`、`md/test/test.md`。
3. 阅读相关源码和测试。
4. 小步实现，不做无关重构。
5. 新增或修改测试。
6. 按 `md/test/test.md` 选择测试层级。
7. 运行测试并记录命令和结果。
8. 更新必要文档。
9. 输出改动、关键文件、测试命令和结果、未跑测试原因、已知风险和后续建议。

Agent B 不得：绕过核心规则直接改状态、擅自扩大范围、删除旧实现、用“已验证”代替具体测试结果、伪造测试通过、回滚用户或其他 Agent 的改动。

### Agent C：验收与核心逻辑更新

Agent C 验收 Agent B 结果，并更新核心逻辑文档。

Agent C 必须：

1. 阅读 Agent B 输出和实际 diff。
2. 核对测试结果。
3. 阅读 `AGENTS.md`、`update_log.md`、`md/flow/flow.md`、`md/test/test.md`。
4. 判断实现是否满足 Agent A 提示词和人工目标。
5. 检查架构边界、测试覆盖、文档同步、未说明风险。
6. 基于新实现更新 `md/flow/flow.md`。
7. 更新 `md/flow/flowchart.md` Mermaid 图。
8. 如形成正式版本或重要历史事项，更新 `update_log.md`。
9. 输出通过/不通过、问题清单、已更新文档和建议下一步。

Agent C 不通过时，回到 Agent B 修复；通过后交给人工复核。

## 6. 测试规则

测试入口是 `md/test/test.md`。后续 Agent 每次实现前必须读它，并根据改动范围从小到大选择测试层级。

最低要求：

- 文档-only：检查文档链接、目录结构、关键命令和事实一致性；说明未跑 XCTest 的原因。
- 逻辑改动：至少跑 Probe / Fast 和相关 XCTest。
- 状态流、模型文件、导出、布局、壁纸、分享改动：至少跑 Stage Regression。
- 影响 App 启动、Xcode 工程、共享状态或跨模块行为：跑 Full。

所有测试记录必须包含实际命令和结果，不得只写“测试通过”。

## 7. 文档规则

每次完成正式版本或重要任务后，必须同步：

- `update_log.md`：版本/任务名、日期、核心变更、关键文件、验证结果、遗留事项。
- `md/test/test.md`：新增测试、测试数量、触发条件、当前基线变化。
- `md/flow/flow.md`：当前真实逻辑，不写历史废话。
- `md/flow/flowchart.md`：与 `flow.md` 同步的 Mermaid 流程图，每张图前有中文读图说明，每个逻辑块有中文注释。
- `README.md`：用户可读功能范围、运行方式和已完成验证。
- `md/prompt/`：Agent A 每轮提示词按版本归档。

README 过期视为 bug。测试数量、命令、功能边界和真实模型状态必须保持一致。

## 8. 交付格式

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

如果是 Agent A，交付 Agent B 提示词路径和本轮版本号。
如果是 Agent B，交付实现结果和测试结果。
如果是 Agent C，交付验收结论、问题清单和已更新文档。

## 9. 禁止项

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

