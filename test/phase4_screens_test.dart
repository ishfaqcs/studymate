import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/features/courses/course_repository.dart';
import 'package:studentplanner/features/grades/grade_form_screen.dart';
import 'package:studentplanner/features/grades/grade_repository.dart';
import 'package:studentplanner/features/grades/grades_screen.dart';
import 'package:studentplanner/features/tasks/task_form_screen.dart';
import 'package:studentplanner/features/tasks/task_repository.dart';
import 'package:studentplanner/features/tasks/tasks_screen.dart';
import 'course_test_support.dart';
import 'phase4_test_support.dart';

Widget app(Widget child,
        {MemoryGradeRepository? grades, MemoryTaskRepository? tasks}) =>
    ProviderScope(overrides: [
      courseRepositoryProvider
          .overrideWithValue(MemoryCourseRepository([sampleCourse()])),
      gradeRepositoryProvider
          .overrideWithValue(grades ?? MemoryGradeRepository()),
      taskRepositoryProvider.overrideWithValue(tasks ?? MemoryTaskRepository())
    ], child: MaterialApp(home: child));
void large(WidgetTester t) {
  t.view.physicalSize = const Size(800, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('grades show professional empty summary', (t) async {
    await t.pumpWidget(app(const GradesScreen()));
    await t.pumpAndSettle();
    expect(find.text('No grades recorded'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });
  testWidgets('grade form validates required fields', (t) async {
    large(t);
    await t.pumpWidget(app(const GradeFormScreen()));
    await t.pumpAndSettle();
    await t.tap(find.text('Save grade'));
    await t.pump();
    expect(find.text('Select a course'), findsOneWidget);
    expect(find.text('Assessment title is required'), findsOneWidget);
  });
  testWidgets('task form validates title and due date', (t) async {
    large(t);
    await t.pumpWidget(app(const TaskFormScreen()));
    await t.pumpAndSettle();
    await t.tap(find.text('Save task'));
    await t.pump();
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Due date is required'), findsOneWidget);
  });
  testWidgets('task list displays and quick-completes task', (t) async {
    final repo = MemoryTaskRepository([sampleTask()]);
    await t.pumpWidget(app(const TasksScreen(), tasks: repo));
    await t.pumpAndSettle();
    expect(find.text('Assignment 2'), findsOneWidget);
    await t.tap(find.byType(Checkbox));
    await t.pumpAndSettle();
    expect(repo.values.single.status.name, 'completed');
  });
}
