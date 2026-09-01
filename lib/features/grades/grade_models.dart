import '../courses/course.dart';

enum AssessmentType {
  assignment,
  quiz,
  midterm,
  finalExam,
  project,
  presentation,
  practical,
  lab,
  other
}

extension AssessmentTypeLabel on AssessmentType {
  String get label => this == AssessmentType.finalExam
      ? 'Final Exam'
      : name[0].toUpperCase() + name.substring(1);
}

class Assessment {
  const Assessment(
      {required this.id,
      required this.courseId,
      required this.semesterId,
      required this.title,
      required this.type,
      required this.marksObtained,
      required this.totalMarks,
      required this.createdAt,
      required this.updatedAt,
      this.weight,
      this.date,
      this.note});
  final String id;
  final String courseId;
  final int semesterId;
  final String title;
  final AssessmentType type;
  final double marksObtained;
  final double totalMarks;
  final double? weight;
  final DateTime? date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  double get percentage =>
      totalMarks == 0 ? 0 : marksObtained / totalMarks * 100;
  factory Assessment.fromMap(Map<String, Object?> map) => Assessment(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      semesterId: (map['semester_id'] as num?)?.toInt() ?? 1,
      title: map['title'] as String,
      type: AssessmentType.values.firstWhere(
          (v) => v.name == map['assessment_type'],
          orElse: () => AssessmentType.other),
      marksObtained: (map['marks_obtained'] as num).toDouble(),
      totalMarks: (map['total_marks'] as num).toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      date: DateTime.tryParse(map['date'] as String? ?? ''),
      note: _clean(map['note'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.parse(map['created_at'] as String));
  Map<String, Object?> toMap({required double creditHours}) => {
        'id': id,
        'course_id': courseId,
        'semester_id': semesterId,
        'title': title.trim(),
        'assessment_type': type.name,
        'marks_obtained': marksObtained,
        'total_marks': totalMarks,
        'weight': weight,
        'date': date?.toIso8601String(),
        'note': _clean(note),
        'credit_hours': creditHours,
        'grade_letter': null,
        'grade_point': 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String()
      };
  static String? _clean(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }
}

class GradeBoundary {
  const GradeBoundary(
      {required this.id,
      required this.letter,
      required this.minimumPercentage,
      required this.gradePoint});
  final String id;
  final String letter;
  final double minimumPercentage;
  final double gradePoint;
  factory GradeBoundary.fromMap(Map<String, Object?> map) => GradeBoundary(
      id: map['id'] as String,
      letter: map['letter'] as String,
      minimumPercentage: (map['minimum_percentage'] as num).toDouble(),
      gradePoint: (map['grade_point'] as num).toDouble());
}

class CourseGradeSummary {
  const CourseGradeSummary(
      {required this.course,
      required this.assessments,
      required this.boundaries});
  final Course course;
  final List<Assessment> assessments;
  final List<GradeBoundary> boundaries;
  double? get average {
    if (assessments.isEmpty) return null;
    final weighted = assessments.where((a) => a.weight != null).toList();
    if (weighted.isNotEmpty) {
      final totalWeight = weighted.fold<double>(0, (sum, a) => sum + a.weight!);
      if (totalWeight == 0) return null;
      return weighted.fold<double>(
              0, (sum, a) => sum + a.percentage * a.weight!) /
          totalWeight;
    }
    return assessments.fold<double>(0, (sum, a) => sum + a.percentage) /
        assessments.length;
  }

  GradeBoundary? get calculatedBoundary => boundaryFor(average, boundaries);
  String? get finalLetter =>
      course.finalGradeLetter ?? calculatedBoundary?.letter;
  double? get finalPoint =>
      course.finalGradePoint ?? calculatedBoundary?.gradePoint;
}

GradeBoundary? boundaryFor(double? percentage, List<GradeBoundary> boundaries) {
  if (percentage == null || percentage < 0 || percentage > 100) return null;
  final ordered = [...boundaries]
    ..sort((a, b) => b.minimumPercentage.compareTo(a.minimumPercentage));
  for (final boundary in ordered) {
    if (percentage >= boundary.minimumPercentage) return boundary;
  }
  return null;
}

class SemesterAcademicSummary {
  const SemesterAcademicSummary(
      {required this.id, required this.name, required this.courses});
  final int id;
  final String name;
  final List<CourseGradeSummary> courses;
  List<CourseGradeSummary> get graded =>
      courses.where((c) => c.finalPoint != null).toList();
  double get credits =>
      graded.fold<double>(0, (sum, c) => sum + c.course.creditHours);
  double? get gpa => credits == 0
      ? null
      : graded.fold<double>(
              0, (sum, c) => sum + c.finalPoint! * c.course.creditHours) /
          credits;
}

double? calculateCgpa(List<SemesterAcademicSummary> semesters) {
  final credits = semesters.fold<double>(0, (sum, s) => sum + s.credits);
  if (credits == 0) return null;
  final quality = semesters.fold<double>(
      0,
      (sum, s) =>
          sum +
          s.graded.fold<double>(
              0, (q, c) => q + c.finalPoint! * c.course.creditHours));
  return quality / credits;
}
