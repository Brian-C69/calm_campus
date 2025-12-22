import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import '../services/db_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/guide_overlay.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

enum _TaskFilter { all, today, week, completed }
enum _TaskSort { custom, newestFirst, oldestFirst, urgency }

class _TasksPageState extends State<TasksPage> {
  final List<Task> _tasks = [];
  bool _isLoading = true;
  bool _isAddingTask = false;
  Future<void> Function()? _dbListener;

  _TaskFilter _selectedFilter = _TaskFilter.all;
  _TaskSort _selectedSort = _TaskSort.custom;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _dbListener = _loadTasks;
    DbService.instance.addChangeListener(_loadTasks);
  }

  @override
  void dispose() {
    if (_dbListener != null) {
      DbService.instance.removeChangeListener(_loadTasks);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final List<Task> filteredTasks = _filteredTasks();
    final pendingCount = _tasks.where((task) => task.status == TaskStatus.pending).length;
    final completedCount = _tasks.length - pendingCount;

    return GuideOverlay(
      pageId: 'tasks',
      steps: const [
        GuideStep(
          title: 'Add tasks quickly',
          body: 'Tap the + button to add what you need to do and set a due date.',
        ),
        GuideStep(
          title: 'Mark done or edit',
          body: 'Use the checkbox to mark complete. Tap a task to edit or delete.',
        ),
        GuideStep(
          title: 'Filter your list',
          body: 'Use the filter and sort rows to focus on what matters.',
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.t('tasks.title')),
          actions: [
            IconButton(
              tooltip: strings.t('tasks.clearCompleted'),
              onPressed: completedCount > 0 ? _clearCompleted : null,
              icon: const Icon(Icons.clear_all),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TaskSummary(pendingCount: pendingCount, completedCount: completedCount),
              const SizedBox(height: 12),
              _FilterRow(
                selected: _selectedFilter,
                onSelected: (filter) => setState(() => _selectedFilter = filter),
              ),
              const SizedBox(height: 12),
              _SortRow(
                selected: _selectedSort,
                onSelected: (sort) => setState(() => _selectedSort = sort),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTasks.isEmpty
                        ? _EmptyState(onAdd: _openTaskComposer)
                        : _selectedSort == _TaskSort.custom
                            ? ReorderableListView.builder(
                                buildDefaultDragHandles: false,
                                itemCount: filteredTasks.length,
                                onReorder: (oldIndex, newIndex) =>
                                    _reorderTasks(filteredTasks, oldIndex, newIndex),
                                itemBuilder: (context, index) {
                                  final task = filteredTasks[index];
                                  return ReorderableDelayedDragStartListener(
                                    key: ValueKey(task),
                                    index: index,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _TaskCard(
                                        task: task,
                                        onToggle: () => _toggleTask(task),
                                        onDelete: () => _deleteTaskWithUndo(task),
                                        onLongPress: () => _showTaskQuickActions(task),
                                        showDragHandle: true,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : ListView.separated(
                              itemCount: filteredTasks.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                return _TaskCard(
                                  task: task,
                                  onToggle: () => _toggleTask(task),
                                  onDelete: () => _deleteTaskWithUndo(task),
                                  onLongPress: () => _showTaskQuickActions(task),
                                );
                              },
                            ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openTaskComposer,
          icon: const Icon(Icons.add_task),
          label: Text(strings.t('tasks.new')),
        ),
      ),
    );
  }

  Future<void> _loadTasks() async {
    final tasks = await DbService.instance.getAllTasks();
    if (!mounted) return;

    setState(() {
      _tasks
        ..clear()
        ..addAll(tasks);
      _isLoading = false;
    });
  }

  Future<void> _toggleTask(Task task) async {
    final toggled = task.copyWith(
      status: task.status == TaskStatus.pending ? TaskStatus.done : TaskStatus.pending,
    );

    if (task.id != null) {
      await DbService.instance.updateTaskStatus(task.id!, toggled.status);
    }

    if (!mounted) return;

    setState(() {
      final index = _tasks.indexOf(task);
      if (index != -1) {
        _tasks[index] = toggled;
      }
    });
  }

  Future<void> _clearCompleted() async {
    final completed = _tasks.where((task) => task.status == TaskStatus.done).toList();

    await Future.wait([
      for (final task in completed)
        if (task.id != null) DbService.instance.deleteTask(task.id!) else Future.value(0)
    ]);

    if (!mounted) return;

    setState(() {
      _tasks.removeWhere((task) => task.status == TaskStatus.done);
    });
  }

  Future<void> _deleteTaskWithUndo(Task task) async {
    if (task.id == null) return;
    final theme = Theme.of(context);
    final removed = _tasks.indexOf(task);
    final removedTask = task;
    await DbService.instance.deleteTask(task.id!);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('tasks')
            .delete()
            .eq('user_id', user.id)
            .eq('local_id', task.id!);
      } catch (_) {
        // best-effort; will be cleaned up on next sync if still present locally
      }
    }
    if (!mounted) return;
    setState(() {
      _tasks.remove(task);
    });
    final strings = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        content: Text(
          strings.t('tasks.deleted'),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        action: SnackBarAction(
          label: strings.t('common.undo'),
          textColor: theme.colorScheme.primary,
          onPressed: () async {
            final newId = await DbService.instance.restoreTask(removedTask);
            if (!mounted) return;
            setState(() {
              _tasks.insert(removed, removedTask.copyWith(id: newId));
            });
          },
        ),
      ),
    );
  }

  List<Task> _filteredTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(Duration(days: DateTime.daysPerWeek - today.weekday));

    final filtered = switch (_selectedFilter) {
      _TaskFilter.today => _tasks
          .where((task) => task.dueDate.year == today.year && task.dueDate.month == today.month && task.dueDate.day == today.day)
          .toList(),
      _TaskFilter.week =>
          _tasks.where((task) => !task.dueDate.isBefore(today) && !task.dueDate.isAfter(endOfWeek)).toList(),
      _TaskFilter.completed => _tasks.where((task) => task.status == TaskStatus.done).toList(),
      _TaskFilter.all => List.of(_tasks),
    };

    return _applySorting(filtered);
  }

  List<Task> _applySorting(List<Task> tasks) {
    final sorted = List<Task>.of(tasks);

    switch (_selectedSort) {
      case _TaskSort.newestFirst:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _TaskSort.oldestFirst:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _TaskSort.urgency:
        sorted.sort((a, b) {
          final priorityOrder = b.priority.index.compareTo(a.priority.index);
          if (priorityOrder != 0) return priorityOrder;
          return a.dueDate.compareTo(b.dueDate);
        });
        break;
      case _TaskSort.custom:
        break;
    }

    return sorted;
  }

  void _reorderTasks(List<Task> visibleTasks, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;

      final updatedVisible = List<Task>.of(visibleTasks);
      final movedTask = updatedVisible.removeAt(oldIndex);
      updatedVisible.insert(newIndex, movedTask);

      final queue = Queue<Task>.from(updatedVisible);
      final reordered = _tasks.map((task) {
        if (visibleTasks.contains(task)) {
          return queue.removeFirst();
        }
        return task;
      }).toList();

      _tasks
        ..clear()
        ..addAll(reordered);
    });
  }

  void _openTaskComposer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final insets = MediaQuery.of(context).viewInsets.bottom;
        final safeBottom = MediaQuery.of(context).padding.bottom;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: insets + safeBottom + 24,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: _TaskComposer(
              onSubmit: (task) async {
                await _addTask(task);
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _addTask(Task task) async {
    if (_isAddingTask) return;
    _isAddingTask = true;
    setState(() => _isLoading = true);
    await DbService.instance.insertTask(task);
    await _loadTasks();
    _isAddingTask = false;
  }

  Future<void> _showTaskQuickActions(Task task) async {
    final strings = AppLocalizations.of(context);
    final TaskStatus toggledStatus =
        task.status == TaskStatus.pending ? TaskStatus.done : TaskStatus.pending;
    final TaskPriority nextPriority = switch (task.priority) {
      TaskPriority.low => TaskPriority.medium,
      TaskPriority.medium => TaskPriority.high,
      TaskPriority.high => TaskPriority.low,
    };
    final nextPriorityLabel = switch (nextPriority) {
      TaskPriority.low => strings.t('tasks.priority.low'),
      TaskPriority.medium => strings.t('tasks.priority.medium'),
      TaskPriority.high => strings.t('tasks.priority.high'),
    };

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(toggledStatus == TaskStatus.done ? Icons.undo : Icons.check_circle),
              title: Text(
                toggledStatus == TaskStatus.done
                    ? strings.t('tasks.markPending')
                    : strings.t('tasks.markDone'),
              ),
              onTap: () => Navigator.of(context).pop('toggle'),
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: Text(
                strings
                    .t('tasks.priority.next')
                    .replaceFirst('{priority}', nextPriorityLabel),
              ),
              onTap: () => Navigator.of(context).pop('priority'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(strings.t('common.delete')),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'toggle') {
      await _toggleTask(task);
    } else if (action == 'priority') {
      final updated = task.copyWith(priority: nextPriority);
      if (task.id != null) {
        await DbService.instance.updateTaskPriority(task.id!, nextPriority);
      }
      if (!mounted) return;
      setState(() {
        final idx = _tasks.indexOf(task);
        if (idx != -1) _tasks[idx] = updated;
      });
    } else if (action == 'delete') {
      await _deleteTaskWithUndo(task);
    }
  }
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({required this.pendingCount, required this.completedCount});

  final int pendingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerHigh,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.t('tasks.summary.title'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(strings.t('tasks.summary.subtitle'),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text('${strings.t('tasks.pending')}: $pendingCount',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: colorScheme.primary)),
                Text('${strings.t('tasks.done')}: $completedCount',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});
  final _TaskFilter selected;
  final ValueChanged<_TaskFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: _TaskFilter.values
          .map(
            (filter) => FilterChip(
              label: Text(_labelForFilter(filter, strings)),
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
            ),
          )
          .toList(),
    );
  }

  String _labelForFilter(_TaskFilter filter, AppLocalizations strings) {
    switch (filter) {
      case _TaskFilter.today:
        return strings.t('tasks.filter.today');
      case _TaskFilter.week:
        return strings.t('tasks.filter.week');
      case _TaskFilter.completed:
        return strings.t('tasks.filter.completed');
      case _TaskFilter.all:
        return strings.t('tasks.filter.all');
    }
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({required this.selected, required this.onSelected});

  final _TaskSort selected;
  final ValueChanged<_TaskSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sort, size: 18),
            const SizedBox(width: 6),
            Text(strings.t('tasks.sort.title'), style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildChip(strings.t('tasks.sort.custom'), _TaskSort.custom),
            _buildChip(strings.t('tasks.sort.newest'), _TaskSort.newestFirst),
            _buildChip(strings.t('tasks.sort.oldest'), _TaskSort.oldestFirst),
            _buildChip(strings.t('tasks.sort.urgency'), _TaskSort.urgency),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, _TaskSort sort) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == sort,
      onSelected: (_) => onSelected(sort),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    this.onDelete,
    this.onLongPress,
    this.showDragHandle = false,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dueText = _dueText(context, task.dueDate);
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && task.status == TaskStatus.pending;

    return Card(
      elevation: 0,
      child: InkWell(
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.status == TaskStatus.done,
                onChanged: (_) => onToggle(),
                shape: const CircleBorder(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  decoration: task.status == TaskStatus.done
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                              ),
                          ),
                        ),
                        _PriorityBadge(priority: task.priority),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: AppLocalizations.of(context).t('common.delete'),
                          onPressed: onDelete,
                        ),
                        if (showDragHandle) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.drag_indicator_rounded,
                            color: colorScheme.outline,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(task.subject, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      dueText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dueText(BuildContext context, DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final strings = AppLocalizations.of(context);
    if (dueDay == today) return strings.t('tasks.due.today');
    if (dueDay.isBefore(today)) {
      return '${strings.t('tasks.due.overdue')} - ${_formatDate(dueDate)}';
    }
    if (dueDay.difference(today).inDays == 1) return strings.t('tasks.due.tomorrow');
    return '${strings.t('tasks.due.on')} ${_formatDate(dueDate)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat.MMMd().format(date);
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color background;
    Color foreground;

    switch (priority) {
      case TaskPriority.high:
        background = colorScheme.errorContainer;
        foreground = colorScheme.onErrorContainer;
        break;
      case TaskPriority.low:
        background = colorScheme.tertiaryContainer;
        foreground = colorScheme.onTertiaryContainer;
        break;
      case TaskPriority.medium:
      background = colorScheme.secondaryContainer;
        foreground = colorScheme.onSecondaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        '${priority.name[0].toUpperCase()}${priority.name.substring(1)}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox, size: 48),
          const SizedBox(height: 8),
          Text(strings.t('tasks.empty.title'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(strings.t('tasks.empty.subtitle')),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(strings.t('tasks.empty.add')),
          ),
        ],
      ),
    );
  }
}

