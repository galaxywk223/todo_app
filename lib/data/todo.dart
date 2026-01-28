import 'package:isar/isar.dart';

part 'todo.g.dart';

@collection
class Todo {
  Id id = Isar.autoIncrement;

  late String title;

  String? note;

  @Index()
  bool isDone = false;

  @Index()
  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  DateTime? dueAt;

  int priority = 0;
}
