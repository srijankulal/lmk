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
  // 🌆 Primary brand colors (Extracted directly from LMK 3D Logo)
  static const Color primary = Color(0xFFFF5722); // Vibrant LMK Orange
  static const Color primaryDark = Color(0xFFD84315);
  static const Color primaryHover = Color(0xFFFF7A45);
  static const Color secondary = Color(0xFF2E3A3B); // Charcoal Slate from Logo
  static const Color accent = Color(0xFFFF5722); // LMK Orange Highlight
  static const Color accentCoral = Color(0xFFFF7A45);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color charcoalSlate = Color(0xFF2E3A3B);
  static const Color charcoalDeep = Color(0xFF1E2526);
  static const Color obsidianDark = Color(0xFF101516);

  // 🪄 Dynamic Canvas & Surfaces
  static Color get background =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF101516) // Deep Obsidian Charcoal
          : const Color(0xFFF1F2E8); // Warm Bone / Linen Paper Cream

  static Color get backgroundCard =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF181F20)
          : const Color(0xFFFBFBFA);

  static Color get surface =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF181F20)
          : const Color(0xFFFBFBFA);

  static Color get surfaceGlass =>
      ThemeController.instance.isDarkMode
          ? const Color(0xB31E2628) // Translucent Frosted Dark Glass
          : const Color(0xF2FBFBFA); // Soft Translucent Paper

  static Color get surfaceDark => const Color(0xFF181F20);

  static Color get surfaceLight =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF222B2D)
          : const Color(0xFFE8EADE);

  static Color get surfaceMuted =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF1B2324)
          : const Color(0xFFE2E4D8);

  // ✏️ Dynamic Text colors
  static Color get textPrimary =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF1C2324); // Ink Charcoal

  static Color get textSecondary =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFFD8DAD0)
          : const Color(0xFF606967);

  static Color get textTertiary =>
      ThemeController.instance.isDarkMode
          ? const Color(0xFF838F8D)
          : const Color(0xFF8C9490);

  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ⚠️ Status & alerts
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // 🧱 Dynamic Borders, shadows, and states
  static Color get border =>
      ThemeController.instance.isDarkMode
          ? const Color(0x2BFFFFFF) // Top specular highlight
          : const Color(0xFFE2E4D8); // Subtle warm hairline border

  static Color get borderSubtle =>
      ThemeController.instance.isDarkMode
          ? const Color(0x18FFFFFF)
          : const Color(0x1F2E3A3B);

  static const Color borderFocus = Color(0x80FF5722);

  static Color get shadow =>
      ThemeController.instance.isDarkMode
          ? const Color(0x80000000)
          : const Color(0x122E3A3B);

  static const Color disabled = Color(0xFF8C9490);

  // 🌅 Signature Gradient Card Palettes (Tactile Editorial & 3D Glass)
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5722), Color(0xFFFF7A45)],
  );

  static const LinearGradient charcoalHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E3A3B), Color(0xFF1E2526)],
  );

  static const LinearGradient darkGlassHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xCC2A3537), Color(0x991E2628)],
  );

  static const List<LinearGradient> lightCardGradients = [
    // 1. Charcoal Slate Hero (High-contrast from logo)
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2E3A3B), Color(0xFF1E2526)],
    ),
    // 2. Vibrant LMK Orange Sunset
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF5722), Color(0xFFFF8A50)],
    ),
    // 3. Warm Honey Amber
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    ),
    // 4. Olive Sage
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3B5249), Color(0xFF517265)],
    ),
    // 5. Deep Slate Twilight
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF333E50), Color(0xFF475569)],
    ),
    // 6. Warm Terracotta
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB45309), Color(0xFFD97706)],
    ),
    // 7. Midnight Indigo
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF312E81), Color(0xFF4338CA)],
    ),
    // 8. Emerald Jade
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF047857), Color(0xFF059669)],
    ),
    // 9. Royal Velvet Plum
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
    ),
    // 10. Crimson Rose
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFBE123C), Color(0xFFE11D48)],
    ),
    // 11. Oceanic Cyan
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    ),
    // 12. Warm Bronze
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9A3412), Color(0xFFC2410C)],
    ),
  ];

  static const List<LinearGradient> darkCardGradients = [
    // 1. Dark 3D Frosted Glass Hero
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xCC263234), Color(0x991A2223)],
    ),
    // 2. Radiant LMK Orange
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD84315), Color(0xFFFF5722)],
    ),
    // 3. Glowing Amber
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
    ),
    // 4. Dark Emerald Slate
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF134E4A), Color(0xFF0F766E)],
    ),
    // 5. Dark Twilight
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E293B), Color(0xFF334155)],
    ),
    // 6. Deep Obsidian Charcoal
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1F292B), Color(0xFF141C1D)],
    ),
    // 7. Midnight Indigo
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E1B4B), Color(0xFF2E2B5F)],
    ),
    // 8. Emerald Jade
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF064E3B), Color(0xFF0D624B)],
    ),
    // 9. Royal Velvet Plum
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4C1D95), Color(0xFF5B21B6)],
    ),
    // 10. Crimson Rose
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF881337), Color(0xFF9F1239)],
    ),
    // 11. Oceanic Cyan
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF075985), Color(0xFF0C4A6E)],
    ),
    // 12. Warm Bronze
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7C2D12), Color(0xFF8C3316)],
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
