# 本地文本推理

用户已选择 AITRANS 中现有的 `Gemma 3 270M` 作为首个正式可导入模型。生产 App 保持模拟模型作为初始选择；只有指定 GGUF 通过可信摘要校验后，发送消息才进入 `VerifiedLlamaRuntime` / `LlamaTextRuntime`，失败显示实际错误，不回退成模拟回答冒充成功。270M 使用新 UUID，不继承原 1B 目录项的信任，不自动删除旧文件。

## 手动导入

1. 在模型页选择 `Gemma 3 270M`，阅读官方许可与使用限制并确认有权使用。
2. 使用已取得的 `gemma-3-270m-it-qat-Q4_0.gguf`，通过 Files 导入。App 不下载模型，GGUF 不随安装包提供。
3. 等待本机复制和 SHA-256 校验为 `verified`，再回到聊天发送消息。模拟部署开关只影响预览计划，不加载模型。

固定文件来自用户明确提供的 AITRANS `llm/` 目录，只读核对 SHA-256 `3626e245220ca4a1c5911eb4010b3ecb7bdbf5bc53c79403c21355354d1e2dc6` 和大小 `241410624` 字节。该摘要是受信的本地文件版本，不伪称已追溯的官方 GGUF 发布 revision。App 的 [Gemma 模型说明](https://ai.google.dev/gemma/docs/core/model_card_3)是背景文档，不是该文件下载来源。许可：[Gemma Terms](https://ai.google.dev/gemma/terms)，[使用限制](https://ai.google.dev/gemma/prohibited_use_policy)。这些链接仅由用户主动打开，不附带对话或文件；确认是否有权使用仍由用户负责。

## 实现与失败边界

- 使用[固定 llama.cpp 依赖](runtime-dependency.md)，不调用网络推理。iOS device 链接原生库；Simulator / Catalyst 使用真实编译的 CPU slice。App 使用独立暂存产物，Catalyst 采用 `Versions/A`、`Resources/Info.plist` 和受限的内部别名；不修改已校验的编译缓存或二进制。CPU 验证不能证明真机 Metal、可用内存或热状态。
- 原生 worker 串行执行，逐次拥有模型、上下文和采样器；退出前同步并释放。文件通过无符号链接的只读描述符重新验摘要并检查文件身份，校验不依赖先前 UI 状态。
- 使用模型内嵌 tokenizer 和受支持的 chat template，保留有序完整正文。上下文不足时明确拒绝，不静默裁剪；最多 4096 context tokens、512 output tokens，输出限额不冒称自然结束。
- 流式 UTF-8 不显示半个字符。停止、会话切换、模型切换、文件失去 verified 或进入后台时取消工作；generation/session identity 阻止迟到事件写回另一会话。
- 只有实际原生输出或有效完成事件才设置 REAL。速度与输出 tokens 来自原生计数；速度为输出 tokens 除以 prefill + generation 耗时（不含加载），避免单 token 回答仅用采样耗时而夸大速度。未测量的内存/CPU不编造数值。模拟模型继续显示模拟状态。
- iPhone/iPad 使用实时 App 可用内存门禁；Catalyst 的该 API 返回零，因此使用明确的物理内存最低预算，不能冒称桌面实时可用内存。两者均为保守入场估算，不能保证一定能加载。尚未实际验证的模型/设备不能标为已支持或发布验收通过。

## 生产 270M 云端验收

`Real Native Text Smoke` 是独立、仅手动触发的云端入口，必须与生产登记的270M文件名、摘要、大小和模型 UUID 一致。保留底层实际加载、多轮记忆、真实 token 指标、限额、取消后重新加载与超长上下文拒绝；另以同一生产 ModelCatalog 导入真实文件，再经 VerifiedLlamaRuntime / InferenceEngine 验证缺文件草稿保护、verified、两轮真实回答与导出、实际正文后停止/会话隔离/重载、校验后文件变更的拒绝与重新导入恢复、完整长问题超限拒绝。

新增的是无 UI 的生产状态链路，不模拟许可同意或 Files 点按，不能声称已做 UI 文件选择、真机或完整模型质量评测。证据分别记录每个门禁、实际正文/token/速度和模型身份；Python 负夹具拒绝把旧底层 fixture 包、缺少导入/停止/恢复的部分结果、模拟回答或错误指标当成生产验收。新 SHA 实际云端结果完成前，旧 d6532b7 只证明当时底层270M测试，不证明本次模型接线通过。

测试材料在公开仓库中仅以加密、未发布草稿资产保存，密钥通过单独的一次性 GitHub secret 提供；任务后清理。工作流拒绝公开 release、其他文件名、尺寸或摘要，结果包只包含测试输出和指标，不含模型或密钥。没有运行成功的精确 SHA/run 及完整结果核对前，本入口只表示验证能力。

270M CPU 通过不证明未登记1B、真机内存/Metal、长时间故障耐久、通用任务质量、签名发行或商店审核通过。手机 UI 入口另验证普通/AX5 的真实270M许可审阅与取消，不替用户自动同意条款、不选择权重；仍保留十个方法/30图。剩余范围见[发布检查表](checklist.md)。

发送/停止、模板直接发送、欢迎页与会话说明同时区分本地推理和模拟预览：真正发送只允许已登记且 verified 的权重；填入、浏览和文件工作流不启动推理。手机许可诊断使用手动 `validation_scope=license`（2项/4图），结果明确不代表完整10项/30图。
