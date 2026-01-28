import 'package:isar/isar.dart';

import 'todo.dart';

class TodoRepository {
  const TodoRepository(this._isar);

  final Isar _isar;

  Stream<List<Todo>> watchTodos() {
    final query = _isar.todos.where();
    return query.watch(fireImmediately: true).map((todos) {
      final sorted = [...todos];
      sorted.sort(_compareTodos);
      return sorted;
    });
  }

  static int _compareTodos(Todo a, Todo b) {
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

  Future<Todo?> getTodoById(Id id) async {
    return _isar.todos.get(id);
  }

  Future<void> saveTodo(Todo todo) async {
    todo.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.todos.put(todo);
    });
  }

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

  Future<void> deleteTodo(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.todos.delete(id);
    });
  }
}
