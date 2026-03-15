import 'todo.dart';

const Duration veryUrgentThreshold = Duration(hours: 24);
const Duration urgentThreshold = Duration(hours: 72);

enum ImportanceLevel {
  important,
  general,
  notImportant,
}

enum UrgencyLevel {
  veryUrgent,
  urgent,
  normal,
  none,
}

int importanceCode(ImportanceLevel level) {
  return switch (level) {
    ImportanceLevel.important => 0,
    ImportanceLevel.general => 1,
    ImportanceLevel.notImportant => 2,
  };
}

ImportanceLevel importanceFromCode(int code) {
  final normalized = normalizeImportanceFromLegacy(code);
  return switch (normalized) {
    0 => ImportanceLevel.important,
    1 => ImportanceLevel.general,
    _ => ImportanceLevel.notImportant,
  };
}

int normalizeImportanceFromLegacy(int storedPriority) {
  return switch (storedPriority) {
    0 || 1 || 2 => storedPriority,
    3 => 2,
    _ => storedPriority < 0
        ? 0
        : (storedPriority > 2 ? 2 : storedPriority),
  };
}

UrgencyLevel urgencyByDueAt(
  DateTime? dueAt, {
  DateTime? now,
}) {
  if (dueAt == null) return UrgencyLevel.none;
  final current = now ?? DateTime.now();
  final remaining = dueAt.difference(current);
  if (remaining <= veryUrgentThreshold) {
    return UrgencyLevel.veryUrgent;
  }
  if (remaining <= urgentThreshold) {
    return UrgencyLevel.urgent;
  }
  return UrgencyLevel.normal;
}

int urgencyRank(UrgencyLevel level) {
  return switch (level) {
    UrgencyLevel.veryUrgent => 0,
    UrgencyLevel.urgent => 1,
    UrgencyLevel.normal => 2,
    UrgencyLevel.none => 3,
  };
}

bool isSameLocalDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isResidentDoneToday(
  Todo todo, {
  DateTime? now,
}) {
  if (!todo.isResident) return todo.isDone;
  final doneAt = todo.residentDoneAt;
  if (doneAt == null) return false;
  final current = now ?? DateTime.now();
  return isSameLocalDate(doneAt, current);
}

int normalizedImportanceForTodo(Todo todo) {
  return normalizeImportanceFromLegacy(todo.priority);
}
