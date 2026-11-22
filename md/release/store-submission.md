# AgentX 商店提交资料

## 商店文案

| 字段 | 内容 |
| --- | --- |
| 名称 | AgentX |
| 副标题 | 本地对话与写作模板 |
| 类别 | 效率 |
| 支持网址 | [AgentX 使用帮助](https://github.com/Altman-sam114/113/blob/main/md/release/support.md) |
| 隐私政策网址 | [AgentX 隐私政策](https://github.com/Altman-sam114/113/blob/main/md/release/privacy.md) |
| 反馈入口 | [AgentX 公开问题区](https://github.com/Altman-sam114/113/issues) |

AgentX 是一款本地文字对话工作台。可以整理会话、保留未发送的草稿、预览和使用提示词模板，以及复制消息或导出 Markdown。

安装后可先使用模拟预览。要使用本地模型，在模型库查看许可并自行取得指定的 Gemma 3 270M GGUF，再从“文件”导入。校验通过后，模型在设备上生成文字。App 不含模型权重，也不会在后台下载权重。

重要信息请自行核对。卸载 App 前，可以先导出需要保留的对话，并保留模型原件。

## 审核复现顺序

1. 首次打开可浏览对话、模板、模型库与设置。模拟预览会明确标识。
2. 在模型库选择 **Gemma 3 270M**，展开“模型许可与固定版本来源”。阅读许可后，从固定网页将指定 GGUF 保存到设备的“文件”。[固定文件页](https://huggingface.co/ggml-org/gemma-3-270m-it-qat-GGUF/blob/7dba9faa7cdb58c7dc44b238c7dbb00e391fbf65/gemma-3-270m-it-qat-Q4_0.gguf)
3. 点按“导入模型文件”，确认模型许可，再选取该文件。等待显示“已校验”。文件约 241 MB，设备还需要上下文和计算内存。
4. 回到对话，发送简短消息。验证流式文字、继续对话、停止、复制和导出。到设置中的“关于、隐私与帮助”查看数据保留与删除方式。

## 出包与提交前核对

- 设备包需由 Xcode 26 或更高版本用 iOS 26 或更高版本 SDK 构建。工程当前最低系统为 iOS 17。[Apple SDK 与最低系统要求](https://developer.apple.com/news/upcoming-requirements/)
- 隐私标签拟填 **不收集数据**、**不跟踪**。提交者须用实际签名包核对 `PrivacyInfo.xcprivacy`、内嵌框架、系统分享与自定义壁纸行为。[Apple App 隐私详情](https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy)
- 商店截图取最终候选在真实支持设备上的界面。优先覆盖聊天、模板预览、模型导入和设置。模拟预览中的正文或速度不可作为真实模型输出示例。
- `com.localgemma.prototype` 是现有工程标识。正式发布前需确认该标识可用于目标 App Store Connect 记录，再确定正式 build number、签名和分发配置。在 App Store Connect 填写审核联系人、年龄分级、出口合规、适用的地区主体信息及目标销售区域。[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- 当前 270M 十项日常任务的人工复核仍未达到放行门槛。真机文件选择、实际推理、VoiceOver、后台恢复与签名安装仍需按最终候选验证。[发布检查表](checklist.md) · [质量复核](task-quality.md)
