import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/core/utils/attendance_calculator.dart';

void main() {
  group('AttendanceCalculator', () {
    test('calculates safe misses', () {
      final r = AttendanceCalculator.calculate(
          attended: 27, total: 32, requiredPercent: 75);
      expect(r.percentage, closeTo(84.375, 0.001));
      expect(r.safeMisses, 4);
    });
    test('four attended out of five is 80 percent at a 75 requirement', () {
      final result = AttendanceCalculator.calculate(
          attended: 4, total: 5, requiredPercent: 75);
      expect(result.percentage, 80);
      expect(result.safeMisses, 0);
      expect(result.recoveryClasses, 0);
    });
    test('calculates recovery classes', () {
      final r = AttendanceCalculator.calculate(
          attended: 14, total: 20, requiredPercent: 75);
      expect(r.recoveryClasses, 4);
    });
    test('rejects invalid data', () {
      expect(
          () => AttendanceCalculator.calculate(
              attended: 5, total: 4, requiredPercent: 75),
          throwsArgumentError);
    });
  });
}
