import 'package:flutter_test/flutter_test.dart';
import 'package:studentplanner/features/grades/grade_models.dart';
import 'package:studentplanner/features/grades/grade_prediction_service.dart';

Assessment assessment(String id, double weight, double score) => Assessment(
    id: id,
    courseId: 'course',
    semesterId: 1,
    title: id,
    type: AssessmentType.other,
    marksObtained: score,
    totalMarks: 100,
    weight: weight,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026));

void main() {
  const service = GradePredictionService();
  final completed = [
    assessment('Assignments', 40, 86),
    assessment('Midterm', 30, 78)
  ];

  test('calculates weighted grade and required final score', () {
    final result = service.requiredScore(completed, 85);
    expect(result.completedWeight, 70);
    expect(result.currentWeightedGrade, closeTo(57.8, .0001));
    expect(result.remainingWeight, 30);
    expect(result.requiredRemainingScore, closeTo(90.6667, .001));
    expect(result.outcome, PredictionOutcome.achievable);
  });
  test('identifies already achieved and impossible targets', () {
    expect(service.requiredScore(completed, 50).outcome,
        PredictionOutcome.alreadyAchieved);
    expect(service.requiredScore(completed, 100).outcome,
        PredictionOutcome.impossible);
  });
  test('handles zero remaining weight', () {
    final all = [assessment('Only', 100, 80)];
    expect(service.requiredScore(all, 70).outcome,
        PredictionOutcome.alreadyAchieved);
    expect(service.requiredScore(all, 90).outcome,
        PredictionOutcome.noRemainingWeight);
  });
  test('rejects invalid weights and targets', () {
    expect(() => service.requiredScore([assessment('A', 101, 80)], 80),
        throwsArgumentError);
    expect(() => service.requiredScore(completed, 101), throwsArgumentError);
  });
  test('supports zero target, rounding, and what-if results', () {
    expect(service.requiredScore(completed, 0).requiredRemainingScore, 0);
    expect(service.whatIfFinalGrade(completed, remainingScore: 90),
        closeTo(84.8, .0001));
  });
}
