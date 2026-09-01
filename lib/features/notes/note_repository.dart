import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import 'note.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? database})
      : _database = database ?? (() => AppDatabase.instance.database);
  final Future<Database> Function() _database;
  Future<List<StudyNote>> list(
      {String? courseId,
      String? query,
      bool pinned = false,
      bool favorite = false}) async {
    final clauses = <String>[], args = <Object?>[];
    if (courseId != null) {
      clauses.add('course_id = ?');
      args.add(courseId);
    }
    if (pinned) {
      clauses.add('pinned = 1');
    }
    if (favorite) {
      clauses.add('favorite = 1');
    }
    final q = query?.trim().toLowerCase();
    if (q?.isNotEmpty == true) {
      clauses.add('(LOWER(title) LIKE ? OR LOWER(body) LIKE ?)');
      args.addAll(['%$q%', '%$q%']);
    }
    final rows = await (await _database()).query('notes',
        where: clauses.isEmpty ? null : clauses.join(' AND '),
        whereArgs: args,
        orderBy: 'pinned DESC, updated_at DESC');
    return rows.map(StudyNote.fromMap).toList();
  }

  Future<StudyNote?> get(String id) async {
    final r = await (await _database())
        .query('notes', where: 'id=?', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : StudyNote.fromMap(r.first);
  }

  Future<void> save(StudyNote n) async => (await _database())
      .insert('notes', n.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> delete(String id) async =>
      (await _database()).delete('notes', where: 'id=?', whereArgs: [id]);
}

final noteRepositoryProvider = Provider((ref) => NoteRepository());
final notesProvider = FutureProvider.autoDispose
    .family<List<StudyNote>, String?>((ref, courseId) =>
        ref.watch(noteRepositoryProvider).list(courseId: courseId));
