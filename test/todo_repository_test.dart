import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:todo_app/data/todo.dart';
import 'package:todo_app/data/todo_priority.dart';
import 'package:todo_app/data/todo_repository.dart';

void main() {
  var isarAvailable = false;

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
      isarAvailable = true;
    } catch (_) {
      isarAvailable = false;
    }
  });

  test('TodoRepository：新增并读取', () async {
    final dir = await Directory.systemTemp.createTemp('todo_app_test_');
    Isar? isar;
    try {
      isar = await Isar.open([TodoSchema], directory: dir.path);
      final repo = IsarTodoRepository(isar);

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
  }, skip: !isarAvailable);

  test('TodoRepository：监听与切换完成状态', () async {
    final dir = await Directory.systemTemp.createTemp('todo_app_test_');
    Isar? isar;
    try {
      isar = await Isar.open([TodoSchema], directory: dir.path);
      final repo = IsarTodoRepository(isar);

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
  }, skip: !isarAvailable);

  test('TodoRepository：常驻项永远在普通项前，且按重要性排序', () async {
    final dir = await Directory.systemTemp.createTemp('todo_app_test_');
    Isar? isar;
    try {
      isar = await Isar.open([TodoSchema], directory: dir.path);
      final repo = IsarTodoRepository(isar);

      await repo.addTodo(title: '普通任务', priority: 0);
      await repo.addTodo(title: '常驻-不重要', priority: 2, isResident: true);
      await repo.addTodo(title: '常驻-重要', priority: 0, isResident: true);

      final list = await repo.watchTodos().firstWhere((todos) => todos.length == 3);
      expect(list[0].title, '常驻-重要');
      expect(list[1].title, '常驻-不重要');
      expect(list[2].title, '普通任务');
    } finally {
      await isar?.close(deleteFromDisk: true);
      await dir.delete(recursive: true);
    }
  }, skip: !isarAvailable);

  test('TodoRepository：常驻项完成状态按天自动重置', () async {
    final dir = await Directory.systemTemp.createTemp('todo_app_test_');
    Isar? isar;
    try {
      isar = await Isar.open([TodoSchema], directory: dir.path);
      final repo = IsarTodoRepository(isar);

      final id = await repo.addTodo(title: '每日打卡', isResident: true);
      await repo.toggleDone(id, isDone: true);
      final todo = await repo.getTodoById(id);
      expect(todo, isNotNull);
      expect(todo!.isResident, isTrue);
      expect(todo.residentDoneAt, isNotNull);

      expect(isResidentDoneToday(todo, now: todo.residentDoneAt!), isTrue);
      expect(
        isResidentDoneToday(
          todo,
          now: todo.residentDoneAt!.add(const Duration(days: 1)),
        ),
        isFalse,
      );
    } finally {
      await isar?.close(deleteFromDisk: true);
      await dir.delete(recursive: true);
    }
  }, skip: !isarAvailable);
}
