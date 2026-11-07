# 手机后台终止与会话恢复

本入口补足真实生产界面的进程生命周期证据，不把同一进程中创建第二个InferenceEngine当作App重启。它不消除已记录的270M任务质量失败，不代替真机断电、SIGKILL、磁盘满、Metal或签名发行验收。

## 操作与范围

[现有手机工作流](../../.github/workflows/iphone-interaction.yml)的full范围保留原10项/30张原图，新增普通/AX5各一项，共12个唯一XCUITest、36张XCUIScreen原图及各自provenance。license诊断仍只运行原两项/四图，不能替代full。

新增测试只经生产UI新建两会话，键入不同且保留首尾空格的草稿，读取实际历史行的稳定会话标识，切回第一会话追加修改。随后经公开Home动作观察App进入后台、XCUIApplication.terminate后确认notRunning、重新launch并确认foreground。重启后首先核对原活动会话和最终草稿，再切到第二会话核对独立草稿。历史选择动作仍须实际可见、hittable且至少44pt，输入通过真实tap/type完成；不操作App容器，不注入内存、文件或保存状态，不发送prompt或导入模型。

测试在终止前已经经过真实导航和可见状态观察，不证明任意时刻强杀都保留尚未提交的最后一次按键。terminate是公开测试API的终止动作，不称为断电或已验证SIGKILL。结果只绑定所记录云端Simulator/普通与AX5系统字号。

## 证据门禁

每种字号新增三张原始截图：后台前、重启后第一会话、重启后第二会话。provenance保留累计实际动作、后台/notRunning/foreground观察、两条不同的生产会话ID、当前选择与未经trim的原草稿、composer可用性和屏内几何；明确physicalDeviceDurabilityVerified=false、realInferenceVerified=false、signedDistributionVerified=false。

导出器要求截图/provenance来自对应新增测试，跨三图的会话ID和动作前缀连续。Python拒绝夹具覆盖缺生命周期、事件改序、错ID、截断/trim草稿、容器注入及把测试升级为真机耐久。原单元212项、完整CI的66图和原手机全部方法/原图不删、不skip、不放宽。

## 验证状态

新增实现尚待自身SHA云端执行和完整原包/实际看图。只能将通过的精确结果回录为这项限定范围的生命周期证据，不提前填写发布通过。
