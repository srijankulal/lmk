import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lmk/components/app_loader.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/data/local/reminder_local.dart';
import 'package:lmk/data/models/local/local_reminder.dart';
import 'package:lmk/data/repository/remote/update_reminder.dart';
import 'package:lmk/main.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationDetailScreen extends StatefulWidget {
  final String? payload;

  const NotificationDetailScreen({super.key, this.payload});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Parsed reminder data
  int? _reminderIndex;
  int? _reminderId;
  String _title = 'Document Reminder';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _scheduledTime = TimeOfDay.now();
  bool _isEnabled = true;
  bool _isLoading = true;
  ReminderLocal? _localRecord;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _parseAndLoadReminder();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _parseAndLoadReminder() async {
    final raw = widget.payload;
    if (raw == null || raw.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (raw.startsWith('{')) {
        // JSON format
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _reminderIndex = data['index'] as int?;
        _reminderId = data['id'] as int?;
        _title = data['title'] as String? ?? 'Document Reminder';
        if (data['expiryDate'] != null) {
          _expiryDate = DateTime.tryParse(data['expiryDate'] as String) ?? _expiryDate;
        }
        if (data['reminderDate'] != null) {
          _scheduledDate =
              DateTime.tryParse(data['reminderDate'] as String) ?? _scheduledDate;
        }
        if (data['time'] != null) {
          final parts = (data['time'] as String).split(':');
          if (parts.length >= 2) {
            _scheduledTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
      } else if (raw.contains('|')) {
        // Pipe delimited legacy format: DocumentType|ExpiryDate|Index
        final parts = raw.split('|');
        _title = parts[0].isNotEmpty ? parts[0] : 'Document Reminder';
        if (parts.length > 1) {
          _expiryDate = DateTime.tryParse(parts[1]) ?? _expiryDate;
        }
        if (parts.length > 2) {
          _reminderIndex = int.tryParse(parts[2]);
        }
      } else {
        _title = raw;
      }
    } catch (e) {
      print('Error parsing payload: $e');
    }

    // Attempt to load from Isar local database
    if (_reminderIndex != null) {
      final match =
          await ReminderLocalDataSource().getReminderByIndex(_reminderIndex!);
      if (match != null) {
        _localRecord = match;
        _reminderId = match.id;
        _title = match.title;
        _expiryDate = match.expiryDate ?? _expiryDate;
        _scheduledDate = match.reminderDate ?? _scheduledDate;
        _isEnabled = match.isEnabled ?? true;
        if (match.time != null && match.time!.contains(':')) {
          final parts = match.time!.split(':');
          _scheduledTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? _scheduledTime.hour,
            minute: int.tryParse(parts[1]) ?? _scheduledTime.minute,
          );
        }
      }
    } else if (_reminderId != null) {
      final match = await ReminderLocalDataSource().getReminderById(_reminderId!);
      if (match != null) {
        _localRecord = match;
        _reminderIndex = match.index;
        _title = match.title;
        _expiryDate = match.expiryDate ?? _expiryDate;
        _scheduledDate = match.reminderDate ?? _scheduledDate;
        _isEnabled = match.isEnabled ?? true;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int get _daysLeft {
    final now = DateTime.now();
    final diff = _expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff;
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  Future<void> _rescheduleNotification(DateTime targetDate, TimeOfDay targetTime) async {
    final notifId = _reminderIndex ?? _title.hashCode.abs();

    const channel = AndroidNotificationChannel(
      'reminder_channel_v2',
      'Reminders',
      description: 'Channel for reminder notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel_v2',
      'Reminders',
      channelDescription: 'Channel for reminder notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final payloadData = jsonEncode({
      'index': notifId,
      'title': _title,
      'expiryDate': _expiryDate.toIso8601String(),
      'reminderDate': targetDate.toIso8601String(),
      'time':
          '${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}',
    });

    await flutterLocalNotificationsPlugin.cancel(notifId);

    final tzTarget = tz.TZDateTime.from(
      DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        targetTime.hour,
        targetTime.minute,
      ),
      tz.local,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notifId,
      _title,
      'Reminder: $_title is due soon.',
      tzTarget,
      notificationDetails,
      payload: payloadData,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _applySnooze(Duration duration, String label) async {
    HapticFeedback.mediumImpact();
    final newTarget = DateTime.now().add(duration);
    final newTime = TimeOfDay.fromDateTime(newTarget);
    final newDate = DateTime(newTarget.year, newTarget.month, newTarget.day);

    setState(() {
      _scheduledDate = newDate;
      _scheduledTime = newTime;
      _isEnabled = true;
    });

    await _rescheduleNotification(newDate, newTime);
    await _saveToDatabase(newDate, newTime, true);

    if (!mounted) return;
    _showToast('Snoozed $label', 'Alert set for ${_formatDate(newDate)} at ${_formatTime(newTime)}');
  }

  Future<void> _snoozeTomorrowMorning() async {
    HapticFeedback.mediumImpact();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    const morningTime = TimeOfDay(hour: 9, minute: 0);
    final newDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    setState(() {
      _scheduledDate = newDate;
      _scheduledTime = morningTime;
      _isEnabled = true;
    });

    await _rescheduleNotification(newDate, morningTime);
    await _saveToDatabase(newDate, morningTime, true);

    if (!mounted) return;
    _showToast('Snoozed to Tomorrow', 'Alert scheduled for 9:00 AM');
  }

  Future<void> _toggleEnabled(bool enabled) async {
    HapticFeedback.selectionClick();
    final notifId = _reminderIndex ?? _title.hashCode.abs();

    setState(() => _isEnabled = enabled);

    if (enabled) {
      await _rescheduleNotification(_scheduledDate, _scheduledTime);
      _showToast('Reminder Enabled', 'Alert will ring at scheduled time.');
    } else {
      await flutterLocalNotificationsPlugin.cancel(notifId);
      _showToast('Reminder Turned Off', 'Notifications for this item are paused.');
    }

    await _saveToDatabase(_scheduledDate, _scheduledTime, enabled);
  }

  Future<void> _pickCustomTimeAndDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledDate.isBefore(now) ? now : _scheduledDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF5B2E),
              surface: Color(0xFF1E2638),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF5B2E),
              surface: Color(0xFF1E2638),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _scheduledDate = pickedDate;
      _scheduledTime = pickedTime;
      _isEnabled = true;
    });

    await _rescheduleNotification(pickedDate, pickedTime);
    await _saveToDatabase(pickedDate, pickedTime, true);

    if (!mounted) return;
    _showToast('Time Updated', 'New reminder set for ${_formatDate(pickedDate)} at ${_formatTime(pickedTime)}');
  }

  Future<void> _saveToDatabase(DateTime date, TimeOfDay time, bool isEnabled) async {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    if (_localRecord != null) {
      _localRecord!.reminderDate = date;
      _localRecord!.time = timeStr;
      _localRecord!.isEnabled = isEnabled;
      _localRecord!.synced = false;
      _localRecord!.updatedAt = DateTime.now();
      await ReminderLocalDataSource().updateReminder(_localRecord!);
    }

    final hasInternet = await InternetConnection().hasInternetAccess;
    if (hasInternet && _reminderIndex != null) {
      try {
        await UpdateReminder().updateReminder(
          index: _reminderIndex!,
          title: _title,
          time: timeStr,
          setDate: date,
          isEnabled: isEnabled,
        );
        if (_localRecord != null) {
          _localRecord!.synced = true;
          await ReminderLocalDataSource().updateReminder(_localRecord!);
        }
      } catch (e) {
        print('Background remote sync deferred: $e');
      }
    }
  }

  void _showToast(String title, String description) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        description: Text(description),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: AppLoader(size: 28),
        ),
      );
    }

    final days = _daysLeft;
    final isUrgent = days <= 30;

    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
        children: [
          // Ambient backdrops
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(25),
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
                color: AppColors.accent.withAlpha(20),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: const SizedBox.expand(),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                _buildTopAppBar(context),

                // Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Document Card
                        _buildHeroCard(isUrgent, days),
                        const SizedBox(height: 22),

                        // Quick Snooze Section
                        _buildSectionHeader('QUICK SNOOZE', Icons.snooze_rounded),
                        const SizedBox(height: 12),
                        _buildSnoozeGrid(),
                        const SizedBox(height: 22),

                        // Schedule & Custom Time Section
                        _buildSectionHeader('ALERT SCHEDULE', Icons.access_time_rounded),
                        const SizedBox(height: 12),
                        _buildScheduleCard(),
                        const SizedBox(height: 22),

                        // Toggle Notification Active State
                        _buildToggleCard(),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                _buildBottomBar(context),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isEnabled
                  ? AppColors.success.withAlpha(20)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isEnabled
                    ? AppColors.success.withAlpha(60)
                    : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isEnabled ? AppColors.success : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isEnabled ? 'ACTIVE' : 'MUTED',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: _isEnabled ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isUrgent, int days) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.primary.withAlpha(20),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(70),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LMK • DOCUMENT REMINDER',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 16),

          // Expiry & Countdown chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPIRES ON',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(_expiryDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? AppColors.error.withAlpha(20)
                      : AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUrgent
                        ? AppColors.error.withAlpha(80)
                        : AppColors.primary.withAlpha(60),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUrgent ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                      size: 15,
                      color: isUrgent ? AppColors.error : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      days < 0
                          ? 'Expired ${days.abs()}d ago'
                          : days == 0
                              ? 'Expires today'
                              : '$days days left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSnoozeGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildSnoozeButton(
            label: '+10 Mins',
            subtitle: 'Short break',
            onTap: () => _applySnooze(const Duration(minutes: 10), 'for 10 minutes'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSnoozeButton(
            label: '+1 Hour',
            subtitle: 'Later today',
            onTap: () => _applySnooze(const Duration(hours: 1), 'for 1 hour'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSnoozeButton(
            label: 'Tomorrow',
            subtitle: '9:00 AM',
            onTap: _snoozeTomorrowMorning,
          ),
        ),
      ],
    );
  }

  Widget _buildSnoozeButton({
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT ALARM',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatDate(_scheduledDate)} at ${_formatTime(_scheduledTime)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withAlpha(20),
              foregroundColor: AppColors.primary,
              elevation: 0,
              side: const BorderSide(color: AppColors.primary, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.edit_calendar_rounded, size: 16),
            label: const Text(
              'Change',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            onPressed: _pickCustomTimeAndDate,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _isEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                color: _isEnabled ? AppColors.success : AppColors.textTertiary,
                size: 22,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Alerts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isEnabled ? 'Ring on scheduled time' : 'Notifications paused',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _isEnabled,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withAlpha(60),
            onChanged: _toggleEnabled,
          ),
        ],
      ),
    );
  }

  Future<void> _dismissAndDisable() async {
    setState(() => _isEnabled = false);
    if (_reminderIndex != null) {
      await flutterLocalNotificationsPlugin.cancel(_reminderIndex!);
    }
    await _saveToDatabase(_scheduledDate, _scheduledTime, false);
    if (mounted) {
      ShadToaster.of(context).show(
        const ShadToast(
          title: Text('Reminder Dismissed', style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text('This reminder has been turned off.'),
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.notifications_off_outlined, size: 18),
                label: const Text(
                  'Dismiss',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onPressed: _dismissAndDisable,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeController.instance.isDarkMode
                      ? Colors.white
                      : AppColors.surfaceDark,
                  foregroundColor: ThemeController.instance.isDarkMode
                      ? const Color(0xFF121019)
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
