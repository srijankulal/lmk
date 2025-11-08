import 'package:flutter/material.dart';

/// Central color definitions for your shadcn_ui theme
class AppColors {
  // 🌆 Primary theme colors
  static const Color primary = Color(0xFFFF5B2E); // vivid orange for alerts & FAB
  static const Color secondary = Color(
    0xFF445046,
  ); // deep gray-green background
  static const Color accent = Color(0xFF91A48A); // soft green for highlights

  // 🪄 Backgrounds & surfaces
  static const Color background = Color(0xFFF5F3EB); // light beige paper tone
  static const Color surface = Color(0xFFDAD6C8); // neutral card color
  static const Color surfaceDark = Color(0xFF5E665A); // toolbar / bottom bar

  // ✏️ Text colors
  static const Color textPrimary = Color(0xFF1E1E1E); // main text
  static const Color textSecondary = Color(0xFF5E5E5E); // muted
  static const Color textOnPrimary = Color(0xFFFFFFFF); // white text on accent

  // ⚠️ Status & alerts
  static const Color success = Color(0xFF6BAA75); // renewal success
  static const Color warning = Color(0xFFFFB84D); // upcoming expiry
  static const Color error = Color(0xFFD9534F); // expired or failed

  // 🧱 Borders, shadows, and states
  static const Color border = Color(0xFFBEBEBE);
  static const Color shadow = Color(0x1A000000);
  static const Color disabled = Color(0xFF9C9C9C);

  // 🌿 Card Colors — matches warm beige & dark green-gray
  static const Color cardMoss = Color(
    0xFF616C5F,
  ); // muted moss green — subtle and rich
  static const Color cardSage = Color(0xFF8FA58A); // soft natural green tone
  static const Color cardClay = Color(0xFFE0CBB2); // light earthy beige
  static const Color cardDrift = Color(
    0xFFDAD6C8,
  ); // calm neutral (already used for surface)
  static const Color cardMist = Color(
    0xFFECE8DA,
  ); // pale warm tint for lighter cards
  static const Color cardAmber = Color(
    0xFFFFB77A,
  ); // warm, friendly orange tone
  static const Color cardCoral = Color(
    0xFFFF8B66,
  ); // brighter variant of your primary
  // 🖋 Card Content Colors
  static const Color cardTextDark = Color(0xFF1E1E1E); // for light cards
  static const Color cardTextLight = Color(0xFFFFFFFF); // for dark cards
  static const Color cardSubtitleLight = Color(
    0xFF5E5E5E,
  ); // subtle gray for light cards
  static const Color cardSubtitleDark = Color(
    0xFFE0E0E0,
  ); // soft gray for dark cards
  static const Color cardPillDark = Color(0xFF2E2E2E); // pill on light cards
  static const Color cardPillLight = Color(0xFFECECEC); // pill on dark cards

  // 🌈 Gradient backgrounds
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF475242), Color(0xFF3B433A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
