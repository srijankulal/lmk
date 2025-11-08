import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.mainColor = const Color(0xFFFF6A00),
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

    // Wrap the whole fab area with a container that provides a subtle outer shadow.
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
              right: (safeRight > 0 ? safeRight : 16) + 72, // space for FAB
              bottom: (safeBottom > 0 ? safeBottom : 16),
            ),
            child: AnimatedBuilder(
              animation: _expand,
              builder: (context, _) {
                final t = _expand.value;
                // Wider for bigger buttons + more spacing
                final targetWidth = (widget.actions.length * 80.0) + 10.0;
                final width = targetWidth * t;

                return IgnorePointer(
                  ignoring: t < 0.95,
                  child: Opacity(
                    opacity: t,
                    child: _LiquidGlassPill(
                      child: SizedBox(
                        width: width,
                        height: 68, // taller pill for bigger buttons
                        child:
                            t <
                                0.95 // Only show buttons when pill is 85% expanded
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ), // more padding
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
                                        right: isLast ? 0 : 12.0,
                                      ), // spacing between buttons
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

          // Main circular FAB (bigger and perfectly circular)
          Padding(
            padding: EdgeInsets.only(
              right: safeRight > 0 ? safeRight : 16,
              bottom: safeBottom > 0 ? safeBottom : 16,
            ),
            child: Material(
              color: widget.mainColor,
              elevation: 6,
              shadowColor: Colors.black.withAlpha(30),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _toggle,
                customBorder: const CircleBorder(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    // subtle layered shadows to give the whole widget a light lift
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        spreadRadius: -4,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        spreadRadius: -2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  width: 64, // bigger circular button
                  height: 64,
                  alignment: Alignment.center,
                  child: AnimatedRotation(
                    turns: _open ? 0.125 : 0.0,
                    duration: widget.duration,
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.add_rounded,
                      size: 28,
                      color: Colors.black,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withAlpha(75), Colors.white.withAlpha(8)],
            ),
            border: Border.all(color: Colors.white.withAlpha(100), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
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
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          width: 60, // bigger button
          height: 60,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Colors.black87,
            size: 30, // bigger icon
          ),
        ),
      ),
    );
  }
}
