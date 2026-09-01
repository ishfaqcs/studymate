import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../courses/course.dart';
import 'class_schedule.dart';

class ScheduleRepository {
  ScheduleRepository({Future<Database> Function()? database})
      : _database = database ?? (() => AppDatabase.instance.database);
  final Future<Database> Function() _database;

  Future<List<ScheduleEntry>> list({int? weekday, String? courseId}) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (weekday != null) {
      clauses.add('s.weekday = ?');
      args.add(weekday);
    }
    if (courseId != null) {
      clauses.add('s.course_id = ?');
      args.add(courseId);
    }
    final rows = await (await _database()).rawQuery('''
      SELECT s.*, c.name course_name, c.semester_id, c.code, c.instructor,
        c.credit_hours, c.required_attendance, c.color_value, c.created_at course_created_at,
        c.room course_room
      FROM schedules s JOIN courses c ON c.id = s.course_id
      ${clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}'}
      ORDER BY s.weekday, s.start_minutes
    ''', args);
    return rows
        .map((row) => ScheduleEntry(
            ClassSchedule.fromMap(row),
            Course.fromMap({
              'id': row['course_id'],
              'semester_id': row['semester_id'],
              'name': row['course_name'],
              'code': row['code'],
              'instructor': row['instructor'],
              'room': row['course_room'],
              'credit_hours': row['credit_hours'],
              'required_attendance': row['required_attendance'],
              'color_value': row['color_value'],
              'created_at': row['course_created_at'],
            })))
        .toList();
  }

  Future<ClassSchedule?> get(String id) async {
    final rows = await (await _database())
        .query('schedules', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : ClassSchedule.fromMap(rows.first);
  }

  Future<ScheduleEntry?> conflict(ClassSchedule value) async {
    final entries = await list(weekday: value.weekday);
    for (final entry in entries) {
      final item = entry.schedule;
      if (item.id != value.id &&
          value.startMinutes < item.endMinutes &&
          value.endMinutes > item.startMinutes) {
        return entry;
      }
    }
    return null;
  }

  Future<void> create(ClassSchedule value) async =>
      (await _database()).insert('schedules', value.toMap());
  Future<void> update(ClassSchedule value) async =>
      (await _database()).update('schedules', value.toMap(),
          where: 'id = ?', whereArgs: [value.id]);
  Future<void> delete(String id) async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.update('attendance', {'schedule_id': null},
          where: 'schedule_id = ?', whereArgs: [id]);
      await txn.delete('schedules', where: 'id = ?', whereArgs: [id]);
    });
  }
}

final scheduleRepositoryProvider =
    Provider<ScheduleRepository>((ref) => ScheduleRepository());
final schedulesProvider = FutureProvider.autoDispose<List<ScheduleEntry>>(
    (ref) => ref.watch(scheduleRepositoryProvider).list());
final schedulesForCourseProvider = FutureProvider.autoDispose
    .family<List<ScheduleEntry>, String>(
        (ref, id) => ref.watch(scheduleRepositoryProvider).list(courseId: id));
