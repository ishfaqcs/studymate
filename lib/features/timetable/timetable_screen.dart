import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/empty_state.dart';
import 'class_schedule.dart';
import 'schedule_repository.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});
  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  int day = DateTime.now().weekday;
  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(schedulesProvider);
    final monday =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/schedule/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
              '${DateFormat('d MMM').format(monday)} – ${DateFormat('d MMM').format(monday.add(const Duration(days: 6)))}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: List.generate(
                    7,
                    (index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              label: Text(days[index]),
                              selected: day == index + 1,
                              onSelected: (_) =>
                                  setState(() => day = index + 1)),
                        ))),
          ),
          const SizedBox(height: 20),
          schedules.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator())),
            error: (_, __) =>
                const Center(child: Text('Schedule could not be loaded.')),
            data: (all) {
              final entries =
                  all.where((entry) => entry.schedule.weekday == day).toList();
              if (entries.isEmpty) {
                return EmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: 'No classes scheduled',
                  message:
                      'Add a class schedule to start building your weekly timetable.',
                  actionLabel: 'Add schedule',
                  onAction: () => context.push('/schedule/add'),
                );
              }
              return Column(
                  children: entries
                      .map((entry) => _ScheduleTile(entry: entry))
                      .toList());
            },
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends ConsumerWidget {
  const _ScheduleTile({required this.entry});
  final ScheduleEntry entry;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Delete schedule?'),
              content: Text(
                  'Remove this ${entry.course.name} class from your weekly timetable?'),
              actions: [
                TextButton(
                    onPressed: () => context.pop(false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => context.pop(true),
                    child: const Text('Delete')),
              ],
            ));
    if (confirmed == true) {
      await ref.read(scheduleRepositoryProvider).delete(entry.schedule.id);
      ref.invalidate(schedulesProvider);
      ref.invalidate(schedulesForCourseProvider(entry.course.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = entry.schedule;
    final details = [
      if (entry.course.code != null) entry.course.code!,
      if (schedule.room != null) schedule.room!,
      if (schedule.classType != null) schedule.classType!.label
    ].join(' • ');
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        leading: SizedBox(
            width: 58,
            child: Text(
                '${formatMinutes(schedule.startMinutes)}\n${formatMinutes(schedule.endMinutes)}',
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center)),
        title: Row(children: [
          Container(width: 4, height: 30, color: entry.course.color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(entry.course.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)))
        ]),
        subtitle: details.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 14, top: 3),
                child: Text(details)),
        trailing: PopupMenuButton<String>(
            tooltip: 'Schedule actions',
            onSelected: (value) {
              if (value == 'edit') {
                context.push('/schedule/${schedule.id}/edit', extra: schedule);
              }
              if (value == 'delete') {
                _delete(context, ref);
              }
            },
            itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete'))
                ]),
      ),
    );
  }
}
