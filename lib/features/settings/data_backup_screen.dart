import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import '../../core/database/app_database.dart';
import '../../core/services/academic_report_service.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/utils/file_size_formatter.dart';
import 'package:go_router/go_router.dart';

class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});
  @override
  State<DataBackupScreen> createState() => _State();
}

class _State extends State<DataBackupScreen> {
  bool busy = false;
  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'The operation could not be completed. Check the selected file and try again.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> backup() async {
    final bytes = await BackupService().create();
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fileName = 'studymate-backup-$date.zip';
    final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(label: 'StudyMate backup', extensions: <String>['zip'])
        ]);
    if (location == null) return;
    await XFile.fromData(bytes, name: fileName).saveTo(location.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully.')));
    }
  }

  Future<void> restore() async {
    final picked = await openFile(acceptedTypeGroups: const <XTypeGroup>[
      XTypeGroup(label: 'StudyMate backup', extensions: <String>['zip'])
    ]);
    if (picked == null) return;
    final selectedPath = picked.path;
    if (selectedPath.isEmpty) {
      throw const FileSystemException(
          'The selected backup could not be accessed.');
    }
    final info = BackupService().inspect(await picked.readAsBytes());
    if (!mounted) return;
    final c = info.counts;
    final ok = await showDialog<bool>(
        context: context,
        builder: (x) => AlertDialog(
                title: const Text('Restore StudyMate backup?'),
                content: Text(
                    'Created ${DateFormat.yMMMMd().format(info.createdAt)}.\n\n${c['semesters']} semesters\n${c['courses']} courses\n${c['attendance']} attendance records\n${c['tasks']} tasks\n${c['notes']} notes\n${c['documents']} documents\n\nRestoring will replace your current StudyMate data.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(x, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(x, true),
                      child: const Text('Restore'))
                ]));
    if (ok == true) {
      await BackupService().restore(info);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored successfully.')));
      }
    }
  }

  Future<void> report() async {
    final bytes = await AcademicReportService().generate();
    await Printing.sharePdf(
        bytes: bytes, filename: 'studymate-academic-summary.pdf');
  }

  Future<void> deleteAllData() async {
    final first = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Delete all StudyMate data?'),
                content: const Text(
                    'This permanently removes your profile, courses, schedules, attendance, grades, tasks, notes and locally stored documents.\n\nThis cannot be undone unless you have a backup.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Continue'))
                ]));
    if (first != true || !mounted) return;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Confirm permanent deletion'),
                content: TextField(
                    controller: controller,
                    autocorrect: false,
                    decoration: const InputDecoration(
                        labelText: 'Type DELETE',
                        helperText: 'Enter DELETE to confirm.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(
                          dialog, controller.text.trim() == 'DELETE'),
                      child: const Text('Delete permanently'))
                ]));
    controller.dispose();
    if (confirmed != true) return;
    setState(() => busy = true);
    try {
      await NotificationService.instance.cancelAll();
      await AppDatabase.instance.resetUserData();
      await PreferencesService.resetUserPreferences();
      if (mounted) context.go('/onboarding');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Data & Backup')),
      body: Stack(children: [
        ListView(children: [
          ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Create Backup'),
              subtitle: const Text('Save a copy of your StudyMate data.'),
              onTap: busy ? null : () => run(backup)),
          ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore Backup'),
              subtitle:
                  const Text('Validate and restore data from a backup file.'),
              onTap: busy ? null : () => run(restore)),
          ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Export Academic Summary'),
              subtitle: const Text('Create and share a PDF overview.'),
              onTap: busy ? null : () => run(report)),
          ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('Storage'),
              subtitle: const Text('View calculated local storage use.'),
              onTap: busy
                  ? null
                  : () => showDialog(
                      context: context,
                      builder: (_) => const _StorageDialog())),
          const Divider(),
          ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Delete all StudyMate data',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              subtitle: const Text(
                  'Permanently reset the app and return to onboarding.'),
              onTap: busy ? null : deleteAllData)
        ]),
        if (busy)
          const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()))
      ]));
}

class _StorageDialog extends StatelessWidget {
  const _StorageDialog();
  Future<List<int>> sizes() async {
    final base = Directory(p.dirname(await AppDatabase.instance.databasePath));
    Future<int> dir(Directory d) async {
      if (!await d.exists()) return 0;
      var n = 0;
      await for (final e in d.list(recursive: true, followLinks: false)) {
        if (e is File) n += await e.length();
      }
      return n;
    }

    final docs =
        await dir(Directory('${base.path}${Platform.pathSeparator}documents'));
    final db = File(await AppDatabase.instance.databasePath);
    return [docs, await db.exists() ? await db.length() : 0];
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('StudyMate Storage'),
          content: FutureBuilder<List<int>>(
              future: sizes(),
              builder: (_, s) => s.hasData
                  ? Text(
                      'Documents\n${formatFileSize(s.data![0])}\n\nDatabase\n${formatFileSize(s.data![1])}')
                  : const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ]);
}
