import 'package:flutter/material.dart';

class Course {
  const Course({
    required this.id,
    required this.semesterId,
    required this.name,
    required this.creditHours,
    required this.requiredAttendance,
    required this.colorValue,
    required this.createdAt,
    this.code,
    this.instructor,
    this.room,
    this.finalGradeLetter,
    this.finalGradePoint,
  });

  final String id;
  final int semesterId;
  final String name;
  final String? code;
  final String? instructor;
  final String? room;
  final String? finalGradeLetter;
  final double? finalGradePoint;
  final double creditHours;
  final double requiredAttendance;
  final int colorValue;
  final DateTime createdAt;

  Color get color => Color(colorValue);

  factory Course.fromMap(Map<String, Object?> map) => Course(
        id: map['id'] as String,
        semesterId: (map['semester_id'] as num?)?.toInt() ?? 1,
        name: map['name'] as String,
        code: _optional(map['code']),
        instructor: _optional(map['instructor']),
        room: _optional(map['room']),
        finalGradeLetter: _optional(map['final_grade_letter']),
        finalGradePoint: (map['final_grade_point'] as num?)?.toDouble(),
        creditHours: (map['credit_hours'] as num).toDouble(),
        requiredAttendance: (map['required_attendance'] as num).toDouble(),
        colorValue: (map['color_value'] as num?)?.toInt() ?? 0xFF3457D5,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'semester_id': semesterId,
        'name': name.trim(),
        'code': _clean(code),
        'instructor': _clean(instructor),
        'room': _clean(room),
        'final_grade_letter': _clean(finalGradeLetter),
        'final_grade_point': finalGradePoint,
        'credit_hours': creditHours,
        'required_attendance': requiredAttendance,
        'color_value': colorValue,
        'created_at': createdAt.toIso8601String(),
      };

  static String? _optional(Object? value) => _clean(value as String?);
  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}

String? validateAttendance(String? value) {
  final attendance = double.tryParse(value?.trim() ?? '');
  if (attendance == null) return 'Enter a valid percentage';
  if (attendance < 1 || attendance > 100) {
    return 'Attendance must be between 1 and 100';
  }
  return null;
}
