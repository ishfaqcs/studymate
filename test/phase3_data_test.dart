import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/features/attendance/attendance_record.dart';

import 'phase3_test_support.dart';
import 'course_test_support.dart';

void main() {
  test('schedule create edit delete and persistence', () async {
    final repository = MemoryScheduleRepository();
    await repository.create(sampleSchedule());
    expect((await repository.list()).single.schedule.room, 'CS-201');
    await repository.update(sampleSchedule(start: 600));
    expect(repository.values.single.startMinutes, 600);
    await repository.delete('schedule-1');
    expect(repository.values, isEmpty);
  });

  test('schedule conflict detects overlap but allows adjacent classes',
      () async {
    final repository = MemoryScheduleRepository([sampleSchedule()]);
    expect(await repository.conflict(sampleSchedule(id: 'overlap', start: 600)),
        isNotNull);
    expect(
        await repository.conflict(sampleSchedule(id: 'adjacent', start: 630)),
        isNull);
  });

  test('attendance create update delete and persistence', () async {
    final repository = MemoryAttendanceRepository();
    await repository.create(sampleAttendance());
    expect((await repository.listForCourse('course-1')).single.status,
        AttendanceStatus.present);
    await repository.update(sampleAttendance(status: AttendanceStatus.late));
    expect(repository.values.single.status, AttendanceStatus.late);
    await repository.delete('attendance-1');
    expect(repository.values, isEmpty);
  });

  test('status treatment excludes excused and cancelled and counts late', () {
    final summary = CourseAttendanceSummary(course: sampleCourse(), records: [
      sampleAttendance(id: '1'),
      sampleAttendance(id: '2', status: AttendanceStatus.late),
      sampleAttendance(id: '3', status: AttendanceStatus.absent),
      sampleAttendance(id: '4', status: AttendanceStatus.excused),
      sampleAttendance(id: '5', status: AttendanceStatus.cancelled),
    ]);
    expect(summary.attended, 2);
    expect(summary.counted, 3);
    expect(summary.insight.percentage, closeTo(66.666, 0.01));
  });

  test('zero records and course requirement are handled', () {
    final summary =
        CourseAttendanceSummary(course: sampleCourse(), records: const []);
    expect(summary.counted, 0);
    expect(summary.insight.percentage, 0);
    expect(summary.course.requiredAttendance, 75);
  });
}
