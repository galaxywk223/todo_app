import 'package:flutter/material.dart';

enum TodoQuadrant {
  importantUrgent,
  importantNotUrgent,
  notImportantUrgent,
  notImportantNotUrgent,
}

TodoQuadrant todoQuadrantFromCode(int code) {
  return switch (code) {
    0 => TodoQuadrant.importantUrgent,
    1 => TodoQuadrant.importantNotUrgent,
    2 => TodoQuadrant.notImportantUrgent,
    3 => TodoQuadrant.notImportantNotUrgent,
    _ => TodoQuadrant.importantNotUrgent,
  };
}

extension TodoQuadrantX on TodoQuadrant {
  int get code => switch (this) {
        TodoQuadrant.importantUrgent => 0,
        TodoQuadrant.importantNotUrgent => 1,
        TodoQuadrant.notImportantUrgent => 2,
        TodoQuadrant.notImportantNotUrgent => 3,
      };

  String get label => switch (this) {
        TodoQuadrant.importantUrgent => '重要且紧急',
        TodoQuadrant.importantNotUrgent => '重要不紧急',
        TodoQuadrant.notImportantUrgent => '不重要但紧急',
        TodoQuadrant.notImportantNotUrgent => '不重要不紧急',
      };

  Color containerColor(ColorScheme scheme) => switch (this) {
        TodoQuadrant.importantUrgent => scheme.errorContainer,
        TodoQuadrant.importantNotUrgent => scheme.secondaryContainer,
        TodoQuadrant.notImportantUrgent => scheme.primaryContainer,
        TodoQuadrant.notImportantNotUrgent => scheme.surfaceContainerHighest,
      };

  Color onContainerColor(ColorScheme scheme) => switch (this) {
        TodoQuadrant.importantUrgent => scheme.onErrorContainer,
        TodoQuadrant.importantNotUrgent => scheme.onSecondaryContainer,
        TodoQuadrant.notImportantUrgent => scheme.onPrimaryContainer,
        TodoQuadrant.notImportantNotUrgent => scheme.onSurfaceVariant,
      };
}

