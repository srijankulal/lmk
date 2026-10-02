import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lmk/components/colours/colours.dart';

class AvatarCard extends StatelessWidget {
  final VoidCallback onTap;
  final String name;
  final String imageUrl;
  final bool isOnline;

  const AvatarCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.onTap,
    this.isOnline = true,
  });

  bool get _hasValidCustomImage {
    if (imageUrl.trim().isEmpty) return false;
    // The previous default was a black icon8 png that was invisible on dark backgrounds
    if (imageUrl.contains('icons8.com') && imageUrl.contains('color=000000')) {
      return false;
    }
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final displayName = name.trim().isNotEmpty ? name.trim() : 'User';
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Profile Avatar with glowing border and live status indicator
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF967FE8),
                              Color(0xFFE58F9A),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF967FE8).withAlpha(50),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _hasValidCustomImage
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stackTrace) =>
                                      _buildFallbackAvatar(initial),
                                )
                              : _buildFallbackAvatar(initial),
                        ),
                      ),
                      // Status Dot (Bottom-Right)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? AppColors.success : AppColors.warning,
                            border: Border.all(
                              color: AppColors.background,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isOnline ? AppColors.success : AppColors.warning)
                                    .withAlpha(120),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  // 2. Greeting & User Name (Never wraps vertically)
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Welcome back 👋",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildFallbackAvatar(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
