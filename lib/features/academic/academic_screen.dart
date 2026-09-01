import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/studymate_components.dart';
import '../attendance/attendance_repository.dart';
import '../grades/grade_models.dart';
import '../grades/grade_repository.dart';

class AcademicScreen extends ConsumerWidget {
  const AcademicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(academicHistoryProvider).valueOrNull ??
        const <SemesterAcademicSummary>[];
    final current = history.where((summary) => summary.id == 1).firstOrNull;
    final attendance =
        ref.watch(attendanceSummariesProvider).valueOrNull ?? const [];
    final counted =
        attendance.fold<int>(0, (total, item) => total + item.counted);
    final attended =
        attendance.fold<int>(0, (total, item) => total + item.attended);
    final percent = counted == 0 ? null : attended / counted * 100;
    final stats = [
      StudyMateStat(
        label: 'GPA',
        value: current?.gpa?.toStringAsFixed(2) ?? '—',
        caption: 'Current',
      ),
      StudyMateStat(
        label: 'Attendance',
        value: percent == null ? '—' : '${percent.toStringAsFixed(1)}%',
        caption: counted == 0 ? 'No records' : '$attended of $counted attended',
      ),
      StudyMateStat(
        label: 'Credits',
        value: current == null ? '—' : current.credits.toStringAsFixed(0),
        caption: 'Completed',
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Academic')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const StudyMateSectionHeader(
            eyebrow: 'Current semester',
            title: 'Academic overview',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 360) {
              return Column(children: stats);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stats
                  .map((stat) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: stat,
                        ),
                      ))
                  .toList(),
            );
          }),
          const Divider(height: 32),
          StudyMateListRow(
            title: 'Grades & GPA',
            subtitle: current?.gpa == null
                ? 'No grades recorded'
                : 'GPA ${current!.gpa!.toStringAsFixed(2)}',
            onTap: () => context.push('/grades'),
          ),
          StudyMateListRow(
            title: 'Attendance',
            subtitle: counted == 0
                ? 'No records yet'
                : '$attended of $counted attended',
            onTap: () => context.push('/attendance'),
          ),
          StudyMateListRow(
            title: 'Academic history',
            subtitle: 'Semester results and CGPA',
            onTap: () => context.push('/academic/history'),
          ),
          StudyMateListRow(
            title: 'Grading scale',
            subtitle: 'Grade boundaries and points',
            showDivider: false,
            onTap: () => context.push('/grading-scale'),
          ),
        ],
      ),
    );
  }
}
