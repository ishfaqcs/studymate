import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0,
      xs = 8.0,
      sm = 12.0,
      md = 16.0,
      lg = 20.0,
      xl = 24.0,
      xxl = 32.0;
}

abstract final class AppRadii {
  static const sm = 8.0, md = 10.0, lg = 12.0, dialog = 16.0;
}

abstract final class AppSizes {
  static const touchTarget = 48.0, icon = 24.0, maxContentWidth = 840.0;
}

abstract final class AppSemanticColors {
  static const lightSuccess = Color(0xFF16815D),
      lightWarning = Color(0xFFB7791F),
      lightDanger = Color(0xFFC2414B),
      lightInformation = Color(0xFF3563B8),
      darkSuccess = Color(0xFF4FC59A),
      darkWarning = Color(0xFFE3B341),
      darkDanger = Color(0xFFE66A73),
      darkInformation = Color(0xFF7C91E8);

  static Color success(Brightness brightness) =>
      brightness == Brightness.dark ? darkSuccess : lightSuccess;
  static Color warning(Brightness brightness) =>
      brightness == Brightness.dark ? darkWarning : lightWarning;
  static Color danger(Brightness brightness) =>
      brightness == Brightness.dark ? darkDanger : lightDanger;
  static Color information(Brightness brightness) =>
      brightness == Brightness.dark ? darkInformation : lightInformation;
}
