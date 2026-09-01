import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(
      BuildContext context, WidgetRef ref, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final key = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit student name'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Student name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Student name is required'
                : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (key.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await ref.read(profileRepositoryProvider).updateName(controller.text);
      ref.invalidate(profileProvider);
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Profile could not be loaded.')),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Profile setup is incomplete.'));
          }
          final name = (data['name'] as String?)?.trim() ?? '';
          final initial =
              name.isEmpty ? '?' : name.characters.first.toUpperCase();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                  radius: 34,
                  child: Text(initial,
                      style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                    child: Text(name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800))),
                IconButton(
                    tooltip: 'Edit student name',
                    onPressed: () => _editName(context, ref, name),
                    icon: const Icon(Icons.edit_outlined)),
              ]),
              const SizedBox(height: 24),
              _row('University', data['university']),
              _row('Program', data['program']),
              _row('Semester', data['semester']),
              _row('Attendance requirement',
                  '${data['attendance_requirement']}%'),
              _row('GPA scale', data['grading_scale']),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, Object? value) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(value == null || value.toString().trim().isEmpty
            ? 'Not set'
            : value.toString()),
      );
}
