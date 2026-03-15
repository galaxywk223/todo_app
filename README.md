# Todo App

一个以安卓端为主的 Flutter 待办清单应用，界面语言为中文，当前功能已经可正常使用。

这个仓库的重点不是展示“Flutter 模板工程”，而是展示一个可运行、可维护的个人效率应用源码。因此根目录文档会优先说明项目定位、目录职责和实际运行方式。

## 项目定位

- 主要使用场景：Android 应用
- 主体代码位置：`lib/`
- 数据存储：Android 等常规平台使用 Isar，本地持久化
- 额外平台说明：仓库中保留了 `ohos/` 目录，用于 OpenHarmony 适配

## 当前功能

- 新建、编辑、删除待办
- 区分“今日常驻”和“普通待办”
- 支持完成状态切换
- 支持优先级与截止时间展示
- 支持主题切换
- 支持本地数据持久化

## 技术栈

- Flutter
- Dart
- Isar
- Shared Preferences
- Material 3

## 目录说明

更详细的目录职责见 [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)。

```text
todo_app/
|- android/          Android 工程
|- assets/           应用资源
|- lib/              Flutter 业务代码
|- ohos/             OpenHarmony 工程与适配说明
|- test/             测试代码
|- pubspec.yaml      Flutter 依赖与项目配置
|- README.md         仓库入口说明
```

## 本地运行

1. 安装 Flutter SDK
2. 在项目根目录执行依赖安装：

```bash
flutter pub get
```

3. 连接 Android 设备或启动模拟器后运行：

```bash
flutter run
```

## 测试

```bash
flutter test
```

## OpenHarmony

`ohos/` 目录是 OpenHarmony 适配工程，不影响 Android 主体功能。

详细说明见 [ohos/README.md](ohos/README.md)。

## 维护说明

- 该仓库以源码和必要文档为主
- 构建产物、缓存目录、日志文件不应提交到版本控制
- 若后续继续扩展平台，建议在文档中明确“主维护平台”和“实验性平台”
