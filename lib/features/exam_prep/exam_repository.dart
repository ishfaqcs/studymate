import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import 'exam_models.dart';

class ExamPreparationRepository {
  ExamPreparationRepository({Future<Database> Function()? database})
      : _database = database ?? (() => AppDatabase.instance.database);
  final Future<Database> Function() _database;
  Future<void> save(ExamPreparation v) async =>
      (await _database()).insert('exam_preparations', v.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<ExamPreparation>> list({String? courseId}) async =>
      (await (await _database()).query('exam_preparations',
              where: courseId == null ? null : 'course_id = ?',
              whereArgs: courseId == null ? null : [courseId],
              orderBy: 'exam_date'))
          .map(ExamPreparation.fromMap)
          .toList();
  Future<void> delete(String id) async => (await _database())
      .delete('exam_preparations', where: 'id = ?', whereArgs: [id]);
  Future<void> saveTopic(ExamTopic v) async =>
      (await _database()).insert('exam_topics', v.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<ExamTopic>> topics(String preparationId) async =>
      (await (await _database()).query('exam_topics',
              where: 'exam_preparation_id = ?',
              whereArgs: [preparationId],
              orderBy: 'position'))
          .map(ExamTopic.fromMap)
          .toList();
  Future<void> deleteTopic(String id) async => (await _database())
      .delete('exam_topics', where: 'id = ?', whereArgs: [id]);
}

final examPreparationRepositoryProvider =
    Provider((ref) => ExamPreparationRepository());
