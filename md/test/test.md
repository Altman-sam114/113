# 测试规范

本文指导 Agent B 和 Agent C 为 `Local Gemma iOS Prototype` 选择测试层级、执行命令并记录结果。

## 固定前缀 / 环境要求

优先使用完整 Xcode 路径，避免 `xcode-select` 指向 Command Line Tools 时导致 SDK 或 Swift module cache 不匹配：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

推荐 DerivedData 固定到工作区内：

```sh
-derivedDataPath .build/DerivedDataCodex
```

基础环境：

- Xcode 位于 `/Applications/Xcode.app/Contents/Developer`。
- iOS Simulator SDK 可用。
- 运行完整 XCTest 时需要可用模拟器，例如 `iPhone 17` 或本机实际存在的 iPhone 模拟器。
- 网络不是测试前提；项目当前不允许自动下载模型权重。

查可用模拟器：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl list devices available
```

当前测试基线：

- `LocalGemmaTests.swift` 当前包含 32 个 `test...` 方法。
- 业务核心覆盖 artifact、模型状态、runtime plan、模拟/真实占位 runtime、提示词、会话、导出、横屏布局、壁纸处理和分享兜底。

统计测试数量：

```sh
grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift
```

## 测试分层

### 1. Probe / Fast

最快发现主链路断点。

触发条件：

- 文档-only 之外的任意轻量逻辑改动。
- 修改 `AppState.swift` 中纯逻辑。
- 修改提示词模板、会话标题、导出文本、artifact validation 小逻辑。

命令：

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -module-cache-path .build/SwiftSmokeModuleCache \
  LocalGemma/AppState.swift Tools/LogicSmoke.swift \
  -o .build/logic-smoke

.build/logic-smoke
```

当前基线：

- 期望输出：`Logic smoke passed`。
- 如命令因 SDK 或沙箱失败，记录具体错误，并改跑 Stage Regression。

### 2. Smoke

验证主要集成路径能编译。

触发条件：

- 修改任意 Swift 源码。
- 修改 Xcode 工程配置。
- 新增 Swift 文件。
- 改动 SwiftUI UI、状态对象或测试文件。

命令：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedDataCodex \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
```

当前基线：

- 期望结果：`TEST BUILD SUCCEEDED`。

### 3. Stage Regression

覆盖当前阶段核心模块。

触发条件：

- 修改 artifact 文件管理、SHA-256、模型部署状态。
- 修改 `InferenceEngine` 会话、流式生成、导出。
- 修改提示词模板行为。
- 修改横屏布局、壁纸、分享兜底。
- 修改测试文件或 README 声明过的功能。

命令：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/DerivedDataCodex \
  CODE_SIGNING_ALLOWED=NO \
  test-without-building
```

如果 `iPhone 17` 不存在，先运行 `xcrun simctl list devices available`，选择本机可用 iPhone 模拟器。

当前基线：

- 期望结果：`TEST EXECUTE SUCCEEDED`。
- 当前测试函数数：32。

### 4. Full

全量测试和人工可视检查。

触发条件：

- 改动 App 启动、导航根结构、Xcode target、Info.plist、权限、横屏主布局。
- 接入真实 runtime 或更改模型隐私边界。
- 发布前或重要里程碑。

命令：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedDataCodex \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project LocalGemma.xcodeproj \
  -scheme LocalGemma \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/DerivedDataCodex \
  CODE_SIGNING_ALLOWED=NO \
  test-without-building
```

可视检查：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl install booted .build/DerivedDataCodex/Build/Products/Debug-iphonesimulator/LocalGemma.app

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl launch booted com.localgemma.prototype

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun simctl io booted screenshot .build/localgemma-check.png
```

当前基线：

- App 能安装和启动。
- 首屏非空，推理页展示模型胶囊、会话栏、消息和输入框。
- 横屏布局由 `WorkspaceLayoutMode` 测试锁住；如能截横屏图，应人工确认侧栏和工作区无遮挡。

## 静态检查

文档结构检查：

```sh
find md -maxdepth 4 -type f | sort
```

关键文档检查：

```sh
grep -n "Agent A\\|Agent B\\|Agent C\\|README\\|测试规范" AGENTS.md
grep -n "func test" LocalGemmaTests/LocalGemmaTests.swift
```

Info.plist 生成后可检查方向和相册权限：

```sh
plutil -p .build/DerivedDataCodex/Build/Products/Debug-iphonesimulator/LocalGemma.app/Info.plist | \
  grep -E 'NSPhotoLibraryUsageDescription|UISupportedInterfaceOrientations' -A 4
```

## 规则

- 每次实现前先读本文件。
- 默认从最小测试开始，根据改动范围扩大测试。
- 不得伪造测试结果。
- 文档-only 修改可只跑静态检查，但必须说明未跑完整测试的原因。
- 新增或修改测试后，必须同步更新本文件当前基线和 README 验证章节。
- 失败测试不能只记录为“环境问题”；必须写清楚失败命令、错误摘要和替代验证。

