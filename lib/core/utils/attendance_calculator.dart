import 'dart:math';

class AttendanceInsight {
  final double percentage;
  final int safeMisses;
  final int recoveryClasses;
  const AttendanceInsight(
      {required this.percentage,
      required this.safeMisses,
      required this.recoveryClasses});
}

class AttendanceCalculator {
  static AttendanceInsight calculate(
      {required int attended,
      required int total,
      required double requiredPercent}) {
    if (attended < 0 || total < 0 || attended > total) {
      throw ArgumentError('Invalid attendance values');
    }
    if (requiredPercent <= 0 || requiredPercent > 100) {
      throw ArgumentError('Required percentage must be 1-100');
    }
    final r = requiredPercent / 100;
    final percentage = total == 0 ? 0.0 : attended / total * 100;
    final safeMisses = total == 0 ? 0 : max(0, (attended / r - total).floor());
    int recovery = 0;
    if (total > 0 && percentage + 1e-9 < requiredPercent) {
      recovery = max(0, ((r * total - attended) / (1 - r)).ceil());
    }
    return AttendanceInsight(
        percentage: percentage,
        safeMisses: safeMisses,
        recoveryClasses: recovery);
  }
}
