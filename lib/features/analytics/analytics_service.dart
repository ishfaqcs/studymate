import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../grades/grade_models.dart';
import '../grades/grade_repository.dart';
import '../study_sessions/study_session_repository.dart';

class AnalyticsService {
  AnalyticsService({StudySessionRepository? sessions, GradeRepository? grades})
      : _sessions = sessions ?? StudySessionRepository(),
        _grades = grades ?? GradeRepository();
  final StudySessionRepository _sessions;
  final GradeRepository _grades;

  Future<List<Map<String, Object?>>> attendanceTrend(
      DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
    return db.rawQuery(
        '''SELECT date, SUM(CASE WHEN status IN ('present','late') THEN 1 ELSE 0 END) attended, SUM(CASE WHEN status NOT IN ('excused','cancelled') THEN 1 ELSE 0 END) counted FROM attendance WHERE date >= ? AND date < ? GROUP BY date ORDER BY date''',
        [start.toIso8601String(), end.toIso8601String()]);
  }

  Future<List<Map<String, Object?>>> taskCompletionTrend(
      DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
    return db.rawQuery(
        '''SELECT substr(completed_at, 1, 10) date, COUNT(*) completed FROM tasks WHERE status = 'completed' AND completed_at >= ? AND completed_at < ? GROUP BY substr(completed_at, 1, 10) ORDER BY date''',
        [start.toIso8601String(), end.toIso8601String()]);
  }

  Future<List<SemesterAcademicSummary>> gpaTrend() =>
      _grades.semesterSummaries();

  Future<List<CourseGradeSummary>> coursePerformance({int semesterId = 1}) =>
      _grades.courseSummaries(semesterId: semesterId);
  Future<int> studyMinutesBetweenDates(DateTime start, DateTime end) =>
      _sessions.totalMinutes(start, end);
  Future<int> studyMinutesToday({DateTime? now}) {
    final d = now ?? DateTime.now();
    final start = DateTime(d.year, d.month, d.day);
    return _sessions.totalMinutes(start, start.add(const Duration(days: 1)));
  }

  Future<int> studyMinutesThisWeek({DateTime? now}) {
    final d = now ?? DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final start = day.subtract(Duration(days: day.weekday - 1));
    return _sessions.totalMinutes(start, start.add(const Duration(days: 7)));
  }

  Future<Map<String, int>> studyMinutesByCourse(
      DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
        "SELECT course_id, COALESCE(SUM(actual_duration_minutes),0) minutes FROM study_sessions WHERE status = 'completed' AND started_at >= ? AND started_at < ? AND course_id IS NOT NULL GROUP BY course_id",
        [start.toIso8601String(), end.toIso8601String()]);
    return {
      for (final r in rows)
        r['course_id'] as String: (r['minutes'] as num).toInt()
    };
  }

  Future<int> completedSessionCount(DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
        "SELECT COUNT(*) count FROM study_sessions WHERE status = 'completed' AND started_at >= ? AND started_at < ?",
        [start.toIso8601String(), end.toIso8601String()]);
    return (rows.first['count'] as num).toInt();
  }
}

final analyticsServiceProvider = Provider((ref) => AnalyticsService(
    sessions: ref.watch(studySessionRepositoryProvider),
    grades: ref.watch(gradeRepositoryProvider)));
