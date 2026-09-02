import 'grade_models.dart';

enum PredictionOutcome {
  achievable,
  alreadyAchieved,
  impossible,
  noRemainingWeight,
  incompleteData
}

class GradePrediction {
  const GradePrediction(
      {required this.currentWeightedGrade,
      required this.completedWeight,
      required this.remainingWeight,
      required this.requiredRemainingScore,
      required this.outcome});
  final double currentWeightedGrade;
  final double completedWeight;
  final double remainingWeight;
  final double? requiredRemainingScore;
  final PredictionOutcome outcome;
}

class GradePredictionService {
  const GradePredictionService();
  GradePrediction requiredScore(List<Assessment> assessments, double target) {
    if (target < 0 || target > 100) {
      throw ArgumentError.value(target, 'target');
    }
    if (assessments
        .any((a) => a.weight == null || a.weight! < 0 || a.totalMarks <= 0)) {
      return const GradePrediction(
          currentWeightedGrade: 0,
          completedWeight: 0,
          remainingWeight: 100,
          requiredRemainingScore: null,
          outcome: PredictionOutcome.incompleteData);
    }
    final completed = assessments.fold<double>(0, (s, a) => s + a.weight!);
    if (completed > 100.000001) {
      throw ArgumentError('Assessment weights exceed 100%.');
    }
    final points = assessments.fold<double>(
        0, (s, a) => s + a.percentage * a.weight! / 100);
    final remaining = 100 - completed;
    if (remaining <= 0) {
      return GradePrediction(
          currentWeightedGrade: points,
          completedWeight: completed,
          remainingWeight: 0,
          requiredRemainingScore: null,
          outcome: points >= target
              ? PredictionOutcome.alreadyAchieved
              : PredictionOutcome.noRemainingWeight);
    }
    final required = (target - points) / remaining * 100;
    final outcome = required <= 0
        ? PredictionOutcome.alreadyAchieved
        : required > 100
            ? PredictionOutcome.impossible
            : PredictionOutcome.achievable;
    return GradePrediction(
        currentWeightedGrade: points,
        completedWeight: completed,
        remainingWeight: remaining,
        requiredRemainingScore: required.clamp(0, double.infinity),
        outcome: outcome);
  }

  double whatIfFinalGrade(List<Assessment> completed,
      {required double remainingScore}) {
    if (remainingScore < 0 || remainingScore > 100) {
      throw ArgumentError.value(remainingScore, 'remainingScore');
    }
    final result = requiredScore(completed, 0);
    return result.currentWeightedGrade +
        result.remainingWeight * remainingScore / 100;
  }
}
