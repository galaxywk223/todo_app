import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/todo.dart';
import '../data/todo_priority.dart';
import '../data/todo_repository.dart';
import '../theme.dart';
import 'todo_edit_sheet.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({
    super.key,
    required this.repository,
    required this.themeController,
  });

  final TodoRepository repository;
  final ThemeController themeController;

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_rounded),
            SizedBox(width: 8),
            Text('待办清单'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _showCompleted ? '隐藏已完成' : '显示已完成',
            icon: Icon(
              _showCompleted ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
          ),
          IconButton(
            tooltip: '切换主题',
            icon: const Icon(Icons.palette_outlined),
            onPressed: _showThemeDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Todo>>(
        stream: widget.repository.watchTodos(),
        builder: (context, snapshot) {
          final allTodos = snapshot.data ?? const <Todo>[];
          final residents = allTodos.where((t) => t.isResident).toList();
          final normalTodos = allTodos
              .where((t) => !t.isResident)
              .where((t) => _showCompleted || !t.isDone)
              .toList();

          if (residents.isEmpty && normalTodos.isEmpty) {
            if (allTodos.any((t) => !t.isResident) && !_showCompleted) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '太棒了，当前没有普通待办',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _showCompleted = true),
                      child: const Text('查看已完成'),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: Text(
                '暂时没有待办，去休息一下吧',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              if (residents.isNotEmpty) ...[
                const _SectionTitle(title: '今日常驻'),
                ...residents.map((todo) {
                  return _TodoCard(
                    key: ValueKey('resident_${todo.id}'),
                    todo: todo,
                    repository: widget.repository,
                    hideCompleted: false,
                  );
                }),
              ],
              if (normalTodos.isNotEmpty) ...[
                const _SectionTitle(title: '普通待办'),
                ...normalTodos.map((todo) {
                  return _TodoCard(
                    key: ValueKey('normal_${todo.id}'),
                    todo: todo,
                    repository: widget.repository,
                    hideCompleted: !_showCompleted,
                  );
                }),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await TodoEditSheet.show(context, repository: widget.repository);
        },
        icon: const Icon(Icons.add),
        label: const Text('新建待办'),
      ),
    );
  }

  void _showThemeDialog() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '选择主题',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ThemeController.availableThemes.length,
                  itemBuilder: (context, index) {
                    final theme = ThemeController.availableThemes[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: theme.seedColor),
                      title: Text(theme.name),
                      onTap: () {
                        widget.themeController.setTheme(theme);
                        Navigator.pop(context);
                      },
                      selected: widget.themeController.value.name == theme.name,
                      trailing: widget.themeController.value.name == theme.name
                          ? const Icon(Icons.check)
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TodoCard extends StatefulWidget {
  const _TodoCard({
    super.key,
    required this.todo,
    required this.repository,
    required this.hideCompleted,
  });

  final Todo todo;
  final TodoRepository repository;
  final bool hideCompleted;

  @override
  State<_TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<_TodoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<double> _fadeAnimation;
  bool _isAnimatingOut = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnimatingOut) {
      return SizeTransition(
        sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(_sizeAnimation),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnimation),
          child: _buildCard(context),
        ),
      );
    }
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    final todo = widget.todo;
    final now = DateTime.now();
    final done = _isAnimatingOut ? true : isResidentDoneToday(todo, now: now);

    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('删除待办？'),
                content: Text('“${todo.title}”将被删除。'),
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
      },
      onDismissed: (_) {
        widget.repository.deleteTodo(todo.id);
      },
      child: Card(
        child: InkWell(
          onTap: () async {
            await TodoEditSheet.show(
              context,
              repository: widget.repository,
              todoId: todo.id,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    shape: const CircleBorder(),
                    value: done,
                    onChanged: (value) {
                      if (value == null) return;
                      _onCheckboxChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              decoration: done ? TextDecoration.lineThrough : null,
                              color: done
                                  ? Theme.of(context).colorScheme.onSurface
                                        .withOpacity(0.6)
                                  : null,
                            ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildSubtitle(context, todo, done),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onCheckboxChanged(bool value) async {
    if (value && widget.hideCompleted) {
      setState(() {
        _isAnimatingOut = true;
      });
      await _controller.forward();
      if (mounted) {
        await widget.repository.toggleDone(widget.todo.id, isDone: value);
      }
      return;
    }
    await widget.repository.toggleDone(widget.todo.id, isDone: value);
  }

  Widget _buildSubtitle(BuildContext context, Todo todo, bool done) {
    final items = <Widget>[];
    final scheme = Theme.of(context).colorScheme;
    final importance = importanceFromCode(todo.priority);

    items.add(
      _Pill(
        text: _importanceLabel(importance),
        background: _importanceColor(scheme, importance).withOpacity(done ? 0.5 : 1),
        foreground: _importanceOnColor(scheme, importance).withOpacity(done ? 0.7 : 1),
      ),
    );

    if (!todo.isResident) {
      final urgency = urgencyByDueAt(todo.dueAt);
      if (urgency != UrgencyLevel.none) {
        final isOverdue = (todo.dueAt?.isBefore(DateTime.now()) ?? false) && !done;
        items.add(
          _Pill(
            text: _urgencyLabel(urgency),
            background: _urgencyColor(scheme, urgency, isOverdue).withOpacity(done ? 0.5 : 1),
            foreground: _urgencyOnColor(scheme, urgency, isOverdue).withOpacity(done ? 0.7 : 1),
          ),
        );
      }
    }

    if (todo.dueAt != null && !todo.isResident) {
      final isOverdue = todo.dueAt!.isBefore(DateTime.now()) && !done;
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDateTime(todo.dueAt!),
              style: TextStyle(
                fontSize: 12,
                color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    final note = todo.note?.trim();
    if (note != null && note.isNotEmpty) {
      items.add(
        Text(
          note,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }

  String _importanceLabel(ImportanceLevel level) {
    return switch (level) {
      ImportanceLevel.important => '重要',
      ImportanceLevel.general => '一般',
      ImportanceLevel.notImportant => '不重要',
    };
  }

  String _urgencyLabel(UrgencyLevel level) {
    return switch (level) {
      UrgencyLevel.veryUrgent => '非常紧急',
      UrgencyLevel.urgent => '紧急',
      UrgencyLevel.normal => '普通',
      UrgencyLevel.none => '无紧急度',
    };
  }

  Color _importanceColor(ColorScheme scheme, ImportanceLevel level) {
    return switch (level) {
      ImportanceLevel.important => scheme.errorContainer,
      ImportanceLevel.general => scheme.primaryContainer,
      ImportanceLevel.notImportant => scheme.surfaceContainerHighest,
    };
  }

  Color _importanceOnColor(ColorScheme scheme, ImportanceLevel level) {
    return switch (level) {
      ImportanceLevel.important => scheme.onErrorContainer,
      ImportanceLevel.general => scheme.onPrimaryContainer,
      ImportanceLevel.notImportant => scheme.onSurfaceVariant,
    };
  }

  Color _urgencyColor(ColorScheme scheme, UrgencyLevel level, bool isOverdue) {
    if (isOverdue) return scheme.errorContainer;
    return switch (level) {
      UrgencyLevel.veryUrgent => scheme.errorContainer,
      UrgencyLevel.urgent => scheme.tertiaryContainer,
      UrgencyLevel.normal => scheme.secondaryContainer,
      UrgencyLevel.none => scheme.surfaceContainerHighest,
    };
  }

  Color _urgencyOnColor(ColorScheme scheme, UrgencyLevel level, bool isOverdue) {
    if (isOverdue) return scheme.onErrorContainer;
    return switch (level) {
      UrgencyLevel.veryUrgent => scheme.onErrorContainer,
      UrgencyLevel.urgent => scheme.onTertiaryContainer,
      UrgencyLevel.normal => scheme.onSecondaryContainer,
      UrgencyLevel.none => scheme.onSurfaceVariant,
    };
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  return DateFormat('yyyy年M月d日 HH:mm', 'zh_CN').format(dt);
}
