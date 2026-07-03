# 测试规范

本文指导 Agent A、Agent B、Agent C 为 `Local Gemma iOS Prototype` 选择本地轻量检查、云端重验证、结果包下载和验收方式。

## 默认策略

- 默认云端重验证，本机只跑轻量检查。
- 只有人工明确说“本机测试”“本地 build”“本地跑探针”“本地 xcodebuild”等，Agent 才把本机完整构建或模拟器验证作为默认路径。
- 文档-only 修改仍可本地跑 `git diff --check`、YAML 解析、`plutil -lint`、目录结构检查等轻量检查，并说明未跑完整 XCTest 的原因。
- Swift / Xcode / UI / 状态流 / workflow 改动完成后，默认 commit 并 push 到 `origin/main`，由 GitHub Actions 运行 build / test。
- 云端失败时，Agent B 根据结果包中的失败摘要、日志路径和 manifest 修复后继续在 `main` 上追加 commit 并 push。
- 本项目当前不允许自动下载模型权重；CI 也不能下载 Gemma 或把提示词发往外部推理服务。

## 固定前缀 / 环境要求

本地如需使用 Xcode，优先使用完整 Xcode 路径，避免 `xcode-select` 指向 Command Line Tools 时导致 SDK 或 Swift module cache 不匹配：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

推荐本地 DerivedData 固定到工作区内：

```sh
-derivedDataPath .build/DerivedDataCodex
```

基础环境：

- Xcode 位于 `/Applications/Xcode.app/Contents/Developer`。
- iOS Simulator SDK 可用。
- 本机完整 XCTest 需要可用模拟器，例如 `iPhone 17` 或本机实际存在的 iPhone 模拟器。
- 网络不是业务测试前提；项目当前不允许自动下载模型权重。
- 云端 CI 由 `.github/workflows/ci-results.yml` 负责，触发条件是 `main` push 和 `workflow_dispatch`。

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

## 本地轻量检查

### 1. 文档 / workflow 静态检查

触发条件：

- 文档-only 修改。
- GitHub Actions workflow 修改。
- Xcode 工程文件未改业务逻辑但需要语法确认。

命令：

```sh
git diff --check
find md -maxdepth 4 -type f | sort
grep -n "Agent A\\|Agent B\\|Agent C\\|README\\|测试规范" AGENTS.md
plutil -lint LocalGemma.xcodeproj/project.pbxproj
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-results.yml"); puts "yaml ok"'
```

当前基线：

- `git diff --check` 无输出且退出码为 0。
- `plutil` 输出 `OK`。
- Ruby YAML 解析输出 `yaml ok`。

### 2. Probe / Fast

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
- 如命令因 SDK 或沙箱失败，记录具体错误，并改由云端 CI 重验证。

## 云端重验证

### 触发方式

Agent B 完成本地轻量检查后，在 `main` 上提交并推送：

```sh
git fetch origin
git switch main
git pull --ff-only origin main
git status --short --branch
git add 相关文件
git commit -m "vX.Y: 简要说明本轮做了什么"
git push origin main
```

