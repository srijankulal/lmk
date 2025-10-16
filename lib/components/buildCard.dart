import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/main/home.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Reminder {
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  Reminder({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}

class BuildCard extends StatefulWidget {
  final List<Reminder> reminders;

  const BuildCard({super.key, required this.reminders});

  @override
  State<BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends State<BuildCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.00),
      child: widget.reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "No reminders",
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.sentiment_satisfied,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ShadIconButton(
                    backgroundColor: AppColors.primary,
                    shadows: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .4),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    icon: const Icon(LucideIcons.plus600, color: Colors.white),
                    onPressed: () {
                      // Action to add a new reminder
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Add Reminder'),
                            content: Text(
                              'Functionality to add a new reminder goes here.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              itemCount: widget.reminders.length,
              itemBuilder: (context, index) {
                final reminder = widget.reminders[index];
                final fadeAnim = CurvedAnimation(
                  parent: _controller,
                  curve: Interval((index * 0.1), 1.0, curve: Curves.easeOut),
                );

                return Align(
                  heightFactor: 0.65,
                  child: AnimatedBuilder(
                    animation: fadeAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - fadeAnim.value)),
                        child: Opacity(
                          opacity: fadeAnim.value,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: _NeumorphicReminderCard(reminder: reminder),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _NeumorphicReminderCard extends StatefulWidget {
  final Reminder reminder;

  const _NeumorphicReminderCard({required this.reminder});

  @override
  State<_NeumorphicReminderCard> createState() =>
      _NeumorphicReminderCardState();
}

class _NeumorphicReminderCardState extends State<_NeumorphicReminderCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() => _isPressed = false);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.background.withAlpha(1000),
              width: 1,
            ),
          ),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: _isPressed ? -4 : 6,
              intensity: _isPressed ? 0.9 : 0,
              color: widget.reminder.color,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
              shadowLightColor: Colors.white.withAlpha(80),
              shadowDarkColor: Colors.black.withAlpha(25),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Texts
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reminder.title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.reminder.subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                // Time pill
                Neumorphic(
                  style: NeumorphicStyle(
                    depth: 3,
                    intensity: 0,
                    color: AppColors.primary,
                    boxShape: NeumorphicBoxShape.roundRect(
                      BorderRadius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    widget.reminder.time,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
