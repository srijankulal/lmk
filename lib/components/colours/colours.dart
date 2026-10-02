import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central theme mode controller for the entire application
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString('theme_mode');
      if (modeStr != null) {
        _themeMode = modeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'theme_mode',
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'theme_mode',
        mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {}
  }
}

/// Central color definitions for the Minimalist Expressive Light & Dark Theme
/// Directly inspired by the reference design:
/// - Light: Soft alabaster lavender canvas with vibrant sunset gradient highlights
/// - Dark: Deep obsidian velvet canvas with high contrast and glowing gradient highlights
class AppColors {
  // 🌆 Primary brand colors
  static const Color primary = Color(0xFF8B5CF6); // Modern Iris / Lavender
  static const Color primaryDark = Color(0xFF1E1B2E);
  static const Color primaryHover = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF1E1B2E);
  static const Color accent = Color(0xFFF59E0B); // Honey Amber Highlight
  static const Color accentCoral = Color(0xFFFF6B6B);
  static const Color accentLavender = Color(0xFFB8A5E8);

  // 🪄 Dynamic Canvas & Surfaces
  static Color get background =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF121019) // Velvet obsidian matching Reference Screen 3
          : const Color(0xFFF4EFF8); // Soft alabaster lavender

  static Color get backgroundCard =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF1E1B29)
          : const Color(0xFFFFFFFF);

  static Color get surface =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF1E1B29)
          : const Color(0xFFFFFFFF);

  static Color get surfaceGlass =>
      ThemeController.instance.isDarkMode
          ? const Color(0xF01E1B29)
          : const Color(0xF2FFFFFF);

  static Color get surfaceDark => const Color(0xFF1E1B2E);

  static Color get surfaceLight =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF282436)
          : const Color(0xFFEDE7F4);

  static Color get surfaceMuted =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF231F30)
          : const Color(0xFFECE7F4);

  // ✏️ Dynamic Text colors
  static Color get textPrimary =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF191622);

  static Color get textSecondary =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFFA29BB5)
          : const Color(0xFF706A82);

  static Color get textTertiary =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF6E6882)
          : const Color(0xFF9E98AD);

  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ⚠️ Status & alerts
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // 🧱 Dynamic Borders, shadows, and states
  static Color get border =>
      ThemeController.instance.isDarkMode
          ? const Color(0x28FFFFFF)
          : const Color(0x181C1924);

  static Color get borderSubtle =>
      ThemeController.instance.isDarkMode
          ? const Color(0x18FFFFFF)
          : const Color(0x0E1C1924);

  static const Color borderFocus = Color(0x808B5CF6);

  static Color get shadow =>
      ThemeController.instance.isDarkMode
          ? const Color(0x60000000)
          : const Color(0x141C1924);

  static const Color disabled = Color(0xFF9E98AD);

  // 🌅 Signature Gradient Card Palettes (Expressive & Minimalist)
  static const List<LinearGradient> lightCardGradients = [
    // 1. Sunset Lavender (Hero Card in reference image Screen 1)
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF967FE8), Color(0xFFE58F9A), Color(0xFFF6C665)],
      stops: [0.0, 0.52, 1.0],
    ),
    // 2. Warm Honey Amber (Summary card in reference image Screen 2)
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE89838), Color(0xFFF5BF56)],
    ),
    // 3. Blush Mauve (Statistic card in reference image Screen 2)
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFCA829F), Color(0xFFDF9DB8)],
    ),
    // 4. Cool Iris Twilight
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7261DD), Color(0xFF9C8BF2)],
    ),
    // 5. Emerald Jade
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF459A89), Color(0xFF72C2B1)],
    ),
    // 6. Sunset Coral
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFDE6350), Color(0xFFF2976D)],
    ),
  ];

  static const List<LinearGradient> darkCardGradients = [
    // 1. Velvet Sunset Lavender (Deep jewel tones with high contrast for obsidian)
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6E56CE), Color(0xFFA8516F), Color(0xFFC7842B)],
      stops: [0.0, 0.52, 1.0],
    ),
    // 2. Deep Honey Amber (Matching Reference Screen 3 glowing amber)
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB86B14), Color(0xFFD9962B)],
    ),
    // 3. Velvet Mauve
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8E4467), Color(0xFFB25B81)],
    ),
    // 4. Velvet Iris Twilight
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF523EB8), Color(0xFF7763D9)],
    ),
    // 5. Velvet Emerald Jade
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2B7062), Color(0xFF4D9B8C)],
    ),
    // 6. Velvet Sunset Coral
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFA83E2D), Color(0xFFCA6947)],
    ),
  ];

  static List<LinearGradient> get cardGradients =>
      ThemeController.instance.isDarkMode ? darkCardGradients : lightCardGradients;

  // Backward compatibility constants
  static const Color cardMoss = Color(0xFF4E9F8E);
  static const Color cardSage = Color(0xFFCE8AA5);
  static const Color cardClay = Color(0xFFE5983A);
  static const Color cardDrift = Color(0xFF9D84E2);
  static const Color cardMist = Color(0xFFFAF8FC);
  static const Color cardAmber = Color(0xFFF5BD58);
  static const Color cardCoral = Color(0xFFE06A58);
  static const Color cardSky = Color(0xFF7565D8);
  static const Color cardMint = Color(0xFF7EC8B7);
  static const Color cardApricot = Color(0xFFF29B72);
  static const Color cardPink = Color(0xFFE0A3BD);
  static const Color cardLavender = Color(0xFFB8A5E8);
  static const Color cardLightBlue = Color(0xFF9E8EF0);
  static const Color cardSoftYellow = Color(0xFFF6C865);
  static const Color cardPeach = Color(0xFFE29E93);
  static const Color cardMauve = Color(0xFFCE8AA5);
  static const Color cardPeriwinkle = Color(0xFF9D84E2);
  static const Color cardLightGreen = Color(0xFF4E9F8E);
  static const Color cardAqua = Color(0xFF7EC8B7);
  static const Color cardRose = Color(0xFFD49FB4);
  static const Color cardLemon = Color(0xFFF5BD58);
  static const Color cardStone = Color(0xFFECE7F4);

  static const Color cardTextDark = Color(0xFF1C1924);
  static const Color cardTextLight = Color(0xFFFFFFFF);
  static const Color cardSubtitleLight = Color(0xCCFFFFFF);
  static const Color cardSubtitleDark = Color(0xFF716B82);
  static const Color cardPillDark = Color(0x18000000);
  static const Color cardPillLight = Color(0x38FFFFFF);

  // 🌈 Gradient backgrounds
  static LinearGradient get canvasGradient => LinearGradient(
        colors:
            ThemeController.instance.isDarkMode
                ? [const Color(0xFF121019), const Color(0xFF1A1725)]
                : [const Color(0xFFF4EFF8), const Color(0xFFFAF7FC)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get glassGradient => LinearGradient(
        colors:
            ThemeController.instance.isDarkMode
                ? [const Color(0xB31E1B29), const Color(0x801E1B29)]
                : [const Color(0xB3FFFFFF), const Color(0x80FFFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
