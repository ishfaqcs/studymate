import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/app_database.dart';
import '../documents/document_repository.dart';
import '../notes/note_repository.dart';

class SearchItem {
  const SearchItem(this.kind, this.id, this.title, this.subtitle);
  final String kind, id, title, subtitle;
}

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});
  @override
  State<GlobalSearchScreen> createState() => _State();
}

class _State extends State<GlobalSearchScreen> {
  String query = '';
  Future<List<SearchItem>> search(String text) async {
    final q = '%${text.trim().toLowerCase()}%';
    if (text.trim().isEmpty) return [];
    final db = await AppDatabase.instance.database;
    final groups = await Future.wait([
      db.rawQuery(
          "SELECT id,name title,COALESCE(code,'') subtitle FROM courses WHERE LOWER(name) LIKE ? OR LOWER(COALESCE(code,'')) LIKE ? OR LOWER(COALESCE(instructor,'')) LIKE ?",
          [q, q, q]),
      db.rawQuery(
          "SELECT t.id,t.title,COALESCE(c.name,'General task') subtitle FROM tasks t LEFT JOIN courses c ON c.id=t.course_id WHERE LOWER(t.title) LIKE ? OR LOWER(COALESCE(t.description,'')) LIKE ? OR LOWER(COALESCE(c.name,'')) LIKE ?",
          [q, q, q]),
      db.rawQuery(
          "SELECT n.id,n.title,COALESCE(c.name,'General note') subtitle FROM notes n LEFT JOIN courses c ON c.id=n.course_id WHERE LOWER(n.title) LIKE ? OR LOWER(n.body) LIKE ? OR LOWER(COALESCE(c.name,'')) LIKE ?",
          [q, q, q]),
      db.rawQuery(
          "SELECT d.id,d.display_name title,COALESCE(c.name,UPPER(d.file_type)) subtitle FROM documents d LEFT JOIN courses c ON c.id=d.course_id WHERE LOWER(d.display_name) LIKE ? OR LOWER(d.original_file_name) LIKE ? OR LOWER(COALESCE(c.name,'')) LIKE ?",
          [q, q, q])
    ]);
    final kinds = ['Courses', 'Tasks', 'Notes', 'Documents'];
    final out = <SearchItem>[];
    for (var i = 0; i < groups.length; i++) {
      out.addAll(groups[i].map((m) => SearchItem(kinds[i], m['id'] as String,
          m['title'] as String, m['subtitle'] as String)));
    }
    return out;
  }

  Future<void> open(SearchItem i) async {
    if (i.kind == 'Courses') {
      context.push('/courses/${i.id}');
    } else if (i.kind == 'Notes') {
      final note = await NoteRepository().get(i.id);
      if (mounted && note != null) {
        context.push('/notes/${i.id}/edit', extra: note);
      }
    } else if (i.kind == 'Documents') {
      final document = await DocumentRepository().get(i.id);
      if (mounted && document != null) {
        context.push('/documents/${i.id}', extra: document);
      }
    } else {
      context.push('/tasks');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Search StudyMate')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
                hintText: 'Courses, tasks, notes, documents',
                leading: const Icon(Icons.search),
                onChanged: (v) => setState(() => query = v))),
        Expanded(
            child: FutureBuilder<List<SearchItem>>(
                future: search(query),
                builder: (c, s) {
                  if (s.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = s.data ?? [];
                  if (query.trim().isEmpty) {
                    return const Center(
                        child: Text('Search your StudyMate data.'));
                  }
                  if (items.isEmpty) {
                    return Center(
                        child: Text(
                            'No results for "$query"\n\nTry another keyword or check your spelling.',
                            textAlign: TextAlign.center));
                  }
                  String? last;
                  return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final header = last != item.kind;
                        last = item.kind;
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (header)
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 18, 16, 4),
                                    child: Text(item.kind.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.w700))),
                              ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  title: Text(item.title),
                                  subtitle: Text(item.subtitle),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => open(item))
                            ]);
                      });
                }))
      ]));
}