class _TaskComposer extends StatefulWidget {
  const _TaskComposer({required this.onSubmit});

  final ValueChanged<Task> onSubmit;

  @override
  State<_TaskComposer> createState() => _TaskComposerState();
}

class _TaskComposerState extends State<_TaskComposer> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TaskPriority _priority = TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _subjectController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.t('tasks.new'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: strings.t('tasks.field.title')),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _subjectController,
          decoration: InputDecoration(labelText: strings.t('tasks.field.subject')),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text('${strings.t('tasks.field.due')}: ${_formatDate(_selectedDate)}'),
            ),
            TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(strings.t('tasks.field.pickDate')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskPriority.values
              .map(
                (priority) => ChoiceChip(
                  label: Text(priority.name),
                  selected: _priority == priority,
                  onSelected: (_) => setState(() => _priority = priority),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(strings.t('common.cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isValid ? _submit : null,
                  icon: const Icon(Icons.check),
                  label: Text(strings.t('common.save')),
                ),
              ],
            ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() => _selectedDate = selected);
    }
  }

  void _submit() {
    final newTask = Task(
      title: _titleController.text.trim(),
      subject: _subjectController.text.trim(),
      dueDate: _selectedDate,
      priority: _priority,
    );

    widget.onSubmit(newTask);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _onTextChanged() {
    setState(() {});
  }

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty && _subjectController.text.trim().isNotEmpty;
}
