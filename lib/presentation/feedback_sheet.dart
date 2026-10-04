import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/services/feedback_service.dart';
import 'package:lmk/services/update_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const FeedbackSheet(),
    );
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  int _rating = 5;
  FeedbackCategory _category = FeedbackCategory.general;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _includeDeviceInfo = true;
  bool _isSubmitting = false;

  final List<({int rating, String emoji, String label})> _ratings = const [
    (rating: 1, emoji: '😡', label: 'Terrible'),
    (rating: 2, emoji: '😕', label: 'Needs Work'),
    (rating: 3, emoji: '😐', label: 'Okay'),
    (rating: 4, emoji: '😊', label: 'Good'),
    (rating: 5, emoji: '🤩', label: 'Love It!'),
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null && user!.email!.isNotEmpty) {
      _emailController.text = user.email!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit({bool openGitHub = false}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      HapticFeedback.mediumImpact();
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Message required'),
          description: Text('Please share a few words before submitting.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    final item = UserFeedbackItem(
      rating: _rating,
      category: _category,
      message: text,
      userEmail: _emailController.text.trim(),
      appVersion: _includeDeviceInfo ? UpdateService.currentVersion : 'Hidden',
      platform: _includeDeviceInfo
          ? (kIsWeb ? 'Web' : Platform.operatingSystem)
          : 'Hidden',
      createdAt: DateTime.now(),
    );

    await FeedbackService.instance.saveFeedback(item);

    if (openGitHub) {
      await FeedbackService.instance.openGitHubIssue(item);
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ShadToaster.of(context).show(
      ShadToast(
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.primary,
        title: const Text(
          'Thank You! ❤️',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        description: const Text(
          'Your opinion and feedback help make LMK better.',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.90,
          ),
          padding: EdgeInsets.fromLTRB(22, 14, 22, bottomInset + 18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181524) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? const Color(0x30FFFFFF) : const Color(0x15000000),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 90 : 30),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x40FFFFFF) : const Color(0x20000000),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.messageSquareHeart,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share Your Feedback',
                              style: TextStyle(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Tell us what you love or what we can improve',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Rating Emojis Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF221E30) : const Color(0xFFF7F3FB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _ratings.map((item) {
                        final isSelected = _rating == item.rating;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _rating = item.rating);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF332B45) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(isDark ? 50 : 20),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary.withAlpha(120)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.emoji,
                                  style: TextStyle(fontSize: isSelected ? 24 : 20),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Selector Chips
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FeedbackCategory.values.map((cat) {
                      final isSelected = _category == cat;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _category = cat);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? const Color(0xFF221E30) : const Color(0xFFF0ECF5)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Feedback Message Text Input
                  Text(
                    'Your Opinion / Thoughts',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF221E30) : const Color(0xFFF8F5FB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0x25FFFFFF) : const Color(0x15000000),
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 4,
                      minLines: 3,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What do you think of LMK? Tell us what you love or what we could improve...',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary.withAlpha(150),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Diagnostics toggle
                  Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Include app version (v${UpdateService.currentVersion})',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _includeDeviceInfo,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _includeDeviceInfo = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _isSubmitting ? null : () => _handleSubmit(openGitHub: false),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Feedback',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),

                  // Secondary Button: Open as GitHub Issue
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: isDark ? const Color(0x30FFFFFF) : const Color(0x20000000),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : () => _handleSubmit(openGitHub: true),
                    icon: const Icon(LucideIcons.externalLink, size: 16),
                    label: const Text(
                      'Post to GitHub Issues',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
