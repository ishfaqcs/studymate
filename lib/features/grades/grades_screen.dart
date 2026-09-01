import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/empty_state.dart';
import 'grade_repository.dart';

class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(courseGradeSummariesProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Grades & GPA')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/grades/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add grade')),
        body: value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Grades could not be loaded.')),
            data: (items) => items.isEmpty
                ? const EmptyState(
                    icon: Icons.school_outlined,
                    title: 'No courses yet',
                    message: 'Add courses before recording assessment results.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final summary = items[index];
                      final average = summary.average;
                      return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 10),
                          leading: Container(
                              width: 5,
                              height: 48,
                              color: summary.course.color),
                          title: Text(summary.course.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(average == null
                              ? 'No grades recorded'
                              : '${summary.assessments.length} assessments • ${summary.finalLetter ?? 'No grade'}'),
                          trailing: Text(
                              average == null
                                  ? '—'
                                  : '${average.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          onTap: () =>
                              context.push('/grades/${summary.course.id}'));
                    })));
  }
}
