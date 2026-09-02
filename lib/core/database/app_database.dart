import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import '../constants/app_constants.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<String> get databasePath async =>
      join(await getDatabasesPath(), AppConstants.dbName);

  Future<void> resetUserData() async {
    final db = await database;
    await db.transaction((txn) async {
      await resetTables(txn);
    });
    final documents = Directory(join(dirname(await databasePath), 'documents'));
    if (await documents.exists()) await documents.delete(recursive: true);
  }

  static Future<void> resetTables(DatabaseExecutor db) async {
    for (final table in [
      'study_plan_blocks',
      'study_plans',
      'exam_topics',
      'exam_preparations',
      'study_sessions',
      'documents',
      'notes',
      'grades',
      'tasks',
      'attendance',
      'schedules',
      'courses',
      'grading_boundaries',
      'semesters',
      'profile'
    ]) {
      await db.delete(table);
    }
    final now = DateTime.now().toIso8601String();
    await db.insert(
        'semesters', {'id': 1, 'name': 'Current semester', 'created_at': now});
    await insertDefaultScale(db, now);
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(path,
        version: AppConstants.dbVersion,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
              """CREATE TABLE profile(id INTEGER PRIMARY KEY, name TEXT NOT NULL, university TEXT, program TEXT, semester TEXT, start_date TEXT, end_date TEXT, attendance_requirement REAL NOT NULL DEFAULT 75, grading_scale TEXT NOT NULL DEFAULT '4.0')""");
          await db.execute(
              """CREATE TABLE courses(id TEXT PRIMARY KEY, semester_id INTEGER NOT NULL DEFAULT 1, name TEXT NOT NULL, code TEXT, instructor TEXT, room TEXT, credit_hours REAL NOT NULL DEFAULT 3, required_attendance REAL NOT NULL DEFAULT 75, color_value INTEGER NOT NULL DEFAULT 4281620437, final_grade_letter TEXT, final_grade_point REAL, created_at TEXT NOT NULL)""");
          await db.execute(
              """CREATE TABLE schedules(id TEXT PRIMARY KEY, course_id TEXT NOT NULL, weekday INTEGER NOT NULL, start_minutes INTEGER NOT NULL, end_minutes INTEGER NOT NULL, room TEXT, class_type TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE)""");
          await db.execute(
              """CREATE TABLE attendance(id TEXT PRIMARY KEY, course_id TEXT NOT NULL, schedule_id TEXT, date TEXT NOT NULL, status TEXT NOT NULL, note TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE, FOREIGN KEY(schedule_id) REFERENCES schedules(id) ON DELETE SET NULL)""");
          await db.execute(
              """CREATE TABLE tasks(id TEXT PRIMARY KEY, course_id TEXT, semester_id INTEGER NOT NULL DEFAULT 1, title TEXT NOT NULL, description TEXT, type TEXT NOT NULL, due_date TEXT NOT NULL, due_time TEXT, priority TEXT NOT NULL, status TEXT NOT NULL, reminder_at TEXT, completed_at TEXT, location TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE)""");
          await db.execute(
              """CREATE TABLE grades(id TEXT PRIMARY KEY, course_id TEXT NOT NULL, semester_id INTEGER NOT NULL DEFAULT 1, title TEXT NOT NULL, assessment_type TEXT NOT NULL DEFAULT 'other', marks_obtained REAL NOT NULL DEFAULT 0, total_marks REAL NOT NULL DEFAULT 100, weight REAL, date TEXT, note TEXT, credit_hours REAL NOT NULL DEFAULT 0, grade_letter TEXT, grade_point REAL NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE)""");
          await db.execute(
              """CREATE TABLE semesters(id INTEGER PRIMARY KEY, name TEXT NOT NULL, start_date TEXT, end_date TEXT, created_at TEXT NOT NULL)""");
          await db.execute(
              """CREATE TABLE grading_boundaries(id TEXT PRIMARY KEY, letter TEXT NOT NULL UNIQUE, minimum_percentage REAL NOT NULL UNIQUE, grade_point REAL NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)""");
          await db.execute(
              """CREATE TABLE notes(id TEXT PRIMARY KEY, course_id TEXT, title TEXT NOT NULL, body TEXT NOT NULL, pinned INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)""");
          await db.execute(
              'ALTER TABLE notes ADD COLUMN semester_id INTEGER NOT NULL DEFAULT 1');
          await db.execute(
              'ALTER TABLE notes ADD COLUMN favorite INTEGER NOT NULL DEFAULT 0');
          await db.execute(
              """CREATE TABLE documents(id TEXT PRIMARY KEY, semester_id INTEGER NOT NULL DEFAULT 1, course_id TEXT, display_name TEXT NOT NULL, original_file_name TEXT NOT NULL, stored_file_name TEXT NOT NULL UNIQUE, file_path TEXT NOT NULL, file_type TEXT NOT NULL, file_size INTEGER NOT NULL, description TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE)""");
          await db
              .execute('CREATE INDEX notes_search ON notes(title, updated_at)');
          await db.execute(
              'CREATE INDEX documents_search ON documents(display_name, file_type)');
          await createPerformanceIndexes(db);
          await createV2Tables(db);
          final now = DateTime.now().toIso8601String();
          await db.insert('semesters', {
            'id': 1,
            'name': 'Current semester',
            'created_at': now,
          });
          await insertDefaultScale(db, now);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
                'ALTER TABLE courses ADD COLUMN semester_id INTEGER NOT NULL DEFAULT 1');
            await db.execute('ALTER TABLE courses ADD COLUMN room TEXT');
            await db.execute(
                'ALTER TABLE courses ADD COLUMN color_value INTEGER NOT NULL DEFAULT 4281620437');
          }
          if (oldVersion < 3) {
            final now = DateTime.now().toIso8601String();
            await db
                .execute('ALTER TABLE schedules ADD COLUMN class_type TEXT');
            await db
                .execute('ALTER TABLE schedules ADD COLUMN created_at TEXT');
            await db
                .execute('ALTER TABLE schedules ADD COLUMN updated_at TEXT');
            await db
                .update('schedules', {'created_at': now, 'updated_at': now});
            await db
                .execute('ALTER TABLE attendance ADD COLUMN schedule_id TEXT');
            await db
                .execute('ALTER TABLE attendance ADD COLUMN created_at TEXT');
            await db
                .execute('ALTER TABLE attendance ADD COLUMN updated_at TEXT');
            await db
                .update('attendance', {'created_at': now, 'updated_at': now});
            await db.execute(
                'CREATE INDEX IF NOT EXISTS schedules_day_time ON schedules(weekday, start_minutes)');
            await db.execute(
                'CREATE INDEX IF NOT EXISTS attendance_course_date ON attendance(course_id, date)');
          }
          if (oldVersion < 4) {
            final now = DateTime.now().toIso8601String();
            await db.execute(
                'ALTER TABLE courses ADD COLUMN final_grade_letter TEXT');
            await db.execute(
                'ALTER TABLE courses ADD COLUMN final_grade_point REAL');
            await db.execute(
                'ALTER TABLE tasks ADD COLUMN semester_id INTEGER NOT NULL DEFAULT 1');
            await db.execute('ALTER TABLE tasks ADD COLUMN due_time TEXT');
            await db.execute('ALTER TABLE tasks ADD COLUMN completed_at TEXT');
            await db.execute('ALTER TABLE tasks ADD COLUMN location TEXT');
            await db.execute('ALTER TABLE tasks ADD COLUMN created_at TEXT');
            await db.execute('ALTER TABLE tasks ADD COLUMN updated_at TEXT');
            await db.update('tasks', {'created_at': now, 'updated_at': now});
            await db.update('tasks', {'due_date': now},
                where: 'due_date IS NULL');
            await db.execute(
                'ALTER TABLE grades ADD COLUMN semester_id INTEGER NOT NULL DEFAULT 1');
            await db.execute(
                "ALTER TABLE grades ADD COLUMN assessment_type TEXT NOT NULL DEFAULT 'other'");
            await db.execute(
                'ALTER TABLE grades ADD COLUMN marks_obtained REAL NOT NULL DEFAULT 0');
            await db.execute(
                'ALTER TABLE grades ADD COLUMN total_marks REAL NOT NULL DEFAULT 100');
            await db.execute('ALTER TABLE grades ADD COLUMN weight REAL');
            await db.execute('ALTER TABLE grades ADD COLUMN date TEXT');
            await db.execute('ALTER TABLE grades ADD COLUMN note TEXT');
            await db.execute('ALTER TABLE grades ADD COLUMN updated_at TEXT');
            await db.update('grades', {'updated_at': now});
            await db.execute(
                "CREATE TABLE semesters(id INTEGER PRIMARY KEY, name TEXT NOT NULL, start_date TEXT, end_date TEXT, created_at TEXT NOT NULL)");
            await db.execute(
                "CREATE TABLE grading_boundaries(id TEXT PRIMARY KEY, letter TEXT NOT NULL UNIQUE, minimum_percentage REAL NOT NULL UNIQUE, grade_point REAL NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)");
            final profile = await db.query('profile', limit: 1);
            await db.insert('semesters', {
              'id': 1,
              'name': profile.isEmpty
                  ? 'Current semester'
                  : ((profile.first['semester'] as String?)
                              ?.trim()
                              .isNotEmpty ??
                          false)
                      ? profile.first['semester']
                      : 'Current semester',
              'start_date':
                  profile.isEmpty ? null : profile.first['start_date'],
              'end_date': profile.isEmpty ? null : profile.first['end_date'],
              'created_at': now,
            });
            await insertDefaultScale(db, now);
            await db.execute(
                'CREATE INDEX IF NOT EXISTS tasks_semester_due ON tasks(semester_id, due_date)');
            await db.execute(
                'CREATE INDEX IF NOT EXISTS grades_semester_course ON grades(semester_id, course_id)');
          }
          if (oldVersion < 5) {
            await db.execute(
                'ALTER TABLE notes ADD COLUMN semester_id INTEGER NOT NULL DEFAULT 1');
            await db.execute(
                'ALTER TABLE notes ADD COLUMN favorite INTEGER NOT NULL DEFAULT 0');
            await db.execute(
                """CREATE TABLE documents(id TEXT PRIMARY KEY, semester_id INTEGER NOT NULL DEFAULT 1, course_id TEXT, display_name TEXT NOT NULL, original_file_name TEXT NOT NULL, stored_file_name TEXT NOT NULL UNIQUE, file_path TEXT NOT NULL, file_type TEXT NOT NULL, file_size INTEGER NOT NULL, description TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE)""");
            await db.execute(
                'CREATE INDEX IF NOT EXISTS notes_search ON notes(title, updated_at)');
            await db.execute(
                'CREATE INDEX IF NOT EXISTS documents_search ON documents(display_name, file_type)');
          }
          if (oldVersion < 6) {
            await createPerformanceIndexes(db);
          }
          if (oldVersion < 7) {
            await createV2Tables(db);
          }
        });
  }

  static Future<void> insertDefaultScale(
      DatabaseExecutor db, String now) async {
    const values = [
      ('A', 85.0, 4.0),
      ('A-', 80.0, 3.67),
      ('B+', 75.0, 3.33),
      ('B', 70.0, 3.0),
      ('B-', 65.0, 2.67),
      ('C+', 60.0, 2.33),
      ('C', 55.0, 2.0),
      ('C-', 50.0, 1.67),
      ('D', 40.0, 1.0),
      ('F', 0.0, 0.0),
    ];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      await db.insert('grading_boundaries', {
        'id': 'default-$i',
        'letter': value.$1,
        'minimum_percentage': value.$2,
        'grade_point': value.$3,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  static Future<void> createPerformanceIndexes(DatabaseExecutor db) async {
    for (final statement in [
      'CREATE INDEX IF NOT EXISTS courses_semester ON courses(semester_id, name)',
      'CREATE INDEX IF NOT EXISTS notes_course_updated ON notes(course_id, updated_at)',
      'CREATE INDEX IF NOT EXISTS notes_flags_updated ON notes(pinned, favorite, updated_at)',
      'CREATE INDEX IF NOT EXISTS documents_course_updated ON documents(course_id, updated_at)',
      'CREATE INDEX IF NOT EXISTS tasks_course_due ON tasks(course_id, due_date)',
    ]) {
      await db.execute(statement);
    }
  }

  /// Schema additions for V2 Phase 1. Existing tables and identifiers are not
  /// rewritten, so an upgrade from version 6 is strictly additive.
  static Future<void> createV2Tables(DatabaseExecutor db) async {
    for (final statement in [
      '''CREATE TABLE IF NOT EXISTS study_sessions(id TEXT PRIMARY KEY, semester_id INTEGER, course_id TEXT, task_id TEXT, title TEXT, session_type TEXT NOT NULL, planned_duration_minutes INTEGER NOT NULL, actual_duration_minutes INTEGER NOT NULL DEFAULT 0, started_at TEXT NOT NULL, completed_at TEXT, status TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(semester_id) REFERENCES semesters(id) ON DELETE SET NULL, FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE SET NULL, FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE SET NULL)''',
      '''CREATE TABLE IF NOT EXISTS exam_preparations(id TEXT PRIMARY KEY, course_id TEXT NOT NULL, task_id TEXT, exam_title TEXT NOT NULL, exam_date TEXT NOT NULL, target_grade REAL, confidence_level INTEGER, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE, FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE SET NULL)''',
      '''CREATE TABLE IF NOT EXISTS exam_topics(id TEXT PRIMARY KEY, exam_preparation_id TEXT NOT NULL, title TEXT NOT NULL, status TEXT NOT NULL, priority TEXT NOT NULL, estimated_minutes INTEGER, notes TEXT, position INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(exam_preparation_id) REFERENCES exam_preparations(id) ON DELETE CASCADE)''',
      '''CREATE TABLE IF NOT EXISTS study_plans(id TEXT PRIMARY KEY, semester_id INTEGER NOT NULL, title TEXT NOT NULL, start_date TEXT NOT NULL, end_date TEXT NOT NULL, status TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(semester_id) REFERENCES semesters(id) ON DELETE CASCADE)''',
      '''CREATE TABLE IF NOT EXISTS study_plan_blocks(id TEXT PRIMARY KEY, study_plan_id TEXT NOT NULL, course_id TEXT, task_id TEXT, exam_preparation_id TEXT, title TEXT NOT NULL, date TEXT NOT NULL, start_time TEXT, planned_minutes INTEGER NOT NULL, priority TEXT NOT NULL, status TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(study_plan_id) REFERENCES study_plans(id) ON DELETE CASCADE, FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE SET NULL, FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE SET NULL, FOREIGN KEY(exam_preparation_id) REFERENCES exam_preparations(id) ON DELETE SET NULL)''',
      'CREATE INDEX IF NOT EXISTS study_sessions_started ON study_sessions(started_at)',
      'CREATE INDEX IF NOT EXISTS study_sessions_course ON study_sessions(course_id, started_at)',
      'CREATE INDEX IF NOT EXISTS exam_topics_preparation ON exam_topics(exam_preparation_id, position)',
      'CREATE INDEX IF NOT EXISTS study_plan_blocks_date ON study_plan_blocks(date)',
      'CREATE INDEX IF NOT EXISTS study_plan_blocks_course ON study_plan_blocks(course_id, date)',
    ]) {
      await db.execute(statement);
    }
  }
}
