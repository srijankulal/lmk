import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/data/repository/remote/delete_reminder.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Reminder {
  final String title;
  final TimeOfDay time;
  final DateTime expiry_date;
  final int index;
  final bool isEnabled;
  final DateTime issue_date;

  Reminder({
    required this.title,
    required this.time,
    required this.expiry_date,
    required this.index,
    required this.isEnabled,
    DateTime? issue_date,
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
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 1.0),
                    1.0,
                    curve: Curves.easeOut,
                  ),
                );

                return AnimatedBuilder(
                  animation: fadeAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - fadeAnim.value)),
                      child: Opacity(
                        opacity: fadeAnim.value,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _GlossyReminderCard(reminder: reminder),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _GlossyReminderCard extends StatefulWidget {
  final Reminder reminder;

  const _GlossyReminderCard({required this.reminder});

  @override
  State<_GlossyReminderCard> createState() => _GlossyReminderCardState();
}

class _GlossyReminderCardState extends State<_GlossyReminderCard> {
  static final List<Color> cardColors = [
    AppColors.cardSage,
    AppColors.cardClay,
    AppColors.cardAmber,
    AppColors.cardCoral,
  ];
  bool _isPressed = false;
  late Color _cardColor;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _cardColor = cardColors[Random().nextInt(cardColors.length)];
    _isEnabled = widget.reminder.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.reminder.title),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            borderRadius: BorderRadius.all(Radius.circular(26)),
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
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );

                                      String result = await DeleteReminder()
                                          .deleteReminder(
                                            widget.reminder.index.toString(),
                                          );

                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                      if (result == "Deleted Successfully") {
                                        Navigator.of(context).pop(true);
                                        final theme = ShadTheme.of(context);
                                        ShadToaster.of(context).show(
                                          ShadToast(
                                            duration: const Duration(
                                              milliseconds: 1500,
                                            ),
                                            backgroundColor: AppColors.success,
                                            title: const Text(
                                              'Reminder Deleted',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        Navigator.of(context).pop(false);
                                        final theme = ShadTheme.of(context);
                                        ShadToaster.of(context).show(
                                          ShadToast.destructive(
                                            duration: const Duration(
                                              milliseconds: 1500,
                                            ),
                                            backgroundColor:
                                                theme.colorScheme.destructive,
                                            title: const Text(
                                              'Failed to Delete Reminder',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
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
              );
            },
            backgroundColor: Colors.redAccent.withOpacity(0.8),
            autoClose: true,

            foregroundColor: Colors.white,
            icon: LucideIcons.trash2,
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
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _cardColor.withOpacity(_isEnabled ? 0.9 : 0.5),
                  _cardColor.withOpacity(_isEnabled ? 0.8 : 0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: _cardColor.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.reminder.title,
                              style: TextStyle(
                                color: AppColors.textPrimary.withOpacity(
                                  _isEnabled ? 1.0 : 0.5,
                                ),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                decoration: _isEnabled
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: AppColors.textPrimary.withOpacity(
                                    _isEnabled ? 1.0 : 0.5,
                                  ),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.reminder.time.format(context),
                                  style: TextStyle(
                                    color: AppColors.textPrimary.withOpacity(
                                      _isEnabled ? 1.0 : 0.5,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.textSecondary.withOpacity(
                                    _isEnabled ? 1.0 : 0.5,
                                  ),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Expires ${widget.reminder.expiry_date.toLocal().toString().split(' ')[0]}",
                                  style: TextStyle(
                                    color: AppColors.textPrimary.withOpacity(
                                      _isEnabled ? 0.9 : 0.5,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEnabled = !_isEnabled;
                              });
                              // TODO: Update reminder status in backend/database
                            },
                            child: Container(
                              width: 52,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: _isEnabled
                                    ? AppColors.success.withOpacity(0.8)
                                    : Colors.white.withOpacity(0.3),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                alignment: _isEnabled
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
  }
}
