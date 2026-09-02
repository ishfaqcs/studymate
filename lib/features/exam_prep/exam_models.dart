enum ExamTopicStatus { notStarted, inProgress, completed }

enum ExamTopicPriority { low, medium, high }

class ExamPreparation {
  const ExamPreparation(
      {required this.id,
      required this.courseId,
      required this.examTitle,
      required this.examDate,
      required this.createdAt,
      required this.updatedAt,
      this.taskId,
      this.targetGrade,
      this.confidenceLevel});
  final String id;
  final String courseId;
  final String? taskId;
  final String examTitle;
  final DateTime examDate;
  final double? targetGrade;
  final int? confidenceLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  factory ExamPreparation.fromMap(Map<String, Object?> m) => ExamPreparation(
      id: m['id'] as String,
      courseId: m['course_id'] as String,
      taskId: m['task_id'] as String?,
      examTitle: m['exam_title'] as String,
      examDate: DateTime.parse(m['exam_date'] as String),
      targetGrade: (m['target_grade'] as num?)?.toDouble(),
      confidenceLevel: (m['confidence_level'] as num?)?.toInt(),
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String));
  Map<String, Object?> toMap() => {
        'id': id,
        'course_id': courseId,
        'task_id': taskId,
        'exam_title': examTitle.trim(),
        'exam_date': examDate.toIso8601String(),
        'target_grade': targetGrade,
        'confidence_level': confidenceLevel,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String()
      };
}

class ExamTopic {
  const ExamTopic(
      {required this.id,
      required this.examPreparationId,
      required this.title,
      required this.status,
      required this.priority,
      required this.position,
      required this.createdAt,
      required this.updatedAt,
      this.estimatedMinutes,
      this.notes});
  final String id;
  final String examPreparationId;
  final String title;
  final ExamTopicStatus status;
  final ExamTopicPriority priority;
  final int? estimatedMinutes;
  final String? notes;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  factory ExamTopic.fromMap(Map<String, Object?> m) => ExamTopic(
      id: m['id'] as String,
      examPreparationId: m['exam_preparation_id'] as String,
      title: m['title'] as String,
      status: ExamTopicStatus.values.byName(m['status'] as String),
      priority: ExamTopicPriority.values.byName(m['priority'] as String),
      estimatedMinutes: (m['estimated_minutes'] as num?)?.toInt(),
      notes: m['notes'] as String?,
      position: (m['position'] as num).toInt(),
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String));
  Map<String, Object?> toMap() => {
        'id': id,
        'exam_preparation_id': examPreparationId,
        'title': title.trim(),
        'status': status.name,
        'priority': priority.name,
        'estimated_minutes': estimatedMinutes,
        'notes': notes?.trim(),
        'position': position,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String()
      };
}
