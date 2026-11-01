# 本地文本推理

生产 App 保持模拟模型作为初始选择，另提供 `Gemma 3 1B` 原生文本模型。只有指定 GGUF 通过可信摘要校验后，发送消息才进入 `VerifiedLlamaRuntime` / `LlamaTextRuntime`；失败时显示实际错误，不回退成模拟回答冒充成功。

## 手动导入

1. 在模型页选择 `Gemma 3 1B`，阅读官方许可与使用限制并确认有权使用。
2. 自行取得固定版本的 `gemma-3-1b-it-Q4_K_M.gguf`，通过 Files 导入。App 不下载模型，GGUF 不随安装包提供。
3. 等待本机复制和 SHA-256 校验为 `verified`，再回到聊天发送消息。模拟部署开关只影响预览计划，不加载模型。

固定来源：[`ggml-org/gemma-3-1b-it-GGUF`](https://huggingface.co/ggml-org/gemma-3-1b-it-GGUF/tree/f9c28bcd85737ffc5aef028638d3341d49869c27)。SHA-256：`8ccc5cd1f1b3602548715ae25a66ed73fd5dc68a210412eea643eb20eb75a135`，文件大小 `806058240` 字节。许可：[Gemma Terms](https://ai.google.dev/gemma/terms)，[使用限制](https://ai.google.dev/gemma/prohibited_use_policy)。这些链接由用户主动打开，不附带对话或文件。

## 实现与失败边界

- 使用[固定 llama.cpp 依赖](runtime-dependency.md)，不调用网络推理。iOS device 链接原生库；Simulator / Catalyst 使用真实编译的 CPU slice。App 使用独立暂存产物，Catalyst 采用 `Versions/A`、`Resources/Info.plist` 和受限的内部别名；不修改已校验的编译缓存或二进制。CPU 验证不能证明真机 Metal、可用内存或热状态。
- 原生 worker 串行执行，逐次拥有模型、上下文和采样器；退出前同步并释放。文件通过无符号链接的只读描述符重新验摘要并检查文件身份，校验不依赖先前 UI 状态。
- 使用模型内嵌 tokenizer 和受支持的 chat template，保留有序完整正文。上下文不足时明确拒绝，不静默裁剪；最多 4096 context tokens、512 output tokens，输出限额不冒称自然结束。
- 流式 UTF-8 不显示半个字符。停止、会话切换、模型切换、文件失去 verified 或进入后台时取消工作；generation/session identity 阻止迟到事件写回另一会话。
- 只有实际原生输出或有效完成事件才设置 REAL。速度与输出 tokens 来自原生计数；速度为输出 tokens 除以 prefill + generation 耗时（不含加载），避免单 token 回答仅用采样耗时而夸大速度。未测量的内存/CPU不编造数值。模拟模型继续显示模拟状态。
- iPhone/iPad 使用实时 App 可用内存门禁；Catalyst 的该 API 返回零，因此使用明确的物理内存最低预算，不能冒称桌面实时可用内存。两者均为保守入场估算，不能保证一定能加载。尚未实际验证的模型/设备不能标为已支持或发布验收通过。

## 用户提供的 270M 云端测试材料

`Real Native Text Smoke` 是独立、仅手动触发的云端入口，不改变生产模型目录或 verified 门禁。使用用户明确提供的 `gemma-3-270m-it-qat-Q4_0.gguf`（`241410624` 字节，SHA-256 `3626e245220ca4a1c5911eb4010b3ecb7bdbf5bc53c79403c21355354d1e2dc6`），检验同一生产底层实现的实际加载、多轮记忆、真实 token 指标、限额、取消后重新加载与超长上下文拒绝。

测试材料在公开仓库中仅以加密、未发布草稿资产保存，密钥通过单独的一次性 GitHub secret 提供；任务后清理。工作流拒绝公开 release、其他文件名、尺寸或摘要，结果包只包含测试输出和指标，不含模型或密钥。没有运行成功的精确 SHA/run 及完整结果核对前，本入口只表示验证能力。

270M 测试通过也不证明生产 1B 权重、真机内存/Metal、长时间故障耐久、签名发行或商店审核通过。手机 UI 入口另验证普通/AX5 的真实许可审阅与取消，不替用户自动同意条款、不选择权重；原八个交互测试与26图保留，增加到十个方法/30图。剩余范围见[发布检查表](checklist.md)。
