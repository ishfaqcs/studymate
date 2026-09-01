import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(padding: const EdgeInsets.all(20), children: const [
        _Section('Local-first by design',
            'StudyMate stores your profile and academic information in its private storage on this device. Core features do not require an account or cloud service.'),
        _Section('Documents',
            'Files you import are copied into StudyMate’s private app storage. StudyMate does not upload them. You can remove a managed copy from its document details screen.'),
        _Section('Backups',
            'Backup files contain the academic data and managed documents you choose to export. You control where the Android system saves or shares them.'),
        _Section('Notifications',
            'StudyMate requests notification access only when a reminder needs it. Denying permission does not prevent you from saving tasks or using other features.'),
        _Section('Permissions',
            'The system file picker provides access only to files you select. StudyMate does not request broad device-storage access.'),
        _Section('Data deletion',
            'You can permanently delete StudyMate data from Data & Backup. Create a backup first if you may need the information later.'),
        _Section('Future changes',
            'If a future version introduces network services, its privacy information should be updated before those services are released.'),
      ]));
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.body);
  final String title, body;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(body,
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45))
      ]));
}
