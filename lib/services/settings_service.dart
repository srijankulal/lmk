import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const SoundOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  static const String keyFullScreenIntent = 'setting_full_screen_intent';
  static const String keyNotificationSound = 'setting_notification_sound';

  static const List<SoundOption> availableSounds = [
    SoundOption(
      id: 'sound_chime',
      name: 'Crystal Chime',
      description: 'Bright dual-tone bell chime',
      icon: LucideIcons.bell,
    ),
    SoundOption(
      id: 'sound_gentle',
      name: 'Warm Marimba',
      description: 'Harmonic resonant wood chord',
      icon: LucideIcons.sparkles,
    ),
    SoundOption(
      id: 'sound_pulse',
      name: 'Tactile Pulse',
      description: 'Modern tactile electronic tick',
      icon: LucideIcons.zap,
    ),
    SoundOption(
      id: 'sound_faahh',
      name: 'Faahh Sound',
      description: 'Expressive resonant vocal tone',
      icon: LucideIcons.smile,
    ),
    SoundOption(
      id: 'notification',
      name: 'Classic Ping',
      description: 'Standard LMK alert sound',
      icon: LucideIcons.volume2,
    ),
  ];

  bool _fullScreenIntent = true;
  String _selectedSound = 'sound_chime';

  bool get fullScreenIntent => _fullScreenIntent;
  String get selectedSound => _selectedSound;

  SoundOption get currentSoundOption {
    return availableSounds.firstWhere(
      (s) => s.id == _selectedSound,
      orElse: () => availableSounds.first,
    );
  }

  String getChannelIdForSound([String? soundId]) {
    final s = soundId ?? _selectedSound;
    return 'lmk_reminder_v2_$s';
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fullScreenIntent = prefs.getBool(keyFullScreenIntent) ?? true;
      final savedSound = prefs.getString(keyNotificationSound);
      if (savedSound != null &&
          availableSounds.any((s) => s.id == savedSound)) {
        _selectedSound = savedSound;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing AppSettings: $e');
    }
  }

  Future<void> setFullScreenIntent(bool enabled) async {
    if (_fullScreenIntent == enabled) return;
    _fullScreenIntent = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyFullScreenIntent, enabled);
    } catch (e) {
      debugPrint('Error saving fullScreenIntent setting: $e');
    }
  }

  Future<void> setNotificationSound(String soundId) async {
    if (_selectedSound == soundId) return;
    _selectedSound = soundId;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyNotificationSound, soundId);
    } catch (e) {
      debugPrint('Error saving notificationSound setting: $e');
    }
  }

  /// Plays a quick preview notification using the selected sound channel
  Future<void> previewSound(String soundId) async {
    try {
      final flutterNotifications = FlutterLocalNotificationsPlugin();
      final channelId = getChannelIdForSound(soundId);
      final soundName = availableSounds
          .firstWhere((s) => s.id == soundId, orElse: () => availableSounds.first)
          .name;

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'Reminders ($soundName)',
        channelDescription: 'Preview notification sound for $soundName',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(soundId),
        playSound: true,
        enableVibration: true,
      );

      await flutterNotifications.show(
        99999, // Unique preview notification ID
        'LMK Sound Preview',
        'Playing "$soundName"',
        NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('Error playing sound preview: $e');
    }
  }
}
