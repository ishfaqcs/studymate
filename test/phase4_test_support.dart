import 'package:studentplanner/core/services/notification_service.dart';
import 'package:studentplanner/features/grades/grade_models.dart';
import 'package:studentplanner/features/grades/grade_repository.dart';
import 'package:studentplanner/features/tasks/academic_task.dart';
import 'package:studentplanner/features/tasks/task_repository.dart';
import 'course_test_support.dart';

const defaultBoundaries = [
  GradeBoundary(id: 'a', letter: 'A', minimumPercentage: 85, gradePoint: 4),
  GradeBoundary(
      id: 'am', letter: 'A-', minimumPercentage: 80, gradePoint: 3.67),
  GradeBoundary(id: 'b', letter: 'B', minimumPercentage: 70, gradePoint: 3),
  GradeBoundary(id: 'f', letter: 'F', minimumPercentage: 0, gradePoint: 0),
];
Assessment sampleAssessment(
        {String id = 'grade-1', double obtained = 85, double total = 100}) =>
    Assessment(
        id: id,
        courseId: 'course-1',
        semesterId: 1,
        title: 'Midterm',
        type: AssessmentType.midterm,
        marksObtained: obtained,
        totalMarks: total,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));
AcademicTask sampleTask(
        {String id = 'task-1',
        TaskStatus status = TaskStatus.notStarted,
        DateTime? due,
        String? courseId = 'course-1',
        DateTime? reminder}) =>
    AcademicTask(
        id: id,
        courseId: courseId,
        semesterId: 1,
        title: 'Assignment 2',
        description: 'Complete chapter exercises',
        type: TaskType.assignment,
        dueDate: due ?? DateTime(2026, 8, 25),
        dueTime: '23:59',
        priority: TaskPriority.high,
        status: status,
        reminderAt: reminder,
        completedAt: status == TaskStatus.completed ? DateTime(2026) : null,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));

class FakeReminderScheduler implements ReminderScheduler {
  final scheduled = <String, DateTime>{};
  final cancelled = <String>[];
  bool allowed = true;
  @override
  Future<void> cancel(String key) async {
    cancelled.add(key);
    scheduled.remove(key);
  }

  @override
  Future<bool> schedule(
      {required String key,
      required String title,
      required String body,
      required DateTime at}) async {
    if (!allowed) return false;
    scheduled[key] = at;
    return true;
  }
}

class MemoryTaskRepository extends TaskRepository {
  MemoryTaskRepository([Iterable<AcademicTask> initial = const []])
      : values = [...initial];
  final List<AcademicTask> values;
  @override
  Future<List<AcademicTask>> list(
          {int semesterId = 1, String? courseId}) async =>
      values
          .where((t) =>
              t.semesterId == semesterId &&
              (courseId == null || t.courseId == courseId))
          .toList();
  @override
  Future<bool> create(AcademicTask task) async {
    values.add(task);
    return true;
  }

  @override
  Future<bool> update(AcademicTask task) async {
    final i = values.indexWhere((t) => t.id == task.id);
    if (i >= 0) values[i] = task;
    return true;
  }

  @override
  Future<void> delete(String id) async => values.removeWhere((t) => t.id == id);
}

class MemoryGradeRepository extends GradeRepository {
  MemoryGradeRepository([Iterable<Assessment> initial = const []])
      : values = [...initial];
  final List<Assessment> values;
  @override
  Future<List<GradeBoundary>> boundaries() async => defaultBoundaries;
  @override
  Future<List<Assessment>> assessments(
          {String? courseId, int? semesterId}) async =>
      values
          .where((a) =>
              (courseId == null || a.courseId == courseId) &&
              (semesterId == null || a.semesterId == semesterId))
          .toList();
  @override
  Future<List<CourseGradeSummary>> courseSummaries(
          {int semesterId = 1}) async =>
      [
        CourseGradeSummary(
            course: sampleCourse(),
            assessments: await assessments(courseId: 'course-1'),
            boundaries: defaultBoundaries)
      ];
  @override
  Future<void> create(Assessment value, double credits) async =>
      values.add(value);
  @override
  Future<void> update(Assessment value, double credits) async {
    final i = values.indexWhere((a) => a.id == value.id);
    if (i >= 0) values[i] = value;
  }

  @override
  Future<void> delete(String id) async => values.removeWhere((a) => a.id == id);
}
