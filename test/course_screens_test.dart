import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:studentplanner/features/courses/course.dart';
import 'package:studentplanner/features/courses/course_details_screen.dart';
import 'package:studentplanner/features/courses/course_form_screen.dart';
import 'package:studentplanner/features/courses/course_repository.dart';
import 'package:studentplanner/features/courses/courses_screen.dart';

import 'course_test_support.dart';

Widget testApp(MemoryCourseRepository repository,
    {String initial = '/courses'}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
      GoRoute(
          path: '/courses/add', builder: (_, __) => const CourseFormScreen()),
      GoRoute(
        path: '/courses/:id',
        builder: (_, state) =>
            CourseDetailsScreen(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/courses/:id/edit',
        builder: (_, state) => CourseFormScreen(course: state.extra as Course?),
      ),
    ],
  );
  return ProviderScope(
    overrides: [courseRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows empty course list and opens Add Course', (tester) async {
    await tester.pumpWidget(testApp(MemoryCourseRepository()));
    await tester.pumpAndSettle();
    expect(find.text('No courses yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Add course'));
    await tester.pumpAndSettle();
    expect(find.text('Course name *'), findsOneWidget);
  });

  testWidgets('validates and successfully adds a course', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryCourseRepository();
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add course'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save course'));
    await tester.tap(find.text('Save course'));
    await tester.pump();
    expect(find.text('Course name is required'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Course name *'),
        '  Artificial Intelligence  ');
    await tester.ensureVisible(find.text('Save course'));
    await tester.tap(find.text('Save course'));
    await tester.pumpAndSettle();
    expect(repository.courses.single.name, 'Artificial Intelligence');
  });

  testWidgets('edits an existing course', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryCourseRepository([sampleCourse()]);
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artificial Intelligence'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit course'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Course name *'),
        'Machine Learning');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(repository.courses, hasLength(1));
    expect(repository.courses.single.name, 'Machine Learning');
  });

  testWidgets('requires confirmation before deleting', (tester) async {
    final repository = MemoryCourseRepository([sampleCourse()]);
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artificial Intelligence'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete course'));
    await tester.pumpAndSettle();
    expect(find.text('Delete course?'), findsOneWidget);
    expect(repository.courses, hasLength(1));

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repository.courses, isEmpty);
  });
}
