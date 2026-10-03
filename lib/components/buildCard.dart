import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/data/local/reminder_local.dart';
import 'package:lmk/data/models/local/local_reminder.dart';
import 'package:lmk/data/models/local/pending_deletion.dart';
import 'package:lmk/data/repository/local/isar_service.dart';
import 'package:lmk/data/repository/remote/delete_reminder.dart';
import 'package:lmk/data/repository/remote/update_reminder.dart';
import 'package:lmk/main.dart';
import 'package:lmk/services/settings_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:timezone/timezone.dart' as tz;

class Reminder {
  final String userId;
  final int id;
  final String title;
  final TimeOfDay time;
  final DateTime expiry_date;
  final DateTime? reminderDate;
  final int index;
  final bool isEnabled;
  final DateTime issue_date;
  bool isSynced;

  Reminder({
    required this.userId,
    required this.id,
    required this.title,
    required this.time,
    required this.expiry_date,
    this.reminderDate,
    required this.index,
    required this.isEnabled,
    required this.isSynced,
    DateTime? issue_date,
  }) : issue_date = issue_date ?? DateTime(0, 0, 0);
}

// ---------------------------------------------------------------------------
// 🃏 STACKED WALLET DECK VIEW
// ---------------------------------------------------------------------------
class BuildCard extends StatefulWidget {
  final List<Reminder> reminders;
  final Function(int id)? onDelete;

  const BuildCard({super.key, required this.reminders, this.onDelete});

