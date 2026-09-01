import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../courses/course.dart';
import 'grade_models.dart';

class GradeRepository {
  GradeRepository({Future<Database> Function()? database})
      : _database = database ?? (() => AppDatabase.instance.database);
  final Future<Database> Function() _database;
  Future<List<GradeBoundary>> boundaries() async => (await (await _database())
          .query('grading_boundaries', orderBy: 'minimum_percentage DESC'))
      .map(GradeBoundary.fromMap)
      .toList();
  Future<List<Assessment>> assessments(
      {String? courseId, int? semesterId}) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (courseId != null) {
      clauses.add('course_id = ?');
      args.add(courseId);
    }
    if (semesterId != null) {
      clauses.add('semester_id = ?');
      args.add(semesterId);
    }
    final rows = await (await _database()).query('grades',
        where: clauses.isEmpty ? null : clauses.join(' AND '),
        whereArgs: args,
        orderBy: 'date DESC, created_at DESC');
    return rows.map(Assessment.fromMap).toList();
  }

  Future<List<CourseGradeSummary>> courseSummaries({int semesterId = 1}) async {
    final db = await _database();
    final bs = await boundaries();
    final courseRows = await db.query('courses',
        where: 'semester_id = ?', whereArgs: [semesterId], orderBy: 'name');
    final all = await assessments(semesterId: semesterId);
    return courseRows.map((row) {
      final course = Course.fromMap(row);
      return CourseGradeSummary(
          course: course,
          assessments: all.where((a) => a.courseId == course.id).toList(),
          boundaries: bs);
    }).toList();
  }

  Future<List<SemesterAcademicSummary>> semesterSummaries() async {
    final rows =
        await (await _database()).query('semesters', orderBy: 'id DESC');
    return Future.wait(rows.map((row) async => SemesterAcademicSummary(
        id: (row['id'] as num).toInt(),
        name: row['name'] as String,
        courses:
            await courseSummaries(semesterId: (row['id'] as num).toInt()))));
  }

  Future<void> create(Assessment value, double credits) async =>
      (await _database()).insert('grades', value.toMap(creditHours: credits));
  Future<void> update(Assessment value, double credits) async =>
      (await _database()).update('grades', value.toMap(creditHours: credits),
          where: 'id = ?', whereArgs: [value.id]);
  Future<void> delete(String id) async =>
      (await _database()).delete('grades', where: 'id = ?', whereArgs: [id]);
  Future<void> setFinalGrade(String courseId, GradeBoundary? boundary) async =>
      (await _database()).update(
          'courses',
          {
            'final_grade_letter': boundary?.letter,
            'final_grade_point': boundary?.gradePoint
          },
          where: 'id = ?',
          whereArgs: [courseId]);
  Future<void> saveBoundary(GradeBoundary value, {bool editing = false}) async {
    final now = DateTime.now().toIso8601String();
    final map = {
      'id': value.id,
      'letter': value.letter.trim().toUpperCase(),
      'minimum_percentage': value.minimumPercentage,
      'grade_point': value.gradePoint,
      'created_at': now,
      'updated_at': now
    };
    editing
        ? await (await _database()).update('grading_boundaries', map,
            where: 'id = ?', whereArgs: [value.id])
        : await (await _database()).insert('grading_boundaries', map);
  }

  Future<void> deleteBoundary(String id) async => (await _database())
      .delete('grading_boundaries', where: 'id = ?', whereArgs: [id]);
  Future<void> resetScale() async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.delete('grading_boundaries');
      await AppDatabase.insertDefaultScale(
          txn, DateTime.now().toIso8601String());
    });
  }
}

final gradeRepositoryProvider =
    Provider<GradeRepository>((ref) => GradeRepository());
final gradingBoundariesProvider =
    FutureProvider.autoDispose<List<GradeBoundary>>(
        (ref) => ref.watch(gradeRepositoryProvider).boundaries());
final courseGradeSummariesProvider =
    FutureProvider.autoDispose<List<CourseGradeSummary>>(
        (ref) => ref.watch(gradeRepositoryProvider).courseSummaries());
final courseGradeSummaryProvider = FutureProvider.autoDispose
    .family<CourseGradeSummary?, String>((ref, id) async =>
        (await ref.watch(gradeRepositoryProvider).courseSummaries())
            .where((s) => s.course.id == id)
            .firstOrNull);
final academicHistoryProvider =
    FutureProvider.autoDispose<List<SemesterAcademicSummary>>(
        (ref) => ref.watch(gradeRepositoryProvider).semesterSummaries());