`.github/workflows/ci-results.yml` 在以下条件触发：

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:
```

### CI 覆盖范围

当前 workflow 目标：

- `git diff --check`
- `plutil -lint LocalGemma.xcodeproj/project.pbxproj`
- Ruby YAML 解析 workflow
- Probe / Fast 逻辑烟测
- `xcodebuild build-for-testing`
- 自动选择可用 iPhone Simulator 后执行 `xcodebuild test-without-building`
- 生成 `ci-artifact-manifest.json`
- 生成 `artifact-name.txt`
- 生成 `ci-failure-summary.md`
- 生成 `junit.xml`
- 上传 `.xcresult`、`xcodebuild.log`、`test.log`、`logic-smoke.log`、`static-checks.log`、`environment.log` 和 manifest

云端 DerivedData 使用 `.derivedData-ci`，不同于本地推荐的 `.build/DerivedDataCodex`。这是 CI 内部缓存路径差异，不改变工程行为。

### 结果包内容

GitHub Actions 上传未加密 artifact，版本号从最新 commit 主题的第一个 `vX.Y` token 提取。命名格式：

```text
localgemma-ci-<commit_version>-main-<short_sha>-run<run_id>-attempt<run_attempt>
```

最低内容：

- `ci-artifact-manifest.json`
- `artifact-name.txt`
- `ci-failure-summary.md`
- `junit.xml`
- `environment.log`
- `xcodebuild.log`
- `test.log`
- `logic-smoke.log`
- `static-checks.log`
- `LocalGemma-build.xcresult`
- `LocalGemma-tests.xcresult`，如果模拟器 XCTest 实际运行

`ci-artifact-manifest.json` 至少包含：

```json
{
  "artifactName": "localgemma-ci-vX.Y-main-abcdef0-run123-attempt1",
  "version": "vX.Y",
  "repository": "owner/repo",
  "branch": "main",
  "commitSha": "...",
  "shortSha": "...",
  "commitSubject": "vX.Y: 简要说明本轮做了什么",
  "runUrl": "https://github.com/owner/repo/actions/runs/123",
  "runId": "...",
  "runAttempt": "...",
  "workflowName": "Local Gemma CI Results",
  "createdAt": "...",
  "projectName": "Local Gemma iOS Prototype",
  "scheme": "LocalGemma",
  "destination": "...",
  "resultBundlePath": "ci-results/LocalGemma-build.xcresult",
  "testResultBundlePath": "ci-results/LocalGemma-tests.xcresult",
  "junitPath": "ci-results/junit.xml",
  "buildLogPath": "ci-results/xcodebuild.log",
  "testLogPath": "ci-results/test.log",
  "failureSummaryPath": "ci-results/ci-failure-summary.md",
  "staticChecksOutcome": "success/failure",
  "logicSmokeOutcome": "success/failure",
  "buildOutcome": "success/failure",
  "testOutcome": "success/failure/skipped",
  "projectSpecificReports": []
}
```

## Agent C 结果包下载与核对

Agent C 验收前必须确认本地和远端：

```sh
git fetch origin
git rev-parse main
git rev-parse origin/main
gh run list --workflow ci-results.yml --branch main --limit 5
```

如果仓库是私有或 artifact 受权限控制，先登录：

```sh
gh auth login
```

下载缓存默认放在：

```text
/private/tmp/localgemma-c-review-<run_id>/
```

下载命令示例：

```sh
mkdir -p /private/tmp/localgemma-c-review-<run_id>
gh run download <run_id> \
  --dir /private/tmp/localgemma-c-review-<run_id>
```

Agent C 必须核对：

- `ci-artifact-manifest.json` 的 `branch` 是 `main`。
- `commitSha` 等于 `origin/main` 最新 commit。
- `artifactName` 等于 `artifact-name.txt` 的内容，也等于本次下载的 artifact 名称。
- `repository`、`commitSubject`、`runUrl` 能定位到本次 `origin/main` 提交和 GitHub Actions run。
- `runId` 和 `runAttempt` 等于本次下载的 GitHub Actions run。
- `staticChecksOutcome`、`logicSmokeOutcome`、`buildOutcome`、`testOutcome` 与 GitHub Actions UI 和日志一致。
- `junit.xml` 的失败数与 `ci-failure-summary.md` 一致。
- `xcodebuild.log`、`test.log`、`.xcresult` 或等价结果存在且可打开。
- 如果 test 被 `skipped`，必须有明确原因，例如 runner 没有可用 iPhone Simulator。

Agent C 不自动删除 `/private/tmp/localgemma-c-review-<run_id>/`，除非人工明确同意。

## 人工明确要求时的本机完整验证

### Smoke

验证主要集成路径能编译。

触发条件：

- 人工要求本地 build。
- 修改任意 Swift 源码后需要本机快速确认。
- 修改 Xcode 工程配置或新增 Swift 文件。

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

### Stage Regression

覆盖当前阶段核心模块。

触发条件：

- 人工要求本地模拟器 XCTest。
- 云端 CI 不可用但需要本地替代验证。
- 修改 artifact 文件管理、SHA-256、模型部署状态。
- 修改 `InferenceEngine` 会话、流式生成、导出。
- 修改提示词模板行为。
- 修改横屏布局、壁纸、分享兜底。

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

### Full

全量测试和人工可视检查。

触发条件：

- 人工明确要求本机完整验证。
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

## 规则

- 每次实现前先读本文件。
- 不得伪造测试结果。
- 不得把云端未触发写成云端通过。
- 新增或修改测试后，必须同步更新本文件当前基线和 README 验证章节。
- 失败测试不能只记录为“环境问题”；必须写清楚失败命令、错误摘要和替代验证。
- 如果没有 `origin`、没有 push 权限或没有 GitHub Actions 权限，必须明确写为云端验证阻塞。
