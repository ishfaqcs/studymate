import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/core/services/backup_service.dart';
import 'package:studentplanner/core/utils/file_size_formatter.dart';
import 'package:studentplanner/features/documents/document_repository.dart';
import 'package:studentplanner/features/notes/note.dart';
import 'package:studentplanner/core/constants/app_constants.dart';

void main() {
  test('database schema advances additively to version 6', () {
    expect(AppConstants.dbVersion, 6);
  });
  test('note persists course, pin, favorite and trimmed content', () {
    final note = StudyNote(
        id: 'n1',
        semesterId: 1,
        courseId: 'c1',
        title: '  Revision  ',
        content: '  Backpropagation  ',
        isPinned: true,
        isFavorite: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 8, 20));
    final restored = StudyNote.fromMap(note.toMap());
    expect(restored.title, 'Revision');
    expect(restored.content, 'Backpropagation');
    expect(restored.courseId, 'c1');
    expect(restored.isPinned, isTrue);
    expect(restored.isFavorite, isTrue);
  });
  test('general note supports no course', () {
    final now = DateTime(2026);
    final n = StudyNote(
        id: 'n',
        semesterId: 1,
        title: 'General',
        content: '',
        isPinned: false,
        isFavorite: false,
        createdAt: now,
        updatedAt: now);
    expect(n.toMap()['course_id'], isNull);
  });
  test('document repository rejects unsupported files before persistence',
      () async {
    final directory = await Directory.systemTemp.createTemp('studymate-doc-');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final source = File('${directory.path}${Platform.pathSeparator}script.exe');
    await source.writeAsBytes(const [1, 2, 3]);

    await expectLater(
      DocumentRepository(root: () async => directory)
          .importFile(source, displayName: 'Unsupported'),
      throwsUnsupportedError,
    );
  });
  test('file size formatter uses readable units', () {
    expect(formatFileSize(850 * 1024), '850 KB');
    expect(formatFileSize(1468006), '1.4 MB');
  });
  test('document types are normalized and unsupported files are other', () {
    expect(DocumentRepository.typeFor('Lecture.PDF'), 'pdf');
    expect(DocumentRepository.typeFor('script.exe'), 'other');
  });
  group('backup validation', () {
    test('accepts a valid versioned structured backup and reports counts', () {
      final info = BackupService().inspect(_backup());
      expect(info.counts['courses'], 1);
      expect(info.createdAt, DateTime.utc(2026, 8, 20));
    });
    test('rejects missing manifest', () {
      expect(() => BackupService().inspect(_backup(manifest: false)),
          throwsFormatException);
    });
    test('rejects unsupported version', () {
      expect(() => BackupService().inspect(_backup(version: 99)),
          throwsFormatException);
    });
    test('rejects invalid relationships', () {
      expect(() => BackupService().inspect(_backup(invalidRelationship: true)),
          throwsFormatException);
    });
    test('rejects path traversal entries', () {
      expect(() => BackupService().inspect(_backup(traversal: true)),
          throwsFormatException);
    });
  });
}

Uint8List _backup(
    {bool manifest = true,
    int version = 1,
    bool invalidRelationship = false,
    bool traversal = false}) {
  final data = {
    for (final t in BackupService.tables) t: <Map<String, Object?>>[]
  };
  data['courses']!.add({'id': 'c1'});
  if (invalidRelationship) {
    data['grades']!.add({'id': 'g', 'course_id': 'missing'});
  }
  final archive = Archive();
  if (manifest) {
    final b = utf8.encode(jsonEncode({
      'backupFormatVersion': version,
      'createdAt': '2026-08-20T00:00:00.000Z'
    }));
    archive.addFile(ArchiveFile('manifest.json', b.length, b));
  }
  final db = utf8.encode(jsonEncode(data));
  archive.addFile(ArchiveFile('database.json', db.length, db));
  if (traversal) archive.addFile(ArchiveFile('../bad.txt', 1, [1]));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
