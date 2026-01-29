import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String name;
  final Color seedColor;
  final Brightness brightness;

  const AppTheme({
    required this.name,
    required this.seedColor,
    this.brightness = Brightness.light,
  });

  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ).surface,
      titleTextStyle: TextStyle(
        color: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        ).onSurface,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0, // Flat style is more modern/student-like
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // More rounded
        side: BorderSide(
          color: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
          ).outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ).surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

class ThemeController extends ValueNotifier<AppTheme> {
  ThemeController(super.value) {
    _loadTheme();
  }

  static const String _prefsKey = 'selected_theme_name';

  static final List<AppTheme> availableThemes = [
    const AppTheme(name: '抹茶清茶', seedColor: Color(0xFF81C784)), // Matcha Green
    const AppTheme(name: '海盐冰蓝', seedColor: Color(0xFF64B5F6)), // Ice Blue
    const AppTheme(name: '香芋波波', seedColor: Color(0xFF9575CD)), // Taro Purple
    const AppTheme(name: '落日橘光', seedColor: Color(0xFFFFB74D)), // Sunset Orange
    const AppTheme(name: '樱花粉黛', seedColor: Color(0xFFF06292)), // Sakura Pink
    const AppTheme(name: '图书馆灰', seedColor: Colors.blueGrey), // Library Grey
    const AppTheme(
      name: '通宵修仙',
      seedColor: Color(0xFF5C6BC0),
      brightness: Brightness.dark,
    ), // Night Mode
  ];

  Future<void> setTheme(AppTheme theme) async {
    value = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, theme.name);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefsKey);
    if (name != null) {
      final theme = availableThemes.firstWhere(
        (t) => t.name == name,
        orElse: () => availableThemes.first,
      );
      value = theme;
    }
  }
}
