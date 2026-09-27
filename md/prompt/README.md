# Agent 提示词归档规则

本文说明 `md/prompt/` 的目录用途、角色召唤约定和云端阶段 Agent A 提示词要求。

## 角色召唤

- `agenta`、`a:`、`A:`：召唤 Agent A。
- `agentb`、`b:`、`B:`：召唤 Agent B。
- `agentc`、`c:`、`C:`：召唤 Agent C。
- `agentx`、`x:`、`X:`：召唤 Agent X。
- 没有这些前缀时，按普通 Codex 任务处理；如果任务需要 A/B/C/X 边界，先提醒人工指定角色，或说明本轮按普通任务执行。

角色最终回复第一行：

- Agent A：`我是 Agent A。`
- Agent B：`我是 Agent B。`
- Agent C：`我是 Agent C。`
- Agent X：`我是 Agent X。`

## 归档路径

Agent A 每轮把给 Agent B 的提示词写入：

```text
md/prompt/v0（简要标题）/vX.Y（简要说明）.md
```

版本号优先使用人工指定版本；否则从 `update_log.md` 的最新版本继续递增。提示词文件名要能看出版本和主题，不要只写 `prompt.md`。

## Agent A 提示词必须包含

- 版本号和版本分配依据。
- 背景、目标、非目标。
- 当前架构依据，引用 `md/flow/flow.md` 和相关源码。
- 实现步骤、关键文件、状态流和旧逻辑保护。
- 测试要求：本地轻量检查、是否需要 Probe / Fast、云端 CI 期望。
- 文档更新要求：README、flow、flowchart、test、update_log 和必要 prompt。
- main 直推要求：Agent B 必须基于最新 `origin/main`，提交到 `main`，并 push 到 `origin/main`。
- CI 结果包要求：workflow、artifact 名称、manifest、JUnit、日志和 `.xcresult`。
- Agent C 验收标准：核对 `origin/main` 最新 commit、run id、run attempt、manifest、日志和失败摘要。
- 风险和禁止项，尤其是禁止下载模型权重、禁止云端推理、禁止绕过 verified 门禁。

## Agent X 循环提示词管理

Agent X 可以围绕人工总目标 X 要求 Agent A 为每一轮生成版本化 Agent B 提示词。Agent X 不直接替代 Agent A 写实现提示词，也不替代 Agent B 实现或 Agent C 验收。

Agent X 调度下的每轮提示词必须包含：

- 本轮版本号、总目标 X 中的当前小目标和版本分配依据。
- 本轮目标和非目标，说明不属于本轮的范围。
- 当前架构依据、关键文件、实现步骤和旧逻辑保护。
- 本地轻量检查命令，以及是否需要 Probe / Fast。
- 云端 CI 触发方式、artifact 命名和结果包最低内容。
- Agent C 验收要求：必须核对最新 `origin/main` commit、run id、run attempt、manifest、`artifact-name.txt`、JUnit、日志和 `.xcresult` 或等价结果。
- 失败处理：Agent C 不通过时退回 Agent B 修复；Agent X 不得跳过验收继续下一轮。
- 小数据量要求：不下载模型权重、大体积测试数据、历史 artifact 或无关产物。

## 云端阶段默认要求

Agent A 给 Agent B 的提示词要默认采用：

```text
本地轻量检查
  -> commit 到 main
  -> push origin main
  -> GitHub Actions 云端重验证
  -> Agent C 下载未加密结果包验收
```

除非人工明确要求，不默认让 Agent B 在本机跑完整 Xcode build 或模拟器 XCTest。若仓库没有 `origin`、没有 push 权限或没有 GitHub Actions 权限，Agent B / Agent C 必须报告阻塞，不能伪装云端验证完成。

在 Agent X 循环中，上述链路每轮都必须完整执行。Agent X 只能根据 Agent C 对最新 artifact 的验收结论继续、退回、暂停或完成。

## 禁止照搬的外部项目特例

本项目只复用 main 直推、云端 CI、未加密结果包和 Agent C 下载复判制度。不要把 AITRANS 的漫画探针、GGUF、模型 Release、`test/1.png`、`smalldata_test`、候选分支、PR 合并流或其他项目特例复制到本项目。

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


## v3.2 提示词页提示词

本轮直接修复 PromptTemplateGrid 的真实宽度列数选择；Agent B 应通过 main 云端 run 验收 iPhone/iPad 亮暗截图，并检查模板卡片在 Mac/Catalyst 宽窗口不再退回单列。


## v3.3 云端视觉采集稳定性（2026-09-27，云端待验收）

`Tools/capture_workbench.py` 的 `sim()` 为 GitHub Actions 上的 `xcrun simctl` 增加最多 3 次、有界 2 秒退避重试，并在最终失败时保留命令与 stderr；覆盖 boot、bootstatus、install、launch、screenshot 和 shutdown，解决 CoreSimulator 瞬态 launch denied 导致视觉阶段误失败的问题。仍只允许 `GITHUB_ACTIONS=true`，仍采集 iPhone/iPad × 亮暗 × 四工作区 16 张截图，不改变 App UI、状态流、模型文件、runtime 或 verified gate。

本地仅做 Python 语法和文本结构检查；构建、XCTest、Catalyst 和截图仍全部在云端执行。
