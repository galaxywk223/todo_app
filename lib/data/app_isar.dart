import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'todo.dart';

Future<Isar> openIsar() {
  _isarFuture ??= _openIsarInternal();
  return _isarFuture!;
}

Future<Isar>? _isarFuture;

Future<Isar> _openIsarInternal() async {
  if (kIsWeb) {
    throw UnsupportedError('Isar is not supported on web.');
  }

  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [TodoSchema],
    directory: dir.path,
  );
}
