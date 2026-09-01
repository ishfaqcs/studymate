import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../courses/course_repository.dart';
import 'class_schedule.dart';
import 'schedule_repository.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  const ScheduleFormScreen({super.key, this.schedule, this.initialCourseId});
  final ClassSchedule? schedule;
  final String? initialCourseId;
  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final formKey = GlobalKey<FormState>();
  final room = TextEditingController();
  String? courseId;
  int weekday = DateTime.now().weekday;
  TimeOfDay? start;
  TimeOfDay? end;
  ClassType type = ClassType.lecture;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final value = widget.schedule;
    courseId = value?.courseId ?? widget.initialCourseId;
    weekday = value?.weekday ?? weekday;
    room.text = value?.room ?? '';
    type = value?.classType ?? ClassType.lecture;
    if (value != null) {
      start = TimeOfDay(
          hour: value.startMinutes ~/ 60, minute: value.startMinutes % 60);
      end = TimeOfDay(
          hour: value.endMinutes ~/ 60, minute: value.endMinutes % 60);
    }
  }

  @override
  void dispose() {
    room.dispose();
    super.dispose();
  }

  int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;

  Future<void> _pick(bool isStart) async {
    final result = await showTimePicker(
        context: context,
        initialTime:
            isStart ? start ?? TimeOfDay.now() : end ?? TimeOfDay.now());
    if (result != null) setState(() => isStart ? start = result : end = result);
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (start == null || end == null) {
      setState(() {});
      return;
    }
    if (_minutes(end!) <= _minutes(start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')));
      return;
    }
    final now = DateTime.now();
    final value = ClassSchedule(
        id: widget.schedule?.id ?? const Uuid().v4(),
        courseId: courseId!,
        weekday: weekday,
        startMinutes: _minutes(start!),
        endMinutes: _minutes(end!),
        room: room.text,
        classType: type,
        createdAt: widget.schedule?.createdAt ?? now,
        updatedAt: now);
    final repository = ref.read(scheduleRepositoryProvider);
    final conflict = await repository.conflict(value);
    if (conflict != null && mounted) {
      await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Schedule conflict'),
                content: Text(
                    'You already have ${conflict.course.name} scheduled from ${formatMinutes(conflict.schedule.startMinutes)} to ${formatMinutes(conflict.schedule.endMinutes)}.'),
                actions: [
                  FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Correct schedule'))
                ],
              ));
      return;
    }
    setState(() => saving = true);
    widget.schedule == null
        ? await repository.create(value)
        : await repository.update(value);
    ref.invalidate(schedulesProvider);
    ref.invalidate(schedulesForCourseProvider(value.courseId));
    if (mounted) context.pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.schedule == null ? 'Add schedule' : 'Edit schedule')),
      body: Form(
          key: formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            courses.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Courses could not be loaded.'),
              data: (items) => DropdownButtonFormField<String>(
                  initialValue: courseId,
                  decoration: const InputDecoration(labelText: 'Course *'),
                  items: items
                      .map((course) => DropdownMenuItem(
                          value: course.id, child: Text(course.name)))
                      .toList(),
                  onChanged: (value) => setState(() => courseId = value),
                  validator: (value) =>
                      value == null ? 'Select a course' : null),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
                initialValue: weekday,
                decoration: const InputDecoration(labelText: 'Day *'),
                items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(const [
                          'Monday',
                          'Tuesday',
                          'Wednesday',
                          'Thursday',
                          'Friday',
                          'Saturday',
                          'Sunday'
                        ][i]))),
                onChanged: (value) => setState(() => weekday = value!)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _TimeButton(
                      label: 'Start time',
                      value: start,
                      error: start == null,
                      onTap: () => _pick(true))),
              const SizedBox(width: 12),
              Expanded(
                  child: _TimeButton(
                      label: 'End time',
                      value: end,
                      error: end == null,
                      onTap: () => _pick(false)))
            ]),
            const SizedBox(height: 12),
            TextFormField(
                controller: room,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(labelText: 'Room / location')),
            const SizedBox(height: 12),
            DropdownButtonFormField<ClassType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Class type'),
                items: ClassType.values
                    .map((value) => DropdownMenuItem(
                        value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) => setState(() => type = value!)),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Saving…' : 'Save schedule')),
          ])),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton(
      {required this.label,
      required this.value,
      required this.error,
      required this.onTap});
  final String label;
  final TimeOfDay? value;
  final bool error;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(
              color: error
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outline)),
      child: Text(value == null ? label : value!.format(context)));
}
