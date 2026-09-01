import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../courses/course_repository.dart';
import 'grade_models.dart';
import 'grade_repository.dart';

class GradeFormScreen extends ConsumerStatefulWidget {
  const GradeFormScreen({super.key, this.assessment, this.initialCourseId});
  final Assessment? assessment;
  final String? initialCourseId;
  @override
  ConsumerState<GradeFormScreen> createState() => _GradeFormScreenState();
}

class _GradeFormScreenState extends ConsumerState<GradeFormScreen> {
  final key = GlobalKey<FormState>();
  late final TextEditingController title, obtained, total, weight, note;
  String? courseId;
  AssessmentType type = AssessmentType.assignment;
  DateTime? date;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final a = widget.assessment;
    courseId = a?.courseId ?? widget.initialCourseId;
    type = a?.type ?? type;
    date = a?.date;
    title = TextEditingController(text: a?.title);
    obtained = TextEditingController(text: a?.marksObtained.toString());
    total = TextEditingController(text: a?.totalMarks.toString());
    weight = TextEditingController(text: a?.weight?.toString());
    note = TextEditingController(text: a?.note);
  }

  @override
  void dispose() {
    for (final c in [title, obtained, total, weight, note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!(key.currentState?.validate() ?? false)) return;
    final courses = ref.read(coursesProvider).valueOrNull ?? [];
    final course = courses.where((c) => c.id == courseId).firstOrNull;
    if (course == null) return;
    setState(() => saving = true);
    final now = DateTime.now();
    final value = Assessment(
        id: widget.assessment?.id ?? const Uuid().v4(),
        courseId: course.id,
        semesterId: course.semesterId,
        title: title.text.trim(),
        type: type,
        marksObtained: double.parse(obtained.text),
        totalMarks: double.parse(total.text),
        weight: weight.text.trim().isEmpty ? null : double.parse(weight.text),
        date: date,
        note: note.text,
        createdAt: widget.assessment?.createdAt ?? now,
        updatedAt: now);
    final repo = ref.read(gradeRepositoryProvider);
    widget.assessment == null
        ? await repo.create(value, course.creditHours)
        : await repo.update(value, course.creditHours);
    ref.invalidate(courseGradeSummariesProvider);
    ref.invalidate(courseGradeSummaryProvider(course.id));
    ref.invalidate(academicHistoryProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);
    return Scaffold(
        appBar: AppBar(
            title:
                Text(widget.assessment == null ? 'Add grade' : 'Edit grade')),
        body: Form(
            key: key,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              courses.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Courses could not be loaded.'),
                  data: (items) => DropdownButtonFormField<String>(
                      initialValue: courseId,
                      decoration: const InputDecoration(labelText: 'Course *'),
                      items: items
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => setState(() => courseId = v),
                      validator: (v) => v == null ? 'Select a course' : null)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: title,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: 'Assessment title *'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Assessment title is required'
                      : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<AssessmentType>(
                  initialValue: type,
                  decoration:
                      const InputDecoration(labelText: 'Assessment type'),
                  items: AssessmentType.values
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(v.label)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _number(obtained, 'Marks obtained *', (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter valid marks';
                  final max = double.tryParse(total.text);
                  if (max != null && n > max) return 'Cannot exceed total';
                  return null;
                })),
                const SizedBox(width: 12),
                Expanded(
                    child: _number(total, 'Total marks *', (v) {
                  final n = double.tryParse(v ?? '');
                  return n == null || n <= 0 ? 'Must be greater than 0' : null;
                }))
              ]),
              const SizedBox(height: 12),
              _number(weight, 'Weight / contribution', (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v);
                return n == null || n < 0 || n > 100
                    ? 'Weight must be 0–100'
                    : null;
              }),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: date ?? DateTime.now());
                    if (d != null) setState(() => date = d);
                  },
                  icon: const Icon(Icons.event),
                  label: Text(date == null
                      ? 'Assessment date'
                      : '${date!.day}/${date!.month}/${date!.year}')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Note')),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Saving…' : 'Save grade'))
            ])));
  }

  Widget _number(TextEditingController c, String label,
          String? Function(String?) validator) =>
      TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
          decoration: InputDecoration(labelText: label),
          validator: validator);
}
