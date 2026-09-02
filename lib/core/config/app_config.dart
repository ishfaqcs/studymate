enum AppEnvironment { development, release }

class V2Features {
  const V2Features({
    this.studyPlanner = true,
    this.examPreparation = true,
    this.studySessions = true,
    this.advancedAnalytics = true,
    this.gradePredictor = true,
    this.cloudSync = false,
    this.aiAssistant = false,
    this.widgets = false,
  });

  final bool studyPlanner;
  final bool examPreparation;
  final bool studySessions;
  final bool advancedAnalytics;
  final bool gradePredictor;
  final bool cloudSync;
  final bool aiAssistant;
  final bool widgets;
}

class AppConfig {
  const AppConfig._(this.environment, this.features);
  final AppEnvironment environment;
  final V2Features features;

  static const current = AppConfig._(
    bool.fromEnvironment('dart.vm.product')
        ? AppEnvironment.release
        : AppEnvironment.development,
    V2Features(),
  );
}
