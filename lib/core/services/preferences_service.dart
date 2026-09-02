import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _onboarding = 'onboarding_completed';
  static const _theme = 'theme_mode';
  static const _notificationPermissionAsked = 'notification_permission_asked';
  static const _cloudSyncEnabled = 'cloud_sync_enabled';
  static const _aiFeaturesEnabled = 'ai_features_enabled';

  static Future<bool> onboardingCompleted() async =>
      (await SharedPreferences.getInstance()).getBool(_onboarding) ?? false;
  static Future<void> setOnboardingCompleted(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_onboarding, value);
  static Future<String> themeMode() async =>
      (await SharedPreferences.getInstance()).getString(_theme) ?? 'system';
  static Future<void> setThemeMode(String value) async =>
      (await SharedPreferences.getInstance()).setString(_theme, value);
  static Future<bool> notificationPermissionAsked() async =>
      (await SharedPreferences.getInstance())
          .getBool(_notificationPermissionAsked) ??
      false;
  static Future<void> markNotificationPermissionAsked() async =>
      (await SharedPreferences.getInstance())
          .setBool(_notificationPermissionAsked, true);
  static Future<bool> cloudSyncEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_cloudSyncEnabled) ??
      false;
  static Future<void> setCloudSyncEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_cloudSyncEnabled, value);
  static Future<bool> aiFeaturesEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_aiFeaturesEnabled) ??
      false;
  static Future<void> setAiFeaturesEnabled(bool value) async =>
      (await SharedPreferences.getInstance())
          .setBool(_aiFeaturesEnabled, value);
  static Future<void> resetUserPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_onboarding);
    await preferences.remove(_theme);
    await preferences.remove(_notificationPermissionAsked);
    await preferences.remove(_cloudSyncEnabled);
    await preferences.remove(_aiFeaturesEnabled);
  }
}
