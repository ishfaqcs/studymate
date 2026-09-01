import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/services/notification_service.dart';
import 'course.dart';

class CourseRepository {
  CourseRepository(
      {Future<Database> Function()? database, ReminderScheduler? reminders})
      : _database = database ?? (() => AppDatabase.instance.database),
        _reminders = reminders ?? NotificationService.instance;

  final Future<Database> Function() _database;
  final ReminderScheduler _reminders;

  Future<int> activeSemesterId() async {
    final rows = await (await _database()).query('profile', limit: 1);
    return rows.isEmpty ? 1 : (rows.first['id'] as num).toInt();
  }

  Future<double> defaultAttendance() async {
    final rows = await (await _database()).query('profile', limit: 1);
    return rows.isEmpty
        ? 75
        : (rows.first['attendance_requirement'] as num?)?.toDouble() ?? 75;
  }

  Future<List<Course>> listForActiveSemester() async {
    final semesterId = await activeSemesterId();
    final rows = await (await _database()).query(
      'courses',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Course.fromMap).toList(growable: false);
  }

  Future<Course?> getById(String id) async {
    final rows = await (await _database())
        .query('courses', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Course.fromMap(rows.first);
  }

  Future<void> create(Course course) async {
    await (await _database()).insert('courses', course.toMap());
  }

  Future<void> update(Course course) async {
    await (await _database()).update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _database();
    final documents = await db.query('documents',
        columns: ['file_path'], where: 'course_id = ?', whereArgs: [id]);
    final tasks = await db.query('tasks',
        columns: ['id'], where: 'course_id = ?', whereArgs: [id]);
    await db.transaction((txn) async {
      for (final table in [
        'schedules',
        'attendance',
        'tasks',
        'grades',
        'notes',
        'documents'
      ]) {
        await txn.delete(table, where: 'course_id = ?', whereArgs: [id]);
      }
      await txn.delete('courses', where: 'id = ?', whereArgs: [id]);
    });
    for (final row in documents) {
      try {
        final file = File(row['file_path'] as String);
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // The academic data is already deleted; stale private files can be
        // reclaimed by app storage cleanup without leaving orphan records.
      }
    }
    for (final row in tasks) {
      try {
        await _reminders.cancel('task:${row['id']}');
      } catch (_) {
        // Notification cleanup must not make a committed course deletion fail.
      }
    }
  }
}

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
});

final coursesProvider = FutureProvider.autoDispose<List<Course>>((ref) {
  return ref.watch(courseRepositoryProvider).listForActiveSemester();
});

final courseProvider = FutureProvider.autoDispose.family<Course?, String>(
  (ref, id) => ref.watch(courseRepositoryProvider).getById(id),
);
