import 'package:studentplanner/features/attendance/attendance_record.dart';
import 'package:studentplanner/features/attendance/attendance_repository.dart';
import 'package:studentplanner/features/timetable/class_schedule.dart';
import 'package:studentplanner/features/timetable/schedule_repository.dart';

import 'course_test_support.dart';

ClassSchedule sampleSchedule({String id = 'schedule-1', int start = 540}) =>
    ClassSchedule(
        id: id,
        courseId: 'course-1',
        weekday: DateTime.now().weekday,
        startMinutes: start,
        endMinutes: start + 90,
        room: 'CS-201',
        classType: ClassType.lecture,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));

AttendanceRecord sampleAttendance(
        {String id = 'attendance-1',
        AttendanceStatus status = AttendanceStatus.present}) =>
    AttendanceRecord(
        id: id,
        courseId: 'course-1',
        scheduleId: 'schedule-1',
        date: DateTime(2026, 8, 20),
        status: status,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));

class MemoryScheduleRepository extends ScheduleRepository {
  MemoryScheduleRepository([Iterable<ClassSchedule> initial = const []])
      : values = [...initial];
  final List<ClassSchedule> values;
  @override
  Future<List<ScheduleEntry>> list(
          {int? weekday, String? courseId}) async =>
      values
          .where((value) =>
              (weekday == null || value.weekday == weekday) &&
              (courseId == null || value.courseId == courseId))
          .map((value) => ScheduleEntry(value, sampleCourse()))
          .toList();
  @override
  Future<ClassSchedule?> get(String id) async =>
      values.where((value) => value.id == id).firstOrNull;
  @override
  Future<ScheduleEntry?> conflict(ClassSchedule value) async {
    for (final item in values) {
      if (item.id != value.id &&
          item.weekday == value.weekday &&
          value.startMinutes < item.endMinutes &&
          value.endMinutes > item.startMinutes) {
        return ScheduleEntry(item, sampleCourse());
      }
    }
    return null;
  }

  @override
  Future<void> create(ClassSchedule value) async => values.add(value);
  @override
  Future<void> update(ClassSchedule value) async {
    final index = values.indexWhere((item) => item.id == value.id);
    if (index >= 0) values[index] = value;
  }

  @override
  Future<void> delete(String id) async =>
      values.removeWhere((value) => value.id == id);
}

class MemoryAttendanceRepository extends AttendanceRepository {
  MemoryAttendanceRepository([Iterable<AttendanceRecord> initial = const []])
      : values = [...initial];
  final List<AttendanceRecord> values;
  @override
  Future<List<AttendanceRecord>> listForCourse(String courseId) async =>
      values.where((value) => value.courseId == courseId).toList();
  @override
  Future<List<CourseAttendanceSummary>> summaries() async => [
        CourseAttendanceSummary(
            course: sampleCourse(), records: await listForCourse('course-1'))
      ];
  @override
  Future<AttendanceRecord?> existing(
      {required String courseId,
      required DateTime date,
      String? scheduleId,
      String? excludingId}) async {
    for (final value in values) {
      if (value.id != excludingId &&
          value.courseId == courseId &&
          value.scheduleId == scheduleId &&
          value.date.year == date.year &&
          value.date.month == date.month &&
          value.date.day == date.day) {
        return value;
      }
    }
    return null;
  }

  @override
  Future<void> create(AttendanceRecord value) async => values.add(value);
  @override
  Future<void> update(AttendanceRecord value) async {
    final index = values.indexWhere((item) => item.id == value.id);
    if (index >= 0) values[index] = value;
  }

  @override
  Future<void> delete(String id) async =>
      values.removeWhere((value) => value.id == id);
}
