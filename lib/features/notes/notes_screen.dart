import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'note.dart';
import 'note_repository.dart';
import '../courses/course_repository.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key, this.courseId});
  final String? courseId;
  @override
  ConsumerState<NotesScreen> createState() => _NotesState();
}

class _NotesState extends ConsumerState<NotesScreen> {
  String query = '', filter = 'all';
  @override
  Widget build(BuildContext context) {
    final value = ref.watch(notesProvider(widget.courseId));
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.courseId == null ? 'Notes' : 'Course notes')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                context.push('/notes/add?course=${widget.courseId ?? ''}'),
            icon: const Icon(Icons.add),
            label: const Text('Add note')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SearchBar(
                  hintText: 'Search notes',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => query = v))),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                  children: ['all', 'pinned', 'favorites']
                      .map((f) => Padding(
                          padding: const EdgeInsets.all(4),
                          child: FilterChip(
                              label: Text(
                                  '${f[0].toUpperCase()}${f.substring(1)}'),
                              selected: filter == f,
                              onSelected: (_) => setState(() => filter = f))))
                      .toList())),
          Expanded(
              child: value.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Center(child: Text('Notes could not be loaded.')),
                  data: (all) {
                    final q = query.trim().toLowerCase();
                    final notes = all
                        .where((n) =>
                            (filter != 'pinned' || n.isPinned) &&
                            (filter != 'favorites' || n.isFavorite) &&
                            (q.isEmpty ||
                                n.title.toLowerCase().contains(q) ||
                                n.content.toLowerCase().contains(q)))
                        .toList();
                    if (notes.isEmpty) {
                      return const Center(child: Text('No notes found.'));
                    }
                    return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) {
                          final n = notes[i],
                              preview = n.content
                                  .replaceAll(RegExp(r'\s+'), ' ')
                                  .trim();
                          return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              title: Text(n.title,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  preview.isEmpty
                                      ? 'Updated ${_relative(n.updatedAt)}'
                                      : 'Updated ${_relative(n.updatedAt)}\n$preview',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis),
                              isThreeLine: preview.isNotEmpty,
                              leading: Icon(
                                  n.isPinned
                                      ? Icons.push_pin
                                      : Icons.note_outlined,
                                  semanticLabel:
                                      n.isPinned ? 'Pinned note' : 'Note'),
                              trailing: n.isFavorite
                                  ? const Icon(Icons.star,
                                      semanticLabel: 'Favorite note')
                                  : null,
                              onTap: () => context.push('/notes/${n.id}/edit',
                                  extra: n));
                        });
                  }))
        ]));
  }

  String _relative(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inDays == 0) return 'today';
    if (d.inDays == 1) return 'yesterday';
    return '${d.inDays} days ago';
  }
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.note, this.initialCourseId});
  final StudyNote? note;
  final String? initialCourseId;
  @override
  ConsumerState<NoteEditorScreen> createState() => _EditorState();
}

class _EditorState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController title, content;
  late bool pinned, favorite;
  String? courseId;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.note?.title);
    content = TextEditingController(text: widget.note?.content);
    pinned = widget.note?.isPinned ?? false;
    favorite = widget.note?.isFavorite ?? false;
    courseId = widget.note?.courseId ??
        (widget.initialCourseId?.isEmpty == true
            ? null
            : widget.initialCourseId);
  }

  @override
  void dispose() {
    title.dispose();
    content.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a note title.')));
      return;
    }
    setState(() => saving = true);
    final now = DateTime.now();
    await ref.read(noteRepositoryProvider).save(StudyNote(
        id: widget.note?.id ?? now.microsecondsSinceEpoch.toString(),
        semesterId: widget.note?.semesterId ?? 1,
        courseId: courseId,
        title: title.text,
        content: content.text,
        isPinned: pinned,
        isFavorite: favorite,
        createdAt: widget.note?.createdAt ?? now,
        updatedAt: now));
    ref.invalidate(notesProvider);
    if (mounted) context.pop();
  }

  Future<void> remove() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Delete note?'),
                content: Text(
                    '"${widget.note!.title}" will be permanently removed.'),
                actions: [
                  TextButton(
                      onPressed: () => c.pop(false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => c.pop(true), child: const Text('Delete'))
                ]));
    if (ok == true) {
      await ref.read(noteRepositoryProvider).delete(widget.note!.id);
      ref.invalidate(notesProvider);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.note == null ? 'New note' : 'Edit note'),
          actions: [
            IconButton(
                tooltip: pinned ? 'Unpin note' : 'Pin note',
                onPressed: () => setState(() => pinned = !pinned),
                icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined)),
            IconButton(
                tooltip: favorite ? 'Remove favorite' : 'Add favorite',
                onPressed: () => setState(() => favorite = !favorite),
                icon: Icon(favorite ? Icons.star : Icons.star_border)),
            if (widget.note != null)
              IconButton(
                  tooltip: 'Delete note',
                  onPressed: remove,
                  icon: const Icon(Icons.delete_outline)),
            TextButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Saving…' : 'Save'))
          ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        ref.watch(coursesProvider).when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (courses) => DropdownButtonFormField<String?>(
                initialValue: courseId,
                decoration: const InputDecoration(
                    labelText: 'Course (optional)',
                    border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('General note')),
                  ...courses.map((course) => DropdownMenuItem<String?>(
                      value: course.id,
                      child:
                          Text(course.name, overflow: TextOverflow.ellipsis)))
                ],
                onChanged: (value) => setState(() => courseId = value))),
        const SizedBox(height: 16),
        TextField(
            controller: title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Title', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(
            controller: content,
            minLines: 14,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Content',
                alignLabelWithHint: true,
                border: OutlineInputBorder()))
      ]));
}
