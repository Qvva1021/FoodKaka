# 饭咔咔 FoodKaKa

个人使用的 Android 饮食记账本，使用 Flutter / Dart 开发。

当前只实现新版方案的第一阶段：Android 工程、今日/记录/我的三个页面、奶油可爱主题和饭团图形。记账、资料编辑和 AI 功能尚未开放，界面没有虚构的摄入记录。

## 本机运行

在项目根目录 `E:\python\FoodKaKa` 打开 PowerShell：

```powershell
.\scripts\dev.ps1 doctor -v
.\scripts\dev.ps1 devices
.\scripts\dev.ps1 run -d emulator-5554
```

若使用真机，先打开开发者选项和 USB 调试，连接电脑并授权，然后将 `emulator-5554` 替换成 `devices` 列出的设备 ID。

项目专用模拟器名称为 `FoodKaKa_API_36`。如未运行，可先在当前 PowerShell 中设置路径并启动：

```powershell
$env:ANDROID_HOME = "$PWD\.tools\android-sdk"
$env:ANDROID_USER_HOME = "$PWD\.tools\android-user"
$env:ANDROID_AVD_HOME = "$env:ANDROID_USER_HOME\avd"
& "$env:ANDROID_HOME\emulator\emulator.exe" -avd FoodKaKa_API_36
```

## 检查与测试

```powershell
.\scripts\dev.ps1 analyze
.\scripts\dev.ps1 test
.\.tools\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed lib test
```

测试覆盖三页导航、禁用的占位按钮，以及 320 × 640 逻辑像素和 1.5 倍字体下的页面布局与滚动。

调试构建仅用于开发验收：

```powershell
.\scripts\dev.ps1 build apk --debug --target-platform android-x64
```

此命令生成的 x64 Debug APK 用于本机模拟器，不是面向个人手机的正式发布包。正式签名、手机架构与 Release APK 留到第五阶段处理。

## 目录

| 路径 | 内容 |
| --- | --- |
| `lib/main.dart` | 应用入口和三个导航入口 |
| `lib/theme.dart` | 共用颜色与组件样式 |
| `lib/pages/` | 今日、记录、我的页面 |
| `lib/widgets/rice_ball.dart` | Flutter 画布绘制的饭团图形 |
| `android/` | Android 原生工程与应用名称 |
| `test/app_test.dart` | 界面测试 |
| `scripts/dev.ps1` | 使用本项目工具路径运行 Flutter |
| `方案/` | 用户方案及阶段验收记录 |
| `.tools/` | 本机 SDK 与缓存，已加入忽略规则 |

## 开发环境

- Flutter 3.50.0 stable / Dart 3.14.0。
- Android SDK API 36、Build Tools 36.0.0、Platform Tools、NDK 28.2.13676358。
- Android 36 x86_64 模拟器，使用本机 WHPX 加速。
- Java 使用已有的 JDK；本机检测为 Java 21。脚本优先尊重已有 `JAVA_HOME`，未设置时根据 `java` 命令定位。
- Flutter SDK 与 Android SDK 安装在项目 `.tools` 中，脚本设置当前运行环境，不修改系统 PATH。
- Flutter 资源与 Dart 包使用 Flutter 中国镜像；Android SDK 使用 Google 官方源。
- `material_ui` 为当前 Flutter 模板自带的 Material 组件包，没有再引入第三方 UI 框架。`flutter_lints` 和 `flutter_test` 用于开发检查。

`.tools` 不属于源码交付。更换电脑后按 [Flutter 安装文档](https://docs.flutter.dev/install/manual) 和 [Android 环境文档](https://docs.flutter.dev/platform-integration/android/setup) 安装上述工具到相同相对目录，或使用自己的环境直接运行 `flutter`。模拟器和构建依赖首次下载需要网络及较多磁盘空间。

新版 Android CLI 的包路径使用斜线；若自动安装 NDK 失败，可显式运行：

```powershell
$env:ANDROID_USER_HOME = "$PWD\.tools\android-user"
& .\.tools\android-sdk\cmdline-tools\latest\bin\android.exe --no-metrics --sdk "$PWD\.tools\android-sdk" sdk install 'ndk/28.2.13676358'
```

第一阶段已通过静态检查、2 项界面测试、Debug APK 构建和 Android 模拟器中的安装/启动/三页切换验收。当前沿用模板最低 Android API 24（Android 7.0），尚未在用户真机上测试。

第二阶段按原方案实现 SQLite 与本地记账；第三阶段才创建独立的 FastAPI 服务。[第一阶段验收记录与截图](方案/2026-11-16_第一阶段开发与验收.md) 已保存。
