import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/todo.dart';
import 'package:todo_app/data/todo_priority.dart';

void main() {
  test('urgencyByDueAt: 24小时内 => veryUrgent', () {
    final now = DateTime(2026, 3, 4, 10, 0);
    final dueAt = now.add(const Duration(hours: 6));
    expect(urgencyByDueAt(dueAt, now: now), UrgencyLevel.veryUrgent);
  });

  test('urgencyByDueAt: 24~72小时 => urgent', () {
    final now = DateTime(2026, 3, 4, 10, 0);
    final dueAt = now.add(const Duration(hours: 30));
    expect(urgencyByDueAt(dueAt, now: now), UrgencyLevel.urgent);
  });

  test('urgencyByDueAt: 超过72小时 => normal', () {
    final now = DateTime(2026, 3, 4, 10, 0);
    final dueAt = now.add(const Duration(days: 5));
    expect(urgencyByDueAt(dueAt, now: now), UrgencyLevel.normal);
  });

  test('urgencyByDueAt: 无截止时间 => none', () {
    expect(urgencyByDueAt(null), UrgencyLevel.none);
  });

  test('normalizeImportanceFromLegacy 映射正确', () {
    expect(normalizeImportanceFromLegacy(0), 0);
    expect(normalizeImportanceFromLegacy(1), 1);
    expect(normalizeImportanceFromLegacy(2), 2);
    expect(normalizeImportanceFromLegacy(3), 2);
  });

  test('isResidentDoneToday 基于日期判定', () {
    final now = DateTime(2026, 3, 4, 21, 0);
    final todo = Todo()
      ..isResident = true
      ..residentDoneAt = DateTime(2026, 3, 4, 8, 0);
    expect(isResidentDoneToday(todo, now: now), isTrue);
    expect(
      isResidentDoneToday(todo, now: DateTime(2026, 3, 5, 0, 1)),
      isFalse,
    );
  });
}
