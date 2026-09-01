import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../courses/course_repository.dart';
import '../timetable/schedule_repository.dart';
import 'attendance_record.dart';
import 'attendance_repository.dart';

class AttendanceCourseScreen extends ConsumerStatefulWidget {
  const AttendanceCourseScreen({super.key, required this.courseId});
  final String courseId;
  @override
  ConsumerState<AttendanceCourseScreen> createState() =>
      _AttendanceCourseScreenState();
}

class _AttendanceCourseScreenState
    extends ConsumerState<AttendanceCourseScreen> {
  AttendanceStatus? filter;

  Future<void> _delete(AttendanceRecord record) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Delete attendance record?'),
                content: const Text(
                    'This attendance entry will be permanently removed.'),
                actions: [
                  TextButton(
                      onPressed: () => context.pop(false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => context.pop(true),
                      child: const Text('Delete')),
                ]));
    if (yes == true) {
      await ref.read(attendanceRepositoryProvider).delete(record.id);
      _refresh();
    }
  }

  void _refresh() {
    ref.invalidate(attendanceForCourseProvider(widget.courseId));
    ref.invalidate(attendanceSummariesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final courseValue = ref.watch(courseProvider(widget.courseId));
    final recordsValue =
        ref.watch(attendanceForCourseProvider(widget.courseId));
    final schedules =
        ref.watch(schedulesForCourseProvider(widget.courseId)).valueOrNull ??
            const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Course attendance')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () =>
              context.push('/attendance/add?course=${widget.courseId}'),
          icon: const Icon(Icons.add),
          label: const Text('Add record')),
      body: courseValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Course could not be loaded.')),
          data: (course) {
            if (course == null) {
              return const Center(child: Text('Course not found.'));
            }
            return recordsValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('History could not be loaded.')),
                data: (records) {
                  final summary =
                      CourseAttendanceSummary(course: course, records: records);
                  final insight = summary.insight;
                  final shown = filter == null
                      ? records
                      : records
                          .where((record) => record.status == filter)
                          .toList();
                  return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      children: [
                        Text(course.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 18),
                        if (summary.counted == 0)
                          const Text('No attendance data',
                              style: TextStyle(fontWeight: FontWeight.w700))
                        else ...[
                          Text('${insight.percentage.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700)),
                          Text(
                              '${summary.attended} attended • ${summary.absent} absent • ${summary.counted} counted classes'),
                          const SizedBox(height: 12),
                          Text(
                              'Required ${course.requiredAttendance.toStringAsFixed(0)}% • ${insight.percentage >= course.requiredAttendance ? 'Safe' : 'Needs attention'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(insight.percentage >= course.requiredAttendance
                              ? 'You can miss ${insight.safeMisses} more class${insight.safeMisses == 1 ? '' : 'es'} and remain at or above ${course.requiredAttendance.toStringAsFixed(0)}%.'
                              : 'Your attendance is below the required ${course.requiredAttendance.toStringAsFixed(0)}%. Attend the next ${insight.recoveryClasses} class${insight.recoveryClasses == 1 ? '' : 'es'} to reach it.'),
                        ],
                        if (schedules.any((entry) =>
                            entry.schedule.weekday ==
                            DateTime.now().weekday)) ...[
                          const SizedBox(height: 18),
                          FilledButton.tonalIcon(
                              onPressed: () => context.push(
                                  '/attendance/add?course=${course.id}&today=true'),
                              icon: const Icon(Icons.fact_check_outlined),
                              label: const Text("Mark today's attendance")),
                        ],
                        const Divider(height: 36),
                        Text('History',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              _chip('All', null),
                              ...AttendanceStatus.values
                                  .where((value) =>
                                      value != AttendanceStatus.cancelled)
                                  .map((value) => _chip(value.label, value)),
                            ])),
                        const SizedBox(height: 8),
                        if (shown.isEmpty)
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                  child: Text(
                                      'No attendance records in this view.')))
                        else
                          ...shown.map((record) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(_statusIcon(record.status),
                                    semanticLabel: record.status.label),
                                title: Text(DateFormat('d MMM yyyy')
                                    .format(record.date)),
                                subtitle: Text([
                                  record.status.label,
                                  if (record.note != null) record.note!
                                ].join(' • ')),
                                trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        context.push(
                                            '/attendance/record/${record.id}/edit',
                                            extra: record);
                                      }
                                      if (value == 'delete') {
                                        _delete(record);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                          PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit')),
                                          PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete'))
                                        ]),
                              )),
                      ]);
                });
          }),
    );
  }

  Widget _chip(String label, AttendanceStatus? value) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
          label: Text(label),
          selected: filter == value,
          onSelected: (_) => setState(() => filter = value)));
  IconData _statusIcon(AttendanceStatus status) => switch (status) {
        AttendanceStatus.present => Icons.check_circle_outline,
        AttendanceStatus.absent => Icons.cancel_outlined,
        AttendanceStatus.late => Icons.schedule,
        AttendanceStatus.excused => Icons.event_busy_outlined,
        AttendanceStatus.cancelled => Icons.block
      };
}
