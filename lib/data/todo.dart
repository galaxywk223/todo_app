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

  // 重要性：0=重要，1=一般，2=不重要（兼容历史四象限时会归一化）
  int priority = 0;

  // 常驻项：每日固定显示在顶部
  bool isResident = false;

  // 常驻项最近一次完成时间（用于“每日自动重置”判定）
  DateTime? residentDoneAt;
}
