import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import 'study_plan_models.dart';

class StudyPlanRepository {
  StudyPlanRepository({Future<Database> Function()? database})
      : _database = database ?? (() => AppDatabase.instance.database);
  final Future<Database> Function() _database;
  Future<void> save(StudyPlan v) async =>
      (await _database()).insert('study_plans', v.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<StudyPlan>> list({int? semesterId}) async =>
      (await (await _database()).query('study_plans',
              where: semesterId == null ? null : 'semester_id = ?',
              whereArgs: semesterId == null ? null : [semesterId],
              orderBy: 'start_date DESC'))
          .map(StudyPlan.fromMap)
          .toList();
  Future<void> delete(String id) async => (await _database())
      .delete('study_plans', where: 'id = ?', whereArgs: [id]);
  Future<void> saveBlock(StudyPlanBlock v) async =>
      (await _database()).insert('study_plan_blocks', v.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<StudyPlanBlock>> blocks(String planId) async =>
      (await (await _database()).query('study_plan_blocks',
              where: 'study_plan_id = ?',
              whereArgs: [planId],
              orderBy: 'date, start_time'))
          .map(StudyPlanBlock.fromMap)
          .toList();
  Future<void> deleteBlock(String id) async => (await _database())
      .delete('study_plan_blocks', where: 'id = ?', whereArgs: [id]);
}

final studyPlanRepositoryProvider = Provider((ref) => StudyPlanRepository());
