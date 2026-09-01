import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'course.dart';
import 'course_repository.dart';
import '../timetable/class_schedule.dart';
import '../timetable/schedule_repository.dart';
import '../attendance/attendance_repository.dart';
import '../grades/grade_repository.dart';
import '../tasks/academic_task.dart';
import '../tasks/task_repository.dart';

class CourseDetailsScreen extends ConsumerWidget {
  const CourseDetailsScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(courseProvider(courseId));
    return value.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Course could not be loaded.')),
      ),
      data: (course) => course == null
          ? Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Course not found.')))
          : _CourseDetails(course: course),
    );
  }
}

class _CourseDetails extends ConsumerWidget {
  const _CourseDetails({required this.course});
  final Course course;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text(
            'This will remove ${course.name} and its associated academic records.'),
        actions: [
          TextButton(
              onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => context.pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(courseRepositoryProvider).delete(course.id);
    ref.invalidate(coursesProvider);
    ref.invalidate(courseProvider(course.id));
    if (context.mounted) context.go('/courses');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = course.creditHours % 1 == 0
        ? course.creditHours.toStringAsFixed(0)
        : course.creditHours.toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course details'),
        actions: [
          IconButton(
            tooltip: 'Edit course',
            onPressed: () =>
                context.push('/courses/${course.id}/edit', extra: course),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete course',
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 58,
                decoration: BoxDecoration(
                    color: course.color,
                    borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    if (course.code != null) ...[
                      const SizedBox(height: 3),
                      Text(course.code!,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  )),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (course.instructor != null)
            _Detail(label: 'Instructor', value: course.instructor!),
          _Detail(label: 'Credit hours', value: credits),
          _Detail(
              label: 'Attendance requirement',
              value: '${course.requiredAttendance.toStringAsFixed(0)}%'),
          if (course.room != null) _Detail(label: 'Room', value: course.room!),
          const Divider(height: 36),
          _CoursePerformance(course: course),
          const Divider(height: 36),
          _CourseSchedule(course: course),
          const Divider(height: 36),
          Text('Course tools',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _Tool(
              icon: Icons.calendar_month_outlined,
              label: 'Schedule',
              onTap: () => context.push('/schedule/add?course=${course.id}')),
          _Tool(
              icon: Icons.fact_check_outlined,
              label: 'Attendance',
              onTap: () => context.push('/attendance/${course.id}')),
          _Tool(
              icon: Icons.task_alt_outlined,
              label: 'Tasks',
              onTap: () => context.push('/tasks/add?course=${course.id}')),
          _Tool(
              icon: Icons.school_outlined,
              label: 'Grades',
              onTap: () => context.push('/grades/${course.id}')),
          _Tool(
              icon: Icons.note_alt_outlined,
              label: 'Notes',
              onTap: () => context.push('/notes?course=${course.id}')),
          _Tool(
              icon: Icons.folder_outlined,
              label: 'Documents',
              onTap: () => context.push('/documents?course=${course.id}')),
        ],
      ),
    );
  }
}

class _CoursePerformance extends ConsumerWidget {
  const _CoursePerformance({required this.course});
  final Course course;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref
        .watch(attendanceSummariesProvider)
        .valueOrNull
        ?.where((summary) => summary.course.id == course.id)
        .firstOrNull;
    final grades = ref.watch(courseGradeSummaryProvider(course.id)).valueOrNull;
    final tasks = ref.watch(tasksForCourseProvider(course.id)).valueOrNull ??
        const <AcademicTask>[];
    final pending =
        tasks.where((task) => task.status != TaskStatus.completed).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Course overview',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Wrap(spacing: 24, runSpacing: 14, children: [
        _summary(
            context,
            'Attendance',
            attendance == null || attendance.counted == 0
                ? '—'
                : '${attendance.insight.percentage.toStringAsFixed(1)}%'),
        _summary(context, 'Current grade', grades?.finalLetter ?? '—'),
        _summary(context, 'Pending tasks', '$pending'),
      ]),
    ]);
  }

  Widget _summary(BuildContext context, String label, String value) => SizedBox(
      width: 105,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 3),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800))
      ]));
}

class _CourseSchedule extends ConsumerWidget {
  const _CourseSchedule({required this.course});
  final Course course;
  static const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Future<void> _delete(
      BuildContext context, WidgetRef ref, ClassSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: const Text('Remove this class from the weekly timetable?'),
        actions: [
          TextButton(
              onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => context.pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(scheduleRepositoryProvider).delete(schedule.id);
      ref.invalidate(schedulesProvider);
      ref.invalidate(schedulesForCourseProvider(course.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(schedulesForCourseProvider(course.id));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text('Weekly schedule',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700))),
        TextButton.icon(
            onPressed: () => context.push('/schedule/add?course=${course.id}'),
            icon: const Icon(Icons.add),
            label: const Text('Add')),
      ]),
      value.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('Schedule could not be loaded.'),
        data: (entries) => entries.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No weekly classes added.'))
            : Column(
                children: entries
                    .map((entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(days[entry.schedule.weekday - 1]),
                          subtitle: Text(
                              '${formatMinutes(entry.schedule.startMinutes)} – ${formatMinutes(entry.schedule.endMinutes)}${entry.schedule.room == null ? '' : ' • ${entry.schedule.room}'}'),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Schedule actions',
                            onSelected: (value) {
                              if (value == 'edit') {
                                context.push(
                                    '/schedule/${entry.schedule.id}/edit',
                                    extra: entry.schedule);
                              } else if (value == 'delete') {
                                _delete(context, ref, entry.schedule);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ))
                    .toList()),
      ),
    ]);
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ]),
      );
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: 52,
        leading: Icon(icon),
        title: Text(label),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        enabled: onTap != null,
        onTap: onTap,
      );
}
