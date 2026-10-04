import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum FeedbackCategory {
  feature('Feature Request 💡', 'feature'),
  bug('Bug Report 🐛', 'bug'),
  design('Design & UI 🎨', 'design'),
  general('General Opinion 💬', 'general');

  final String label;
  final String key;
  const FeedbackCategory(this.label, this.key);
}

class UserFeedbackItem {
  final int rating; // 1-5
  final FeedbackCategory category;
  final String message;
  final String userEmail;
  final String appVersion;
  final String platform;
  final DateTime createdAt;

  UserFeedbackItem({
    required this.rating,
    required this.category,
    required this.message,
    required this.userEmail,
    required this.appVersion,
    required this.platform,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'category': category.key,
    'message': message,
    'userEmail': userEmail,
    'appVersion': appVersion,
    'platform': platform,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserFeedbackItem.fromJson(Map<String, dynamic> json) => UserFeedbackItem(
    rating: json['rating'] as int? ?? 5,
    category: FeedbackCategory.values.firstWhere(
      (c) => c.key == json['category'],
      orElse: () => FeedbackCategory.general,
    ),
    message: json['message'] as String? ?? '',
    userEmail: json['userEmail'] as String? ?? '',
    appVersion: json['appVersion'] as String? ?? '',
    platform: json['platform'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  static const String _storageKey = 'lmk_user_feedback_history';

  /// Save feedback locally to persistent storage
  Future<void> saveFeedback(UserFeedbackItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey) ?? [];
      list.add(jsonEncode(item.toJson()));
      await prefs.setStringList(_storageKey, list);
    } catch (e) {
      debugPrint('Error saving user feedback locally: $e');
    }
  }

  /// Get all past feedback entries submitted on this device
  Future<List<UserFeedbackItem>> getFeedbackHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey) ?? [];
      return list
          .map((str) => UserFeedbackItem.fromJson(jsonDecode(str) as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Open GitHub Issue creation with prefilled title and markdown body
  Future<bool> openGitHubIssue(UserFeedbackItem item) async {
    try {
      final title = Uri.encodeComponent('[${item.category.label}] ${item.message.split('\n').first.take(50)}');
      final body = Uri.encodeComponent(
        '### Category\n${item.category.label}\n\n'
        '### Rating\n${_ratingStars(item.rating)}\n\n'
        '### Opinion / Feedback\n${item.message}\n\n'
        '---\n'
        '**App Version**: ${item.appVersion}\n'
        '**Platform**: ${item.platform}\n'
        '**User**: ${item.userEmail.isNotEmpty ? item.userEmail : "Anonymous"}\n',
      );

      final url = 'https://github.com/srijankulal/lmk/issues/new?title=$title&body=$body';
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening GitHub issue: $e');
      return false;
    }
  }

  static String _ratingStars(int rating) {
    switch (rating) {
      case 1:
        return '⭐ (1/5 - Terrible)';
      case 2:
        return '⭐⭐ (2/5 - Poor)';
      case 3:
        return '⭐⭐⭐ (3/5 - Okay)';
      case 4:
        return '⭐⭐⭐⭐ (4/5 - Good)';
      case 5:
      default:
        return '⭐⭐⭐⭐⭐ (5/5 - Love it!)';
    }
  }
}

extension _StringTake on String {
  String take(int n) => length <= n ? this : '${substring(0, n)}...';
}
