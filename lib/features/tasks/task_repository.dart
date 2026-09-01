import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/services/notification_service.dart';
import 'academic_task.dart';

class TaskRepository {
  TaskRepository(
      {Future<Database> Function()? database, ReminderScheduler? reminders})
      : _database = database ?? (() => AppDatabase.instance.database),
        _reminders = reminders ?? NotificationService.instance;
  final Future<Database> Function() _database;
  final ReminderScheduler _reminders;
  Future<List<AcademicTask>> list(
      {int semesterId = 1, String? courseId}) async {
    final rows = await (await _database()).query('tasks',
        where: courseId == null
            ? 'semester_id = ?'
            : 'semester_id = ? AND course_id = ?',
        whereArgs: [semesterId, if (courseId != null) courseId],
        orderBy: 'due_date, due_time');
    return rows.map(AcademicTask.fromMap).toList();
  }

  Future<bool> create(AcademicTask task) async {
    await (await _database()).insert('tasks', task.toMap());
    return _syncReminder(task);
  }

  Future<bool> update(AcademicTask task) async {
    await (await _database())
        .update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
    return _syncReminder(task);
  }

  Future<void> delete(String id) async {
    await (await _database()).delete('tasks', where: 'id = ?', whereArgs: [id]);
    await _reminders.cancel('task:$id');
  }

  Future<bool> _syncReminder(AcademicTask task) async {
    await _reminders.cancel('task:${task.id}');
    if (task.reminderAt != null && task.status != TaskStatus.completed) {
      return _reminders.schedule(
          key: 'task:${task.id}',
          title: 'StudyMate',
          body: '${task.title} is due soon.',
          at: task.reminderAt!);
    }
    return true;
  }
}

final taskRepositoryProvider =
    Provider<TaskRepository>((ref) => TaskRepository());
final tasksProvider = FutureProvider.autoDispose<List<AcademicTask>>(
    (ref) => ref.watch(taskRepositoryProvider).list());
final tasksForCourseProvider = FutureProvider.autoDispose
    .family<List<AcademicTask>, String>(
        (ref, id) => ref.watch(taskRepositoryProvider).list(courseId: id));
