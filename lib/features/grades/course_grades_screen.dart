import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'grade_models.dart';
import 'grade_repository.dart';

class CourseGradesScreen extends ConsumerWidget {
  const CourseGradesScreen({super.key, required this.courseId});
  final String courseId;
  Future<void> _delete(BuildContext c, WidgetRef ref, Assessment a) async {
    final yes = await showDialog<bool>(
        context: c,
        builder: (c) => AlertDialog(
                title: const Text('Delete grade?'),
                content: Text('Remove “${a.title}” permanently?'),
                actions: [
                  TextButton(
                      onPressed: () => c.pop(false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => c.pop(true), child: const Text('Delete'))
                ]));
    if (yes == true) {
      await ref.read(gradeRepositoryProvider).delete(a.id);
      ref.invalidate(courseGradeSummaryProvider(courseId));
      ref.invalidate(courseGradeSummariesProvider);
      ref.invalidate(academicHistoryProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(courseGradeSummaryProvider(courseId));
    return Scaffold(
        appBar: AppBar(title: const Text('Course grades')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/grades/add?course=$courseId'),
            icon: const Icon(Icons.add),
            label: const Text('Add grade')),
        body: value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Grades could not be loaded.')),
            data: (s) {
              if (s == null) {
                return const Center(child: Text('Course not found.'));
              }
              final average = s.average;
              return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                  children: [
                    Text(s.course.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 18),
                    Wrap(spacing: 24, runSpacing: 12, children: [
                      _metric(
                          context, 'Assessments', '${s.assessments.length}'),
                      _metric(
                          context,
                          'Average',
                          average == null
                              ? '—'
                              : '${average.toStringAsFixed(1)}%'),
                      _metric(
                          context,
                          s.course.finalGradePoint == null
                              ? 'Calculated grade'
                              : 'Final grade',
                          s.finalLetter ?? '—'),
                      _metric(context, 'Credit hours',
                          s.course.creditHours.toStringAsFixed(0))
                    ]),
                    const SizedBox(height: 16),
                    OutlinedButton(
                        onPressed: () => _finalDialog(context, ref, s),
                        child: Text(s.course.finalGradePoint == null
                            ? 'Override final grade'
                            : 'Edit final grade')),
                    const Divider(height: 36),
                    if (s.assessments.isEmpty)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                  'No grades yet\nAdd assessment results to track your GPA.',
                                  textAlign: TextAlign.center)))
                    else
                      ...s.assessments.map((a) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(a.title),
                          subtitle: Text(
                              '${a.type.label} • ${a.marksObtained}/${a.totalMarks} • ${a.percentage.toStringAsFixed(1)}%'),
                          trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') {
                                  context.push('/grades/record/${a.id}/edit',
                                      extra: a);
                                }
                                if (v == 'delete') {
                                  _delete(context, ref, a);
                                }
                              },
                              itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(
                                        value: 'delete', child: Text('Delete'))
                                  ])))
                  ]);
            }));
  }

  Widget _metric(BuildContext c, String l, String v) => SizedBox(
      width: 130,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: Theme.of(c).textTheme.labelLarge),
        const SizedBox(height: 3),
        Text(v,
            style: Theme.of(c)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800))
      ]));
  Future<void> _finalDialog(
      BuildContext context, WidgetRef ref, CourseGradeSummary s) async {
    final selected = await showDialog<GradeBoundary?>(
        context: context,
        builder: (c) =>
            SimpleDialog(title: const Text('Official final grade'), children: [
              SimpleDialogOption(
                  onPressed: () => c.pop(null),
                  child: const Text('Use calculated grade')),
              ...s.boundaries.map((b) => SimpleDialogOption(
                  onPressed: () => c.pop(b),
                  child: Text(
                      '${b.letter}  •  ${b.gradePoint.toStringAsFixed(2)}')))
            ]));
    await ref.read(gradeRepositoryProvider).setFinalGrade(courseId, selected);
    ref.invalidate(courseGradeSummaryProvider(courseId));
    ref.invalidate(courseGradeSummariesProvider);
    ref.invalidate(academicHistoryProvider);
  }
}
