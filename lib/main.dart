import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import 'data/app_isar.dart';
import 'data/todo_repository.dart';
import 'theme.dart';
import 'ui/todo_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late final Future<Isar> _isarFuture;
  late final ThemeController _themeController;
  Isar? _isar;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController(ThemeController.availableThemes.first);
    _isarFuture = openIsar().then((isar) {
      _isar = isar;
      return isar;
    });
  }

  @override
  void dispose() {
    _isar?.close();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: _themeController,
      builder: (context, theme, child) {
        return MaterialApp(
          title: '待办',
          theme: theme.themeData,
          home: FutureBuilder<Isar>(
            future: _isarFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Scaffold(
                  appBar: AppBar(title: const Text('待办')),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('初始化失败：${snapshot.error}'),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final repository = TodoRepository(snapshot.data!);
              return TodoListPage(
                repository: repository,
                themeController: _themeController,
              );
            },
          ),
        );
      },
    );
  }
}
