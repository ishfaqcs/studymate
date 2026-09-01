import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import 'attendance_repository.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(attendanceSummariesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/attendance/add'),
          icon: const Icon(Icons.add),
          label: const Text('Add record')),
      body: summaries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Attendance could not be loaded.')),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No courses yet',
                message: 'Add courses before tracking attendance.')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final summary = items[index];
                  final insight = summary.insight;
                  final hasData = summary.counted > 0;
                  final safe = hasData &&
                      insight.percentage >= summary.course.requiredAttendance;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    leading: Container(
                        width: 5, height: 48, color: summary.course.color),
                    title: Text(summary.course.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(hasData
                        ? 'Required: ${summary.course.requiredAttendance.toStringAsFixed(0)}% • ${safe ? 'Safe' : 'Needs attention'}'
                        : 'No attendance data'),
                    trailing: Text(
                        hasData
                            ? '${insight.percentage.toStringAsFixed(1)}%'
                            : '—',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    onTap: () =>
                        context.push('/attendance/${summary.course.id}'),
                  );
                }),
      ),
    );
  }
}
