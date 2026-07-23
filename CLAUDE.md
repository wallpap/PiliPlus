# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

PiliPlus 是使用 Flutter 开发的第三方 BiliBili（B站）客户端，支持 Android 和 Windows。项目 Fork 自 [guozhigq/pilipala](https://github.com/guozhigq/pilipala) / [orz12/PiliPalaX](https://github.com/orz12/PiliPalaX)。

## 开发环境

- **Flutter**: 3.44.7（通过 FVM 管理，见 `.fvmrc`）
- **Dart SDK**: >=3.12.0
- **Java**: 17 (Android)
- 使用 `flutter pub get` 安装依赖

## 常用命令

```bash
# 运行应用（debug 模式）
flutter run

# 构建 Android APK（分 ABI）
flutter build apk --release --split-per-abi

# 开发版构建（不带 dart-define）
flutter build apk --release --split-per-abi --android-project-arg dev=1

# 发布版构建（需要 pili_release.json）
flutter build apk --release --split-per-abi --dart-define-from-file=pili_release.json --pub

# 代码分析
flutter analyze

# 代码生成（build_runner）
flutter pub run build_runner build

# 国际化
flutter gen-l10n
```

## 核心架构

### 状态管理 — GetX

项目使用 **GetX** (`get` 包) 进行状态管理、路由和依赖注入：

- 每个页面目录通常包含 `view.dart`（UI）和 `controller.dart`（业务逻辑），Controller 继承 `GetxController`
- 全局服务通过 `Get.lazyPut()` 在 `main.dart` 中注册（如 `AccountService`、`DownloadService`）
- 路由定义在 `lib/router/app_pages.dart`，使用 `GetPage` 命名路由

### 网络层 — `lib/http/`

- **`init.dart`** — Dio 单例封装，支持 HTTP/2（`dio_http2_adapter`），处理压缩（gzip/brotli）、代理、网络切换自适应
- **`loading_state.dart`** — 网络请求状态的 sealed class：`Loading` / `Success<T>` / `Error`
- 各 API 模块文件（`video.dart`、`user.dart`、`fav.dart`、`live.dart` 等）按业务域拆分，通常定义 `*Http` 类封装静态请求方法
- 多账号支持通过 `AccountManager` 拦截器实现，`Request.accountManager` 在请求中自动注入对应账号的 Cookie
- 请求方法通过 `Request()` 实例的 `get`/`post`/`downloadFile` 发起，`DioException` 已统一捕获

### 本地存储 — `lib/utils/storage.dart`

使用 **Hive CE** (`hive_ce`)，初始化在 `GStorage.init()`，包含以下 Box：
- `userInfo` — 用户信息（`UserInfoData`）
- `setting` — 应用设置
- `video` — 视频相关设置
- `historyWord` — 搜索历史
- `localCache` — 本地缓存
- `watchProgress` — 观看进度
- `reply` — 评论缓存（可选，受 `saveReply` 设置控制）

### 模型层 — `lib/models/` 和 `lib/models_new/`

项目存在两套模型目录，正在从 `models/` 向 `models_new/` 迁移重构中：
- **`lib/models/`** — 旧版模型，早期开发时的数据结构
- **`lib/models_new/`** — 新版模型，更贴近 B站 API 最新结构。新增功能应在 `models_new/` 下编写

### 页面结构

`lib/pages/` 下每个子目录代表一个功能页面，典型结构为：
```
pages/{page_name}/
  view.dart        # UI 层（Widget build）
  controller.dart  # 业务逻辑层（GetxController）
  widgets/          # 页面专用组件
```

### 核心播放器 — `lib/plugin/pl_player/`

视频播放核心插件，基于 `media_kit`：
- `controller.dart` — 播放器主控制器
- `models/` — 播放器数据模型（`data_source.dart`、`heart_beat_type.dart` 等）
- `view/` — 播放器 UI 层
- `widgets/` — 播放器子组件（手势、控制栏、弹幕等）

### gRPC 与实时通信 — `lib/grpc/` 和 `lib/tcp/`

- `lib/grpc/` — gRPC 服务，处理弹幕流、直播聊天、动态推送等实时数据
  - `grpc_req.dart` — gRPC 请求封装
  - `dm.dart` — 弹幕 gRPC
  - `bilibili/` — 从 protobuf 生成的代码（被 analyzer 排除）
- `lib/tcp/live.dart` — 直播 TCP 连接

### 公共组件 — `lib/common/widgets/`

包含大量对 Flutter 框架组件的自定义覆写（`lib/common/widgets/flutter/` 子目录），用于修复或增强原生控件行为（如文本字段选择、可滚动页面、标签页等）。这些是通过 `scripts/` 中的 patch 文件从 Flutter SDK 修改而来的。

### 平台适配 — `lib/scripts/`

`patch.ps1` 脚本在 CI 构建时应用 Flutter 框架级别的补丁（修复不同平台上的特定问题，如 Android BottomSheet、iOS 文本编辑等）。补丁文件在 `scripts/` 目录中。

### 应用入口 — `lib/main.dart`

- 初始化顺序：Hive 存储 → 下载路径 → 临时路径 → 缓存管理器 → GetX 服务注册 → HTTP 客户端 → 平台特定配置
- 生产环境通过 `Catcher2` 进行错误捕获和日志记录（由 `enableLog` 设置控制）
- UI 缩放通过 `Pref.uiScale` 实现（`ScaledWidgetsFlutterBinding`），支持文本缩放独立控制
- 桌面端通过 `window_manager` 管理窗口状态
- 支持 Dynamic Color（Material You）主题

## 构建配置

构建参数通过 `dart-define` 环境变量传入：
- `pili.code` — 版本号（int）
- `pili.name` — 版本名（String）
- `pili.time` — 构建时间戳
- `pili.hash` — Git commit hash

读取端在 `lib/build_config.dart`。CI 构建通过 `lib/scripts/build.ps1` 提取版本信息并写入 `pili_release.json`。

## 代码规范

- `analysis_options.yaml` 定义 lint 规则，启用了多项额外规则（`avoid_print`、`always_use_package_imports` 等）
- `lib/grpc/bilibili/` 被 analyzer 排除
- 格式化使用 trailing commas（`formatter.trailing_commas: preserve`）

## 测试

项目当前没有测试（`test/` 目录不存在，`.gitignore` 中排除了 `test*`）。`dev_dependencies` 中保留了 `flutter_test`，如需添加测试可直接创建 `test/` 目录。

## 依赖说明

大量依赖使用 Fork 版本（来自 `bggRGjQaUbCoE` 和 `My-Responsitories` 两个 GitHub org），包括 `get`、`media_kit`、`audio_service`、`flutter_inappwebview`、`cached_network_image_ce` 等核心库。这些 Fork 通常包含上游尚未合入的修复或定制功能。遇到这些库的问题时，需要检查对应 Fork 仓库的 diff。

## Android 原生代码

Android 平台原生代码位于 `android/app/src/main/java/com/example/piliplus/`：
- `AndroidHelper.java` — 平台辅助功能
- `MediaHelper.java` — 媒体处理
- `MainActivity.kt` — 主 Activity

JNI 绑定通过 `tool/jnigen.dart` 生成（`dart run tool/jnigen.dart`），输出到 `lib/utils/android/bindings.g.dart`（被 `.gitignore` 忽略）。
