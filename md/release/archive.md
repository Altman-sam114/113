# 云端未签名归档

本入口只在 GitHub-hosted macOS runner 生成真正的 iPhoneOS Release `.xcarchive`，不在本机编译。归档包含 App 与匹配的 dSYM；未签名归档不能安装分发，不等于 IPA、TestFlight、App Store 审核或真实推理验收。

## 运行入口

在仓库的 `Unsigned Release Archive` Actions 页面选择 `main`，输入：

- `expected_sha`：待归档 main 提交的完整 40 位 SHA，必须与 checkout 和事件 SHA 完全相同。
- `marketing_version`：两个或三个数字分量，例如 `1.0`；不得低于该提交工程配置中的版本。
- `build_number`：正整数，必须大于该提交工程中的 build number。此检查不读取 App Store Connect 历史，开发者仍需确认正式递增号。

也可使用 GitHub CLI 触发。先确认活动账号是 `Altman-sam114`，并替换 `EXACT_MAIN_SHA` 为真实完整 SHA：

```sh
gh workflow run release-archive.yml --repo Altman-sam114/113 --ref main \
  -f expected_sha=EXACT_MAIN_SHA -f marketing_version=1.0 -f build_number=2
```

不得在本机设置 `GITHUB_ACTIONS=true` 等变量冒充云端执行。workflow 不因普通 push 自动重复归档，不下载模型、不读取会话，也不导入证书、发布 tag 或上传商店。

## 验收产物

下载对应 run/attempt 的完整 `localgemma-unsigned-release-...` artifact，核对 GitHub artifact digest、ZIP CRC 与安全路径，然后检查：

1. `manifest.json` 的 requested/checkout/event SHA、branch、run/attempt、输入版本及 build 完全一致；source/archive/validation 三项均成功。
2. `LocalGemma-unsigned-...xcarchive.zip` 的独立摘要、完整文件清单、字节数与 Unix 权限匹配；解包后保留 `.xcarchive` 目录结构，不只拿 `.app` 代替归档。
3. `Info.plist` 的 `ApplicationProperties` 与实际 arm64 device App 的版本、build、bundle identifier 和平台一致；隐私与图标资源实际存在且通过原资源检查。
4. 原始 `executable-uuid.log` / `dsym-uuid.log` 的 arm64 UUID 相等，且与清单中的原日志摘要一致。
5. `signingVerified`、`appStoreReady`、`runtimeVerified` 必须保持 `false`。成功仅证明未签名归档与符号交付，不能据此勾选发行或模型推理门槛。

失败必须保留 `failure.json`、失败阶段和可用原日志，并使 workflow 失败。纯 Python 夹具使用明确的微型假结构验证拒绝路径；它们不执行 Xcode，也不代替真实云端 archive。

签名、entitlement、provisioning、正式版本与商店提交请继续按[发布检查表](checklist.md)核验，不把发行凭据提交到 Git 或普通 artifact。
