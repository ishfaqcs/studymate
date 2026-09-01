import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/services/preferences_service.dart';

class SemesterSetupScreen extends StatefulWidget {
  const SemesterSetupScreen({super.key});
  @override
  State<SemesterSetupScreen> createState() => _SemesterSetupScreenState();
}

class _SemesterSetupScreenState extends State<SemesterSetupScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      university = TextEditingController(),
      program = TextEditingController(),
      semester = TextEditingController();
  double attendance = 75;
  DateTime? start, end;
  bool saving = false;
  @override
  void dispose() {
    for (final c in [name, university, program, semester]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pick(bool isStart) async {
    final d = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2040),
        initialDate: DateTime.now());
    if (d != null) {
      setState(() {
        if (isStart) {
          start = d;
        } else {
          end = d;
        }
      });
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (start != null && end != null && end!.isBefore(start!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Semester end date must be after the start date.')));
      return;
    }
    setState(() => saving = true);
    final db = await AppDatabase.instance.database;
    await db.delete('profile');
    await db.insert('profile', {
      'id': 1,
      'name': name.text.trim(),
      'university': university.text.trim(),
      'program': program.text.trim(),
      'semester': semester.text.trim(),
      'start_date': start?.toIso8601String(),
      'end_date': end?.toIso8601String(),
      'attendance_requirement': attendance,
      'grading_scale': '4.0'
    });
    await db.insert(
      'semesters',
      {
        'id': 1,
        'name': semester.text.trim().isEmpty
            ? 'Current semester'
            : semester.text.trim(),
        'start_date': start?.toIso8601String(),
        'end_date': end?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await PreferencesService.setOnboardingCompleted(true);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Set up StudyMate')),
      body: SafeArea(
          child: Form(
              key: formKey,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                Text("Let's set up your semester",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                    'A few details will help StudyMate personalize your academic dashboard.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                _field(name, 'Student name', required: true),
                const SizedBox(height: 12),
                _field(university, 'University / College'),
                const SizedBox(height: 12),
                _field(program, 'Degree / Program'),
                const SizedBox(height: 12),
                _field(semester, 'Semester name'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () => pick(true),
                          icon: const Icon(Icons.event),
                          label: Text(start == null
                              ? 'Start date'
                              : '${start!.day}/${start!.month}/${start!.year}'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () => pick(false),
                          icon: const Icon(Icons.event),
                          label: Text(end == null
                              ? 'End date'
                              : '${end!.day}/${end!.month}/${end!.year}')))
                ]),
                const SizedBox(height: 20),
                Text('Minimum attendance',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    children: [70, 75, 80, 85]
                        .map((v) => ChoiceChip(
                            label: Text('$v%'),
                            selected: attendance == v,
                            onSelected: (_) =>
                                setState(() => attendance = v.toDouble())))
                        .toList()),
                const SizedBox(height: 18),
                const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Grading scale'),
                    subtitle: Text('4.0 GPA Scale'),
                    trailing: Icon(Icons.chevron_right)),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: saving ? null : save,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child:
                            Text(saving ? 'Saving…' : 'Set up my semester'))),
              ]))));
  Widget _field(TextEditingController c, String label,
          {bool required = false}) =>
      TextFormField(
          controller: c,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: label),
          validator: (v) => required && (v == null || v.trim().isEmpty)
              ? 'Please enter your $label'
              : null);
}
