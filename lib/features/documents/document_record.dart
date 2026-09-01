class DocumentRecord {
  const DocumentRecord(
      {required this.id,
      required this.semesterId,
      this.courseId,
      required this.displayName,
      required this.originalFileName,
      required this.storedFileName,
      required this.filePath,
      required this.fileType,
      required this.fileSize,
      this.description,
      required this.createdAt,
      required this.updatedAt});
  final String id,
      displayName,
      originalFileName,
      storedFileName,
      filePath,
      fileType;
  final int semesterId, fileSize;
  final String? courseId, description;
  final DateTime createdAt, updatedAt;
  factory DocumentRecord.fromMap(Map<String, Object?> m) => DocumentRecord(
      id: m['id'] as String,
      semesterId: (m['semester_id'] as num).toInt(),
      courseId: m['course_id'] as String?,
      displayName: m['display_name'] as String,
      originalFileName: m['original_file_name'] as String,
      storedFileName: m['stored_file_name'] as String,
      filePath: m['file_path'] as String,
      fileType: m['file_type'] as String,
      fileSize: (m['file_size'] as num).toInt(),
      description: m['description'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String));
  Map<String, Object?> toMap() => {
        'id': id,
        'semester_id': semesterId,
        'course_id': courseId,
        'display_name': displayName.trim(),
        'original_file_name': originalFileName,
        'stored_file_name': storedFileName,
        'file_path': filePath,
        'file_type': fileType,
        'file_size': fileSize,
        'description': description?.trim(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String()
      };
}
