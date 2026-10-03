import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lmk/auth/services/google_auth.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthMethods().signInWithGoogle(context);
    } catch (e) {
      // Handle error if needed, usually AuthMethods handles it or returns null
      print("Sign in error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            top: -80,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withAlpha(45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withAlpha(35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Logo / Icon
                  ScaleTransition(
                    scale: _fadeAnimation,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGlass,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(16),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: AppColors.primary.withAlpha(20),
                            blurRadius: 30,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 62,
                            height: 62,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.notifications_active_rounded,
                              size: 42,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Welcome Text
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "LMK",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "• LET ME KNOW",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Welcome Back",
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.6,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Sign in to sync your smart reminders\nseamlessly across all your devices.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Sign In Buttons
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          else ...[
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ShadButton(
                                width: double.infinity,
                                height: 54,
                                backgroundColor: isDark
                                    ? const Color(0xFF1E1B29)
                                    : Colors.white,
                                hoverBackgroundColor: isDark
                                    ? const Color(0xFF282436)
                                    : const Color(0xFFF8FAFC),
                                onPressed: _handleSignIn,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      size: 32,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Continue with Google",
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ShadButton.outline(
                              width: double.infinity,
                              height: 54,
                              backgroundColor: AppColors.surface.withAlpha(200),
                              onPressed: _guestSignIn,
                              child: Text(
                                "Continue as Guest",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            "By continuing, you agree to our Terms & Privacy Policy",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textTertiary.withAlpha(180),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Future<void> _guestSignIn() async {
    final pageContext = context;
    setState(() => _isLoading = true);
    showGeneralDialog(
      context: pageContext,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (dlgCtx, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  LucideIcons.user,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Continue as Guest",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "Your reminders will be stored locally on this device. You can sign in anytime later to sync your data to the cloud.",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(dlgCtx).pop();
                                  setState(() => _isLoading = false);
                                },
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                              const Spacer(),
                              ShadButton(
                                backgroundColor: AppColors.primary,
                                child: const Text("Continue"),
                                onPressed: () async {
                                  Navigator.of(dlgCtx).pop();

                                  final nameController = TextEditingController();
                                  final name = await showDialog<String>(
                                    context: pageContext,
                                    builder: (nameCtx) => Center(
                                      child: Container(
                                        constraints:
                                            const BoxConstraints(maxWidth: 340),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              border: Border.all(
                                                color: AppColors.border,
                                                width: 1.0,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withAlpha(20),
                                                  blurRadius: 30,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(22),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  "What should we call you?",
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 14),
                                                TextField(
                                                  controller: nameController,
                                                  autofocus: true,
                                                  style: TextStyle(
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: "Enter your name",
                                                    hintStyle: TextStyle(
                                                      color: AppColors
                                                          .textSecondary
                                                          .withAlpha(120),
                                                    ),
                                                    filled: true,
                                                    fillColor: AppColors
                                                        .surfaceLight,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      borderSide: BorderSide(
                                                        color: AppColors.border,
                                                      ),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      borderSide: BorderSide(
                                                        color: AppColors.border,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              nameCtx),
                                                      child: Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ShadButton(
                                                      backgroundColor:
                                                          AppColors.primary,
                                                      onPressed: () {
                                                        if (nameController.text
                                                            .trim()
                                                            .isEmpty) return;
                                                        Navigator.pop(
                                                          nameCtx,
                                                          nameController.text
                                                              .trim(),
                                                        );
                                                      },
                                                      child: const Text(
                                                          "Get Started"),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );

                                  if (name != null && name.isNotEmpty) {
                                    await AuthMethods()
                                        .signInAsGuest(pageContext, name: name);
                                  } else {
                                    setState(() => _isLoading = false);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
