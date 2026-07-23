# 开发环境搭建记录

> 适用于 Windows 11，基于 PiliPlus Flutter 3.44.7

## SDK 布局

```
E:\SDK\
  Android\          # Android SDK 36.1.0（Android Studio 预装）
  dart\              # Dart 3.12.2（独立 ZIP，FVM 引导用，可删除）
  jdk-17\            # Eclipse Temurin 17.0.19（ZIP 解压，非全局安装）
```

- Flutter 3.44.7 由 FVM 管理，缓存于 `%USERPROFILE%\.fvm\versions\3.44.7`
- FVM 4.1.2 由 Dart Pub 全局安装至 `%LOCALAPPDATA%\Pub\Cache\bin`

## 环境变量（按需设置）

```powershell
# 每新开终端需手动设置（或写入 Profile）
$env:JAVA_HOME = "E:\SDK\jdk-17"
$env:ANDROID_HOME = "E:\SDK\Android"
$env:ANDROID_SDK_ROOT = "E:\SDK\Android"
$env:PATH = "E:\SDK\jdk-17\bin;$env:PATH"
$env:PATH = "$env:LOCALAPPDATA\Pub\Cache\bin;$env:PATH"

# 代理（需 VPN 端口 10808）
$env:HTTP_PROXY = "http://127.0.0.1:10808"
$env:HTTPS_PROXY = "http://127.0.0.1:10808"
```

## Git 代理

```bash
git config --global http.proxy http://127.0.0.1:10808
git config --global https.proxy http://127.0.0.1:10808
```

## Gradle 全局配置

`%USERPROFILE%\.gradle\gradle.properties`：

```properties
org.gradle.java.home=E:\\SDK\\jdk-17
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=10808
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=10808
```

## 项目级修改

### android/gradle/wrapper/gradle-wrapper.properties

```
-distributionUrl=gradle-9.5.0-all.zip
+distributionUrl=gradle-9.5.0-bin.zip
-networkTimeout=10000
+networkTimeout=300000
```

- `-all.zip`(200MB) → `-bin.zip`(130MB)，首次下载更快
- `networkTimeout` 从 10s 延长至 5min，代理下载不超时

### android/gradle.properties

```diff
+org.gradle.parallel=true
+org.gradle.caching=true
+kotlin.incremental=false
```

- `parallel` — 并行编译模块
- `caching` — 启用构建缓存
- `kotlin.incremental=false` — Kotlin 2.3.20 增量编译在跨盘符多插件场景下有路径解析 bug（pub cache 在 C:，项目在 E:），关闭它避免 `Storage is already registered` 错误

### .vscode/settings.json

```diff
+"dart.flutterSdkPath": ".fvm/flutter_sdk",
```

VS Code Dart 插件使用 FVM 管理的 Flutter SDK。

## 依赖修复：flutter_inappwebview

`bggRGjQaUbCoE/flutter_inappwebview`（ref `v6.1.5`）的 `flutter_inappwebview_android` 插件缺失多个 Java 源文件，需要从官方 `pichillilorenzo/flutter_inappwebview`（tag `v6.1.5`）补齐。

**缺失文件列表**（`android/src/main/java/com/pichillilorenzo/flutter_inappwebview_android/`）：

| 路径 | 文件 |
|------|------|
| `credential_database/` | `URLProtectionSpaceContract.java` |
| `content_blocker/` | `ContentBlockerTriggerResourceType.java` |
| `webview/in_app_webview/` | `InAppWebViewChromeClient.java` |
| `webview/in_app_webview/` | `InAppWebViewClientCompat.java` |
| `webview/in_app_webview/` | `InAppWebViewRenderProcessClient.java` |

以及大量其他文件（建议直接用官方源码完整覆盖）。

> **注意**：`flutter pub get` 会重新 clone Git 依赖，覆盖 Pub cache 中的修复。正式方案需将修复提交到 Fork 仓库。

## 引导安装步骤（新机器参考）

```powershell
# 1. 下载独立 Dart SDK ZIP → 解压到 E:\SDK\dart
$env:PATH = "E:\SDK\dart\bin;$env:PATH"

# 2. 安装 FVM
dart pub global activate fvm
$env:PATH = "$env:LOCALAPPDATA\Pub\Cache\bin;$env:PATH"

# 3. 安装 Flutter
fvm install 3.44.7
cd E:\Code\PiliPlus
fvm use 3.44.7 --force

# 4. 下载 JDK 17 ZIP → 解压到 E:\SDK\jdk-17
#    https://adoptium.net/download/

# 5. 设置环境变量（见上文）

# 6. 接受 Android 许可
fvm flutter doctor --android-licenses

# 7. 获取依赖 + 构建
fvm flutter pub get
fvm flutter build apk --debug
```
