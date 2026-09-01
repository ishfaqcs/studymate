import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('About StudyMate')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Center(
            child: Image.asset('assets/branding/studymate-mark-source.png',
                width: 88, height: 88)),
        const SizedBox(height: 18),
        Text('StudyMate',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Student Planner, Attendance & GPA Tracker',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        const Text(
            'StudyMate helps students organize courses, schedules, attendance, deadlines, grades, notes and academic progress.',
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (_, snapshot) => ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                subtitle: Text(snapshot.hasData
                    ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                    : 'Loading…'))),
        ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Privacy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy')),
        ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Open-source licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
                context: context,
                applicationName: 'StudyMate',
                applicationVersion: '1.0.0'))
      ]));
}
