import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';

class BackupInfo {
  const BackupInfo(this.createdAt, this.counts, this.data, this.files,
      {this.formatVersion = 1});
  final DateTime createdAt;
  final Map<String, int> counts;
  final Map<String, List<Map<String, Object?>>> data;
  final Map<String, Uint8List> files;
  final int formatVersion;
}

class BackupService {
  static const formatVersion = 2,
      maxInput = 100 * 1024 * 1024,
      maxExpanded = 500 * 1024 * 1024;
  static const tables = [
    'profile',
    'semesters',
    'courses',
    'schedules',
    'attendance',
    'tasks',
    'grades',
    'grading_boundaries',
    'notes',
    'documents',
    'study_sessions',
    'exam_preparations',
    'exam_topics',
    'study_plans',
    'study_plan_blocks'
  ];
  Future<Uint8List> create() async {
    final db = await AppDatabase.instance.database;
    final data = <String, List<Map<String, Object?>>>{};
    for (final t in tables) {
      data[t] =
          (await db.query(t)).map((e) => Map<String, Object?>.from(e)).toList();
    }
    final now = DateTime.now();
    final archive = Archive();
    final manifest = utf8.encode(jsonEncode({
      'backupFormatVersion': formatVersion,
      'appVersion': '1.0.0',
      'databaseVersion': 7,
      'createdAt': now.toIso8601String(),
      'counts': {for (final e in data.entries) e.key: e.value.length}
    }));
    archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest));
    final json = utf8.encode(jsonEncode(data));
    archive.addFile(ArchiveFile('database.json', json.length, json));
    for (final row in data['documents']!) {
      final file = File(row['file_path'] as String);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(
            'documents/${row['stored_file_name']}', bytes.length, bytes));
      }
    }
    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  BackupInfo inspect(Uint8List bytes) {
    if (bytes.length > maxInput) {
      throw const FormatException('Backup exceeds the 100 MB limit.');
    }
    final a = ZipDecoder().decodeBytes(bytes);
    var total = 0;
    final files = <String, Uint8List>{};
    for (final e in a) {
      final name = e.name.replaceAll('\\', '/');
      if (name.startsWith('/') || name.split('/').contains('..')) {
        throw const FormatException('Unsafe archive path.');
      }
      total += e.size;
      if (total > maxExpanded) {
        throw const FormatException('Expanded backup is too large.');
      }
      if (e.isFile) {
        final content = e.readBytes();
        if (content == null) {
          throw const FormatException('Unreadable archive entry.');
        }
        files[name] = Uint8List.fromList(content);
      }
    }
    if (!files.containsKey('manifest.json') ||
        !files.containsKey('database.json')) {
      throw const FormatException('Backup manifest or data is missing.');
    }
    final manifest = jsonDecode(utf8.decode(files['manifest.json']!))
        as Map<String, dynamic>;
    final backupVersion = manifest['backupFormatVersion'];
    if (backupVersion != 1 && backupVersion != formatVersion) {
      throw const FormatException('Unsupported backup version.');
    }
    final raw = jsonDecode(utf8.decode(files['database.json']!))
        as Map<String, dynamic>;
    final data = <String, List<Map<String, Object?>>>{};
    for (final t in tables) {
      final rows = raw[t];
      if (rows == null && backupVersion == 1 && _v2Tables.contains(t)) {
        data[t] = [];
        continue;
      }
      if (rows is! List) throw FormatException('Missing $t data.');
      data[t] = rows.map((e) => Map<String, Object?>.from(e as Map)).toList();
    }
    final courses = data['courses']!.map((e) => e['id']).toSet();
    for (final t in ['schedules', 'attendance', 'grades']) {
      for (final r in data[t]!) {
        if (!courses.contains(r['course_id'])) {
          throw FormatException('Invalid $t relationship.');
        }
      }
    }
    for (final r in data['documents']!) {
      final stored = r['stored_file_name'];
      if (stored is! String ||
          p.basename(stored) != stored ||
          !files.containsKey('documents/$stored')) {
        throw const FormatException('A managed document is missing or unsafe.');
      }
    }
    return BackupInfo(DateTime.parse(manifest['createdAt'] as String),
        {for (final e in data.entries) e.key: e.value.length}, data, files,
        formatVersion: backupVersion as int);
  }

  Future<void> restore(BackupInfo info) async {
    final base = Directory(p.dirname(await AppDatabase.instance.databasePath));
    final docs = Directory(p.join(base.path, 'documents'));
    final temp = Directory(
        p.join(base.path, 'restore-${DateTime.now().microsecondsSinceEpoch}'));
    final previous = Directory(p.join(base.path,
        'documents-before-restore-${DateTime.now().microsecondsSinceEpoch}'));
    await temp.create(recursive: true);
    var swapped = false;
    try {
      for (final r in info.data['documents']!) {
        final n = r['stored_file_name'] as String;
        await File(p.join(temp.path, n))
            .writeAsBytes(info.files['documents/$n']!);
      }
      if (await docs.exists()) await docs.rename(previous.path);
      await temp.rename(docs.path);
      swapped = true;
      final db = await AppDatabase.instance.database;
      await db.transaction((tx) async {
        for (final t in tables.reversed) {
          await tx.delete(t);
        }
        for (final t in tables) {
          for (final row in info.data[t]!) {
            final copy = Map<String, Object?>.from(row);
            if (t == 'documents') {
              copy['file_path'] =
                  p.join(docs.path, copy['stored_file_name'] as String);
            }
            await tx.insert(t, copy);
          }
        }
      });
    } catch (_) {
      if (await temp.exists()) await temp.delete(recursive: true);
      if (swapped && await docs.exists()) await docs.delete(recursive: true);
      if (await previous.exists()) await previous.rename(docs.path);
      rethrow;
    }
    // The database and new document set are committed at this point. Failure
    // to remove the rollback copy must not undo only the files.
    try {
      if (await previous.exists()) await previous.delete(recursive: true);
    } on FileSystemException {
      // A stale rollback directory is safer than a database/file mismatch.
    }
  }

  static const _v2Tables = {
    'study_sessions',
    'exam_preparations',
    'exam_topics',
    'study_plans',
    'study_plan_blocks'
  };
}
