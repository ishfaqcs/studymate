import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'grade_models.dart';
import 'grade_repository.dart';

class AcademicHistoryScreen extends ConsumerWidget {
  const AcademicHistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(academicHistoryProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Academic history')),
        body: value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
                child: Text('Academic history could not be loaded.')),
            data: (items) => items.isEmpty
                ? const Center(
                    child: Text(
                        'No previous semesters\nYour academic history will appear here.',
                        textAlign: TextAlign.center))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) =>
                        _semester(context, items[i]))));
  }

  Widget _semester(BuildContext c, SemesterAcademicSummary s) => ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(s.gpa == null
          ? 'No graded courses'
          : 'GPA ${s.gpa!.toStringAsFixed(2)} • ${s.credits.toStringAsFixed(0)} credits • ${s.graded.length} courses'),
      children: s.courses
          .map((course) => ListTile(
              contentPadding: const EdgeInsets.only(left: 16),
              title: Text(course.course.name),
              trailing: Text(course.finalLetter ?? '—')))
          .toList());
}
