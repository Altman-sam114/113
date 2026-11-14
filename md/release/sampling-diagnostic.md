# 270M 采样对照

固定用户现有 Gemma 3 270M 与[既定十任务](../../Tools/fixtures/task_quality_270m.json)，比较生产 greedy 与 AITRANS `ModelDecodingProfile.sampled`：topK40 → topP0.90 → minP0.05 → temperature0.2 → dist。无 repetition penalty。AITRANS 通常随机选 seed；本实验在执行前声明 42、1337、2026，四组各完整十例，共40条，不挑选最好种子。

## 范围与冻结

[profiles](../../Tools/fixtures/sampling_profiles_270m.json)保留参考 commit/路径/文件摘要及全部参数。模型为241410624字节，SHA-256 `3626e245220ca4a1c5911eb4010b3ecb7bdbf5bc53c79403c21355354d1e2dc6`。原任务文件、完整模板/输入、评分标准、4096上下文与512输出预算均保持不变；不以加载成功代替答案质量。

[云端入口](../../.github/workflows/sampling-diagnostic.yml)只接受精确 main SHA 和临时私有加密draft。使用独立一次性secret `LOCALGEMMA_SAMPLING_FIXTURE_KEY`，模型及密钥不进入源码或结果；全部Swift/Catalyst编译和实际模型执行仅GitHub-hosted macOS。完成后由发起者核对并删除仅本实验的draft/asset/secret，本机密文用trash回收。

[Python诊断](../../Tools/native_sampling_diagnostic.py)严格核验生产runtime SHA，仅替换唯一sampler创建点，并保存原源、生成副本、单点diff和摘要。其余加载、内嵌模板、tokenizer、UTF-8、上下文、取消与内存门禁不改。greedy组调用原greedy；另外三组使用同一个[诊断factory/probe](../../Tools/NativeSamplingProbe.swift)。该文件只被云端命令行编译，不注册App target。

## 结果合同

结果必须绑定同SHA/run/attempt，包含四份原始报告、每组十条完整prompt/text/error、原生指标、EOS/输出上限、所有原始日志、冻结定义、源副本及依赖manifest。进程每完成一例原子保存报告，失败或超时保留已取得证据且继续其他固定profile；缺例或错误证据不能通过验证。

自动复核与原十任务使用同样NFKC/casefold事实组及严格输出标准，不新增更宽松评分。任一sampled组事实检查失败，工作流非零失败并上传全部结果。自动通过后仍需逐条按原rubric人工语义审读，记录遗漏、否定、编造、重复和截断，不能把最好一次结果当稳定质量。

这是隔离采样诊断副本，未修改App生产默认，也没有经过ModelCatalog/InferenceEngine或UI；不伪造productionFlow。它不能取代[现有失败的生产质量门禁](task-quality.md)，也不证明真机Metal/内存、Files、辅助技术或签名发行。只有结果支持采用时，才另行实现生产变更并验证实际生产链路。当前尚无本实验云端结果。

本机只运行Python负夹具与文本/JSON/YAML检查；负夹具须拒绝缺组/缺例、改prompt/seed/标准、错误模型/运行身份、模拟正文、非有限指标和将诊断冒充生产验收。
