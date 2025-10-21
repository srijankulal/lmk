import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/main/home.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Reminder {
  final String title;
  final TimeOfDay time;
  final DateTime expiry_date;
  // final Color color;
  final DateTime issue_date;
  // final bool isEnabled;

  Reminder({
    required this.title,
    required this.time,
    required this.expiry_date,
    // required this.color,
    DateTime? issue_date,

    // required this.isEnabled,
  }) : issue_date = issue_date ?? DateTime(0, 0, 0);
}

class BuildCard extends StatefulWidget {
  final List<Reminder> reminders;

  const BuildCard({super.key, required this.reminders});

  @override
  State<BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends State<BuildCard> with TickerProviderStateMixin {
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
      padding: const EdgeInsets.only(top: 28.00),
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
                  heightFactor: 0.67,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedBuilder(
                      animation: fadeAnim,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - fadeAnim.value)),
                          child: Opacity(
                            opacity: fadeAnim.value,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: _NeumorphicReminderCard(
                                reminder: reminder,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
  static final List<Color> cardColors = [
    AppColors.cardSage,
    AppColors.cardClay,
    AppColors.cardAmber,
    AppColors.cardCoral,
  ];
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.reminder.title),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            onPressed: (context) {
              showShadDialog(
                context: context,
                builder: (context) => Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.background.withAlpha(95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(30),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(20),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Delete Reminder?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'This action cannot be undone.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ShadButton.outline(
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                  ),
                                  ShadButton(
                                    backgroundColor: Colors.redAccent,
                                    child: const Text('Delete'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
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
              );
            },
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: GestureDetector(
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
                color: cardColors[Random().nextInt(cardColors.length)],
                boxShape: NeumorphicBoxShape.roundRect(
                  BorderRadius.circular(20),
                ),
                shadowLightColor: Colors.white.withAlpha(80),
                shadowDarkColor: Colors.black.withAlpha(25),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.reminder.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Expiry: ${widget.reminder.expiry_date.toLocal().toString().split(' ')[0]}",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

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
                      widget.reminder.time.format(context),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
