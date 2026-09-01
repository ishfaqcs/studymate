class StudyNote {
  const StudyNote(
      {required this.id,
      required this.semesterId,
      this.courseId,
      required this.title,
      required this.content,
      required this.isPinned,
      required this.isFavorite,
      required this.createdAt,
      required this.updatedAt});
  final String id;
  final int semesterId;
  final String? courseId;
  final String title, content;
  final bool isPinned, isFavorite;
  final DateTime createdAt, updatedAt;
  factory StudyNote.fromMap(Map<String, Object?> m) => StudyNote(
      id: m['id'] as String,
      semesterId: (m['semester_id'] as num?)?.toInt() ?? 1,
      courseId: m['course_id'] as String?,
      title: m['title'] as String,
      content: m['body'] as String? ?? '',
      isPinned: m['pinned'] == 1,
      isFavorite: m['favorite'] == 1,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String));
  Map<String, Object?> toMap() => {
        'id': id,
        'semester_id': semesterId,
        'course_id': courseId,
        'title': title.trim(),
        'body': content.trim(),
        'pinned': isPinned ? 1 : 0,
        'favorite': isFavorite ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String()
      };
  StudyNote copyWith(
          {String? title,
          String? content,
          String? courseId,
          bool clearCourse = false,
          bool? isPinned,
          bool? isFavorite,
          DateTime? updatedAt}) =>
      StudyNote(
          id: id,
          semesterId: semesterId,
          courseId: clearCourse ? null : courseId ?? this.courseId,
          title: title ?? this.title,
          content: content ?? this.content,
          isPinned: isPinned ?? this.isPinned,
          isFavorite: isFavorite ?? this.isFavorite,
          createdAt: createdAt,
          updatedAt: updatedAt ?? this.updatedAt);
}
