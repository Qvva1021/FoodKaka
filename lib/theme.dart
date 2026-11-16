import 'package:material_ui/material_ui.dart';

const cream = Color(0xFFFFFAF3);
const peach = Color(0xFFF4AE9F);
const mint = Color(0xFFE5EFE5);
const ink = Color(0xFF403D38);
const muted = Color(0xFF716C65);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: peach,
    brightness: Brightness.light,
    surface: cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: cream,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: ink,
      displayColor: ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: ink,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: peach.withValues(alpha: 0.35),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: ink,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: peach,
        foregroundColor: ink,
        disabledBackgroundColor: peach.withValues(alpha: 0.45),
        disabledForegroundColor: const Color(0xFF67534B),
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}
