import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/preferences_service.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
    (ref) => ThemeModeController());

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system) {
    _load();
  }
  Future<void> _load() async {
    state = _fromString(await PreferencesService.themeMode());
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await PreferencesService.setThemeMode(mode.name);
  }

  ThemeMode _fromString(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system
      };
}
