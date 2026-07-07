import 'package:flutter/material.dart';

import '../app_state.dart';

@immutable
class PanchangColors extends ThemeExtension<PanchangColors> {
  const PanchangColors({
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.border,
  });

  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color text;
  final Color textMuted;
  final Color border;

  @override
  PanchangColors copyWith({Color? primary, Color? accent, Color? background, Color? surface, Color? text, Color? textMuted, Color? border}) {
    return PanchangColors(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
    );
  }

  @override
  PanchangColors lerp(ThemeExtension<PanchangColors>? other, double t) {
    if (other is! PanchangColors) return this;
    return PanchangColors(
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

class PanchangTheme {
  PanchangTheme(this.colors);

  final PanchangColors colors;

  static final softShadow = [
    BoxShadow(color: Colors.brown.withValues(alpha: .10), blurRadius: 18, offset: const Offset(0, 8)),
  ];

  factory PanchangTheme.fromSettings(AppSettings settings) {
    return PanchangTheme(
      PanchangColors(
        primary: const Color(0xff9a4f00),
        accent: const Color(0xffffcf94),
        background: Color(settings.backgroundColor),
        surface: const Color(0xfffff4e8),
        text: Color(settings.textColor),
        textMuted: const Color(0xff6f574d),
        border: const Color(0xffead8c8),
      ),
    );
  }

  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(seedColor: colors.primary, surface: colors.surface);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      colorScheme: scheme.copyWith(primary: colors.primary, secondary: colors.accent),
      extensions: [colors],
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        displaySmall: TextStyle(fontSize: 46, height: 1.12, fontWeight: FontWeight.w800, color: colors.primary),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.primary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.text),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.text),
        bodyLarge: TextStyle(fontSize: 16, color: colors.text),
        bodyMedium: TextStyle(fontSize: 14, color: colors.textMuted),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.primary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textMuted),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.text,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
          shadowColor: colors.accent.withValues(alpha: .38),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: colors.primary,
        backgroundColor: const Color(0xffeee9e4),
        labelStyle: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}
