import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/studymate_components.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('More'),
          actions: [
            IconButton(
              tooltip: 'Search StudyMate',
              icon: const Icon(Icons.search),
              onPressed: () => context.push('/search'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const _Heading('Account and academic'),
            _item(context, Icons.person_outline, 'Profile',
                'Student and semester details', '/profile'),
            _item(context, Icons.menu_book_outlined, 'Courses',
                'Courses and course details', '/courses'),
            _item(context, Icons.tune, 'Academic settings',
                'Grading scale and academic rules', '/grading-scale',
                last: true),
            const _Heading('Study'),
            _item(context, Icons.note_alt_outlined, 'Notes',
                'Course and revision notes', '/notes'),
            _item(context, Icons.folder_outlined, 'Documents',
                'Local academic library', '/documents',
                last: true),
            const _Heading('Application'),
            _item(context, Icons.palette_outlined, 'Appearance',
                'System, light or dark theme', '/settings'),
            _item(context, Icons.backup_outlined, 'Data & backup',
                'Backup, restore, reports and storage', '/data-backup'),
            _item(context, Icons.shield_outlined, 'Privacy',
                'How StudyMate handles your data', '/privacy'),
            _item(context, Icons.info_outline, 'About StudyMate',
                'Version, privacy and licenses', '/about',
                last: true),
          ],
        ),
      );

  Widget _item(BuildContext context, IconData icon, String title,
          String subtitle, String path,
          {bool last = false}) =>
      StudyMateListRow(
        leading: Icon(icon, size: 22),
        title: title,
        subtitle: subtitle,
        showDivider: !last,
        onTap: () => context.push(path),
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}
