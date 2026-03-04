import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';

import '../data/todo.dart';
import '../data/todo_priority.dart';
import '../data/todo_repository.dart';

class TodoEditSheet extends StatefulWidget {
  const TodoEditSheet({super.key, required this.repository, this.todoId});

  final TodoRepository repository;
  final Id? todoId;

  static Future<void> show(
    BuildContext context, {
    required TodoRepository repository,
    Id? todoId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          TodoEditSheet(repository: repository, todoId: todoId),
    );
  }

  @override
  State<TodoEditSheet> createState() => _TodoEditSheetState();
}

class _TodoEditSheetState extends State<TodoEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  bool _isResident = false;
  DateTime? _dueAt;
  ImportanceLevel _importance = ImportanceLevel.important;
  Todo? _editingTodo;

  late Future<Todo?> _todoFuture;

  @override
  void initState() {
    super.initState();
    _todoFuture = widget.todoId == null
        ? Future.value(null)
        : widget.repository.getTodoById(widget.todoId!);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Todo?>(
      future: _todoFuture,
      builder: (context, snapshot) {
        if (widget.todoId != null &&
            snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final todo = snapshot.data;
        if (!_initialized) {
          _initialized = true;
          _editingTodo = todo;
          if (todo != null) {
            _titleController.text = todo.title;
            _noteController.text = todo.note ?? '';
            _dueAt = todo.dueAt;
            _isResident = todo.isResident;
            _importance = importanceFromCode(todo.priority);
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          TextFormField(
                            controller: _titleController,
                            autofocus: widget.todoId == null,
                            decoration: const InputDecoration(
                              labelText: '标题',
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '请输入标题';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _noteController,
                            decoration: const InputDecoration(
                              labelText: '备注（可选）',
                              border: OutlineInputBorder(),
                            ),
                            minLines: 3,
                            maxLines: 6,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('设为常驻项'),
                            subtitle: const Text('每日固定显示在顶部，仅展示重要性'),
                            value: _isResident,
                            onChanged: (value) {
                              setState(() {
                                _isResident = value;
                                if (_isResident) {
                                  _dueAt = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildImportanceField(context),
                          const SizedBox(height: 12),
                          _buildUrgencyField(context),
                          const SizedBox(height: 12),
                          _DueAtTile(
                            dueAt: _dueAt,
                            enabled: !_isResident,
                            onPick: _isResident ? null : _pickDueAt,
                            onClear: _isResident || _dueAt == null
                                ? null
                                : () {
                                    setState(() => _dueAt = null);
                                  },
                          ),
                          const SizedBox(height: 24),
                          if (widget.todoId != null)
                            FilledButton.icon(
                              onPressed: _saving ? null : _onDeletePressed,
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onError,
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('删除此待办'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          Text(
            widget.todoId == null ? '新建待办' : '编辑待办',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextButton(
            onPressed: _saving ? null : _onSavePressed,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildImportanceField(BuildContext context) {
    return DropdownButtonFormField<ImportanceLevel>(
      initialValue: _importance,
      decoration: const InputDecoration(
        labelText: '重要性',
        border: OutlineInputBorder(),
      ),
      items: ImportanceLevel.values.map((level) {
        final scheme = Theme.of(context).colorScheme;
        final color = _importanceColor(scheme, level);
        return DropdownMenuItem(
          value: level,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(_importanceLabel(level)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _importance = value);
      },
    );
  }

  Widget _buildUrgencyField(BuildContext context) {
    final urgency = _isResident
        ? UrgencyLevel.none
        : urgencyByDueAt(_dueAt);

    String label;
    if (_isResident) {
      label = '常驻项不计算紧急度';
    } else {
      label = _urgencyLabel(urgency);
    }

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '紧急度（自动）',
        border: OutlineInputBorder(),
      ),
      child: Text(
        label,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Future<void> _onSavePressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final title = _titleController.text.trim();
      final note = _noteController.text.trim();
      final importanceCodeValue = importanceCode(_importance);
      final dueAtValue = _isResident ? null : _dueAt;

      if (_editingTodo == null) {
        await widget.repository.addTodo(
          title: title,
          note: note.isEmpty ? null : note,
          dueAt: dueAtValue,
          priority: importanceCodeValue,
          isResident: _isResident,
        );
      } else {
        final todo = _editingTodo!
          ..title = title
          ..note = note.isEmpty ? null : note
          ..dueAt = dueAtValue
          ..priority = importanceCodeValue
          ..isResident = _isResident
          ..residentDoneAt = _isResident ? _editingTodo!.residentDoneAt : null;
        await widget.repository.saveTodo(todo);
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onDeletePressed() async {
    final todoId = widget.todoId;
    if (todoId == null) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除待办？'),
            content: const Text('删除后无法恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await widget.repository.deleteTodo(todoId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDueAt() async {
    final now = DateTime.now();
    final initialDate = _dueAt ?? now;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
      initialDate: DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
      ),
      helpText: '选择到期日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (date == null || !mounted) return;

    final initialTime = _dueAt == null
        ? TimeOfDay(hour: now.hour, minute: now.minute)
        : TimeOfDay(hour: _dueAt!.hour, minute: _dueAt!.minute);
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: '选择到期时间',
      cancelText: '取消',
      confirmText: '确定',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _importanceLabel(ImportanceLevel level) {
    return switch (level) {
      ImportanceLevel.important => '重要',
      ImportanceLevel.general => '一般',
      ImportanceLevel.notImportant => '不重要',
    };
  }

  Color _importanceColor(ColorScheme scheme, ImportanceLevel level) {
    return switch (level) {
      ImportanceLevel.important => scheme.errorContainer,
      ImportanceLevel.general => scheme.primaryContainer,
      ImportanceLevel.notImportant => scheme.surfaceContainerHighest,
    };
  }

  String _urgencyLabel(UrgencyLevel level) {
    return switch (level) {
      UrgencyLevel.veryUrgent => '非常紧急（24小时内）',
      UrgencyLevel.urgent => '紧急（72小时内）',
      UrgencyLevel.normal => '普通（72小时外）',
      UrgencyLevel.none => '无紧急度',
    };
  }
}

class _DueAtTile extends StatelessWidget {
  const _DueAtTile({
    required this.dueAt,
    required this.enabled,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? dueAt;
  final bool enabled;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '到期时间（可选）',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              enabled
                  ? (dueAt == null ? '未设置' : _formatDateTime(dueAt!))
                  : '常驻项不设置到期时间',
            ),
          ),
          TextButton(
            onPressed: onPick,
            child: const Text('选择'),
          ),
          if (onClear != null)
            TextButton(onPressed: onClear, child: const Text('清空')),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  return DateFormat('yyyy年M月d日 HH:mm', 'zh_CN').format(dt);
}
