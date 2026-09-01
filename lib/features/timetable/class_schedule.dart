import '../courses/course.dart';

enum ClassType { lecture, lab, tutorial, seminar, other }

extension ClassTypeLabel on ClassType {
  String get label => name[0].toUpperCase() + name.substring(1);
}

class ClassSchedule {
  const ClassSchedule({
    required this.id,
    required this.courseId,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.room,
    this.classType,
  });

  final String id;
  final String courseId;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final String? room;
  final ClassType? classType;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ClassSchedule.fromMap(Map<String, Object?> map) => ClassSchedule(
        id: map['id'] as String,
        courseId: map['course_id'] as String,
        weekday: (map['weekday'] as num).toInt(),
        startMinutes: (map['start_minutes'] as num).toInt(),
        endMinutes: (map['end_minutes'] as num).toInt(),
        room: _clean(map['room'] as String?),
        classType: _type(map['class_type'] as String?),
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'course_id': courseId,
        'weekday': weekday,
        'start_minutes': startMinutes,
        'end_minutes': endMinutes,
        'room': _clean(room),
        'class_type': classType?.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static String? _clean(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }

  static ClassType? _type(String? value) {
    for (final type in ClassType.values) {
      if (type.name == value?.toLowerCase()) return type;
    }
    return null;
  }
}

class ScheduleEntry {
  const ScheduleEntry(this.schedule, this.course);
  final ClassSchedule schedule;
  final Course course;
}

String formatMinutes(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
