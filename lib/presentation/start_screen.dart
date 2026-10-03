import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingItem {
  final String title;
  final String description;
  final IconData? icon;
  final Widget? customWidget;

  OnboardingItem({
    required this.title,
    required this.description,
    this.icon,
    this.customWidget,
  });
}

class StartScreen extends StatefulWidget {
  final bool isTour;
  const StartScreen({super.key, this.isTour = false});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: "Welcome to LMK",
      description:
          "Never forget the little things.\nSimple, elegant reminders for documents, warranties & tasks.",
      icon: LucideIcons.sparkles,
    ),
    OnboardingItem(
      title: "3 Ways to Create",
      description:
          "Tap (+) to create reminders in seconds:\n📸 Camera OCR Scan, 🖼️ Gallery Photo, or ✍️ Manual Entry.",
      customWidget: const _CreationButtonsExampleWidget(),
    ),
    OnboardingItem(
      title: "Swipe to Delete",
      description:
          "Swipe right on any reminder to delete it.\nKeep your list clean and tidy.",
      customWidget: const _SwipeExampleWidget(),
    ),
    OnboardingItem(
      title: "Tap to Edit Details",
      description:
          "Need to change date or time?\nJust tap any card to view and edit details.",
      customWidget: const _TapExampleWidget(),
    ),
    OnboardingItem(
      title: "Deck Stage vs Stream",
      description:
          "Switch your view anytime in the top header:\nFlip through 3D cards or scan the compact Stream List.",
      icon: LucideIcons.layers,
    ),
    OnboardingItem(
      title: "One-Touch Smart Filters",
      description:
          "Filter by All, Active, Disabled, or tap Urgent\nto spotlight anything due in 3 days or less.",
      icon: LucideIcons.flame,
    ),
    OnboardingItem(
      title: "Full-Screen Alerts & Sounds",
      description:
          "Alarms wake your phone even when locked.\nDismissing pauses the reminder. Pick custom sounds in Settings.",
      icon: LucideIcons.bellRing,
    ),
    OnboardingItem(
      title: "Offline Guest or Synced",
      description:
          "Use 100% offline as a Guest with local privacy,\nor sign in with Google to backup across devices.",
      icon: LucideIcons.shieldCheck,
    ),
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    if (widget.isTour) {
      Navigator.of(context).pop();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Ambient Background Glows
              Positioned(
                top: -100,
                left: -60,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withAlpha(isDark ? 35 : 45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                right: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withAlpha(isDark ? 25 : 35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar (Skip / Close)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            widget.isTour ? "Close" : "Skip",
                            style: TextStyle(
                              color: AppColors.textSecondary.withAlpha(180),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _items.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon or Custom Animated Demonstration
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: item.customWidget ??
                                        Container(
                                          width: 130,
                                          height: 130,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1E1B29)
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(36),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                  isDark ? 50 : 16,
                                                ),
                                                blurRadius: 30,
                                                offset: const Offset(0, 10),
                                              ),
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withAlpha(
                                                        isDark ? 35 : 20),
                                                blurRadius: 24,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0x30FFFFFF)
                                                  : AppColors.border,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              item.icon,
                                              size: 52,
                                              color: item.icon ==
                                                      LucideIcons.flame
                                                  ? const Color(0xFFEF4444)
                                                  : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                  ),
                                ),

                                const SizedBox(height: 44),

                                // Text Content
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Column(
                                      children: [
                                        Text(
                                          item.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                                letterSpacing: -0.6,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          item.description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                                height: 1.5,
                                                fontSize: 15.5,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom Controls
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 36),
                      child: Column(
                        children: [
                          // Page Indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _items.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3.5),
                                height: 6,
                                width: _currentPage == index ? 24 : 6,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? AppColors.primary
                                      : (isDark
                                          ? Colors.white.withAlpha(45)
                                          : Colors.black.withAlpha(25)),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Action Button
                          ShadButton(
                            width: double.infinity,
                            height: 52,
                            backgroundColor: AppColors.primary,
                            onPressed: _nextPage,
                            child: Text(
                              _currentPage == _items.length - 1
                                  ? (widget.isTour ? "Done" : "Get Started")
                                  : "Next",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// Interactive 3-Way Creation Action Buttons Widget
// -------------------------------------------------------------
class _CreationButtonsExampleWidget extends StatelessWidget {
  const _CreationButtonsExampleWidget();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B29) : Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 16),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.primary.withAlpha(isDark ? 35 : 20),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0x30FFFFFF) : AppColors.border,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBtn(LucideIcons.camera, const Color(0xFF10B981), isDark),
              _buildBtn(LucideIcons.images, const Color(0xFF38BDF8), isDark),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBtn(LucideIcons.squarePen, const Color(0xFFF59E0B), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(IconData icon, Color color, bool isDark) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 40 : 25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Center(
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// -------------------------------------------------------------
// Interactive Swipe-to-Delete Demonstration
// -------------------------------------------------------------
class _SwipeExampleWidget extends StatefulWidget {
  const _SwipeExampleWidget();

  @override
  State<_SwipeExampleWidget> createState() => _SwipeExampleWidgetState();
}

class _SwipeExampleWidgetState extends State<_SwipeExampleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    return SizedBox(
      height: 110,
      width: 280,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Delete Action Background
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
              ),
              border: Border.all(
                color: Colors.redAccent.withAlpha(60),
                width: 1,
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(
              LucideIcons.trash2,
              color: Colors.white,
              size: 24,
            ),
          ),
          // The Card
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final slide = CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeInOut,
                  ).value *
                  80;
              return Transform.translate(
                offset: Offset(slide, 0),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1B29) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 45 : 15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: isDark ? const Color(0x30FFFFFF) : AppColors.border,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withAlpha(200),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 50,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withAlpha(120),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Interactive Tap-to-Edit Demonstration
// -------------------------------------------------------------
class _TapExampleWidget extends StatefulWidget {
  const _TapExampleWidget();

  @override
  State<_TapExampleWidget> createState() => _TapExampleWidgetState();
}

class _TapExampleWidgetState extends State<_TapExampleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    return SizedBox(
      height: 110,
      width: 280,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double scale = 1.0;
            double opacity = 0.0;

            if (_controller.value > 0.4 && _controller.value < 0.6) {
              scale = 0.95;
              opacity = 1.0;
            } else if (_controller.value >= 0.6 && _controller.value < 0.8) {
              scale = 1.0;
              opacity = 0.0;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1B29) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 45 : 15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: isDark
                            ? const Color(0x30FFFFFF)
                            : AppColors.border,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withAlpha(200),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 13,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 50,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withAlpha(120),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Touch Indicator
                Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withAlpha(50),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(150),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
