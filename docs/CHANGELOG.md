# Changelog

## v2.2.0 (2026-07-23)

### 平台精简
- 移除 iOS / Linux / macOS 平台支持，仅保留 Android + Windows
- 删除 3 个平台目录（`ios/`、`linux/`、`macos/`）共 ~120 文件
- 删除 3 个 CI 工作流（`ios.yml`、`linux_x64.yml`、`mac.yml`）
- 删除 3 个 iOS 专用补丁（`bottom_sheet_ios_*.patch`、`geetest_ios.patch`）
- 删除 `permission_handler_apple`、`media_kit_libs_ios_video`、`desktop_webview_window` 依赖
- 删除 HwDec 类型中 VideoToolbox（macOS）、VAAPI/DRM/VDPAU（Linux）
- 清理 30+ Dart 文件中 iOS/macOS/Linux 平台分支
- `PlatformUtils.isMobile` → 仅 Android；`isDesktop` → 仅 Windows；删除 `isDarwin`

### 包名更改
- Android: `com.example.piliplus` → `com.white.piliplus`
- 更新 `AndroidManifest.xml`、`build.gradle.kts`、`shortcuts.xml`、Java/Kotlin 源文件路径
- 更新 `jnigen.dart`、`bindings.g.dart`、`audio_handler.dart` 中的引用

### Windows 自定义字体
- 新增 `lib/utils/windows/windows_font_helper.dart` — 使用 win32 `EnumFontFamiliesEx` API 枚举系统字体
- 新增设置项 "自定义字体"（Windows 专属，设置 → 样式）
- 字体选择弹窗支持搜索过滤 + 实时预览（使用自身字体渲染）
- 通过 `ThemeData(fontFamily: ...)` 全局应用，即时生效

### Bug 修复
- `VideoDetailController not found`：`reply_item_grpc.dart` 中改用 `Get.isRegistered<T>()` 预检查
- `LateInitializationError`：评论时间戳校验增加 `try/catch` 保护 `late` 字段访问
- ListTile/ColoredBox 渲染警告：字体选择器 `Container` → `Material`
- Flutter 3.44.7 SemanticsData 断言：通过 Flutter SDK 补丁 `semantics_fix.patch` 为 `textDirection` 提供默认值
- CMake CMP0175 / MSVC C4244/C4458 构建警告：通过 `CMakeLists.txt` 全局抑制
