# Todo App

[中文文档](./README.zh-CN.md)

Todo App is a Flutter task-management application focused on daily personal tasks. The current implementation primarily targets Android and keeps OpenHarmony adaptation files in the repository.

## Features

- Create, edit, and delete todo items.
- Separate persistent today tasks from regular todo items.
- Toggle completion state.
- Display priority and due dates.
- Switch application theme.
- Persist data locally.

## Tech Stack

- Flutter
- Dart
- Material 3
- Isar
- Shared Preferences

## Project Structure

```text
todo_app/
|- android/          Android project
|- assets/           icons and static assets
|- lib/              main Flutter application code
|- ohos/             OpenHarmony adaptation project
|- test/             tests
|- pubspec.yaml      dependencies and project metadata
```

More detailed structure notes are available in [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md).

## Quick Start

### Install Dependencies

```bash
flutter pub get
```

### Run

Connect an Android device or start an emulator, then run:

```bash
flutter run
```

### Test

```bash
flutter test
```

## Code Entry Points

Primary files:

- `lib/main.dart`
- `lib/ui/todo_list_page.dart`
- `lib/data/todo_repository.dart`

## OpenHarmony

The repository contains an `ohos/` directory for OpenHarmony adaptation work.

Related notes are available in [ohos/README.md](ohos/README.md).

## License

This project is released under the [GNU GPLv3](LICENSE).

The license allows use, modification, and redistribution. Distributed modified versions must keep the corresponding source code open under GPL-compatible terms. The project is not suitable for closed-source redistribution.
