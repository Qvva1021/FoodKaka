# 饭咔咔 FoodKaKa

个人使用的 Android 饮食记账本，使用 Flutter / Dart 开发。

当前已实现个人资料与 BMI、SQLite 本地记账、历史编辑、拍照/相册/识别确认和 FastAPI 服务，已构建个人签名的通用 Release APK。离线记账可以直接使用；真实 AI 识别需要在电脑端配置可用的免费视觉 API，尚未完成真实模型验收。

本机安装包位于 `releases/FoodKaKa-0.1.0-release.apk`（约 51 MiB，Android 7.0 及以上，ARM64/ARMv7/x64）。APK 不提交源码仓库。具体校验值、安装与待验收项见 [第五阶段交付说明](方案/2026-11-17_第五阶段打包与验收.md)。

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

测试覆盖 SQLite 持久化、BMI 与热量、历史预算快照、编辑删除、事务回滚、首次资料填写、多食物保存和防重复提交，以及窄屏与大字体布局。

调试构建仅用于开发验收：

```powershell
.\scripts\dev.ps1 build apk --debug --target-platform android-x64
```

此命令生成的 x64 Debug APK 用于本机模拟器。正式发布包使用个人签名，运行 `.\scripts\dev.ps1 build apk --release`；首次构建需先用已有 JDK 运行 `python scripts/create_signing.py` 创建本地签名。已有签名时不要重新生成，请备份 `android/upload-keystore.jks` 与 `android/key.properties`，二者不上传 Git。

## 目录

| 路径 | 内容 |
| --- | --- |
| `lib/main.dart` | 应用入口和三个导航入口 |
| `lib/theme.dart` | 共用颜色与组件样式 |
| `lib/pages/` | 今日、记录、我的页面 |
| `lib/data/food_store.dart` | 五张 SQLite 表、事务、预算与汇总 |
| `lib/services/ai_service.dart` | 服务连接、安全存储、HTTP 与结果校验 |
| `server/` | FastAPI 图片转发、免费模型限制及测试 |
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

已通过客户端 13 项测试和后端 7 项测试，Android 模拟器验证本地持久化、真实 HTTP 连接、相册预览及配置缺失时不入账。中文日期选择器、圆角表单和原生饭团图标已完成。当前最低 Android API 24（Android 7.0），尚未在用户真机上测试。本地数据库不上传仓库；卸载或清理应用数据会丢失本机记录。

[服务配置与费用/地区限制](server/README.md)、[第一阶段验收](方案/2026-11-16_第一阶段开发与验收.md)、[第二阶段验收](方案/2026-11-16_第二阶段开发与验收.md)、[第三阶段待验证条件](方案/2026-11-16_第三阶段开发与验收.md)、[第四阶段界面与截图](方案/2026-11-16_第四阶段开发与验收.md) 已保存。每阶段验证后提交并推送 GitHub，再继续后续可独立完成的工作。
