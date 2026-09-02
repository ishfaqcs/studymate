enum StudySessionType { focus, shortBreak, longBreak, custom }

enum StudySessionStatus { planned, running, paused, completed, cancelled }

class StudySession {
  const StudySession(
      {required this.id,
      required this.sessionType,
      required this.plannedDurationMinutes,
      required this.actualDurationMinutes,
      required this.startedAt,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      this.semesterId,
      this.courseId,
      this.taskId,
      this.title,
      this.completedAt});
  final String id;
  final int? semesterId;
  final String? courseId;
  final String? taskId;
  final String? title;
  final StudySessionType sessionType;
  final int plannedDurationMinutes;
  final int actualDurationMinutes;
  final DateTime startedAt;
  final DateTime? completedAt;
  final StudySessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StudySession.fromMap(Map<String, Object?> map) => StudySession(
      id: map['id'] as String,
      semesterId: (map['semester_id'] as num?)?.toInt(),
      courseId: map['course_id'] as String?,
      taskId: map['task_id'] as String?,
      title: map['title'] as String?,
      sessionType:
          StudySessionType.values.byName(map['session_type'] as String),
      plannedDurationMinutes: (map['planned_duration_minutes'] as num).toInt(),
      actualDurationMinutes: (map['actual_duration_minutes'] as num).toInt(),
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: DateTime.tryParse(map['completed_at'] as String? ?? ''),
      status: StudySessionStatus.values.byName(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String));
  Map<String, Object?> toMap() => {
        'id': id,
        'semester_id': semesterId,
        'course_id': courseId,
        'task_id': taskId,
        'title': title?.trim(),
        'session_type': sessionType.name,
        'planned_duration_minutes': plannedDurationMinutes,
        'actual_duration_minutes': actualDurationMinutes,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String()
      };
}
