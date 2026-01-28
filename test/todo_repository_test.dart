import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:todo_app/data/todo.dart';
import 'package:todo_app/data/todo_repository.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  test('TodoRepository：新增并读取', () async {
    final dir = await Directory.systemTemp.createTemp('todo_app_test_');
    Isar? isar;
    try {
      isar = await Isar.open([TodoSchema], directory: dir.path);
      final repo = TodoRepository(isar);

      final id = await repo.addTodo(title: '买牛奶', note: '两盒');
      final todo = await repo.getTodoById(id);

      expect(todo, isNotNull);
      expect(todo!.title, '买牛奶');
      expect(todo.note, '两盒');
      expect(todo.isDone, isFalse);
    } finally {
      await isar?.close(deleteFromDisk: true);
      await dir.delete(recursive: true);
    }
  });

  test('TodoRepository：监听与切换完成状态', () async {
    final dir = await Directory.systemTemp.createTemp('todo_app_test_');
    Isar? isar;
    try {
      isar = await Isar.open([TodoSchema], directory: dir.path);
      final repo = TodoRepository(isar);

      final stream = repo.watchTodos();

      final first = await repo.addTodo(title: '写代码');
      await repo.addTodo(title: '写文档');
      await repo.toggleDone(first, isDone: true);

      final list = await stream.firstWhere(
        (todos) =>
            todos.length == 2 &&
            todos[0].isDone == false &&
            todos[1].isDone == true,
      );
      expect(list[0].title, '写文档');
      expect(list[1].title, '写代码');
    } finally {
      await isar?.close(deleteFromDisk: true);
      await dir.delete(recursive: true);
    }
  });
}
