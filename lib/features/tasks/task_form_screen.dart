import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../courses/course_repository.dart';
import 'academic_task.dart';
import 'task_repository.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.task, this.initialCourseId});
  final AcademicTask? task;
  final String? initialCourseId;
  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final key = GlobalKey<FormState>();
  late final TextEditingController title, description, location;
  String? courseId;
  TaskType type = TaskType.assignment;
  TaskPriority priority = TaskPriority.medium;
  TaskStatus status = TaskStatus.notStarted;
  DateTime? due;
  TimeOfDay? time;
  String reminder = 'none';
  DateTime? customReminder;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final t = widget.task;
    courseId = t?.courseId ?? widget.initialCourseId;
    type = t?.type ?? type;
    priority = t?.priority ?? priority;
    status = t?.status ?? status;
    due = t?.dueDate;
    location = TextEditingController(text: t?.location);
    title = TextEditingController(text: t?.title);
    description = TextEditingController(text: t?.description);
    if (t?.dueTime != null) {
      final p = t!.dueTime!.split(':');
      time = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    if (t?.reminderAt != null) {
      reminder = 'custom';
      customReminder = t!.reminderAt;
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    location.dispose();
    super.dispose();
  }

  DateTime? _reminderAt(DateTime deadline) {
    if (reminder == 'none') return null;
    if (reminder == 'custom') return customReminder;
    final minutes = int.parse(reminder);
    return reminderTime(deadline, minutes);
  }

  Future<void> save() async {
    if (!(key.currentState?.validate() ?? false)) return;
    if (due == null) {
      setState(() {});
      return;
    }
    final now = DateTime.now();
    final dueTime = time == null
        ? null
        : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';
    final deadline = time == null
        ? DateTime(due!.year, due!.month, due!.day, 23, 59, 59)
        : DateTime(due!.year, due!.month, due!.day, time!.hour, time!.minute);
    final task = AcademicTask(
        id: widget.task?.id ?? const Uuid().v4(),
        courseId: courseId,
        semesterId: 1,
        title: title.text.trim(),
        description: description.text,
        type: type,
        dueDate: due!,
        dueTime: dueTime,
        priority: priority,
        status: status,
        reminderAt: _reminderAt(deadline),
        completedAt: status == TaskStatus.completed
            ? (widget.task?.completedAt ?? now)
            : null,
        location: location.text,
        createdAt: widget.task?.createdAt ?? now,
        updatedAt: now);
    setState(() => saving = true);
    final repo = ref.read(taskRepositoryProvider);
    final reminderEnabled =
        widget.task == null ? await repo.create(task) : await repo.update(task);
    ref.invalidate(tasksProvider);
    if (courseId != null) ref.invalidate(tasksForCourseProvider(courseId!));
    if (!mounted) return;
    if (!reminderEnabled && task.reminderAt != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Task saved, but notification permission was denied. The reminder is disabled.')));
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);
    return Scaffold(
        appBar:
            AppBar(title: Text(widget.task == null ? 'Add task' : 'Edit task')),
        body: Form(
            key: key,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              TextFormField(
                  controller: title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Title is required'
                      : null),
              const SizedBox(height: 12),
              courses.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Courses unavailable'),
                  data: (items) => DropdownButtonFormField<String?>(
                      initialValue: courseId,
                      decoration: const InputDecoration(labelText: 'Course'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('General academic task')),
                        ...items.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)))
                      ],
                      onChanged: (v) => setState(() => courseId = v))),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: TaskType.values
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(v.label)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 3650)),
                              initialDate: due ?? DateTime.now());
                          if (d != null) setState(() => due = d);
                        },
                        icon: const Icon(Icons.event),
                        label: Text(due == null
                            ? 'Due date *'
                            : '${due!.day}/${due!.month}/${due!.year}'))),
                const SizedBox(width: 10),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () async {
                          final t = await showTimePicker(
                              context: context,
                              initialTime: time ?? TimeOfDay.now());
                          if (t != null) setState(() => time = t);
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text(time?.format(context) ?? 'Due time')))
              ]),
              if (due == null)
                Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text('Due date is required',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: TaskPriority.values
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(v.label)))
                      .toList(),
                  onChanged: (v) => setState(() => priority = v!)),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: TaskStatus.values
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(v.label)))
                      .toList(),
                  onChanged: (v) => setState(() => status = v!)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  initialValue: reminder,
                  decoration: const InputDecoration(labelText: 'Reminder'),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('No reminder')),
                    DropdownMenuItem(value: '0', child: Text('At due time')),
                    DropdownMenuItem(
                        value: '10', child: Text('10 minutes before')),
                    DropdownMenuItem(
                        value: '30', child: Text('30 minutes before')),
                    DropdownMenuItem(value: '60', child: Text('1 hour before')),
                    DropdownMenuItem(
                        value: '1440', child: Text('1 day before')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom'))
                  ],
                  onChanged: (v) => setState(() => reminder = v!)),
              if (reminder == 'custom')
                OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: due ??
                              DateTime.now().add(const Duration(days: 3650)),
                          initialDate: customReminder ?? DateTime.now());
                      if (d == null || !mounted) return;
                      final t = await showTimePicker(
                          context: this.context,
                          initialTime: TimeOfDay.fromDateTime(
                              customReminder ?? DateTime.now()));
                      if (!mounted) return;
                      if (t != null) {
                        setState(() => customReminder =
                            DateTime(d.year, d.month, d.day, t.hour, t.minute));
                      }
                    },
                    child: Text(customReminder == null
                        ? 'Choose reminder time'
                        : '${customReminder!.day}/${customReminder!.month} ${TimeOfDay.fromDateTime(customReminder!).format(context)}')),
              if (type == TaskType.exam) ...[
                const SizedBox(height: 12),
                TextFormField(
                    controller: location,
                    decoration:
                        const InputDecoration(labelText: 'Location / room'))
              ],
              const SizedBox(height: 12),
              TextFormField(
                  controller: description,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Saving…' : 'Save task'))
            ])));
  }
}
