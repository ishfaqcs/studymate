import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'grade_models.dart';
import 'grade_repository.dart';

class GradingScaleScreen extends ConsumerWidget {
  const GradingScaleScreen({super.key});
  Future<void> _edit(BuildContext context, WidgetRef ref,
      [GradeBoundary? old]) async {
    final letter = TextEditingController(text: old?.letter),
        minimum =
            TextEditingController(text: old?.minimumPercentage.toString()),
        points = TextEditingController(text: old?.gradePoint.toString());
    final key = GlobalKey<FormState>();
    final save = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(
                    old == null ? 'Add grade boundary' : 'Edit grade boundary'),
                content: Form(
                    key: key,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextFormField(
                          controller: letter,
                          decoration:
                              const InputDecoration(labelText: 'Grade letter'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: minimum,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Minimum percentage'),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            return n == null || n < 0 || n > 100
                                ? 'Enter 0–100'
                                : null;
                          }),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: points,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Grade points'),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            return n == null || n < 0 || n > 10
                                ? 'Enter valid points'
                                : null;
                          })
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => c.pop(false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (key.currentState?.validate() ?? false) c.pop(true);
                      },
                      child: const Text('Save'))
                ]));
    if (save == true) {
      try {
        await ref.read(gradeRepositoryProvider).saveBoundary(
            GradeBoundary(
                id: old?.id ?? const Uuid().v4(),
                letter: letter.text,
                minimumPercentage: double.parse(minimum.text),
                gradePoint: double.parse(points.text)),
            editing: old != null);
        ref.invalidate(gradingBoundariesProvider);
        ref.invalidate(courseGradeSummariesProvider);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Grade letters and boundaries must be unique.')));
        }
      }
    }
    letter.dispose();
    minimum.dispose();
    points.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(gradingBoundariesProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Grading scale'), actions: [
          PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'reset') {
                  await ref.read(gradeRepositoryProvider).resetScale();
                  ref.invalidate(gradingBoundariesProvider);
                  ref.invalidate(courseGradeSummariesProvider);
                }
              },
              itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'reset', child: Text('Reset to default'))
                  ])
        ]),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add boundary')),
        body: value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Grading scale could not be loaded.')),
            data: (items) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final b = items[i];
                  return ListTile(
                      title: Text(b.letter,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(
                          'Minimum ${b.minimumPercentage.toStringAsFixed(1)}%'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(b.gradePoint.toStringAsFixed(2)),
                        IconButton(
                            tooltip: 'Edit ${b.letter}',
                            onPressed: () => _edit(context, ref, b),
                            icon: const Icon(Icons.edit_outlined)),
                        IconButton(
                            tooltip: 'Delete ${b.letter}',
                            onPressed: () async {
                              await ref
                                  .read(gradeRepositoryProvider)
                                  .deleteBoundary(b.id);
                              ref.invalidate(gradingBoundariesProvider);
                              ref.invalidate(courseGradeSummariesProvider);
                            },
                            icon: const Icon(Icons.delete_outline))
                      ]));
                })));
  }
}
