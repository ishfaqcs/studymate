import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/studymate_components.dart';
import '../courses/course_repository.dart';
import '../profile/profile_repository.dart';
import '../timetable/class_schedule.dart';
import '../timetable/schedule_repository.dart';
import '../attendance/attendance_repository.dart';
import '../grades/grade_models.dart';
import '../grades/grade_repository.dart';
import '../tasks/academic_task.dart';
import '../tasks/task_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final courseItems = ref.watch(coursesProvider).valueOrNull ?? const [];
    final name = profile?['name'] as String? ?? '';
    final courses = courseItems.length;
    final taskItems =
        ref.watch(tasksProvider).valueOrNull ?? const <AcademicTask>[];
    final pendingTasks = taskItems
        .where((task) => task.status != TaskStatus.completed)
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    final tasks = pendingTasks.length;
    final histories = ref.watch(academicHistoryProvider).valueOrNull ??
        const <SemesterAcademicSummary>[];
    final current = histories.where((semester) => semester.id == 1).firstOrNull;
    final gpa = current?.gpa;
    final gradeSummaries =
        ref.watch(courseGradeSummariesProvider).valueOrNull ?? const [];
    final grades = gradeSummaries.fold<int>(
        0, (count, summary) => count + summary.assessments.length);
    final summaries =
        ref.watch(attendanceSummariesProvider).valueOrNull ?? const [];
    final attendance =
        summaries.fold<int>(0, (total, summary) => total + summary.counted);
    final attended =
        summaries.fold<int>(0, (total, summary) => total + summary.attended);
    final todayClasses =
        (ref.watch(schedulesProvider).valueOrNull ?? const <ScheduleEntry>[])
            .where((entry) => entry.schedule.weekday == DateTime.now().weekday)
            .toList();
    final date = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final attendancePercent =
        attendance == 0 ? null : attended / attendance * 100;
    final firstName =
        name.trim().isEmpty ? '' : name.trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(coursesProvider);
          ref.invalidate(schedulesProvider);
          ref.invalidate(attendanceSummariesProvider);
          ref.invalidate(tasksProvider);
          ref.invalidate(academicHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text(
              '${greeting()}${firstName.isEmpty ? '' : ', $firstName'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 28),
            const StudyMateSectionHeader(
              eyebrow: 'Today',
              title: "Today's classes",
            ),
            const SizedBox(height: 4),
            if (todayClasses.isEmpty)
              EmptyState(
                compact: true,
                icon: Icons.event_available_outlined,
                title: 'No classes scheduled today',
                message: 'Your timetable is empty for today.',
                actionLabel: courses == 0 ? 'Add course' : 'Add schedule',
                onAction: () => courses == 0
                    ? context.push('/courses/add')
                    : context.push('/schedule/add'),
              )
            else
              ...todayClasses.map((entry) => _TodayClass(entry: entry)),
            const SizedBox(height: 24),
            StudyMateSectionHeader(
              eyebrow: 'Upcoming',
              title: 'Tasks and deadlines',
              actionLabel: tasks == 0 ? null : 'View all',
              onAction: tasks == 0 ? null : () => context.go('/tasks'),
            ),
            const SizedBox(height: 4),
            if (tasks == 0)
              const EmptyState(
                compact: true,
                icon: Icons.task_alt,
                title: "You're all caught up",
                message: 'Assignments, quizzes and exams will appear here.',
              )
            else ...[
              ...pendingTasks.take(3).map((task) => StudyMateListRow(
                    title: task.title,
                    subtitle: deadlineLabel(task, DateTime.now()),
                    onTap: () => context.go('/tasks'),
                  )),
            ],
            const SizedBox(height: 24),
            const StudyMateSectionHeader(
              eyebrow: 'Progress',
              title: 'Academic overview',
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final metrics = [
                  _metric(
                    context,
                    'Attendance',
                    attendancePercent == null
                        ? '—'
                        : '${attendancePercent.toStringAsFixed(1)}%',
                    attendance == 0
                        ? 'No records yet'
                        : '$attended of $attendance attended',
                  ),
                  _metric(
                    context,
                    'GPA',
                    gpa == null ? '—' : gpa.toStringAsFixed(2),
                    grades == 0 ? 'No grades yet' : '$grades grade entries',
                  ),
                  _metric(
                    context,
                    'Tasks',
                    '$tasks',
                    tasks == 0 ? 'Nothing pending' : '$courses courses',
                  ),
                ];
                if (constraints.maxWidth < 360) {
                  return Column(
                    children: metrics
                        .map((metric) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SizedBox(
                                  width: double.infinity, child: metric),
                            ))
                        .toList(),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: metrics[i]),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _TodayClass extends StatelessWidget {
  const _TodayClass({required this.entry});
  final ScheduleEntry entry;
  @override
  Widget build(BuildContext context) {
    final schedule = entry.schedule;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
          width: 52,
          child: Text(formatMinutes(schedule.startMinutes),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700))),
      title: Row(children: [
        Container(width: 4, height: 28, color: entry.course.color),
        const SizedBox(width: 10),
        Expanded(
            child: Text(entry.course.name,
                style: const TextStyle(fontWeight: FontWeight.w700))),
      ]),
      subtitle: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text([
            if (entry.course.code != null) entry.course.code!,
            if (schedule.room != null) schedule.room!,
          ].join(' • '))),
      trailing: IconButton(
          tooltip: 'Mark attendance',
          icon: const Icon(Icons.fact_check_outlined),
          onPressed: () => context
              .push('/attendance/add?course=${entry.course.id}&today=true')),
    );
  }
}
