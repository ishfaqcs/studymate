import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Appearance',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setMode(value);
              }
            },
            child: Column(
              children: ThemeMode.values
                  .map((m) => RadioListTile<ThemeMode>(
                      value: m,
                      title: Text(m == ThemeMode.system
                          ? 'System'
                          : m == ThemeMode.light
                              ? 'Light'
                              : 'Dark')))
                  .toList(),
            ),
          ),
          const Divider(height: 32),
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data & backup'),
              subtitle: const Text(
                  'Create or restore backups, export a report and view storage.'),
              leading: const Icon(Icons.backup_outlined),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/data-backup'))
        ]));
  }
}
