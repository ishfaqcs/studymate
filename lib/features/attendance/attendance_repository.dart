import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../courses/course_repository.dart';
import 'attendance_record.dart';

class AttendanceRepository {
  AttendanceRepository({Future<Database> Function()? database})
      : _database = database ?? (() => AppDatabase.instance.database);
  final Future<Database> Function() _database;

  Future<List<AttendanceRecord>> listForCourse(String courseId) async {
    final rows = await (await _database()).query('attendance',
        where: 'course_id = ?', whereArgs: [courseId], orderBy: 'date DESC');
    return rows.map(AttendanceRecord.fromMap).toList();
  }

  Future<List<CourseAttendanceSummary>> summaries() async {
    final courses =
        await CourseRepository(database: _database).listForActiveSemester();
    return Future.wait(courses.map((course) async => CourseAttendanceSummary(
        course: course, records: await listForCourse(course.id))));
  }

  Future<AttendanceRecord?> existing(
      {required String courseId,
      required DateTime date,
      String? scheduleId,
      String? excludingId}) async {
    final day = DateTime(date.year, date.month, date.day).toIso8601String();
    final rows = await (await _database()).query('attendance',
        where: scheduleId == null
            ? 'course_id = ? AND date = ? AND schedule_id IS NULL${excludingId == null ? '' : ' AND id != ?'}'
            : 'course_id = ? AND date = ? AND schedule_id = ?${excludingId == null ? '' : ' AND id != ?'}',
        whereArgs: [
          courseId,
          day,
          if (scheduleId != null) scheduleId,
          if (excludingId != null) excludingId
        ],
        limit: 1);
    return rows.isEmpty ? null : AttendanceRecord.fromMap(rows.first);
  }

  Future<void> create(AttendanceRecord value) async =>
      (await _database()).insert('attendance', value.toMap());
  Future<void> update(AttendanceRecord value) async =>
      (await _database()).update('attendance', value.toMap(),
          where: 'id = ?', whereArgs: [value.id]);
  Future<void> delete(String id) async => (await _database())
      .delete('attendance', where: 'id = ?', whereArgs: [id]);
}

final attendanceRepositoryProvider =
    Provider<AttendanceRepository>((ref) => AttendanceRepository());
final attendanceSummariesProvider =
    FutureProvider.autoDispose<List<CourseAttendanceSummary>>(
        (ref) => ref.watch(attendanceRepositoryProvider).summaries());
final attendanceForCourseProvider = FutureProvider.autoDispose
    .family<List<AttendanceRecord>, String>(
        (ref, id) => ref.watch(attendanceRepositoryProvider).listForCourse(id));
