import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app_isar.dart';
import 'todo.dart';

abstract class TodoRepository {
  Stream<List<Todo>> watchTodos();

  Future<Id> addTodo({
    required String title,
    String? note,
    DateTime? dueAt,
    int priority = 1,
  });

  Future<Todo?> getTodoById(Id id);
  Future<void> saveTodo(Todo todo);
  Future<void> toggleDone(Id id, {required bool isDone});
  Future<void> deleteTodo(Id id);
  void dispose();

  static Future<TodoRepository> open() async {
    if (kIsWeb) {
      throw UnsupportedError('Local persistence is not supported on web.');
    }
    if (Platform.operatingSystem == 'ohos') {
      return FileTodoRepository.open();
    }
    try {
      final isar = await openIsar();
      return IsarTodoRepository(isar);
    } catch (_) {
      return FileTodoRepository.open();
    }
  }

  static int compareTodos(Todo a, Todo b) {
    final doneCmp = (a.isDone ? 1 : 0).compareTo(b.isDone ? 1 : 0);
    if (doneCmp != 0) return doneCmp;

    final priorityCmp = a.priority.compareTo(b.priority);
    if (priorityCmp != 0) return priorityCmp;

    final aDue = a.dueAt;
    final bDue = b.dueAt;
    if (aDue == null && bDue != null) return 1;
    if (aDue != null && bDue == null) return -1;
    if (aDue != null && bDue != null) {
      final dueCmp = aDue.compareTo(bDue);
      if (dueCmp != 0) return dueCmp;
    }

    return b.createdAt.compareTo(a.createdAt);
  }
}

class IsarTodoRepository implements TodoRepository {
  IsarTodoRepository(this._isar);

  final Isar _isar;

  @override
  Stream<List<Todo>> watchTodos() {
    final query = _isar.todos.where();
    return query.watch(fireImmediately: true).map((todos) {
      final sorted = [...todos];
      sorted.sort(TodoRepository.compareTodos);
      return sorted;
    });
  }

  @override
  Future<Id> addTodo({
    required String title,
    String? note,
    DateTime? dueAt,
    int priority = 1,
  }) async {
    final now = DateTime.now();
    final todo = Todo()
      ..title = title
      ..note = note
      ..dueAt = dueAt
      ..priority = priority
      ..createdAt = now
      ..updatedAt = now;

    return _isar.writeTxn(() async {
      return _isar.todos.put(todo);
    });
  }

  @override
  Future<Todo?> getTodoById(Id id) async {
    return _isar.todos.get(id);
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    todo.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.todos.put(todo);
    });
  }

  @override
  Future<void> toggleDone(Id id, {required bool isDone}) async {
    await _isar.writeTxn(() async {
      final todo = await _isar.todos.get(id);
      if (todo == null) return;
      todo
        ..isDone = isDone
        ..updatedAt = DateTime.now();
      await _isar.todos.put(todo);
    });
  }

  @override
  Future<void> deleteTodo(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.todos.delete(id);
    });
  }

  @override
  void dispose() {
    _isar.close();
  }
}

class FileTodoRepository implements TodoRepository {
  FileTodoRepository._(this._file, this._state, this._controller);

  static const String _fileName = 'todos.json';

  final File _file;
  final _FileRepoState _state;
  final StreamController<List<Todo>> _controller;

  static Future<FileTodoRepository> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]');
    }
    final todos = await _readTodos(file);
    final state = _FileRepoState(todos);
    late final StreamController<List<Todo>> controller;
    controller = StreamController<List<Todo>>.broadcast(
      onListen: () {
        final sorted = [...state.todos]..sort(TodoRepository.compareTodos);
        controller.add(sorted);
      },
    );
    final repo = FileTodoRepository._(file, state, controller);
    return repo;
  }

  static Future<List<Todo>> _readTodos(File file) async {
    try {
      final text = await file.readAsString();
      final raw = jsonDecode(text);
      if (raw is! List) return [];
      return raw.whereType<Map>().map(_todoFromJson).toList();
    } catch (_) {
      return [];
    }
  }

  static Todo _todoFromJson(Map raw) {
    final todo = Todo();
    todo.id = (raw['id'] is num) ? (raw['id'] as num).toInt() : 0;
    todo.title = (raw['title'] as String?) ?? '';
    todo.note = raw['note'] as String?;
    todo.isDone = (raw['isDone'] as bool?) ?? false;
    todo.priority = (raw['priority'] is num) ? (raw['priority'] as num).toInt() : 0;
    todo.createdAt = DateTime.tryParse(raw['createdAt'] as String? ?? '') ?? DateTime.now();
    todo.updatedAt = DateTime.tryParse(raw['updatedAt'] as String? ?? '') ?? todo.createdAt;
    todo.dueAt = raw['dueAt'] == null ? null : DateTime.tryParse(raw['dueAt'] as String);
    return todo;
  }

  static Map<String, Object?> _todoToJson(Todo todo) {
    return <String, Object?>{
      'id': todo.id,
      'title': todo.title,
      'note': todo.note,
      'isDone': todo.isDone,
      'createdAt': todo.createdAt.toIso8601String(),
      'updatedAt': todo.updatedAt.toIso8601String(),
      'dueAt': todo.dueAt?.toIso8601String(),
      'priority': todo.priority,
    };
  }

  Future<void> _persist() async {
    final list = _state.todos.map(_todoToJson).toList(growable: false);
    await _file.writeAsString(jsonEncode(list));
  }

  void _emit() {
    final sorted = [..._state.todos]..sort(TodoRepository.compareTodos);
    _controller.add(sorted);
  }

  @override
  Stream<List<Todo>> watchTodos() {
    return _controller.stream;
  }

  @override
  Future<Id> addTodo({
    required String title,
    String? note,
    DateTime? dueAt,
    int priority = 1,
  }) async {
    final now = DateTime.now();
    final id = _state.nextId();
    final todo = Todo()
      ..id = id
      ..title = title
      ..note = note
      ..dueAt = dueAt
      ..priority = priority
      ..createdAt = now
      ..updatedAt = now;
    _state.todos.add(todo);
    await _persist();
    _emit();
    return id;
  }

  @override
  Future<Todo?> getTodoById(Id id) async {
    for (final todo in _state.todos) {
      if (todo.id == id) return todo;
    }
    return null;
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    todo.updatedAt = DateTime.now();
    final index = _state.todos.indexWhere((t) => t.id == todo.id);
    if (index >= 0) {
      _state.todos[index] = todo;
    } else {
      _state.todos.add(todo);
    }
    await _persist();
    _emit();
  }

  @override
  Future<void> toggleDone(Id id, {required bool isDone}) async {
    final todo = await getTodoById(id);
    if (todo == null) return;
    todo
      ..isDone = isDone
      ..updatedAt = DateTime.now();
    await _persist();
    _emit();
  }

  @override
  Future<void> deleteTodo(Id id) async {
    _state.todos.removeWhere((t) => t.id == id);
    await _persist();
    _emit();
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class _FileRepoState {
  _FileRepoState(this.todos) : _maxId = todos.fold<int>(0, (m, t) => t.id > m ? t.id : m);

  final List<Todo> todos;
  int _maxId;

  int nextId() {
    _maxId += 1;
    return _maxId;
  }
}
