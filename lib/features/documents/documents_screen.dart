import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import '../../core/utils/file_size_formatter.dart';
import 'document_record.dart';
import 'document_repository.dart';
import '../courses/course_repository.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key, this.courseId});
  final String? courseId;
  @override
  ConsumerState<DocumentsScreen> createState() => _DocsState();
}

class _DocsState extends ConsumerState<DocumentsScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final value = ref.watch(documentsProvider(widget.courseId));
    return Scaffold(
        appBar: AppBar(
            title: Text(
                widget.courseId == null ? 'Documents' : 'Course documents')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                context.push('/documents/add?course=${widget.courseId ?? ''}'),
            icon: const Icon(Icons.upload_file),
            label: const Text('Add document')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: SearchBar(
                  hintText: 'Search documents',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => query = v))),
          Expanded(
              child: value.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                      child: Text('Documents could not be loaded.')),
                  data: (all) {
                    final q = query.toLowerCase();
                    final docs = all
                        .where((d) =>
                            d.displayName.toLowerCase().contains(q) ||
                            d.originalFileName.toLowerCase().contains(q))
                        .toList();
                    if (docs.isEmpty) {
                      return const Center(child: Text('No documents found.'));
                    }
                    return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) {
                          final d = docs[i];
                          return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(d.fileType == 'pdf'
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.insert_drive_file_outlined),
                              title: Text(d.displayName,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  '${d.fileType.toUpperCase()} • ${formatFileSize(d.fileSize)}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  context.push('/documents/${d.id}', extra: d));
                        });
                  }))
        ]));
  }
}

class DocumentImportScreen extends ConsumerStatefulWidget {
  const DocumentImportScreen({super.key, this.courseId});
  final String? courseId;
  @override
  ConsumerState<DocumentImportScreen> createState() => _ImportState();
}

class _ImportState extends ConsumerState<DocumentImportScreen> {
  bool busy = false;
  String? courseId;
  @override
  void initState() {
    super.initState();
    courseId = widget.courseId?.isEmpty == true ? null : widget.courseId;
  }

  Future<void> pick() async {
    final selected = await openFile(acceptedTypeGroups: <XTypeGroup>[
      XTypeGroup(
          label: 'Documents', extensions: DocumentRepository.allowed.toList())
    ]);
    if (selected == null) return;
    final selectedPath = selected.path;
    if (selectedPath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('The selected file could not be accessed.')));
      }
      return;
    }
    final controller = TextEditingController(
        text: selected.name.replaceFirst(RegExp(r'\.[^.]+$'), ''));
    if (!mounted) return;
    final display = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Import document'),
                content: TextField(
                    controller: controller,
                    decoration:
                        const InputDecoration(labelText: 'Display name')),
                actions: [
                  TextButton(
                      onPressed: () => c.pop(), child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => c.pop(controller.text.trim()),
                      child: const Text('Import'))
                ]));
    controller.dispose();
    if (display?.isEmpty != false) return;
    setState(() => busy = true);
    try {
      await ref.read(documentRepositoryProvider).importFile(File(selectedPath),
          displayName: display!, courseId: courseId);
      ref.invalidate(documentsProvider);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Couldn’t import this document. Check that the file is available and try again.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Add document')),
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
                      value: null, child: Text('General document')),
                  ...courses.map((course) => DropdownMenuItem<String?>(
                      value: course.id,
                      child:
                          Text(course.name, overflow: TextOverflow.ellipsis)))
                ],
                onChanged:
                    busy ? null : (value) => setState(() => courseId = value))),
        const SizedBox(height: 24),
        if (busy)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton.icon(
              onPressed: pick,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose file'))
      ]));
}

class DocumentDetailsScreen extends ConsumerWidget {
  const DocumentDetailsScreen({super.key, required this.document});
  final DocumentRecord document;
  Future<void> open(BuildContext context) async {
    if (!await File(document.filePath).exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This file no longer exists.')));
      }
      return;
    }
    if (document.fileType == 'pdf') {
      if (context.mounted) context.push('/documents/pdf', extra: document);
    } else {
      await OpenFilex.open(document.filePath);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: const Text('Document details'), actions: [
        IconButton(
            tooltip: 'Delete document',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                          title: const Text('Delete document?'),
                          content: Text(
                              '"${document.displayName}" and its local copy will be removed.'),
                          actions: [
                            TextButton(
                                onPressed: () => c.pop(false),
                                child: const Text('Cancel')),
                            FilledButton(
                                onPressed: () => c.pop(true),
                                child: const Text('Delete'))
                          ]));
              if (ok == true) {
                await ref.read(documentRepositoryProvider).delete(document);
                ref.invalidate(documentsProvider);
                if (context.mounted) context.pop();
              }
            })
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Icon(
            document.fileType == 'pdf'
                ? Icons.picture_as_pdf
                : Icons.insert_drive_file,
            size: 64),
        const SizedBox(height: 16),
        Text(document.displayName,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
            'Original file: ${document.originalFileName}\nType: ${document.fileType.toUpperCase()}\nSize: ${formatFileSize(document.fileSize)}'),
        const SizedBox(height: 24),
        FilledButton.icon(
            onPressed: () => open(context),
            icon: const Icon(Icons.open_in_new),
            label: Text(
                document.fileType == 'pdf' ? 'View PDF' : 'Open externally'))
      ]));
}

class PdfViewerScreen extends StatelessWidget {
  const PdfViewerScreen({super.key, required this.document});
  final DocumentRecord document;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(document.displayName)),
      body: PdfPreview(
          build: (_) => File(document.filePath).readAsBytes(),
          canChangeOrientation: false,
          canChangePageFormat: false));
}
