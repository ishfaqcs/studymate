import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/features/tasks/academic_task.dart';
import 'phase4_test_support.dart';

void main() {
  test('grade create edit delete and persistence', () async {
    final repo = MemoryGradeRepository();
    await repo.create(sampleAssessment(), 3);
    expect((await repo.assessments()).single.title, 'Midterm');
    await repo.update(sampleAssessment(obtained: 90), 3);
    expect(repo.values.single.marksObtained, 90);
    await repo.delete('grade-1');
    expect(repo.values, isEmpty);
  });
  test('task create edit delete complete course filter and persistence',
      () async {
    final repo = MemoryTaskRepository();
    await repo.create(sampleTask());
    expect(
        (await repo.list(courseId: 'course-1')).single.title, 'Assignment 2');
    await repo.update(sampleTask(status: TaskStatus.completed));
    expect(repo.values.single.status, TaskStatus.completed);
    await repo.delete('task-1');
    expect(repo.values, isEmpty);
  });
}
