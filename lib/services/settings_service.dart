import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool isCustom;
  final String? localFilePath;

  const SoundOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isCustom = false,
    this.localFilePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'isCustom': isCustom,
    'localFilePath': localFilePath,
  };

  factory SoundOption.fromJson(Map<String, dynamic> json) => SoundOption(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? 'Custom uploaded audio',
    icon: LucideIcons.music,
    isCustom: true,
    localFilePath: json['localFilePath'] as String?,
  );
}

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  static const String keyFullScreenIntent = 'setting_full_screen_intent';
  static const String keyNotificationSound = 'setting_notification_sound';
  static const String keyCustomSounds = 'setting_custom_sounds_list';

  static const List<SoundOption> bundledSounds = [
    SoundOption(
      id: 'notification',
      name: 'Classic Ping',
      description: 'Standard LMK alert sound',
      icon: LucideIcons.volume2,
    ),
    SoundOption(
      id: 'sound_chime',
      name: 'Crystal Chime',
      description: 'Bright dual-tone bell chime',
      icon: LucideIcons.bell,
    ),
    SoundOption(
      id: 'sound_crystal',
      name: 'Cosmic Crystal',
      description: 'Sparkling ascending crystal arpeggio',
      icon: LucideIcons.gem,
    ),
    SoundOption(
      id: 'sound_zen',
      name: 'Zen Singing Bowl',
      description: 'Deep resonant meditation chime',
      icon: LucideIcons.sun,
    ),
    SoundOption(
      id: 'sound_faahh',
      name: 'Faahh Sound',
      description: 'Authentic expressive vocal sigh',
      icon: LucideIcons.smile,
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
  ];

  static List<SoundOption> get availableSounds => [
    ...bundledSounds,
    ...instance._customSounds,
  ];

  bool _fullScreenIntent = true;
  String _selectedSound = 'notification';
  List<SoundOption> _customSounds = [];

  AudioPlayer? _audioPlayer;
  Timer? _playbackTimer;
  bool _isPlaying = false;
  String? _currentlyPlayingId;

  bool get fullScreenIntent => _fullScreenIntent;
  String get selectedSound => _selectedSound;
  List<SoundOption> get customSounds => List.unmodifiable(_customSounds);
  List<SoundOption> get allSounds => [...bundledSounds, ..._customSounds];
  bool get isPlaying => _isPlaying;
  String? get currentlyPlayingId => _currentlyPlayingId;

  SoundOption get currentSoundOption {
    return allSounds.firstWhere(
      (s) => s.id == _selectedSound,
      orElse: () => bundledSounds.first,
    );
  }

  String getChannelIdForSound([String? soundId]) {
    final s = soundId ?? _selectedSound;
    // Android resource names cannot have dashes or paths
    final cleanId = s.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return 'lmk_reminder_v2_$cleanId';
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fullScreenIntent = prefs.getBool(keyFullScreenIntent) ?? true;

      // Load custom sounds
      final customJsonList = prefs.getStringList(keyCustomSounds) ?? [];
      _customSounds = [];
      for (final raw in customJsonList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final opt = SoundOption.fromJson(map);
          if (opt.localFilePath != null && File(opt.localFilePath!).existsSync()) {
            _customSounds.add(opt);
          }
        } catch (_) {}
      }

      final savedSound = prefs.getString(keyNotificationSound);
      if (savedSound != null &&
          allSounds.any((s) => s.id == savedSound) &&
          savedSound != 'sound_chime') {
        _selectedSound = savedSound;
      } else {
        _selectedSound = 'notification';
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

  /// Lets the user pick an audio file from their device, copies it to safe storage,
  /// and sets it as the active reminder sound.
  Future<SoundOption?> pickAndUploadUserAudio() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );

      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      if (file.path == null) return null;

      final sourceFile = File(file.path!);
      if (!await sourceFile.exists()) return null;

      // Copy to persistent local documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory('${appDir.path}/custom_sounds');
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      final ext = file.extension ?? 'mp3';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\.]'), '_');
      final targetPath = '${soundsDir.path}/${timestamp}_$sanitizedName';

      final savedFile = await sourceFile.copy(targetPath);

      final soundId = 'custom_$timestamp';
      String displayName = file.name;
      if (displayName.contains('.')) {
        displayName = displayName.substring(0, displayName.lastIndexOf('.'));
      }
      if (displayName.length > 24) {
        displayName = '${displayName.substring(0, 24)}...';
      }

      final newOption = SoundOption(
        id: soundId,
        name: displayName,
        description: 'Custom sound (${ext.toUpperCase()})',
        icon: LucideIcons.music,
        isCustom: true,
        localFilePath: savedFile.path,
      );

      _customSounds.add(newOption);
      _selectedSound = soundId;
      await _persistCustomSounds();
      notifyListeners();

      // Play short preview immediately
      await previewSound(soundId, maxDurationSeconds: 4);

      return newOption;
    } catch (e) {
      debugPrint('Error picking and uploading user audio: $e');
      return null;
    }
  }

  /// Deletes a custom user audio file
  Future<void> removeCustomAudio(String soundId) async {
    try {
      final index = _customSounds.indexWhere((s) => s.id == soundId);
      if (index == -1) return;

      final option = _customSounds[index];
      if (option.localFilePath != null) {
        final f = File(option.localFilePath!);
        if (await f.exists()) {
          await f.delete();
        }
      }

      _customSounds.removeAt(index);
      if (_selectedSound == soundId) {
        _selectedSound = bundledSounds.first.id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyNotificationSound, _selectedSound);
      }

      await _persistCustomSounds();
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing custom audio: $e');
    }
  }

  Future<void> _persistCustomSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _customSounds.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(keyCustomSounds, list);
    } catch (e) {
      debugPrint('Error persisting custom sounds: $e');
    }
  }

  /// Plays a quick audio preview for a short duration (defaults to 3.5 seconds)
  Future<void> previewSound(String soundId, {int maxDurationSeconds = 3}) async {
    try {
      // Cancel previous playback
      _playbackTimer?.cancel();
      if (_audioPlayer != null) {
        await _audioPlayer?.stop();
      } else {
        _audioPlayer = AudioPlayer();
      }

      final soundOption = allSounds.firstWhere(
        (s) => s.id == soundId,
        orElse: () => bundledSounds.first,
      );

      _isPlaying = true;
      _currentlyPlayingId = soundId;
      notifyListeners();

      if (soundOption.isCustom && soundOption.localFilePath != null) {
        // Play custom user file directly
        await _audioPlayer?.play(DeviceFileSource(soundOption.localFilePath!));
      } else {
        // Fire Android notification sound channel for built-in sounds
        final flutterNotifications = FlutterLocalNotificationsPlugin();
        final channelId = getChannelIdForSound(soundId);
        final androidDetails = AndroidNotificationDetails(
          channelId,
          'Reminders (${soundOption.name})',
          channelDescription: 'Preview notification sound for ${soundOption.name}',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(soundId),
          playSound: true,
          enableVibration: true,
        );

        await flutterNotifications.show(
          99999,
          'LMK Sound Preview',
          'Playing "${soundOption.name}"',
          NotificationDetails(android: androidDetails),
        );
      }

      // Automatically cut off after short duration as requested
      _playbackTimer = Timer(Duration(seconds: maxDurationSeconds), () async {
        await stopPreview();
      });
    } catch (e) {
      debugPrint('Error playing sound preview: $e');
      _isPlaying = false;
      _currentlyPlayingId = null;
      notifyListeners();
    }
  }

  Future<void> stopPreview() async {
    _playbackTimer?.cancel();
    await _audioPlayer?.stop();
    _isPlaying = false;
    _currentlyPlayingId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
}
