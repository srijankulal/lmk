import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppReleaseInfo {
  final String version;
  final String tagName;
  final String title;
  final String changelog;
  final String htmlUrl;
  final String? downloadUrl;
  final DateTime publishedAt;
  final bool isPrerelease;

  AppReleaseInfo({
    required this.version,
    required this.tagName,
    required this.title,
    required this.changelog,
    required this.htmlUrl,
    this.downloadUrl,
    required this.publishedAt,
    this.isPrerelease = false,
  });

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tagName = (json['tag_name'] as String? ?? '').trim();
    // Clean tag name e.g. "v0.1.1" -> "0.1.1"
    final version = tagName.startsWith('v') || tagName.startsWith('V')
        ? tagName.substring(1)
        : tagName;

    String? apkDownloadUrl;
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkDownloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
    }

    final publishedStr = json['published_at'] as String?;
    final publishedAt = publishedStr != null
        ? DateTime.tryParse(publishedStr) ?? DateTime.now()
        : DateTime.now();

    return AppReleaseInfo(
      version: version,
      tagName: tagName,
      title: json['name'] as String? ?? 'LMK Release $tagName',
      changelog: json['body'] as String? ?? 'Bug fixes and performance improvements.',
      htmlUrl: json['html_url'] as String? ?? 'https://github.com/srijankulal/lmk/releases',
      downloadUrl: apkDownloadUrl ?? json['html_url'] as String?,
      publishedAt: publishedAt,
      isPrerelease: json['prerelease'] as bool? ?? false,
    );
  }
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static String _version = '0.1.1-alpha';
  static int _buildNumber = 2;

  static String get currentVersion => _version;
  static int get currentBuildNumber => _buildNumber;

  /// Loads the actual runtime package version from platform
  Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        _version = info.version;
        _buildNumber = int.tryParse(info.buildNumber) ?? _buildNumber;
        debugPrint('UpdateService initialized with app version: $_version (+$_buildNumber)');
      }
    } catch (e) {
      debugPrint('Failed to load package info: $e');
    }
  }
  static const String githubRepo = 'srijankulal/lmk';
  static const String _dismissedKey = 'lmk_dismissed_update_version';
  static const String _dismissedTimeKey = 'lmk_dismissed_update_time';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'LMK-App-UpdateChecker',
      },
    ),
  );

  /// Check if a newer version exists on GitHub Releases.
  /// If [force] is true, checks regardless of previous dismissal.
  Future<AppReleaseInfo?> checkForUpdate({bool force = false}) async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$githubRepo/releases',
      );

      if (response.statusCode != 200 || response.data == null) {
        return null;
      }

      final List<dynamic> releases = response.data is List ? response.data : [response.data];
      if (releases.isEmpty) return null;

      // Find the most recent applicable release
      final latestJson = releases.first as Map<String, dynamic>;
      final release = AppReleaseInfo.fromJson(latestJson);

      final isNewer = isVersionNewer(release.version, currentVersion);
      if (!isNewer) return null;

      if (!force) {
        final prefs = await SharedPreferences.getInstance();
        final dismissedVersion = prefs.getString(_dismissedKey);
        final dismissedTimeMillis = prefs.getInt(_dismissedTimeKey) ?? 0;
        final dismissedTime = DateTime.fromMillisecondsSinceEpoch(dismissedTimeMillis);

        // If user dismissed this exact version within 24 hours, don't nag them
        if (dismissedVersion == release.version &&
            DateTime.now().difference(dismissedTime).inHours < 24) {
          return null;
        }
      }

      return release;
    } catch (e) {
      debugPrint('Update check error: $e');
      return null;
    }
  }

  /// Compares semantic versions (e.g., "0.1.1" vs "0.1.0-alpha")
  static bool isVersionNewer(String remote, String current) {
    if (remote.trim().isEmpty) return false;
    if (remote.trim() == current.trim()) return false;

    try {
      final remoteParts = _parseVersion(remote);
      final currentParts = _parseVersion(current);

      for (int i = 0; i < 3; i++) {
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }

      // If numeric segments (major, minor, patch) are identical,
      // a clean release (e.g. 0.1.0) is newer than pre-release (0.1.0-alpha)
      final remoteHasPre = remote.contains('-');
      final currentHasPre = current.contains('-');
      if (!remoteHasPre && currentHasPre) return true;

      return false;
    } catch (_) {
      return remote != current;
    }
  }

  static List<int> _parseVersion(String ver) {
    // Strip "v" and anything after "-" or "+"
    var clean = ver.trim().toLowerCase();
    if (clean.startsWith('v')) clean = clean.substring(1);
    if (clean.contains('-')) clean = clean.split('-').first;
    if (clean.contains('+')) clean = clean.split('+').first;

    final parts = clean.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts.sublist(0, 3);
  }

  /// Mark release version as dismissed for 24h
  Future<void> dismissVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedKey, version);
      await prefs.setInt(_dismissedTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Open release or download page in browser
  Future<bool> launchDownload(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch download url: $e');
      return false;
    }
  }
}
