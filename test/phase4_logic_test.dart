import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/core/services/notification_service.dart';
import 'package:studentplanner/features/grades/grade_models.dart';
import 'package:studentplanner/features/tasks/academic_task.dart';
import 'package:studentplanner/features/courses/course.dart';
import 'course_test_support.dart';
import 'phase4_test_support.dart';

void main() {
  test('single-course GPA is 4.00', () {
    final s = SemesterAcademicSummary(id: 1, name: 'Fall', courses: [
      CourseGradeSummary(
          course: sampleCourse(),
          assessments: [sampleAssessment()],
          boundaries: defaultBoundaries)
    ]);
    expect(s.gpa, 4);
  });
  test('GPA weights course grade points by credits', () {
    final a = sampleCourse();
    final b = Course(
        id: 'b',
        semesterId: 1,
        name: 'DB',
        creditHours: 4,
        requiredAttendance: 75,
        colorValue: 0,
        createdAt: DateTime(2026),
        finalGradeLetter: 'B',
        finalGradePoint: 3);
    final aFinal = Course(
        id: a.id,
        semesterId: 1,
        name: a.name,
        creditHours: 3,
        requiredAttendance: 75,
        colorValue: a.colorValue,
        createdAt: a.createdAt,
        finalGradeLetter: 'A',
        finalGradePoint: 4);
    final s = SemesterAcademicSummary(id: 1, name: 'Fall', courses: [
      CourseGradeSummary(
          course: aFinal, assessments: const [], boundaries: defaultBoundaries),
      CourseGradeSummary(
          course: b, assessments: const [], boundaries: defaultBoundaries)
    ]);
    expect(s.gpa, closeTo(24 / 7, 0.0001));
  });
  test('CGPA weights semester quality points, not semester averages', () {
    Course course(String id, double credits, double point) => Course(
        id: id,
        semesterId: 1,
        name: id,
        creditHours: credits,
        requiredAttendance: 75,
        colorValue: 0,
        createdAt: DateTime(2026),
        finalGradeLetter: 'X',
        finalGradePoint: point);
    final semesters = [
      SemesterAcademicSummary(id: 1, name: 'One', courses: [
        CourseGradeSummary(
            course: course('a', 15, 3),
            assessments: const [],
            boundaries: defaultBoundaries)
      ]),
      SemesterAcademicSummary(id: 2, name: 'Two', courses: [
        CourseGradeSummary(
            course: course('b', 18, 4),
            assessments: const [],
            boundaries: defaultBoundaries)
      ])
    ];
    expect(calculateCgpa(semesters), closeTo((45 + 72) / 33, 0.0001));
    expect(calculateCgpa(semesters), isNot(3.5));
  });
  test('grade boundaries handle exact, above, below, 100 and 0', () {
    expect(boundaryFor(85, defaultBoundaries)?.letter, 'A');
    expect(boundaryFor(85.1, defaultBoundaries)?.letter, 'A');
    expect(boundaryFor(84.9, defaultBoundaries)?.letter, 'A-');
    expect(boundaryFor(100, defaultBoundaries)?.letter, 'A');
    expect(boundaryFor(0, defaultBoundaries)?.letter, 'F');
  });
  test('task deadline labels today tomorrow and overdue', () {
    final now = DateTime(2026, 8, 20, 12);
    expect(deadlineLabel(sampleTask(due: DateTime(2026, 8, 20)), now),
        'Due today');
    expect(deadlineLabel(sampleTask(due: DateTime(2026, 8, 21)), now),
        'Due tomorrow');
    expect(deadlineLabel(sampleTask(due: DateTime(2026, 8, 18)), now),
        'Overdue by 2 days');
    expect(
        sampleTask(status: TaskStatus.completed, due: DateTime(2026, 8, 18))
            .isOverdueAt(now),
        false);
  });
  test('reminder timestamp and notification id are stable', () {
    final due = DateTime(2026, 8, 25, 12);
    expect(reminderTime(due, 60), DateTime(2026, 8, 25, 11));
    final service = NotificationService.instance;
    expect(
        service.notificationId('task:abc'), service.notificationId('task:abc'));
    expect(service.notificationId('task:abc'),
        isNot(service.notificationId('task:def')));
  });
  test('reminder scheduler records scheduling and cancellation', () async {
    final scheduler = FakeReminderScheduler();
    final at = DateTime(2026, 8, 25, 11);
    expect(
        await scheduler.schedule(
            key: 'task:1', title: 'StudyMate', body: 'Due soon', at: at),
        true);
    expect(scheduler.scheduled['task:1'], at);
    await scheduler.cancel('task:1');
    expect(scheduler.scheduled, isNot(contains('task:1')));
    expect(scheduler.cancelled, contains('task:1'));
  });
}
