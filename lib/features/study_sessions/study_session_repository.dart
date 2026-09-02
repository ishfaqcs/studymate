import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import 'study_session.dart';

class StudySessionRepository {
  StudySessionRepository({Future<Database> Function()? database})
      : _database = database ?? (() => AppDatabase.instance.database);
  final Future<Database> Function() _database;
  Future<void> create(StudySession value) async =>
      (await _database()).insert('study_sessions', value.toMap());
  Future<StudySession?> get(String id) async {
    final rows = await (await _database())
        .query('study_sessions', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : StudySession.fromMap(rows.first);
  }

  Future<void> update(StudySession value) async =>
      (await _database()).update('study_sessions', value.toMap(),
          where: 'id = ?', whereArgs: [value.id]);
  Future<void> complete(String id,
      {required int actualMinutes, DateTime? at}) async {
    final now = at ?? DateTime.now();
    await (await _database()).update(
        'study_sessions',
        {
          'status': StudySessionStatus.completed.name,
          'actual_duration_minutes': actualMinutes,
          'completed_at': now.toIso8601String(),
          'updated_at': now.toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> cancel(String id, {DateTime? at}) async {
    final now = at ?? DateTime.now();
    await (await _database()).update(
        'study_sessions',
        {
          'status': StudySessionStatus.cancelled.name,
          'updated_at': now.toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> delete(String id) async => (await _database())
      .delete('study_sessions', where: 'id = ?', whereArgs: [id]);
  Future<List<StudySession>> between(DateTime start, DateTime end,
      {String? courseId}) async {
    final rows = await (await _database()).query('study_sessions',
        where:
            'started_at >= ? AND started_at < ?${courseId == null ? '' : ' AND course_id = ?'}',
        whereArgs: [
          start.toIso8601String(),
          end.toIso8601String(),
          if (courseId != null) courseId
        ],
        orderBy: 'started_at DESC');
    return rows.map(StudySession.fromMap).toList();
  }

  Future<List<StudySession>> byDate(DateTime date) => between(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day).add(const Duration(days: 1)));
  Future<List<StudySession>> byCourse(String courseId) async {
    final rows = await (await _database()).query('study_sessions',
        where: 'course_id = ?',
        whereArgs: [courseId],
        orderBy: 'started_at DESC');
    return rows.map(StudySession.fromMap).toList();
  }

  Future<int> totalMinutes(DateTime start, DateTime end,
      {String? courseId}) async {
    final db = await _database();
    final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(actual_duration_minutes), 0) total FROM study_sessions WHERE status = ? AND started_at >= ? AND started_at < ?${courseId == null ? '' : ' AND course_id = ?'}',
        [
          StudySessionStatus.completed.name,
          start.toIso8601String(),
          end.toIso8601String(),
          if (courseId != null) courseId
        ]);
    return (rows.first['total'] as num).toInt();
  }
}

final studySessionRepositoryProvider =
    Provider((ref) => StudySessionRepository());
final studySessionsForDateProvider = FutureProvider.autoDispose
    .family<List<StudySession>, DateTime>(
        (ref, date) => ref.watch(studySessionRepositoryProvider).byDate(date));
