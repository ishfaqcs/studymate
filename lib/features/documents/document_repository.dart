import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import 'document_record.dart';

class DocumentRepository {
  DocumentRepository(
      {Future<Database> Function()? database,
      Future<Directory> Function()? root})
      : _database = database ?? (() => AppDatabase.instance.database),
        _root = root ?? _defaultRoot;
  final Future<Database> Function() _database;
  final Future<Directory> Function() _root;
  static Future<Directory> _defaultRoot() async {
    final databasePath = await AppDatabase.instance.databasePath;
    return Directory(p.join(p.dirname(databasePath), 'documents'))
      ..createSync(recursive: true);
  }

  static const allowed = {
    'pdf',
    'txt',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'jpg',
    'jpeg',
    'png',
    'webp'
  };
  static String typeFor(String name) {
    final e = p.extension(name).replaceFirst('.', '').toLowerCase();
    return allowed.contains(e) ? e : 'other';
  }

  Future<DocumentRecord> importFile(File source,
      {required String displayName,
      String? courseId,
      int semesterId = 1}) async {
    if (!await source.exists()) {
      throw const FileSystemException('Selected file no longer exists.');
    }
    final fileType = typeFor(source.path);
    if (fileType == 'other') {
      throw UnsupportedError('This file type is not supported.');
    }
    final size = await source.length();
    if (size > 100 * 1024 * 1024) {
      throw const FileSystemException(
          'Files larger than 100 MB are not supported.');
    }
    final id = const Uuid().v4(), ext = p.extension(source.path).toLowerCase();
    final stored = '$id${ext.length <= 10 ? ext : ''}';
    final target = File(p.join((await _root()).path, stored));
    await source.copy(target.path);
    final now = DateTime.now();
    final record = DocumentRecord(
        id: id,
        semesterId: semesterId,
        courseId: courseId,
        displayName: displayName.trim(),
        originalFileName: p.basename(source.path),
        storedFileName: stored,
        filePath: target.path,
        fileType: fileType,
        fileSize: size,
        createdAt: now,
        updatedAt: now);
    try {
      await (await _database()).insert('documents', record.toMap());
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    }
    return record;
  }

  Future<List<DocumentRecord>> list(
      {String? courseId, String? query, String? type}) async {
    final c = <String>[], a = <Object?>[];
    if (courseId != null) {
      c.add('course_id=?');
      a.add(courseId);
    }
    if (type != null) {
      c.add('file_type=?');
      a.add(type);
    }
    if (query?.trim().isNotEmpty == true) {
      c.add('(LOWER(display_name) LIKE ? OR LOWER(original_file_name) LIKE ?)');
      final q = '%${query!.trim().toLowerCase()}%';
      a.addAll([q, q]);
    }
    final r = await (await _database()).query('documents',
        where: c.isEmpty ? null : c.join(' AND '),
        whereArgs: a,
        orderBy: 'updated_at DESC');
    return r.map(DocumentRecord.fromMap).toList();
  }

  Future<DocumentRecord?> get(String id) async {
    final r = await (await _database())
        .query('documents', where: 'id=?', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : DocumentRecord.fromMap(r.first);
  }

  Future<void> delete(DocumentRecord d) async {
    final file = File(d.filePath);
    if (await file.exists()) await file.delete();
    await (await _database())
        .delete('documents', where: 'id=?', whereArgs: [d.id]);
  }
}

final documentRepositoryProvider = Provider((ref) => DocumentRepository());
final documentsProvider = FutureProvider.autoDispose
    .family<List<DocumentRecord>, String?>((ref, course) =>
        ref.watch(documentRepositoryProvider).list(courseId: course));
