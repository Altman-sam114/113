# AGENTS.md

本文是本项目的入口记忆、总览、基本规则和多 Agent 云端迭代工作流。后续任何 Codex / Agent 进入项目后，先读本文，再读项目核心文档和相关源码。

## 1. 项目一句话总览

`Local Gemma iOS Prototype` 是一个 SwiftUI iOS 原型 App，用本地模拟 runtime 验证 iPhone、iPad 与 Mac Catalyst build/run 基线下端侧部署 Gemma 1.5B 的产品交互、模型文件管理、artifact 校验、会话导出、大屏双栏布局、Mac/iPad 工作区与会话命令菜单、提示词筛选辅助语义、相册壁纸和 Apple Silicon 运行计划；当前不下载模型权重，不执行真实模型推理，也没有原生 macOS target。

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
- `ModelLibraryLayoutMode` 控制模型页内部单栏/双栏；Mac/iPad 足够宽的模型部署工作流和窄屏回退要有测试锁住。
- `WorkspaceTab.shortcutKey`、工作区 command menu、会话 command menu、regular 侧栏说明、选择语义、composer 输入焦点/辅助语义和提示词分类筛选辅助语义锁住 Mac/iPad 工作区导航；改动快捷键、菜单、侧栏文案、输入焦点、提示词筛选或可访问性映射时必须同步测试。
- `WallpaperImageProcessor` 控制相册壁纸压缩和尺寸，避免大图直接进入 `AppStorage`。
- `ExportPayload` 和导出视图必须处理 Markdown 文件不存在时的文本分享兜底。
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
