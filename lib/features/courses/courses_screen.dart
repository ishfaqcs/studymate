import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import 'course.dart';
import 'course_repository.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/courses/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add course'),
      ),
      body: courses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: OutlinedButton(
            onPressed: () => ref.invalidate(coursesProvider),
            child: const Text('Try loading courses again'),
          ),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No courses yet',
                message: 'Add your courses to build your timetable,\n'
                    'track attendance and organize coursework.',
                actionLabel: 'Add course',
                onAction: () => context.push('/courses/add'),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(coursesProvider);
                  await ref.read(coursesProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _CourseTile(course: items[index]),
                ),
              ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final creditText = course.creditHours % 1 == 0
        ? course.creditHours.toStringAsFixed(0)
        : course.creditHours.toStringAsFixed(1);
    return Semantics(
      button: true,
      label: 'Open ${course.name} course details',
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        onTap: () => context.push('/courses/${course.id}'),
        leading: Container(
          width: 5,
          height: 52,
          decoration: BoxDecoration(
            color: course.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        title: Text(course.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text([
                if (course.code != null) course.code!,
                if (course.instructor != null) course.instructor!,
              ].join(' • ')),
              const SizedBox(height: 2),
              Text(
                '$creditText credit hours • Required attendance ${course.requiredAttendance.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
