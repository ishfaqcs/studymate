class GradeEntry {
  final double creditHours;
  final double gradePoint;
  const GradeEntry(this.creditHours, this.gradePoint);
}

class GpaCalculator {
  static double calculate(List<GradeEntry> grades) {
    final credits = grades.fold<double>(0, (s, g) => s + g.creditHours);
    if (credits == 0) return 0;
    return grades.fold<double>(0, (s, g) => s + g.creditHours * g.gradePoint) /
        credits;
  }
}