  @override
  State<BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends State<BuildCard> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedReminderId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        if (widget.reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(25),
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No reminders yet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Tap + below or scan a document to get started",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final reminders = widget.reminders;

        // Ensure active featured reminder exists
        final selectedId = _selectedReminderId;
        final featuredReminder = (selectedId != null &&
                reminders.any((r) => r.id == selectedId))
            ? reminders.firstWhere((r) => r.id == selectedId)
            : reminders.first;

        // Other cards displayed in cascading deck below
        final otherReminders =
            reminders.where((r) => r.id != featuredReminder.id).toList();

        final isDark = ThemeController.instance.isDarkMode;

        return ScrollConfiguration(
          behavior: const _SmoothScrollBehavior(),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Featured Top Card (Interactive Apple Wallet hero card)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    final curved = CurvedAnimation(
                      parent: anim,
                      curve: Curves.easeOutCubic,
                    );
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.08),
                          end: Offset.zero,
                        ).animate(curved),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.96, end: 1.0)
                              .animate(curved),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _SwipeDismissWrapper(
                    key: ValueKey('featured_${featuredReminder.id}'),
                    reminder: featuredReminder,
                    onDelete: (id) {
                      widget.onDelete?.call(id);
                      if (_selectedReminderId == id) {
                        setState(() => _selectedReminderId = null);
                      }
                    },
                    child: _FeaturedReminderCard(
                      key: ValueKey(featuredReminder.id),
                      reminder: featuredReminder,
                      index: reminders.indexOf(featuredReminder),
                      onDelete: (id) {
                        widget.onDelete?.call(id);
                        if (_selectedReminderId == id) {
                          setState(() => _selectedReminderId = null);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Cascading Deck Header (if there are other cards)
                if (otherReminders.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.layers,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "DECK (${otherReminders.length})",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Tap card to view",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Cascading Stacked Cards Deck (Overlapping cards)
                  _buildCascadingDeck(otherReminders, isDark),
                ] else ...[
                  // Single card subtle status badge
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.checkCheck,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "All reminders displayed",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Bottom padding for expandable FAB
                const SizedBox(height: 120),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the cascading overlapping deck of cards matching reference image
  /// Top card is kept physically above the subsequent cards with staggered entrance animations
  Widget _buildCascadingDeck(List<Reminder> others, bool isDark) {
    const double cardHeight = 98.0;
    const double peekHeight = 72.0;
    final double stackHeight = (others.length - 1) * peekHeight + cardHeight;

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Keep top card visually above the others by rendering from bottom (last) to top (first)
          for (int i = others.length - 1; i >= 0; i--)
            Positioned(
              top: i * peekHeight,
              left: 0,
              right: 0,
              height: cardHeight,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('deck_anim_${others[i].id}'),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 250 + (i * 50).clamp(0, 300)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * 16),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _SwipeDismissWrapper(
                  key: ValueKey('deck_${others[i].id}'),
                  reminder: others[i],
                  onDelete: (id) {
                    widget.onDelete?.call(id);
                  },
                  child: _StackedDeckCard(
                    key: ValueKey('deck_card_${others[i].id}'),
                    reminder: others[i],
                    index: i,
                    total: others.length,
                    onSelect: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedReminderId = others[i].id;
                      });
                    },
                    onDelete: widget.onDelete,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🗑️ SWIPE-TO-DELETE WRAPPER
// ---------------------------------------------------------------------------
class _SwipeDismissWrapper extends StatelessWidget {
  final Reminder reminder;
  final Function(int id)? onDelete;
  final Widget child;

  const _SwipeDismissWrapper({
    super.key,
    required this.reminder,
    required this.child,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${reminder.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return await _confirmDelete(context);
      },
      onDismissed: (_) async {
        await _performDelete(context);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.red.withAlpha(0),
              Colors.red.withAlpha(40),
              Colors.red.withAlpha(90),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.trash2,
                color: Colors.redAccent,
                size: 19,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: child,
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Dismiss',
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, _, __) => const SizedBox(),
          transitionBuilder: (context, anim1, anim2, child) {
            return Transform.scale(
              scale: Curves.easeOutBack.transform(anim1.value),
              child: Opacity(
                opacity: anim1.value,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.trash2,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Delete Reminder?',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This will cancel scheduled alarms.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ShadButton.outline(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ShadButton(
                                backgroundColor: const Color(0xFFDC2626),
                                child: const Text('Delete'),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
  }

  Future<void> _performDelete(BuildContext context) async {
    final hasInternet = await InternetConnection().hasInternetAccess;
    final isar = await IsarService().db;

    if (hasInternet) {
      try {
        await DeleteReminder().deleteReminder(reminder.index.toString());
        await ReminderLocalDataSource().deleteReminder(reminder.id);
      } catch (_) {}
    } else {
      await isar.writeTxn(() async {
        await isar.pendingDeletions.put(
          PendingDeletion()
            ..remoteIndex = reminder.index.toString()
            ..deletedAt = DateTime.now(),
        );
        await isar.reminderLocals.delete(reminder.id);
      });
    }

    await flutterLocalNotificationsPlugin.cancel(reminder.index);
    onDelete?.call(reminder.id);

    if (context.mounted) {
      ShadToaster.of(context).show(
        ShadToast(
          duration: const Duration(milliseconds: 1500),
          backgroundColor: AppColors.success,
          title: Text(
            hasInternet ? 'Reminder Deleted' : 'Deleted (Saved for Sync)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// 🏷️ CATEGORY ICON & 3D WELL HELPERS
// ---------------------------------------------------------------------------
IconData getCategoryIconForTitle(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('insurance') ||
      lower.contains('health') ||
      lower.contains('medical') ||
      lower.contains('doctor') ||
      lower.contains('shield') ||
      lower.contains('safe') ||
      lower.contains('policy') ||
      lower.contains('hospital') ||
      lower.contains('dental') ||
      lower.contains('mediclaim')) {
    return LucideIcons.shieldCheck;
  }
  if (lower.contains('car') ||
      lower.contains('vehicle') ||
      lower.contains('emission') ||
      lower.contains('puc') ||
      lower.contains('bike') ||
      lower.contains('motor') ||
      lower.contains('drive') ||
      lower.contains('license') ||
      lower.contains('service') ||
      lower.contains('rc') ||
      lower.contains('fastag')) {
    return LucideIcons.car;
  }
  if (lower.contains('passport') ||
      lower.contains('visa') ||
      lower.contains('aadhaar') ||
      lower.contains('pan') ||
      lower.contains('voter') ||
      lower.contains('identity') ||
      lower.contains('citizenship') ||
      lower.contains('cert') ||
      lower.contains('certificate') ||
      lower.contains('document')) {
    return LucideIcons.fileBadge;
  }
  if (lower.contains('lease') ||
      lower.contains('rent') ||
      lower.contains('apartment') ||
      lower.contains('house') ||
      lower.contains('home') ||
      lower.contains('flat') ||
      lower.contains('building') ||
      lower.contains('property')) {
    return LucideIcons.building;
  }
  if (lower.contains('bill') ||
      lower.contains('electricity') ||
      lower.contains('water') ||
      lower.contains('gas') ||
      lower.contains('wifi') ||
      lower.contains('broadband') ||
      lower.contains('recharge') ||
      lower.contains('pay') ||
      lower.contains('bank') ||
      lower.contains('money') ||
      lower.contains('emi') ||
      lower.contains('loan') ||
      lower.contains('subscription') ||
      lower.contains('finance') ||
      lower.contains('credit') ||
      lower.contains('tax') ||
      lower.contains('gst')) {
    return LucideIcons.creditCard;
  }
  if (lower.contains('flight') ||
      lower.contains('trip') ||
      lower.contains('travel') ||
      lower.contains('train') ||
      lower.contains('ticket') ||
      lower.contains('hotel') ||
      lower.contains('booking')) {
    return LucideIcons.plane;
  }
  if (lower.contains('warranty') ||
      lower.contains('guarantee') ||
      lower.contains('phone') ||
      lower.contains('laptop') ||
      lower.contains('device')) {
    return LucideIcons.shieldAlert;
  }
  if (lower.contains('work') ||
      lower.contains('exam') ||
      lower.contains('project') ||
      lower.contains('meeting') ||
      lower.contains('deadline') ||
      lower.contains('contract')) {
    return LucideIcons.briefcase;
  }
  return LucideIcons.calendar;
}

Widget build3DIconWell(
  IconData icon,
  bool isDark,
  bool isUrgent,
  bool isEnabled, {
  double size = 36,
  double iconSize = 16,
  Color? iconColor,
  Color? backgroundColor,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.3),
      color: backgroundColor ??
          (isDark ? const Color(0xFF13191A) : const Color(0xFFE8EADE)),
      border: Border.all(
        color: isDark ? Colors.white.withAlpha(25) : const Color(0xFFD6D9C8),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withAlpha(120) : const Color(0x182E3A3B),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Center(
      child: Icon(
        icon,
        size: iconSize,
        color: !isEnabled
            ? AppColors.textTertiary
            : (iconColor ??
                (isUrgent
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF38BDF8) : AppColors.secondary))),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 🌟 FEATURED ACTIVE REMINDER CARD (Top Hero Card)
// ---------------------------------------------------------------------------
class _FeaturedReminderCard extends StatefulWidget {
  final Reminder reminder;
  final int index;
  final Function(int id)? onDelete;

  const _FeaturedReminderCard({
    super.key,
    required this.reminder,
    required this.index,
    this.onDelete,
  });

  @override
  State<_FeaturedReminderCard> createState() => _FeaturedReminderCardState();
}

class _FeaturedReminderCardState extends State<_FeaturedReminderCard> {
  bool _isPressed = false;
  late bool _isEnabled;
  late String _title;
  late TimeOfDay _time;
  late DateTime _expiryDate;
  DateTime? _reminderDate;

  @override
  void initState() {
    super.initState();
    _syncState();
  }

  @override
  void didUpdateWidget(covariant _FeaturedReminderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reminder != widget.reminder) {
      _syncState();
    }
  }

  void _syncState() {
    _isEnabled = widget.reminder.isEnabled;
    _title = widget.reminder.title;
    _time = widget.reminder.time;
    _expiryDate = widget.reminder.expiry_date;
    _reminderDate = widget.reminder.reminderDate;
  }

  LinearGradient _getCardGradient() {
    final idx =
        (widget.reminder.index.abs() + widget.index) % AppColors.cardGradients.length;
    return AppColors.cardGradients[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final gradient = _getCardGradient();
    final effectiveDate = _reminderDate ?? _expiryDate;
    final daysLeft = _calculateDaysLeft(effectiveDate);
    final dueText = _formatDueText(daysLeft);
    final isUrgent = daysLeft <= 3;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 80));
        if (mounted) setState(() => _isPressed = false);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _openEditDialog(context),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _openDeleteDialog(context);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: _isEnabled ? gradient : null,
            color: _isEnabled ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isEnabled
                  ? Colors.white.withAlpha(isDark ? 45 : 70)
                  : AppColors.borderSubtle,
              width: 1.2,
            ),
            boxShadow: [
              if (_isEnabled)
                BoxShadow(
                  color: gradient.colors.first.withAlpha(isDark ? 85 : 55),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                )
              else
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: Date & Time pill + Toggle Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _infoPill(
                            icon: LucideIcons.calendar,
                            text:
                                '${_formatDateShort(effectiveDate)} • ${_time.format(context)}',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _toggleSwitch(isDark),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Middle: Title with dynamic 3D Category Icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        build3DIconWell(
                          getCategoryIconForTitle(_title),
                          isDark,
                          isUrgent,
                          _isEnabled,
                          size: 40,
                          iconSize: 19,
                          backgroundColor: isDark
                              ? const Color(0x33FFFFFF)
                              : Colors.white.withAlpha(220),
                          iconColor: !_isEnabled
                              ? AppColors.textTertiary
                              : (isDark ? Colors.white : AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _title,
                            style: TextStyle(
                              color: _isEnabled
                                  ? Colors.white
                                  : AppColors.textTertiary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1.2,
                              decoration: _isEnabled
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Bottom row: Status badge + Due badge + Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _statusPill(isUrgent, isDark),
                              const SizedBox(width: 6),
                              Flexible(
                                child: _duePill(dueText, isUrgent, isDark),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit Action Button
                            _cardActionButton(
                              icon: LucideIcons.pencil,
                              tooltip: 'Edit',
                              onTap: () => _openEditDialog(context),
                            ),
                            const SizedBox(width: 6),
                            // Delete Action Button
                            _cardActionButton(
                              icon: LucideIcons.trash2,
                              tooltip: 'Delete',
                              isDestructive: true,
                              onTap: () => _openDeleteDialog(context),
                            ),
                          ],
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
  }

  Widget _cardActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withAlpha(isDestructive ? 40 : 25),
            border: Border.all(
              color: Colors.white.withAlpha(isDestructive ? 60 : 40),
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isDestructive ? const Color(0xFFFFB3B3) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _statusPill(bool isUrgent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _isEnabled
            ? (isUrgent
                ? const Color(0xFFFF5722).withAlpha(55)
                : Colors.white.withAlpha(30))
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isEnabled
              ? (isUrgent
                  ? const Color(0xFFFF7A45).withAlpha(120)
                  : Colors.white.withAlpha(50))
              : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isEnabled
                  ? (isUrgent
                      ? const Color(0xFFFF5722)
                      : const Color(0xFF10B981))
                  : AppColors.textTertiary,
              boxShadow: [
                if (_isEnabled && isUrgent)
                  BoxShadow(
                    color: const Color(0xFFFF5722).withAlpha(180),
                    blurRadius: 6,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isUrgent ? "URGENT" : "ACTIVE",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: _isEnabled
                  ? (isUrgent ? const Color(0xFFFFB399) : Colors.white)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _isEnabled
            ? Colors.white.withAlpha(35)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: _isEnabled
              ? Colors.white.withAlpha(50)
              : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: _isEnabled ? Colors.white : AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _isEnabled ? Colors.white : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _duePill(String dueText, bool isUrgent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _isEnabled
            ? (isUrgent
                ? Colors.red.withAlpha(45)
                : Colors.black.withAlpha(25))
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        dueText,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: _isEnabled
              ? (isUrgent
                  ? const Color(0xFFFFB3B3)
                  : Colors.white)
              : AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _toggleSwitch(bool isDark) {
    return GestureDetector(
      onTap: _toggleReminder,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 44.0,
        height: 25.0,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.0),
          gradient: _isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFFFF7A45), Color(0xFFFF5722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isEnabled
              ? null
              : (isDark ? const Color(0xFF263032) : const Color(0xFFE2E4D8)),
          border: Border.all(
            color: _isEnabled
                ? Colors.white.withAlpha(90)
                : (isDark ? Colors.white.withAlpha(25) : const Color(0xFFD4D6C8)),
            width: 1.0,
          ),
          boxShadow: [
            if (_isEnabled)
              BoxShadow(
                color: const Color(0xFFFF5722).withAlpha(120),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          alignment:
              _isEnabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19.0,
            height: 19.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(45),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleReminder() async {
    HapticFeedback.lightImpact();
    final newEnabled = !_isEnabled;
    setState(() => _isEnabled = newEnabled);

    final updated = widget.reminder.copyWith(
      isEnabled: newEnabled,
      time: _time,
      expiry_date: _expiryDate,
      title: _title,
      reminderDate: _reminderDate,
    );

    if (newEnabled) {
      await _scheduleAlarm(updated);
    } else {
      await flutterLocalNotificationsPlugin.cancel(widget.reminder.index);
    }
    await _updateDatabase(updated);
  }

  void _openEditDialog(BuildContext context) {
    _showEditModal(
      context: context,
      reminder: widget.reminder,
      currentTitle: _title,
      currentTime: _time,
      currentExpiryDate: _expiryDate,
      currentReminderDate: _reminderDate,
      onSaved: (newTitle, newTime, newDate) {
        setState(() {
          _title = newTitle;
          _time = newTime;
          _reminderDate = newDate;
        });
      },
      onDelete: widget.onDelete,
    );
  }

  void _openDeleteDialog(BuildContext context) {
    _showDeleteModal(
      context: context,
      reminder: widget.reminder,
      onDelete: widget.onDelete,
    );
  }
}

// ---------------------------------------------------------------------------
// 📚 STACKED DECK CARD (Cascading card in the lower stack)
// ---------------------------------------------------------------------------
class _StackedDeckCard extends StatefulWidget {
  final Reminder reminder;
  final int index;
  final int total;
  final VoidCallback onSelect;
  final Function(int id)? onDelete;

  const _StackedDeckCard({
    super.key,
    required this.reminder,
    required this.index,
    required this.total,
    required this.onSelect,
    this.onDelete,
  });

  @override
  State<_StackedDeckCard> createState() => _StackedDeckCardState();
}

class _StackedDeckCardState extends State<_StackedDeckCard> {
  bool _isPressed = false;

  LinearGradient _getCardGradient() {
    final idx =
        (widget.reminder.index.abs() + widget.index + 1) % AppColors.cardGradients.length;
    return AppColors.cardGradients[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final effectiveDate =
        widget.reminder.reminderDate ?? widget.reminder.expiry_date;
    final daysLeft = _calculateDaysLeft(effectiveDate);
    final dueText = _formatDueText(daysLeft);
    final isUrgent = daysLeft <= 3;
    final isEnabled = widget.reminder.isEnabled;
    final cardGradient = _getCardGradient();
    final categoryIcon = getCategoryIconForTitle(widget.reminder.title);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 70));
        if (mounted) setState(() => _isPressed = false);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onSelect,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showDeleteModal(
          context: context,
          reminder: widget.reminder,
          onDelete: widget.onDelete,
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          height: 94,
          decoration: BoxDecoration(
            color: isDark
                ? (isEnabled ? const Color(0xEB1E2729) : AppColors.surface)
                : (isEnabled ? AppColors.surface : AppColors.surfaceMuted),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? (isEnabled ? Colors.white.withAlpha(28) : AppColors.borderSubtle)
                  : (isEnabled ? const Color(0xFFE2E4D8) : AppColors.borderSubtle),
              width: 1.1,
            ),
            boxShadow: [
              // Clean downward drop shadow casting onto cards below in the deck
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(160)
                    : const Color(0x222E3A3B),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              if (isDark && isEnabled)
                BoxShadow(
                  color: Colors.white.withAlpha(14),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Vibrant Color Accent Pill
                    Container(
                      width: 3.5,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: cardGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Category 3D Embossed Icon Well
                    build3DIconWell(
                      categoryIcon,
                      isDark,
                      isUrgent,
                      isEnabled,
                      size: 38,
                      iconSize: 17,
                      iconColor: isUrgent
                          ? AppColors.primary
                          : (isDark ? cardGradient.colors.last : cardGradient.colors.first),
                    ),
                    const SizedBox(width: 10),

                    // Title & Subtitle Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.reminder.title,
                            style: TextStyle(
                              color: isEnabled
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              decoration: isEnabled
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_formatDateShort(effectiveDate)} • ${widget.reminder.time.format(context)}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Due Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? (isUrgent
                                ? (isDark
                                    ? const Color(0xFFFF5722).withAlpha(45)
                                    : const Color(0xFFFF5722).withAlpha(25))
                                : (isDark
                                    ? Colors.white.withAlpha(20)
                                    : const Color(0xFFE8EADE)))
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isEnabled && isUrgent
                              ? const Color(0xFFFF5722).withAlpha(70)
                              : (isDark ? Colors.white.withAlpha(15) : const Color(0xFFD6D9C8)),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        dueText,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isEnabled
                              ? (isUrgent
                                  ? AppColors.primary
                                  : AppColors.textPrimary)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🛠️ SHARED HELPERS
// ---------------------------------------------------------------------------

int _calculateDaysLeft(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  return target.difference(today).inDays;
}

String _formatDueText(int daysLeft) {
  if (daysLeft < 0) return '${daysLeft.abs()}d overdue';
  if (daysLeft == 0) return 'Today';
  if (daysLeft == 1) return 'Tomorrow';
  return '${daysLeft}d left';
}

String _formatDateShort(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]}';
}

Future<void> _updateDatabase(Reminder reminder) async {
  final isar = await IsarService().db;
  final existing = await isar.reminderLocals.get(reminder.id);
  if (existing == null) return;

  final hasInternet = await InternetConnection().hasInternetAccess;
  bool synced = false;

  if (hasInternet) {
    try {
      await UpdateReminder().updateReminder(
        index: reminder.index,
        title: reminder.title,
        time:
            "${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}",
        expiryDate: reminder.expiry_date,
        setDate: reminder.issue_date,
        isEnabled: reminder.isEnabled,
        issuedDate: reminder.issue_date,
      );
      synced = true;
    } catch (_) {
      synced = false;
    }
  }

  existing.title = reminder.title;
  existing.time =
      "${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}";
  existing.expiryDate = reminder.expiry_date;
  existing.isEnabled = reminder.isEnabled;
  existing.synced = synced;
  existing.updatedAt = DateTime.now();

  await ReminderLocalDataSource().updateReminder(existing);
}

Future<void> _scheduleAlarm(Reminder reminder) async {
  final targetDate = reminder.reminderDate ?? reminder.expiry_date;
  final tzTarget = tz.TZDateTime.from(
    DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      reminder.time.hour,
      reminder.time.minute,
    ),
    tz.local,
  );

  final settings = AppSettings.instance;
  final soundId = settings.selectedSound;
  final channelId = settings.getChannelIdForSound(soundId);
  final fullIntent = settings.fullScreenIntent;

  await flutterLocalNotificationsPlugin.zonedSchedule(
    reminder.index,
    reminder.title,
    'Reminder: ${reminder.title} is due.',
    tzTarget,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Reminders (${settings.currentSoundOption.name})',
        channelDescription: 'Reminder notifications',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound(soundId),
        fullScreenIntent: fullIntent,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    ),
    payload: jsonEncode({
      'index': reminder.index,
      'id': reminder.id,
      'title': reminder.title,
      'expiryDate': reminder.expiry_date.toIso8601String(),
      'reminderDate': targetDate.toIso8601String(),
      'time':
          '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}',
    }),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

// ---------------------------------------------------------------------------
// ✏️ EDIT MODAL
// ---------------------------------------------------------------------------

void _showEditModal({
  required BuildContext context,
  required Reminder reminder,
  required String currentTitle,
  required TimeOfDay currentTime,
  required DateTime currentExpiryDate,
  DateTime? currentReminderDate,
  required Function(String title, TimeOfDay time, DateTime? date) onSaved,
  Function(int id)? onDelete,
}) {
  final editFormKey = GlobalKey<ShadFormState>();
  TimeOfDay selectedTime = currentTime;
  DateTime selectedDate =
      currentReminderDate ??
      DateTime(
        currentExpiryDate.year,
        currentExpiryDate.month,
        currentExpiryDate.day,
      );
  String title = currentTitle;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, _, __) => const SizedBox(),
    transitionBuilder: (context, anim1, anim2, child) {
      final isDark = ThemeController.instance.isDarkMode;
      return Transform.scale(
        scale: Curves.easeOutBack.transform(anim1.value),
        child: Opacity(
          opacity: anim1.value,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: ShadForm(
                  key: editFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
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
                                LucideIcons.pen,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Edit reminder',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ShadInputFormField(
                          id: 'Title',
                          label: const Text('Title'),
                          initialValue: title,
                          onChanged: (v) => title = v ?? '',
                          leading: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              LucideIcons.bell,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ShadDatePickerFormField(
                          id: 'Reminder Date',
                          label: const Text('Reminder date'),
                          closeOnSelection: true,
                          placeholder:
                              const Text('Select reminder date'),
                          initialValue: selectedDate,
                          selectableDayPredicate: (day) {
                            final now = DateTime.now();
                            final startOfToday = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            return !day.isBefore(startOfToday);
                          },
                          onChanged: (v) {
                            if (v != null) selectedDate = v;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Time',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.borderSubtle,
                                  ),
                                  color: AppColors.surfaceLight,
                                ),
                                child: Text(
                                  '${((selectedTime.hour % 12 == 0 ? 12 : selectedTime.hour % 12)).toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.hour >= 12 ? 'PM' : 'AM'}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ShadButton(
                              leading: const Icon(
                                LucideIcons.clock,
                                size: 16,
                              ),
                              backgroundColor: AppColors.primary,
                              onPressed: () async {
                                final picked =
                                    await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: isDark
                                            ? ColorScheme.dark(
                                                primary:
                                                    AppColors.primary,
                                                onPrimary: Colors.white,
                                                surface:
                                                    AppColors.surface,
                                                onSurface: AppColors
                                                    .textPrimary,
                                              )
                                            : ColorScheme.light(
                                                primary:
                                                    AppColors.primary,
                                                onPrimary: Colors.white,
                                                surface:
                                                    AppColors.surface,
                                                onSurface: AppColors
                                                    .textPrimary,
                                              ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  selectedTime = picked;
                                  (context as Element)
                                      .markNeedsBuild();
                                }
                              },
                              child: const Text('Pick time'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    AppColors.textSecondary,
                              ),
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const Spacer(),
                            ShadButton(
                              backgroundColor: AppColors.primary,
                              child: const Text('Save Changes'),
                              onPressed: () async {
                                final ok = editFormKey
                                    .currentState!
                                    .saveAndValidate();
                                if (!ok || title.trim().isEmpty) {
                                  return;
                                }

                                onSaved(
                                  title,
                                  selectedTime,
                                  selectedDate,
                                );

                                final updated = reminder.copyWith(
                                  title: title,
                                  time: selectedTime,
                                  reminderDate: selectedDate,
                                );

                                if (reminder.isEnabled) {
                                  await _scheduleAlarm(updated);
                                }
                                await _updateDatabase(updated);

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ShadToaster.of(context).show(
                                    ShadToast(
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                      backgroundColor:
                                          AppColors.success,
                                      title: const Text(
                                        'Reminder updated',
                                        style: TextStyle(
                                          color: Colors.white,
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

// ---------------------------------------------------------------------------
// 🗑️ DELETE MODAL
// ---------------------------------------------------------------------------

void _showDeleteModal({
  required BuildContext context,
  required Reminder reminder,
  Function(int id)? onDelete,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, _, __) => const SizedBox(),
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: Curves.easeOutBack.transform(anim1.value),
        child: Opacity(
          opacity: anim1.value,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.trash2,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delete Reminder?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action cannot be undone and will cancel scheduled alarms.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: ShadButton.outline(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          onPressed: () =>
                              Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadButton(
                          backgroundColor: const Color(0xFFDC2626),
                          child: const Text('Delete'),
                          onPressed: () async {
                            final hasInternet =
                                await InternetConnection()
                                    .hasInternetAccess;
                            final isar = await IsarService().db;

                            if (hasInternet) {
                              try {
                                await DeleteReminder()
                                    .deleteReminder(
                                  reminder.index.toString(),
                                );
                                await ReminderLocalDataSource()
                                    .deleteReminder(reminder.id);
                              } catch (_) {}
                            } else {
                              await isar.writeTxn(() async {
                                await isar.pendingDeletions.put(
                                  PendingDeletion()
                                    ..remoteIndex =
                                        reminder.index.toString()
                                    ..deletedAt = DateTime.now(),
                                );
                                await isar.reminderLocals
                                    .delete(reminder.id);
                              });
                            }

                            await flutterLocalNotificationsPlugin
                                .cancel(reminder.index);
                            onDelete?.call(reminder.id);
                            if (context.mounted) {
                              Navigator.of(context).pop(true);
                              ShadToaster.of(context).show(
                                ShadToast(
                                  duration: const Duration(
                                    milliseconds: 1500,
                                  ),
                                  backgroundColor: AppColors.success,
                                  title: Text(
                                    hasInternet
                                        ? 'Reminder Deleted'
                                        : 'Deleted (Saved for Sync)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// 💫 EXTENSIONS & SCROLL BEHAVIOR
// ---------------------------------------------------------------------------

extension _CopyReminder on Reminder {
  Reminder copyWith({
    String? userId,
    int? id,
    String? title,
    TimeOfDay? time,
    DateTime? expiry_date,
    DateTime? reminderDate,
    int? index,
    bool? isEnabled,
    DateTime? issue_date,
    bool? isSynced,
  }) {
    return Reminder(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      expiry_date: expiry_date ?? this.expiry_date,
      reminderDate: reminderDate ?? this.reminderDate,
      index: index ?? this.index,
      isEnabled: isEnabled ?? this.isEnabled,
      issue_date: issue_date ?? this.issue_date,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class _SmoothScrollBehavior extends ScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
