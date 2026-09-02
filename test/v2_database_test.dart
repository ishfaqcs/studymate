import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studentplanner/core/database/app_database.dart';
import 'package:studentplanner/features/exam_prep/exam_models.dart';
import 'package:studentplanner/features/exam_prep/exam_repository.dart';
import 'package:studentplanner/features/study_plans/study_plan_models.dart';
import 'package:studentplanner/features/study_plans/study_plan_repository.dart';
import 'package:studentplanner/features/study_sessions/study_session.dart';
import 'package:studentplanner/features/study_sessions/study_session_repository.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  final now = DateTime.utc(2026, 9, 2, 10);
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON')));
    await db.execute(
        "CREATE TABLE profile(id INTEGER PRIMARY KEY, name TEXT NOT NULL)");
    await db.execute(
        "CREATE TABLE semesters(id INTEGER PRIMARY KEY, name TEXT NOT NULL, start_date TEXT, end_date TEXT, created_at TEXT NOT NULL)");
    await db.execute(
        "CREATE TABLE courses(id TEXT PRIMARY KEY, semester_id INTEGER NOT NULL, name TEXT NOT NULL)");
    await db.execute("CREATE TABLE tasks(id TEXT PRIMARY KEY, course_id TEXT)");
    await db.execute(
        "CREATE TABLE schedules(id TEXT PRIMARY KEY, course_id TEXT NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id))");
    await db.execute(
        "CREATE TABLE attendance(id TEXT PRIMARY KEY, course_id TEXT NOT NULL, schedule_id TEXT, FOREIGN KEY(course_id) REFERENCES courses(id), FOREIGN KEY(schedule_id) REFERENCES schedules(id))");
    await db.execute(
        "CREATE TABLE grades(id TEXT PRIMARY KEY, course_id TEXT NOT NULL, semester_id INTEGER NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id))");
    await db.execute(
        "CREATE TABLE grading_boundaries(id TEXT PRIMARY KEY, letter TEXT NOT NULL UNIQUE, minimum_percentage REAL NOT NULL UNIQUE, grade_point REAL NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)");
    await db.execute(
        "CREATE TABLE notes(id TEXT PRIMARY KEY, course_id TEXT, semester_id INTEGER NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id))");
    await db.execute(
        "CREATE TABLE documents(id TEXT PRIMARY KEY, course_id TEXT, semester_id INTEGER NOT NULL, stored_file_name TEXT NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id))");
    await db.insert('profile', {'id': 1, 'name': 'Student'});
    await db.insert('semesters',
        {'id': 1, 'name': 'Fall', 'created_at': now.toIso8601String()});
    await db.insert('semesters',
        {'id': 2, 'name': 'Spring', 'created_at': now.toIso8601String()});
    for (var i = 1; i <= 4; i++) {
      await db.insert('courses',
          {'id': 'c$i', 'semester_id': i < 3 ? 1 : 2, 'name': 'Course $i'});
    }
    await db.insert('tasks', {'id': 't1', 'course_id': 'c1'});
    await db.insert('schedules', {'id': 'sc1', 'course_id': 'c1'});
    await db.insert(
        'attendance', {'id': 'a1', 'course_id': 'c1', 'schedule_id': 'sc1'});
    await db
        .insert('grades', {'id': 'g1', 'course_id': 'c1', 'semester_id': 1});
    await db.insert('grading_boundaries', {
      'id': 'gb1',
      'letter': 'A',
      'minimum_percentage': 85,
      'grade_point': 4,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String()
    });
    await db.insert('notes', {'id': 'n1', 'course_id': 'c1', 'semester_id': 1});
    await db.insert('documents', {
      'id': 'd1',
      'course_id': 'c1',
      'semester_id': 1,
      'stored_file_name': 'lecture.pdf'
    });
    await AppDatabase.createV2Tables(db);
  });
  tearDown(() => db.close());

  test('v6 to v7 migration is additive and idempotent', () async {
    await AppDatabase.createV2Tables(db);
    expect((await db.query('profile')).single['name'], 'Student');
    expect(await db.query('semesters'), hasLength(2));
    expect(await db.query('courses'), hasLength(4));
    expect(
        (await db.query('courses', where: 'id = ?', whereArgs: ['c1']))
            .single['semester_id'],
        1);
    for (final table in [
      'schedules',
      'attendance',
      'tasks',
      'grades',
      'grading_boundaries',
      'notes',
      'documents'
    ]) {
      expect(await db.query(table), hasLength(1),
          reason: '$table must survive migration');
    }
    expect((await db.rawQuery('PRAGMA foreign_key_check')), isEmpty);
    for (final table in [
      'study_sessions',
      'exam_preparations',
      'exam_topics',
      'study_plans',
      'study_plan_blocks'
    ]) {
      expect(await db.query(table), isEmpty);
    }
  });

  test('study session CRUD and totals', () async {
    final repo = StudySessionRepository(database: () async => db);
    final value = StudySession(
        id: 's1',
        semesterId: 1,
        courseId: 'c1',
        taskId: 't1',
        sessionType: StudySessionType.focus,
        plannedDurationMinutes: 25,
        actualDurationMinutes: 0,
        startedAt: now,
        status: StudySessionStatus.planned,
        createdAt: now,
        updatedAt: now);
    await repo.create(value);
    expect((await repo.byDate(now)).single.id, 's1');
    await repo.complete('s1',
        actualMinutes: 24, at: now.add(const Duration(minutes: 24)));
    expect(
        await repo.totalMinutes(now.subtract(const Duration(hours: 1)),
            now.add(const Duration(days: 1))),
        24);
    await repo.cancel('s1');
    await repo.delete('s1');
    expect(await repo.get('s1'), isNull);
  });

  test('exam preparations/topics and study plans/blocks persist', () async {
    final exams = ExamPreparationRepository(database: () => Future.value(db));
    await exams.save(ExamPreparation(
        id: 'e1',
        courseId: 'c1',
        taskId: 't1',
        examTitle: 'Final',
        examDate: now,
        createdAt: now,
        updatedAt: now));
    await exams.saveTopic(ExamTopic(
        id: 'et1',
        examPreparationId: 'e1',
        title: 'Algebra',
        status: ExamTopicStatus.notStarted,
        priority: ExamTopicPriority.high,
        position: 0,
        createdAt: now,
        updatedAt: now));
    expect((await exams.topics('e1')).single.title, 'Algebra');
    final plans = StudyPlanRepository(database: () => Future.value(db));
    await plans.save(StudyPlan(
        id: 'p1',
        semesterId: 1,
        title: 'Final plan',
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
        status: StudyPlanStatus.planned,
        createdAt: now,
        updatedAt: now));
    await plans.saveBlock(StudyPlanBlock(
        id: 'b1',
        studyPlanId: 'p1',
        courseId: 'c1',
        taskId: 't1',
        examPreparationId: 'e1',
        title: 'Revise',
        date: now,
        plannedMinutes: 60,
        priority: StudyPlanPriority.high,
        status: StudyPlanBlockStatus.planned,
        createdAt: now,
        updatedAt: now));
    expect((await plans.blocks('p1')).single.title, 'Revise');
    await plans.delete('p1');
    expect(await plans.blocks('p1'), isEmpty);
    await exams.delete('e1');
    expect(await exams.topics('e1'), isEmpty);
  });

  test('full reset removes every V2 record', () async {
    final sessions = StudySessionRepository(database: () async => db);
    await sessions.create(StudySession(
        id: 's-reset',
        semesterId: 1,
        courseId: 'c1',
        sessionType: StudySessionType.focus,
        plannedDurationMinutes: 10,
        actualDurationMinutes: 0,
        startedAt: now,
        status: StudySessionStatus.planned,
        createdAt: now,
        updatedAt: now));
    final exams = ExamPreparationRepository(database: () async => db);
    await exams.save(ExamPreparation(
        id: 'e-reset',
        courseId: 'c1',
        examTitle: 'Exam',
        examDate: now,
        createdAt: now,
        updatedAt: now));
    await exams.saveTopic(ExamTopic(
        id: 'et-reset',
        examPreparationId: 'e-reset',
        title: 'Topic',
        status: ExamTopicStatus.notStarted,
        priority: ExamTopicPriority.medium,
        position: 0,
        createdAt: now,
        updatedAt: now));
    final plans = StudyPlanRepository(database: () async => db);
    await plans.save(StudyPlan(
        id: 'p-reset',
        semesterId: 1,
        title: 'Plan',
        startDate: now,
        endDate: now,
        status: StudyPlanStatus.planned,
        createdAt: now,
        updatedAt: now));
    await plans.saveBlock(StudyPlanBlock(
        id: 'b-reset',
        studyPlanId: 'p-reset',
        title: 'Block',
        date: now,
        plannedMinutes: 10,
        priority: StudyPlanPriority.medium,
        status: StudyPlanBlockStatus.planned,
        createdAt: now,
        updatedAt: now));
    await db.transaction(AppDatabase.resetTables);
    for (final table in [
      'study_sessions',
      'exam_preparations',
      'exam_topics',
      'study_plans',
      'study_plan_blocks'
    ]) {
      expect(await db.query(table), isEmpty);
    }
  });
}
