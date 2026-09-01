import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../courses/course_repository.dart';
import 'academic_task.dart';
import 'task_repository.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String filter = 'all';
  String search = '';
  Future<void> _toggle(AcademicTask task) async {
    final complete = task.status != TaskStatus.completed;
    await ref.read(taskRepositoryProvider).update(AcademicTask(
        id: task.id,
        courseId: task.courseId,
        semesterId: task.semesterId,
        title: task.title,
        description: task.description,
        type: task.type,
        dueDate: task.dueDate,
        dueTime: task.dueTime,
        priority: task.priority,
        status: complete ? TaskStatus.completed : TaskStatus.notStarted,
        reminderAt: task.reminderAt,
        completedAt: complete ? DateTime.now() : null,
        location: task.location,
        createdAt: task.createdAt,
        updatedAt: DateTime.now()));
    ref.invalidate(tasksProvider);
  }

  Future<void> _delete(AcademicTask task) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Delete task?'),
                content: Text('“${task.title}” will be permanently removed.'),
                actions: [
                  TextButton(
                      onPressed: () => c.pop(false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => c.pop(true), child: const Text('Delete'))
                ]));
    if (yes == true) {
      await ref.read(taskRepositoryProvider).delete(task.id);
      ref.invalidate(tasksProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final courses = ref.watch(coursesProvider).valueOrNull ?? [];
    return Scaffold(
        appBar: AppBar(title: const Text('Tasks')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/tasks/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add task')),
        body: tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Tasks could not be loaded.')),
            data: (items) {
              final now = DateTime.now();
              final shown = items.where((task) {
                final course =
                    courses.where((c) => c.id == task.courseId).firstOrNull;
                final query = search.toLowerCase();
                final matches = query.isEmpty ||
                    task.title.toLowerCase().contains(query) ||
                    (task.description?.toLowerCase().contains(query) ??
                        false) ||
                    (course?.name.toLowerCase().contains(query) ?? false);
                if (!matches) return false;
                return switch (filter) {
                  'today' => deadlineLabel(task, now) == 'Due today',
                  'upcoming' => !task.isOverdueAt(now) &&
                      task.status != TaskStatus.completed,
                  'overdue' => task.isOverdueAt(now),
                  'completed' => task.status == TaskStatus.completed,
                  _ => true
                };
              }).toList()
                ..sort((a, b) {
                  if (a.isOverdueAt(now) != b.isOverdueAt(now)) {
                    return a.isOverdueAt(now) ? -1 : 1;
                  }
                  return a.deadline.compareTo(b.deadline);
                });
              return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    SearchBar(
                        hintText: 'Search tasks',
                        leading: const Icon(Icons.search),
                        onChanged: (v) => setState(() => search = v)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: [
                          'all',
                          'today',
                          'upcoming',
                          'overdue',
                          'completed'
                        ]
                                .map((v) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                        label: Text(v[0].toUpperCase() +
                                            v.substring(1)),
                                        selected: filter == v,
                                        onSelected: (_) =>
                                            setState(() => filter = v))))
                                .toList())),
                    const SizedBox(height: 14),
                    if (shown.isEmpty)
                      EmptyState(
                          icon: Icons.task_alt,
                          title: filter == 'all'
                              ? 'No upcoming tasks'
                              : 'No tasks in this view',
                          message: filter == 'all'
                              ? "You're all caught up."
                              : 'Try another filter or add a task.',
                          actionLabel: 'Add task',
                          onAction: () => context.push('/tasks/add'))
                    else
                      ...shown.map((task) {
                        final course = courses
                            .where((c) => c.id == task.courseId)
                            .firstOrNull;
                        final priorityColor = switch (task.priority) {
                          TaskPriority.high => AppSemanticColors.danger(
                              Theme.of(context).brightness),
                          TaskPriority.medium => AppSemanticColors.warning(
                              Theme.of(context).brightness),
                          TaskPriority.low =>
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        };
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 4),
                            leading: Semantics(
                                label: task.status == TaskStatus.completed
                                    ? 'Mark incomplete'
                                    : 'Mark completed',
                                child: Checkbox(
                                    value: task.status == TaskStatus.completed,
                                    onChanged: (_) => _toggle(task))),
                            title: Row(children: [
                              Expanded(
                                child: Text(task.title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        decoration:
                                            task.status == TaskStatus.completed
                                                ? TextDecoration.lineThrough
                                                : null)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                task.priority.label.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: priorityColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ]),
                            subtitle: Text([
                              if (course != null) course.name,
                              task.type.label,
                              deadlineLabel(task, now),
                              if (task.dueTime != null) task.dueTime!,
                            ].join(' • ')),
                            trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    context.push('/tasks/${task.id}/edit',
                                        extra: task);
                                  }
                                  if (v == 'delete') {
                                    _delete(task);
                                  }
                                },
                                itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'))
                                    ]),
                          ),
                        );
                      })
                  ]);
            }));
  }
}
