# Todo App

一个专注于日常任务管理的 Flutter 待办应用，当前主要面向 Android 使用。

## 功能特性

- 新建、编辑、删除待办事项
- 区分今日常驻任务与普通待办
- 支持完成状态切换
- 支持优先级与截止时间展示
- 支持主题切换
- 本地持久化保存

## 技术栈

- Flutter
- Dart
- Material 3
- Isar
- Shared Preferences

## 项目结构

```text
todo_app/
|- android/          Android 工程
|- assets/           图标与静态资源
|- lib/              Flutter 主要业务代码
|- ohos/             OpenHarmony 适配工程
|- test/             测试代码
|- pubspec.yaml      依赖与项目配置
```

更详细的目录说明见 [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)。

## 快速开始

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 运行项目

连接 Android 设备或启动模拟器后执行：

```bash
flutter run
```

### 3. 运行测试

```bash
flutter test
```

## 代码入口

如果你是第一次阅读这个项目，建议从下面几个文件开始：

- `lib/main.dart`
- `lib/ui/todo_list_page.dart`
- `lib/data/todo_repository.dart`

## OpenHarmony

仓库中包含 `ohos/` 目录，用于 OpenHarmony 版本适配。

相关说明见 [ohos/README.md](ohos/README.md)。
