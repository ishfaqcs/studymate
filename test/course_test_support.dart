import 'package:studentplanner/features/courses/course.dart';
import 'package:studentplanner/features/courses/course_repository.dart';

class MemoryCourseRepository extends CourseRepository {
  MemoryCourseRepository([Iterable<Course> initial = const []])
      : courses = [...initial];

  final List<Course> courses;

  @override
  Future<int> activeSemesterId() async => 1;

  @override
  Future<double> defaultAttendance() async => 75;

  @override
  Future<List<Course>> listForActiveSemester() async =>
      courses.where((course) => course.semesterId == 1).toList();

  @override
  Future<Course?> getById(String id) async {
    for (final course in courses) {
      if (course.id == id) return course;
    }
    return null;
  }

  @override
  Future<void> create(Course course) async => courses.add(course);

  @override
  Future<void> update(Course course) async {
    final index = courses.indexWhere((item) => item.id == course.id);
    if (index >= 0) courses[index] = course;
  }

  @override
  Future<void> delete(String id) async {
    courses.removeWhere((course) => course.id == id);
  }
}

Course sampleCourse({String name = 'Artificial Intelligence'}) => Course(
      id: 'course-1',
      semesterId: 1,
      name: name,
      code: 'CS-401',
      instructor: 'Dr. Ahmed Khan',
      room: 'CS Lab 2',
      creditHours: 3,
      requiredAttendance: 75,
      colorValue: 0xFF3457D5,
      createdAt: DateTime(2026),
    );
