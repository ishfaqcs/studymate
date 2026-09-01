import 'package:flutter/material.dart';

import 'design_tokens.dart';

class AppTheme {
  static const _lightPrimary = Color(0xFF1E3A5F);
  static const _lightAccent = Color(0xFF4056A1);
  static const _lightSecondary = Color(0xFF0F766E);
  static const _lightBackground = Color(0xFFF6F8FB);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSecondarySurface = Color(0xFFEEF2F7);
  static const _lightText = Color(0xFF172033);
  static const _lightMuted = Color(0xFF667085);
  static const _lightBorder = Color(0xFFDCE3EC);
  static const _darkBackground = Color(0xFF10141C);
  static const _darkSurface = Color(0xFF171D27);
  static const _darkSecondarySurface = Color(0xFF202735);
  static const _darkText = Color(0xFFF1F5F9);
  static const _darkMuted = Color(0xFF9DAABD);
  static const _darkBorder = Color(0xFF2B3545);
  static const _darkAccent = Color(0xFF7C91E8);
  static const _darkSecondary = Color(0xFF45B8AC);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? _darkAccent : _lightPrimary;
    final accent = dark ? _darkAccent : _lightAccent;
    final secondary = dark ? _darkSecondary : _lightSecondary;
    final background = dark ? _darkBackground : _lightBackground;
    final surface = dark ? _darkSurface : _lightSurface;
    final secondarySurface =
        dark ? _darkSecondarySurface : _lightSecondarySurface;
    final text = dark ? _darkText : _lightText;
    final muted = dark ? _darkMuted : _lightMuted;
    final border = dark ? _darkBorder : _lightBorder;
    final error = AppSemanticColors.danger(brightness);
    final colors = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: dark ? _darkBackground : Colors.white,
      primaryContainer:
          dark ? const Color(0xFF293557) : const Color(0xFFE8ECFA),
      onPrimaryContainer: dark ? _darkText : _lightPrimary,
      secondary: secondary,
      onSecondary: dark ? _darkBackground : Colors.white,
      tertiary: accent,
      error: error,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: secondarySurface,
      surfaceContainerHighest: secondarySurface,
    );
    final base = Typography.material2021().black.apply(
          bodyColor: text,
          displayColor: text,
        );
    final type = base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall:
          base.bodySmall?.copyWith(fontSize: 13, height: 1.4, color: muted),
      labelLarge:
          base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: border),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      textTheme: type,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: type.headlineSmall?.copyWith(fontSize: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            type.labelMedium?.copyWith(
              color: states.contains(WidgetState.selected) ? primary : muted,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? primary : muted,
              size: 23,
            )),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1),
      listTileTheme: ListTileThemeData(
        minTileHeight: AppSizes.touchTarget,
        iconColor: muted,
        textColor: text,
        titleTextStyle: type.titleMedium,
        subtitleTextStyle: type.bodySmall,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.touchTarget),
          foregroundColor: muted,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSizes.touchTarget),
          textStyle: type.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSizes.touchTarget),
          side: BorderSide(color: border),
          textStyle: type.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, AppSizes.touchTarget),
          textStyle: type.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondarySurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: type.bodyMedium?.copyWith(color: muted),
        hintStyle: type.bodyMedium?.copyWith(color: muted),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: error)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: border),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(secondarySurface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(color: border)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        )),
        constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        selectedColor: colors.primaryContainer,
        backgroundColor: surface,
        labelStyle: type.labelMedium,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        highlightElevation: 2,
        backgroundColor: primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 6,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.dialog),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: border, width: 1.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}
