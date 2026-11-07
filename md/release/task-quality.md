# 270M日常任务质量验证

本入口补足ORCHID记忆/停止恢复之外的任务行为证据，不把加载成功当成润色、总结、翻译和计划质量通过。用户指定的270M、许可和可信摘要不变，不下载其他模型，不修改AITRANS，不改变App的初始模拟预览或verified门禁。

## 输入与执行

[固定案例](../../Tools/fixtures/task_quality_270m.json)包含四个生产日常模板各两例和中英文精确指令两例，共十例。全部输入为预先写定的合成内容；每例冻结应保留的原文事实和人工语义标准，不读取用户会话。测试用ModelCatalog真实导入、VerifiedLlamaRuntime与InferenceEngine，实际调用PromptTemplateLibrary和applyTemplate，保持产品4096上下文/512输出及默认greedy sampler，不为过关更换成简单提示词、降低长度或注入回答。

[原生工作流](../../.github/workflows/native-text-smoke.yml)可选输入include_task_quality默认false；设为true时保留原生产smoke全部断言，再执行十项任务。仍只在GitHub-hosted macOS运行，使用用户已授权、SHA固定的临时加密模型draft和一次性secret，原模型/密钥不进入结果包。

## 结果与门槛

probe.json的taskQuality保存每例实际prompt、完整回答、token数/速度、总耗时、后端、错误和runtime状态文字。结果同时保存固定案例原件与task-quality-checks.json；身份绑定精确SHA/run/attempt/模型及案例文件SHA-256。旧底层probe、缺例/重复/改序、模拟输出、被替换的生产模板、无效指标或错模型都不能充当新质量证据。

自动检查只覆盖指定事实词、精确格式和真实runtime成功。任一失败会使本次质量run失败，全部原始回答和失败仍保存；不能用生产smoke成功抵消。即使自动检查通过，也保持manualReviewRequired=true和generalTaskQualityVerified=false：事实词出现不证明否定含义、依赖顺序、忠实性或表达质量。

人工须按每例rubric逐条核对指令遵循、原文事实、未经支持的补充和可读性，记录完整原文及失败原因。不得在看过输出后放宽原标准、删例或把模型不适用改写成通过。十个固定案例只能支持这些任务的有限结论，不证明通用质量、真机Metal/内存/热状态、Files点按、辅助技术、耐久或签名发行。

## 独立上游诊断

质量profile另编译固定b12032原件examples/simple/simple.cpp，保留MIT许可和源码摘要，使用同一CPU framework及同一模型，对英译中和2+3两个冻结案例走独立C++ batch/process路径。原样保存stdout/stderr并严格核对完整prompt echo后提取回答。上游例子使用自己的batch/context默认值，差异或一致都只作根因诊断，不能替代生产质量门禁或证明真机等价；不改案例、回答或评分标准。全部C++执行仍仅云端。

## 当前状态

入口和纯Python拒绝夹具已实现，实际云端任务与人工语义审读仍待本轮新SHA结果。既有561866b未签名候选保持原证据和限制，不提前继承新入口的质量结论。结果收口后将实际run和逐项结论记入[更新记录](../../update_log.md)与[发布检查表](checklist.md)。
