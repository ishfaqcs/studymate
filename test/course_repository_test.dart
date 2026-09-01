import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/features/courses/course.dart';

import 'course_test_support.dart';

void main() {
  group('course data', () {
    test('creates and persists a course in the repository', () async {
      final repository = MemoryCourseRepository();
      await repository.create(sampleCourse());

      final persisted = await repository.getById('course-1');
      expect(persisted?.name, 'Artificial Intelligence');
      expect((await repository.listForActiveSemester()).length, 1);
    });

    test('edits without duplicating a course', () async {
      final repository = MemoryCourseRepository([sampleCourse()]);
      await repository.update(sampleCourse(name: 'Machine Learning'));

      expect(repository.courses, hasLength(1));
      expect(repository.courses.single.name, 'Machine Learning');
    });

    test('deletes a course', () async {
      final repository = MemoryCourseRepository([sampleCourse()]);
      await repository.delete('course-1');
      expect(repository.courses, isEmpty);
    });

    test('maps all persistent course fields', () {
      final original = sampleCourse();
      final restored = Course.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.semesterId, original.semesterId);
      expect(restored.room, original.room);
      expect(restored.colorValue, original.colorValue);
    });
  });

  group('attendance validation', () {
    test('accepts percentages from 1 through 100', () {
      expect(validateAttendance('1'), isNull);
      expect(validateAttendance('75'), isNull);
      expect(validateAttendance('100'), isNull);
    });

    test('rejects missing and out-of-range percentages', () {
      expect(validateAttendance(''), isNotNull);
      expect(validateAttendance('0'), isNotNull);
      expect(validateAttendance('101'), isNotNull);
      expect(validateAttendance('abc'), isNotNull);
    });
  });
}
