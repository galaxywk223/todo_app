import 'package:flutter/material.dart';

import '../data/todo.dart';
import '../data/todo_repository.dart';
import '../theme.dart';
import 'todo_edit_sheet.dart';
import 'todo_quadrant.dart';

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
          final todos = allTodos
              .where((t) => _showCompleted || !t.isDone)
              .toList();

          if (todos.isEmpty) {
            if (allTodos.isNotEmpty && !_showCompleted) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '太棒了！没有作业要做 🎉',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _showCompleted = true),
                      child: const Text('查看已完成任务'),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: Text(
                '今天很清闲哦 ~ ☕',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return _TodoCard(
                key: ValueKey(todo.id),
                todo: todo,
                repository: widget.repository,
                hideCompleted: !_showCompleted,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await TodoEditSheet.show(context, repository: widget.repository);
        },
        icon: const Icon(Icons.add),
        label: const Text('新增待办'),
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
    // If animating out, force checked state visual
    final isChecked = _isAnimatingOut ? true : todo.isDone;

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
        // elevation and margin are handled by Theme
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
                    value: isChecked,
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
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isChecked
                                  ? Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6)
                                  : null,
                            ),
                      ),
                      if (todo.note != null ||
                          todo.dueAt != null ||
                          todo.priority != 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildSubtitle(context, todo),
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
    // If we are checking it (value is true) AND we are hiding completed items,
    // then animate out.
    if (value && widget.hideCompleted) {
      setState(() {
        _isAnimatingOut = true;
      });
      await _controller.forward();
      if (mounted) {
        widget.repository.toggleDone(widget.todo.id, isDone: value);
      }
    } else {
      widget.repository.toggleDone(widget.todo.id, isDone: value);
    }
  }

  Widget _buildSubtitle(BuildContext context, Todo todo) {
    final items = <Widget>[];
    final quadrant = todoQuadrantFromCode(todo.priority);
    final scheme = Theme.of(context).colorScheme;

    // Priority chip
    items.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: quadrant
              .containerColor(scheme)
              .withValues(alpha: todo.isDone ? 0.5 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          quadrant.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: quadrant
                .onContainerColor(scheme)
                .withValues(alpha: todo.isDone ? 0.7 : 1),
          ),
        ),
      ),
    );

    // Due date
    if (todo.dueAt != null) {
      final isOverdue = todo.dueAt!.isBefore(DateTime.now()) && !todo.isDone;
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

    // Note
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

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
