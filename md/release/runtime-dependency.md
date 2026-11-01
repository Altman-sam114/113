# 固定版本本地推理依赖

该入口只准备 native 文本推理依赖，不下载任何模型权重，不运行模型、不联网推理，也不构成发布或真实模型验收。所有 CMake、Clang、Xcode、Mach-O 平台验证和链接检查只在本仓库的真实 GitHub-hosted macOS runner 执行；不得在本机伪造环境变量运行。

## 固定输入

- 上游：[ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)，tag `b12032`，源码 commit `dde879bc4f954b809892fd0d660515f42536394a`。
- 源码 URL：`https://codeload.github.com/ggml-org/llama.cpp/tar.gz/dde879bc4f954b809892fd0d660515f42536394a`。
- 源码 tar.gz SHA-256：`83f099b6bbb531ca72d22cdd76d86641438469a214fd49a38f026c6a868598ed`。
- 官方二进制：`https://github.com/ggml-org/llama.cpp/releases/download/b12032/llama-b12032-xcframework.zip`。
- 官方 ZIP SHA-256：`ac8244300899cb619d3725a95caf101e853050d7ddb016dc343b01816545ad6e`。此摘要也与 GitHub release asset API 的 digest 对齐；不跟随 latest/tag 浮动版本。

下载只允许上述两项固定输入，逐个重定向限定 HTTPS 和 GitHub 官方文件主机；解包前检查路径、重复条目、总大小及文件类型。源码不允许 symlink/hardlink/special file。官方 b12032 ZIP 的真实元数据仅含 iOS device 与 macOS，不含 Simulator 或 Catalyst；脚本只提取不含链接的 iOS device slice，不解包和复用其 versioned macOS framework。

## 产物与平台

云端执行 `PYTHONDONTWRITEBYTECODE=1 python3 Tools/prepare_llama_dependency.py`，输出 `.runtime/llama.xcframework`，C module 名为 `llama`：

| 变体 | 架构 | 来源 / 后端边界 |
| --- | --- | --- |
| iOS device | arm64 | 官方固定摘要的动态 framework，包含 upstream CPU/Metal/Accelerate 实现 |
| iOS Simulator | arm64、x86_64 | 同一固定源码构建，CPU-only；不以缺失的官方 Simulator slice 或 macOS 二进制冒充 |
| Mac Catalyst | arm64、x86_64 | 同一固定源码构建，CPU-only；禁用 Metal、Accelerate、BLAS、OpenMP、mtmd、网络工具、子进程和动态后端加载 |

Simulator 使用 Simulator SDK 和真实 `arch-apple-ios17.0-simulator` 目标；Catalyst 使用 macOS SDK 和真实 `arch-apple-ios17.0-macabi` 目标。两者逐架构编译 CPU-only 静态库，链接成动态 `llama.framework`，生成各自 dSYM 并与官方 device 合成三变体 XCFramework。脚本检查 Mach-O `LC_BUILD_VERSION` 的 device/simulator/Catalyst 平台编号及所有架构，并在云端逐个执行五组极小 C++ 编译链接检查；只链接，不启动可执行文件或加载模型。

首轮专用云端 run `41291373138` attempt 1（代码 `05c63eed4007445cb3e8c1f6aacc4f9565ca42c8`）在解包阶段严格失败，原因是曾误认为官方 ZIP 包含 Simulator。修复按实物元数据新增源码 Simulator 构建，而不是删除最终三变体或五架构门槛；此失败不算 native 编译或链接通过，修复仍需新 SHA 云端验收。

官方 iOS framework 还包含 upstream 的 mtmd 等函数；本产品只使用文本 C API，不因此承诺图片、语音或多模态能力。Catalyst 仅暴露核心头文件，不暴露未编译的 mtmd/Metal/BLAS 入口。App target 必须正确链接并 Embed & Sign 动态 XCFramework，不能把它当成无须嵌入的静态库。

## 缓存与证据

- `.runtime/manifest.json` 记录固定输入、源码与二进制下载摘要、builder 自身摘要、Xcode/macOS SDK 版本、原始生产 run/attempt、五组链接检查及最终每个文件的 SHA-256/大小/权限；明确 `runtimeVerified=false`、`modelWeightsDownloaded=false`。
- 每次命中缓存仍核对全部文件、平台、架构、许可证、输入及当前 toolchain；损坏、陈旧或不完整缓存失败，不静默降级到无 native runtime。缓存键应包含脚本摘要和选定 Xcode 版本，不使用宽泛 restore key。
- Actions cache 只缓存 `.runtime/llama.xcframework` 和 `.runtime/manifest.json`，不缓存 `.runtime/work`。原生产 run 与当前复核 run 可以不同，不能把缓存来源的 SHA 当作当前 App 已构建证据。
- 日志保存在 `.runtime/logs/run<id>-attempt<attempt>/`，含下载摘要和上游原始 XCFramework plist；失败额外写 `.runtime/failure.json` 并非零退出。workflow 必须保留这些失败证据，不把依赖准备失败吞掉后继续发布。
- 每个 framework 内保留原 `LICENSE` 和从固定源码聚合的 `THIRD_PARTY_NOTICES.txt`，包含独立 license 文件和 embedded vendor notices；依赖许可不授权任何模型权重。真实分发仍需核对所选模型许可和所有 SDK 的实际使用。

纯 Python 夹具入口：`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Tools/tests -p test_llama_dependency.py -v`。夹具只生成明确的微型假结构与 Mach-O 头测试拒绝路径，不执行任何 Apple 工具，不能替代云端 native 编译链接、真实权重推理、真机资源/热状态或签名发行验收。

## 必须另验收

新增 native SDK 后重新审核隐私 required-reason API；例如 llama 的 `fstat` 模型文件读取必须与 App 容器/用户授权路径及实际用途匹配。依赖构建通过不证明流式输出、正确 tokenizer/chat template、多轮上下文、停止/内存释放、后台中断、模型来源可信或发布签名可用。没有实际云端产物与结果时不得将本页当作已验证声明。

## App framework 暂存格式

编译缓存 `.runtime/llama.xcframework` 保持不可变、全文件 SHA-256/权限和五个平台架构链接校验。共同 action 随后运行仅云端 `Tools/stage_native_framework.py`，复制到 `.runtime/app-bundle/llama.xcframework`，将 Catalyst 整理为标准版本化 framework：`Versions/A`、`Versions/Current`、`Resources/Info.plist` 与固定相对别名。iOS device/Simulator 仍为浅层 bundle，所有原生二进制和 dSYM 字节保持不变；App 工程和真实 native probe 统一使用暂存路径。

仅允许脚本构造的七个内部相对别名，目标必须在物理版本 A 内；上游下载、不可变缓存和其他路径仍拒绝符号链接。额外别名、外部目标、旧浅层 Info.plist、切片/摘要/权限不匹配都会失败，不关闭 Xcode bundle validation。专用依赖产物使用保留这些别名的 ZIP，不能让普通 artifact 上传将别名展开后当作原始 framework。格式暂存不意味着 App/Catalyst 构建、真实推理或签名已验收，仍核对各自精确 SHA 的云端结果。
