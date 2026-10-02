import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lmk/components/colours/colours.dart';

class FabAction {
  final IconData icon;
  final VoidCallback onTap;

  const FabAction({required this.icon, required this.onTap});
}

class GlassExpandableFab extends StatefulWidget {
  final List<FabAction> actions;
  final Color mainColor;
  final Duration duration;

  const GlassExpandableFab({
    super.key,
    required this.actions,
    this.mainColor = AppColors.primary,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<GlassExpandableFab> createState() => _GlassExpandableFabState();
}

class _GlassExpandableFabState extends State<GlassExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expand;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _expand = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeRight = media.padding.right;
    final safeBottom = media.padding.bottom;

    return SizedBox(
      width: media.size.width,
      height: 100 + safeBottom,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Tap outside to close
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_open,
              child: AnimatedOpacity(
                duration: widget.duration,
                opacity: _open ? 1 : 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                ),
              ),
            ),
          ),

          // Glass pill bar (expands from right)
          Padding(
            padding: EdgeInsets.only(
              right: (safeRight > 0 ? safeRight : 16) + 72,
              bottom: (safeBottom > 0 ? safeBottom : 16),
            ),
            child: AnimatedBuilder(
              animation: _expand,
              builder: (context, _) {
                final t = _expand.value;
                final extraWidth =
                    MediaQuery.of(context).size.width - 160 - safeRight;
                final targetWidth =
                    (widget.actions.length * 50.0) + 10.0 + extraWidth * 0.2;
                final width = targetWidth * t;

                return IgnorePointer(
                  ignoring: t < 0.95,
                  child: Opacity(
                    opacity: t,
                    child: _LiquidGlassPill(
                      child: SizedBox(
                        width: width,
                        height: 64,
                        child: t < 0.95
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: widget.actions.asMap().entries.map((
                                    entry,
                                  ) {
                                    final isLast =
                                        entry.key == widget.actions.length - 1;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: isLast ? 0 : 10.0,
                                      ),
                                      child: _GlassIconButton(
                                        icon: entry.value.icon,
                                        onTap: () {
                                          if (_open) _toggle();
                                          entry.value.onTap();
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main circular FAB
          Padding(
            padding: EdgeInsets.only(
              right: safeRight > 0 ? safeRight : 16,
              bottom: safeBottom > 0 ? safeBottom : 16,
            ),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF7C3AED),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(90),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _toggle,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: AnimatedRotation(
                      turns: _open ? 0.125 : 0.0,
                      duration: widget.duration,
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.add_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidGlassPill extends StatelessWidget {
  final Widget child;

  const _LiquidGlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode;
        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: isDark
                    ? const Color(0xF21E1B29)
                    : Colors.white.withAlpha(245),
                border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceLight,
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
