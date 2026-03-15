# Project Structure

这份文档用于帮助第一次打开仓库的人快速理解项目，而不是去猜哪些目录是源码、哪些目录是生成产物。

## 顶层目录

### `android/`

Flutter 生成的 Android 宿主工程。

适合关注的内容：

- Gradle 构建配置
- Android 清单与打包配置
- 平台侧权限或原生接入

### `assets/`

应用静态资源目录，目前主要包含应用图标等资源文件。

### `lib/`

项目最核心的业务代码目录，也是日常功能开发应优先查看的位置。

当前结构：

```text
lib/
|- data/
|  |- app_isar.dart          Isar 初始化
|  |- todo.dart              待办数据模型
|  |- todo.g.dart            Isar 生成文件
|  |- todo_priority.dart     优先级/紧急度逻辑
|  |- todo_repository.dart   数据访问与持久化
|- ui/
|  |- todo_edit_sheet.dart   新建/编辑待办弹层
|  |- todo_list_page.dart    待办列表主页
|  |- todo_quadrant.dart     待办分类展示组件
|- main.dart                 应用入口
|- theme.dart                主题配置与切换
```

### `ohos/`

OpenHarmony 适配工程，单独维护平台侧实现与构建脚本。

这个目录存在的意义是平台扩展，不是 Android 主功能入口。第一次看仓库时，如果你只关心 Android，可先忽略它，先读 `lib/`。

### `test/`

测试代码目录，目前包含：

- 数据逻辑测试
- 基础渲染 smoke test

### `build/`

本地构建输出目录，不应纳入版本控制。

## 阅读顺序建议

如果你是第一次接手这个项目，建议按下面顺序看：

1. `README.md`
2. `lib/main.dart`
3. `lib/ui/todo_list_page.dart`
4. `lib/data/todo_repository.dart`
5. `test/`

## 仓库整理约定

- 根目录只保留必要源码、配置和文档
- 构建产物不提交
- 平台目录可以保留，但要在 README 中明确主次关系
- 自动生成文件如果必须提交，应让读者知道它的来源和用途
