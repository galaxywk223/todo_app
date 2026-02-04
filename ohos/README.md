# 鸿蒙（OpenHarmony）版本

这个仓库的鸿蒙版本走的是 **Flutter on OpenHarmony** 容器方案，`ohos/` 目录即为 DevEco Studio 工程。

## 环境要求

- DevEco Studio（含 OpenHarmony SDK；本工程 `compileSdkVersion/targetSdkVersion` 为 20）
- flutter_ohos（支持 `flutter build hap`）

## 首次配置签名（必须）

1. 用 DevEco Studio 打开 `ohos/` 工程
2. File → Project Structure → Signing Configs
3. 勾选 Automatically generate signature

## 构建 HAP

在仓库根目录运行：

```powershell
.\ohos\build_hap.bat
```

如你的 flutter_ohos 不在默认路径，可先设置环境变量：

```powershell
$env:FLUTTER_OHOS_BIN="D:\dev\flutter_ohos\bin"
.\ohos\build_hap.bat
```

构建产物：

- `ohos/dist/todo_app.hap`
- `ohos/entry/build/default/outputs/default/entry-default-unsigned.hap`

## 运行/安装

推荐直接在 DevEco Studio 里连接模拟器/真机后运行/安装 HAP（可自动处理调试签名）。

## 与 Android 版本一致性的关键点

- UI/交互：Flutter 端完全复用 Android 版本的 `lib/` 代码。
- 插件：鸿蒙侧补齐 `path_provider` 与 `shared_preferences` 的最小实现（入口注册在 `ohos/entry/src/main/ets/plugins/GeneratedPluginRegistrant.ets`）。
- 本地数据：鸿蒙侧默认使用文件 `todos.json` 做持久化（避免 Isar 在鸿蒙环境下的原生库兼容风险）；非鸿蒙平台仍使用 Isar。 
