import '../../core/utils/attendance_calculator.dart';
import '../courses/course.dart';
import '../timetable/class_schedule.dart';

enum AttendanceStatus { present, absent, late, excused, cancelled }

extension AttendanceStatusInfo on AttendanceStatus {
  String get label => name[0].toUpperCase() + name.substring(1);
  bool get isCounted =>
      this != AttendanceStatus.excused && this != AttendanceStatus.cancelled;
  bool get isAttended =>
      this == AttendanceStatus.present || this == AttendanceStatus.late;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.courseId,
    required this.date,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.scheduleId,
    this.note,
  });
  final String id;
  final String courseId;
  final String? scheduleId;
  final DateTime date;
  final AttendanceStatus status;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AttendanceRecord.fromMap(Map<String, Object?> map) =>
      AttendanceRecord(
        id: map['id'] as String,
        courseId: map['course_id'] as String,
        scheduleId: map['schedule_id'] as String?,
        date: DateTime.parse(map['date'] as String),
        status: AttendanceStatus.values
            .firstWhere((value) => value.name == map['status']),
        note: _clean(map['note'] as String?),
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'course_id': courseId,
        'schedule_id': scheduleId,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'status': status.name,
        'note': _clean(note),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static String? _clean(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }
}

class AttendanceEntry {
  const AttendanceEntry(this.record, this.course, this.schedule);
  final AttendanceRecord record;
  final Course course;
  final ClassSchedule? schedule;
}

class CourseAttendanceSummary {
  const CourseAttendanceSummary({required this.course, required this.records});
  final Course course;
  final List<AttendanceRecord> records;
  int get attended => records.where((r) => r.status.isAttended).length;
  int get counted => records.where((r) => r.status.isCounted).length;
  int get absent =>
      records.where((r) => r.status == AttendanceStatus.absent).length;
  AttendanceInsight get insight => AttendanceCalculator.calculate(
      attended: attended,
      total: counted,
      requiredPercent: course.requiredAttendance);
}
