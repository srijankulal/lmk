import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/data/local/reminder_local.dart';
import 'package:lmk/data/models/local/local_reminder.dart';
import 'package:lmk/main.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:timezone/timezone.dart' as tz;

class Reminder {
  final String userId;
  final int id;
  final String title;
  final TimeOfDay time;
  final DateTime expiry_date;
  final int index;
  final bool isEnabled;
  final DateTime issue_date;

  Reminder({
    required this.userId,
    required this.id,
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
  final Function(int id)? onDelete;

  const BuildCard({super.key, required this.reminders, this.onDelete});

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
              child: Text(
                "No reminders 😌",
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
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
                          child: _GlossyReminderCard(
                            reminder: reminder,
                            onDelete: widget.onDelete,
                          ),
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
  final Function(int id)? onDelete;

  const _GlossyReminderCard({required this.reminder, this.onDelete});

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
          Builder(
            builder: (context) {
              bool _isPressed = false;
              return StatefulBuilder(
                builder: (context, setInnerState) {
                  return GestureDetector(
                    onTapDown: (_) => setInnerState(() => _isPressed = true),
                    onTapUp: (_) async {
                      await Future.delayed(const Duration(milliseconds: 120));
                      setInnerState(() => _isPressed = false);
                      _showDeleteDialog(context);
                    },
                    onTapCancel: () => setInnerState(() => _isPressed = false),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: _isPressed ? 0.93 : 1.0,
                      curve: Curves.easeOutBack,
                      child: Container(
                        height: double.infinity,
                        width: 90,
                        decoration: BoxDecoration(
                          // OUTER gradient border like molten glass edge
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF3B3B), // bright coral red
                              Color(0xFFFF5E3A), // warm orange tint
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            2.0,
                          ), // border thickness
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Glass blur layer
                                BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(color: Colors.transparent),
                                ),
                                // LIQUID inner fill gradient (semi-translucent)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: _isPressed
                                          ? [
                                              const Color(
                                                0xFFFF4C4C,
                                              ).withOpacity(
                                                0.85,
                                              ), // deeper red on press
                                              const Color(
                                                0xFFFF1E1E,
                                              ).withOpacity(0.6),
                                            ]
                                          : [
                                              const Color(
                                                0xFFFF5B5B,
                                              ).withOpacity(0.75), // bright red
                                              const Color(
                                                0xFFFF7C5C,
                                              ).withOpacity(
                                                0.55,
                                              ), // soft molten tint
                                            ],
                                    ),
                                  ),
                                ),
                                // Reflective highlight layer
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: 50,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withOpacity(0.25),
                                          Colors.white.withOpacity(0.05),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Inner shadow glow (liquid depth)
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF3B3B,
                                        ).withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: -5,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.1),
                                        blurRadius: 12,
                                        spreadRadius: -3,
                                        offset: const Offset(0, -3),
                                      ),
                                    ],
                                  ),
                                ),
                                // Positioned.fill(
                                //   child: AnimatedOpacity(
                                //     opacity: _isPressed ? 0.0 : 0.3,
                                //     duration: const Duration(milliseconds: 600),
                                //     child: ShaderMask(
                                //       shaderCallback: (rect) => LinearGradient(
                                //         colors: [
                                //           Colors.white.withOpacity(0.4),
                                //           Colors.transparent,
                                //         ],
                                //         begin: Alignment.topLeft,
                                //         end: Alignment.bottomRight,
                                //       ).createShader(rect),
                                //       blendMode: BlendMode.lighten,
                                //       child: Container(color: Colors.white),
                                //     ),
                                //   ),
                                // ),

                                // Button content (icon + text)
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        LucideIcons.trash2,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        "Delete",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
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
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
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
                  child: _buildCardContent(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
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
                  decoration: _isEnabled ? null : TextDecoration.lineThrough,
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
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              onTap: () async {
                if (_isEnabled) {
                  await flutterLocalNotificationsPlugin.cancel(
                    widget.reminder.index,
                  );
                } else {
                  await flutterLocalNotificationsPlugin.zonedSchedule(
                    widget.reminder.index,
                    'Reminder: ${widget.reminder.title}',
                    'It\'s time for your reminder scheduled at ${widget.reminder.time.format(context)}',

                    tz.TZDateTime.from(
                      DateTime(
                        widget.reminder.expiry_date.year,
                        widget.reminder.expiry_date.month,
                        widget.reminder.expiry_date.day,
                        widget.reminder.time.hour,
                        widget.reminder.time.minute,
                      ),
                      tz.local,
                    ),
                    const NotificationDetails(
                      android: AndroidNotificationDetails(
                        'reminder_channel',
                        'Reminders',
                        channelDescription:
                            'Channel for reminder notifications',
                        importance: Importance.max,
                        priority: Priority.high,
                      ),
                    ),
                    androidScheduleMode:
                        AndroidScheduleMode.exactAllowWhileIdle,
                  );
                }
                await ReminderLocalDataSource().updateReminder(
                  ReminderLocal(
                    userId: widget.reminder.userId,
                    id: widget.reminder.id,
                    title: widget.reminder.title,
                    index: widget.reminder.index,
                    time:
                        "${widget.reminder.time.hour.toString().padLeft(2, '0')}:${widget.reminder.time.minute.toString().padLeft(2, '0')}",
                    expiryDate: widget.reminder.expiry_date,
                    isEnabled: !_isEnabled,
                  ),
                );

                setState(() {
                  _isEnabled = !_isEnabled;
                });
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
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, _, __) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Center(
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  bool deleted = await ReminderLocalDataSource()
                                      .deleteReminder(widget.reminder.id);

                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();

                                  if (deleted) {
                                    widget.onDelete?.call(widget.reminder.id);
                                    Navigator.of(context).pop(true);
                                    ShadToaster.of(context).show(
                                      const ShadToast(
                                        duration: Duration(milliseconds: 1500),
                                        backgroundColor: AppColors.success,
                                        title: Text(
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
                                    ShadToaster.of(context).show(
                                      ShadToast.destructive(
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
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
          ),
        );
      },
    );
  }
}
