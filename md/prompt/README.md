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
