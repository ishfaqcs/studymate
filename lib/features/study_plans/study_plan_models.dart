enum StudyPlanStatus { planned, active, completed, cancelled }

enum StudyPlanBlockStatus { planned, completed, skipped }

enum StudyPlanPriority { low, medium, high }

class StudyPlan {
  const StudyPlan(
      {required this.id,
      required this.semesterId,
      required this.title,
      required this.startDate,
      required this.endDate,
      required this.status,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final int semesterId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final StudyPlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  factory StudyPlan.fromMap(Map<String, Object?> m) => StudyPlan(
      id: m['id'] as String,
      semesterId: (m['semester_id'] as num).toInt(),
      title: m['title'] as String,
      startDate: DateTime.parse(m['start_date'] as String),
      endDate: DateTime.parse(m['end_date'] as String),
      status: StudyPlanStatus.values.byName(m['status'] as String),
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String));
  Map<String, Object?> toMap() => {
        'id': id,
        'semester_id': semesterId,
        'title': title.trim(),
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String()
      };
}

class StudyPlanBlock {
  const StudyPlanBlock(
      {required this.id,
      required this.studyPlanId,
      required this.title,
      required this.date,
      required this.plannedMinutes,
      required this.priority,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      this.courseId,
      this.taskId,
      this.examPreparationId,
      this.startTime});
  final String id;
  final String studyPlanId;
  final String? courseId;
  final String? taskId;
  final String? examPreparationId;
  final String title;
  final DateTime date;
  final String? startTime;
  final int plannedMinutes;
  final StudyPlanPriority priority;
  final StudyPlanBlockStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  factory StudyPlanBlock.fromMap(Map<String, Object?> m) => StudyPlanBlock(
      id: m['id'] as String,
      studyPlanId: m['study_plan_id'] as String,
      courseId: m['course_id'] as String?,
      taskId: m['task_id'] as String?,
      examPreparationId: m['exam_preparation_id'] as String?,
      title: m['title'] as String,
      date: DateTime.parse(m['date'] as String),
      startTime: m['start_time'] as String?,
      plannedMinutes: (m['planned_minutes'] as num).toInt(),
      priority: StudyPlanPriority.values.byName(m['priority'] as String),
      status: StudyPlanBlockStatus.values.byName(m['status'] as String),
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String));
  Map<String, Object?> toMap() => {
        'id': id,
        'study_plan_id': studyPlanId,
        'course_id': courseId,
        'task_id': taskId,
        'exam_preparation_id': examPreparationId,
        'title': title.trim(),
        'date': date.toIso8601String(),
        'start_time': startTime,
        'planned_minutes': plannedMinutes,
        'priority': priority.name,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String()
      };
}
