import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../courses/course_repository.dart';
import '../timetable/schedule_repository.dart';
import 'attendance_record.dart';
import 'attendance_repository.dart';

class AttendanceFormScreen extends ConsumerStatefulWidget {
  const AttendanceFormScreen(
      {super.key, this.record, this.initialCourseId, this.today = false});
  final AttendanceRecord? record;
  final String? initialCourseId;
  final bool today;
  @override
  ConsumerState<AttendanceFormScreen> createState() =>
      _AttendanceFormScreenState();
}

class _AttendanceFormScreenState extends ConsumerState<AttendanceFormScreen> {
  final formKey = GlobalKey<FormState>();
  final note = TextEditingController();
  String? courseId;
  String? scheduleId;
  late DateTime date;
  AttendanceStatus? status;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final value = widget.record;
    courseId = value?.courseId ?? widget.initialCourseId;
    scheduleId = value?.scheduleId;
    date = value?.date ?? DateTime.now();
    status = value?.status;
    note.text = value?.note ?? '';
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (status == null) {
      setState(() {});
      return;
    }
    final now = DateTime.now();
    final value = AttendanceRecord(
        id: widget.record?.id ?? const Uuid().v4(),
        courseId: courseId!,
        scheduleId: scheduleId,
        date: date,
        status: status!,
        note: note.text,
        createdAt: widget.record?.createdAt ?? now,
        updatedAt: now);
    final repository = ref.read(attendanceRepositoryProvider);
    final duplicate = await repository.existing(
        courseId: value.courseId,
        date: value.date,
        scheduleId: value.scheduleId,
        excludingId: widget.record?.id);
    if (duplicate != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Attendance already exists for this class and date. Edit the existing record instead.')));
      return;
    }
    setState(() => saving = true);
    widget.record == null
        ? await repository.create(value)
        : await repository.update(value);
    ref.invalidate(attendanceSummariesProvider);
    ref.invalidate(attendanceForCourseProvider(value.courseId));
    if (mounted) context.pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);
    final schedules = courseId == null
        ? const AsyncValue.data([])
        : ref.watch(schedulesForCourseProvider(courseId!));
    final relevant = schedules.valueOrNull
            ?.where((entry) => entry.schedule.weekday == date.weekday)
            .toList() ??
        const [];
    return Scaffold(
        appBar: AppBar(
            title: Text(
                widget.record == null ? 'Add attendance' : 'Edit attendance')),
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
                      onChanged: (value) => setState(() {
                            courseId = value;
                            scheduleId = null;
                          }),
                      validator: (value) =>
                          value == null ? 'Select a course' : null)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: () async {
                    final result = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        initialDate: date);
                    if (result != null) {
                      setState(() {
                        date = result;
                        scheduleId = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.event),
                  label: Text('${date.day}/${date.month}/${date.year}')),
              if (relevant.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                    initialValue: scheduleId,
                    decoration:
                        const InputDecoration(labelText: 'Class schedule'),
                    items: [
                      const DropdownMenuItem(
                          value: null,
                          child: Text('General / unspecified class')),
                      ...relevant.map((entry) => DropdownMenuItem(
                          value: entry.schedule.id,
                          child: Text(
                              '${entry.schedule.classType?.label ?? 'Class'} • ${entry.schedule.startMinutes ~/ 60}:${(entry.schedule.startMinutes % 60).toString().padLeft(2, '0')}')))
                    ],
                    onChanged: (value) => setState(() => scheduleId = value))
              ],
              const SizedBox(height: 16),
              Text('Status *', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AttendanceStatus.values
                      .map((value) => ChoiceChip(
                          avatar: Icon(_icon(value), size: 18),
                          label: Text(value.label),
                          selected: status == value,
                          onSelected: (_) => setState(() => status = value)))
                      .toList()),
              if (status == null)
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Select an attendance status',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: 16),
              TextFormField(
                  controller: note,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Note')),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Saving…' : 'Save attendance')),
            ])));
  }

  IconData _icon(AttendanceStatus value) => switch (value) {
        AttendanceStatus.present => Icons.check_circle_outline,
        AttendanceStatus.absent => Icons.cancel_outlined,
        AttendanceStatus.late => Icons.schedule,
        AttendanceStatus.excused => Icons.event_busy_outlined,
        AttendanceStatus.cancelled => Icons.block
      };
}
