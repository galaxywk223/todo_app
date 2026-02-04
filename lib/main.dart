import 'package:flutter/material.dart';

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
  late final Future<TodoRepository> _repositoryFuture;
  late final ThemeController _themeController;
  TodoRepository? _repository;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController(ThemeController.availableThemes.first);
    _repositoryFuture = TodoRepository.open().then((repository) {
      _repository = repository;
      return repository;
    });
  }

  @override
  void dispose() {
    _repository?.dispose();
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
          home: FutureBuilder<TodoRepository>(
            future: _repositoryFuture,
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

              final repository = snapshot.data!;
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
