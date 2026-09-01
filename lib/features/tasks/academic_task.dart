enum TaskType {
  assignment,
  quiz,
  exam,
  project,
  presentation,
  lab,
  reading,
  other
}

enum TaskPriority { low, medium, high }

enum TaskStatus { notStarted, inProgress, completed }

extension TaskLabel on Enum {
  String get label {
    if (this == TaskStatus.notStarted) return 'Not Started';
    final value = name;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class AcademicTask {
  const AcademicTask(
      {required this.id,
      required this.semesterId,
      required this.title,
      required this.type,
      required this.dueDate,
      required this.priority,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      this.courseId,
      this.description,
      this.dueTime,
      this.reminderAt,
      this.completedAt,
      this.location});
  final String id;
  final String? courseId;
  final int semesterId;
  final String title;
  final String? description;
  final TaskType type;
  final DateTime dueDate;
  final String? dueTime;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? reminderAt;
  final DateTime? completedAt;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  DateTime get deadline {
    final parts = dueTime?.split(':');
    return parts == null
        ? DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59)
        : DateTime(dueDate.year, dueDate.month, dueDate.day,
            int.parse(parts[0]), int.parse(parts[1]));
  }

  bool isOverdueAt(DateTime now) =>
      status != TaskStatus.completed && deadline.isBefore(now);
  factory AcademicTask.fromMap(Map<String, Object?> map) => AcademicTask(
      id: map['id'] as String,
      courseId: map['course_id'] as String?,
      semesterId: (map['semester_id'] as num?)?.toInt() ?? 1,
      title: map['title'] as String,
      description: _clean(map['description'] as String?),
      type: _enum(TaskType.values, map['type'] as String, TaskType.other),
      dueDate: DateTime.parse(map['due_date'] as String),
      dueTime: map['due_time'] as String?,
      priority: _enum(
          TaskPriority.values, map['priority'] as String, TaskPriority.medium),
      status: _enum(TaskStatus.values, _camel(map['status'] as String),
          TaskStatus.notStarted),
      reminderAt: DateTime.tryParse(map['reminder_at'] as String? ?? ''),
      completedAt: DateTime.tryParse(map['completed_at'] as String? ?? ''),
      location: _clean(map['location'] as String?),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now());
  Map<String, Object?> toMap() => {
        'id': id,
        'course_id': courseId,
        'semester_id': semesterId,
        'title': title.trim(),
        'description': _clean(description),
        'type': type.name,
        'due_date': DateTime(dueDate.year, dueDate.month, dueDate.day)
            .toIso8601String(),
        'due_time': dueTime,
        'priority': priority.name,
        'status': status.name,
        'reminder_at': reminderAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'location': _clean(location),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String()
      };
  static T _enum<T extends Enum>(List<T> values, String name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static String _camel(String value) => value
      .split('_')
      .asMap()
      .entries
      .map((e) => e.key == 0
          ? e.value
          : '${e.value[0].toUpperCase()}${e.value.substring(1)}')
      .join();
  static String? _clean(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }
}

String deadlineLabel(AcademicTask task, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
  final days = due.difference(today).inDays;
  if (task.isOverdueAt(now)) {
    final overdue = today.difference(due).inDays;
    return overdue <= 0
        ? 'Overdue'
        : 'Overdue by $overdue day${overdue == 1 ? '' : 's'}';
  }
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  if (days > 1 && days <= 7) return '$days days left';
  return 'Due ${due.day}/${due.month}';
}

DateTime reminderTime(DateTime deadline, int minutesBefore) =>
    deadline.subtract(Duration(minutes: minutesBefore));
