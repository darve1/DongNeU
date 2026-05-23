part of '../../main.dart';

const _primary = Color(0xFFFF7E33);
const _secondary = Color(0xFF5E8D5A);
const _tertiary = Color(0xFFFFB347);
const _background = Color(0xFFFFFDF9);
const _surface = Color(0xFFFFFFFF);
const _surfaceVariant = Color(0xFFF2EBE1);
const _primaryText = Color(0xFF2D241E);
const _secondaryText = Color(0xFF7A6F66);
const _alternate = Color(0xFFE8DFD5);
const _accentText = Color(0xFFBCAFA3);
const _success = Color(0xFF4CAF50);
const _warning = Color(0xFFFF9800);
const _info = Color(0xFF2196F3);

ThemeData _dongNeuTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: _background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      tertiary: _tertiary,
      surface: _surface,
      error: const Color(0xFFE53935),
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: _primaryText,
      ),
      headlineMedium: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: _primaryText,
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: _primaryText,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: _primaryText,
      ),
      titleMedium: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: _primaryText,
      ),
      titleSmall: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: _primaryText,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: _primaryText,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: _primaryText,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _secondaryText,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      labelSmall: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    ),
  );
}
