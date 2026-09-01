import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/core/utils/gpa_calculator.dart';

void main() {
  test('weighted GPA uses credit hours', () {
    final gpa =
        GpaCalculator.calculate(const [GradeEntry(3, 4), GradeEntry(4, 3)]);
    expect(gpa, closeTo(24 / 7, 0.0001));
  });
}
