import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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

enum _DeckMode { stage, stream }

// ---------------------------------------------------------------------------
// 🎴 NEXT-GEN CARD & DECK UI
// ---------------------------------------------------------------------------
class BuildCard extends StatefulWidget {
  final List<Reminder> reminders;
  final Function(int id)? onDelete;
  final Function(Reminder updated)? onUpdate;

  const BuildCard({
    super.key,
    required this.reminders,
    this.onDelete,
    this.onUpdate,
  });

  @override
  State<BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends State<BuildCard> {
  _DeckMode _deckMode = _DeckMode.stage;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        if (widget.reminders.isEmpty) {
          return _buildEmptyState();
        }

        final filtered = widget.reminders;
        final isDark = ThemeController.instance.isDarkMode;

        return ScrollConfiguration(
          behavior: const _SmoothScrollBehavior(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1. Deck View Mode Controls (No duplicated filter bar)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _deckMode == _DeckMode.stage
                                  ? LucideIcons.layers
                                  : LucideIcons.layoutList,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _deckMode == _DeckMode.stage
                                    ? "DECK STAGE (${filtered.length})"
                                    : "STREAM LIST (${filtered.length})",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View Mode Toggle (Carousel Stage vs Bento Stream)
                      _buildViewToggle(isDark),
                    ],
                  ),
                ),
              ),

              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No reminders match this filter',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              else if (_deckMode == _DeckMode.stage) ...[
                // 2. Carousel Stage (Expansive 3D Card Deck)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 290,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: filtered.length,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (idx) {
                            HapticFeedback.selectionClick();
                            setState(() => _currentPage = idx);
                          },
                          itemBuilder: (context, index) {
                            final reminder = filtered[index];
                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double value = 1.0;
                                double rotation = 0.0;
                                if (_pageController.position.haveDimensions) {
                                  value = (_pageController.page! - index);
                                  rotation = (value * 0.05).clamp(-0.1, 0.1);
                                  value = (1 - (value.abs() * 0.08)).clamp(0.90, 1.0);
                                }
                                return Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateZ(rotation)
                                    ..scaleByDouble(value, value, 1.0, 1.0),
                                  alignment: Alignment.center,
                                  child: child,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                child: _ModernDocumentCard(
                                  key: ValueKey('stage_${reminder.id}'),
                                  reminder: reminder,
                                  index: index,
                                  isHero: true,
                                  onDelete: widget.onDelete,
                                  onUpdate: widget.onUpdate,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Carousel Indicators
                      const SizedBox(height: 10),
                      _buildPageIndicators(filtered.length, isDark),
                      const SizedBox(height: 20),

                      // Quick Jump Deck Folio Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.layers,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'DECK FOLIO (${filtered.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Tap card to view in stage',
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
                    ],
                  ),
                ),

                // 3. Compact List below stage
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final reminder = filtered[index];
                        final isSelected = index == _currentPage;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FolioTile(
                            reminder: reminder,
                            index: index,
                            isSelected: isSelected,
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            onDelete: widget.onDelete,
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
              ] else ...[
                // 4. Bento Stream Mode (Expanded full list view)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final reminder = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _SwipeDismissWrapper(
                            key: ValueKey('stream_${reminder.id}'),
                            reminder: reminder,
                            onDelete: widget.onDelete,
                            child: _ModernDocumentCard(
                              key: ValueKey('stream_card_${reminder.id}'),
                              reminder: reminder,
                              index: index,
                              isHero: false,
                              onDelete: widget.onDelete,
                              onUpdate: widget.onUpdate,
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
              ],

              // Bottom padding for expandable FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(25),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "No reminders yet",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap + below or scan a document to get started",
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildViewToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2324) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewToggleOption(
            icon: LucideIcons.layers,
            tooltip: 'Deck Flow',
            isSelected: _deckMode == _DeckMode.stage,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _deckMode = _DeckMode.stage);
            },
            isDark: isDark,
          ),
          _viewToggleOption(
            icon: LucideIcons.layoutList,
            tooltip: 'Stream List',
            isSelected: _deckMode == _DeckMode.stream,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _deckMode = _DeckMode.stream);
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _viewToggleOption({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2E3B3D) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 15,
            color: isSelected ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators(int total, bool isDark) {
    if (total <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < math.min(total, 8); i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _currentPage == i ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _currentPage == i
                  ? AppColors.primary
                  : (isDark ? Colors.white.withAlpha(40) : const Color(0xFFD2D5C4)),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        if (total > 8) ...[
          const SizedBox(width: 4),
          Text(
            '+${total - 8}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 🌟 MODERN DOCUMENT CARD (Brand-new Card UI)
// ---------------------------------------------------------------------------
class _ModernDocumentCard extends StatefulWidget {
  final Reminder reminder;
  final int index;
  final bool isHero;
  final Function(int id)? onDelete;
  final Function(Reminder updated)? onUpdate;

  const _ModernDocumentCard({
    super.key,
    required this.reminder,
    required this.index,
    required this.isHero,
    this.onDelete,
    this.onUpdate,
  });

  @override
  State<_ModernDocumentCard> createState() => _ModernDocumentCardState();
}

class _ModernDocumentCardState extends State<_ModernDocumentCard> {
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
  void didUpdateWidget(covariant _ModernDocumentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reminder.isEnabled != widget.reminder.isEnabled ||
        oldWidget.reminder.title != widget.reminder.title ||
        oldWidget.reminder.time != widget.reminder.time ||
        oldWidget.reminder.reminderDate != widget.reminder.reminderDate ||
        oldWidget.reminder.expiry_date != widget.reminder.expiry_date) {
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
    final idx = (widget.reminder.index.abs() + widget.index) % AppColors.cardGradients.length;
    return AppColors.cardGradients[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final gradient = _getCardGradient();
    final effectiveDate = _reminderDate ?? _expiryDate;
    final daysLeft = _calculateDaysLeft(effectiveDate);
    final dueText = _formatDueText(daysLeft);
    final isUrgent = daysLeft <= 3 && _isEnabled;
    final categoryIcon = getCategoryIconForTitle(_title);

    // Calculate validity progress (from issue date to expiry date)
    final progress = _calculateProgress(widget.reminder.issue_date, _expiryDate);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 70));
        if (mounted) setState(() => _isPressed = false);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _openEditDialog(context),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _openDeleteDialog(context);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: _isEnabled ? gradient : null,
            color: _isEnabled
                ? null
                : (isDark ? const Color(0xFF161D1E) : AppColors.surface),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _isEnabled
                  ? Colors.white.withAlpha(isDark ? 50 : 85)
                  : AppColors.borderSubtle,
              width: 1.2,
            ),
            boxShadow: [
              if (_isEnabled)
                BoxShadow(
                  color: gradient.colors.first.withAlpha(isDark ? 90 : 55),
                  blurRadius: widget.isHero ? 24 : 14,
                  offset: const Offset(0, 8),
                )
              else
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(_isEnabled ? 35 : (isDark ? 10 : 25)),
                      Colors.white.withAlpha(0),
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Top Bar: Category 3D Well + Title + Power Switch
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        build3DIconWell(
                          categoryIcon,
                          isDark,
                          isUrgent,
                          _isEnabled,
                          size: 42,
                          iconSize: 20,
                          backgroundColor: _isEnabled
                              ? (isDark
                                  ? const Color(0x35000000)
                                  : Colors.white.withAlpha(220))
                              : (isDark
                                  ? const Color(0xFF1E2729)
                                  : const Color(0xFFE2E4D8)),
                          iconColor: !_isEnabled
                              ? AppColors.textTertiary
                              : (isUrgent
                                  ? AppColors.primary
                                  : (_isEnabled ? Colors.white : AppColors.textPrimary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title,
                                style: TextStyle(
                                  color: _isEnabled
                                      ? Colors.white
                                      : AppColors.textTertiary,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  decoration: _isEnabled
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    widget.reminder.isSynced
                                        ? LucideIcons.cloud
                                        : LucideIcons.cloudOff,
                                    size: 11,
                                    color: _isEnabled
                                        ? Colors.white.withAlpha(180)
                                        : AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.reminder.isSynced ? 'Cloud Synced' : 'Local Draft',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: _isEnabled
                                          ? Colors.white.withAlpha(200)
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPowerSwitch(isDark),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 2. Centerpiece: Big Days Left Display + Due Pill
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COUNTDOWN',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: _isEnabled
                                    ? Colors.white.withAlpha(170)
                                    : AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dueText,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: _isEnabled
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isEnabled
                                ? (isUrgent
                                    ? const Color(0xFFDC2626).withAlpha(180)
                                    : Colors.black.withAlpha(35))
                                : (isDark ? const Color(0xFF222B2D) : const Color(0xFFE8EADE)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isEnabled
                                  ? (isUrgent
                                      ? Colors.white.withAlpha(90)
                                      : Colors.white.withAlpha(40))
                                  : AppColors.borderSubtle,
                              width: 0.8,
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
                                      ? (isUrgent ? Colors.white : AppColors.success)
                                      : AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isEnabled
                                    ? (isUrgent ? 'URGENT' : 'ACTIVE')
                                    : 'MUTED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: _isEnabled ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 3. Validity Progress Bar
                    if (progress != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Timeline Lifecycle',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _isEnabled
                                      ? Colors.white.withAlpha(160)
                                      : AppColors.textTertiary,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}% elapsed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _isEnabled
                                      ? Colors.white.withAlpha(200)
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: Colors.black.withAlpha(_isEnabled ? 35 : 15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isEnabled
                                    ? (isUrgent
                                        ? const Color(0xFFFF4D4D)
                                        : Colors.white)
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 4. Bottom Row: Schedule Pill + Quick Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isEnabled
                                  ? Colors.black.withAlpha(25)
                                  : (isDark ? const Color(0xFF1E2628) : const Color(0xFFE5E7DA)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isEnabled
                                    ? Colors.white.withAlpha(35)
                                    : AppColors.borderSubtle,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.alarmClock,
                                  size: 13,
                                  color: _isEnabled ? Colors.white : AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${_formatDateShort(effectiveDate)} • ${_time.format(context)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _isEnabled
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _actionCircleButton(
                              icon: LucideIcons.pencil,
                              tooltip: 'Edit',
                              onTap: () => _openEditDialog(context),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 6),
                            _actionCircleButton(
                              icon: LucideIcons.trash2,
                              tooltip: 'Delete',
                              isDestructive: true,
                              onTap: () => _openDeleteDialog(context),
                              isDark: isDark,
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

  Widget _actionCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isDestructive = false,
    required bool isDark,
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
            color: _isEnabled
                ? Colors.black.withAlpha(isDestructive ? 50 : 30)
                : (isDark ? const Color(0xFF222B2D) : const Color(0xFFE2E4D8)),
            border: Border.all(
              color: _isEnabled
                  ? Colors.white.withAlpha(isDestructive ? 70 : 45)
                  : AppColors.borderSubtle,
              width: 0.8,
            ),
          ),
          child: Icon(
            icon,
            size: 13.5,
            color: _isEnabled
                ? (isDestructive ? const Color(0xFFFFB3B3) : Colors.white)
                : (isDestructive ? Colors.redAccent : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildPowerSwitch(bool isDark) {
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
          alignment: _isEnabled ? Alignment.centerRight : Alignment.centerLeft,
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

    // Optimistic in-memory update for 0ms UI response
    widget.onUpdate?.call(updated);

    if (newEnabled) {
      unawaited(_scheduleAlarm(updated));
    } else {
      unawaited(flutterLocalNotificationsPlugin.cancel(widget.reminder.index));
    }
    unawaited(_updateDatabase(updated));
  }

  void _openEditDialog(BuildContext context) {
    _showEditModal(
      context: context,
      reminder: widget.reminder.copyWith(
        title: _title,
        time: _time,
        expiry_date: _expiryDate,
        reminderDate: _reminderDate,
        isEnabled: _isEnabled,
      ),
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
        final updated = widget.reminder.copyWith(
          title: newTitle,
          time: newTime,
          reminderDate: newDate,
          isEnabled: _isEnabled,
        );
        widget.onUpdate?.call(updated);
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

  double? _calculateProgress(DateTime issueDate, DateTime expiryDate) {
    if (issueDate.year <= 1970) return null;
    final now = DateTime.now();
    final total = expiryDate.difference(issueDate).inSeconds;
    if (total <= 0) return 1.0;
    final elapsed = now.difference(issueDate).inSeconds;
    if (elapsed <= 0) return 0.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

// ---------------------------------------------------------------------------
// 📑 FOLIO TILE (For the list view & quick jump folio)
// ---------------------------------------------------------------------------
class _FolioTile extends StatelessWidget {
  final Reminder reminder;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(int id)? onDelete;

  const _FolioTile({
    required this.reminder,
    required this.index,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final effectiveDate = reminder.reminderDate ?? reminder.expiry_date;
    final daysLeft = _calculateDaysLeft(effectiveDate);
    final dueText = _formatDueText(daysLeft);
    final isUrgent = daysLeft <= 3 && reminder.isEnabled;
    final categoryIcon = getCategoryIconForTitle(reminder.title);

    return _SwipeDismissWrapper(
      reminder: reminder,
      onDelete: onDelete,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF222C2E) : const Color(0xFFE5E8DA))
                : (isDark ? const Color(0xFF182022) : AppColors.surface),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withAlpha(120)
                  : AppColors.borderSubtle,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              build3DIconWell(
                categoryIcon,
                isDark,
                isUrgent,
                reminder.isEnabled,
                size: 38,
                iconSize: 18,
                iconColor: reminder.isEnabled
                    ? (isUrgent ? AppColors.primary : AppColors.textPrimary)
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: reminder.isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        decoration: reminder.isEnabled
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatDateShort(effectiveDate)} • ${reminder.time.format(context)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: reminder.isEnabled
                      ? (isUrgent
                          ? const Color(0xFFDC2626).withAlpha(30)
                          : (isDark ? Colors.white.withAlpha(15) : const Color(0xFFE8EADE)))
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: reminder.isEnabled && isUrgent
                        ? const Color(0xFFDC2626).withAlpha(70)
                        : AppColors.borderSubtle,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  dueText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: reminder.isEnabled
                        ? (isUrgent ? AppColors.primary : AppColors.textPrimary)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(size * 0.32),
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
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: child,
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Delete Reminder',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${reminder.title}"? This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(BuildContext context) async {
    unawaited(flutterLocalNotificationsPlugin.cancel(reminder.index));
    onDelete?.call(reminder.id);

    try {
      await ReminderLocalDataSource().deleteReminder(reminder.id);
    } catch (_) {}

    unawaited(_syncRemoteDelete(reminder));
  }
}

// ---------------------------------------------------------------------------
// 🛠️ SHARED HELPERS & TIME FORMATTERS
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

String _formatDateShort(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

Future<void> _scheduleAlarm(Reminder reminder) async {
  final targetDate = reminder.reminderDate ?? reminder.expiry_date;
  final scheduledDateTime = DateTime(
    targetDate.year,
    targetDate.month,
    targetDate.day,
    reminder.time.hour,
    reminder.time.minute,
  );

  var tzTarget = tz.TZDateTime.from(scheduledDateTime, tz.local);
  if (tzTarget.isBefore(tz.TZDateTime.now(tz.local))) {
    tzTarget = tzTarget.add(const Duration(days: 1));
  }

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

Future<void> _updateDatabase(Reminder updated) async {
  final isar = await IsarService().db;
  final existing = await isar.reminderLocals.get(updated.id);
  if (existing != null) {
    existing.isEnabled = updated.isEnabled;
    existing.title = updated.title;
    existing.time =
        '${updated.time.hour.toString().padLeft(2, '0')}:${updated.time.minute.toString().padLeft(2, '0')}';
    existing.reminderDate = updated.reminderDate;
    existing.updatedAt = DateTime.now();
    existing.synced = false;
    await ReminderLocalDataSource().updateReminder(existing);
  }

  unawaited(_syncRemoteUpdate(updated, existing));
}

Future<void> _syncRemoteUpdate(Reminder updated, dynamic existing) async {
  try {
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (hasInternet) {
      try {
        await UpdateReminder().updateReminder(
          index: updated.index,
          title: updated.title,
          time:
              '${updated.time.hour.toString().padLeft(2, '0')}:${updated.time.minute.toString().padLeft(2, '0')}',
          setDate: updated.reminderDate ?? updated.expiry_date,
          isEnabled: updated.isEnabled,
        );
        if (existing != null) {
          existing.synced = true;
          await ReminderLocalDataSource().updateReminder(existing);
        }
      } catch (_) {}
    }
  } catch (_) {}
}

Future<void> _syncRemoteDelete(Reminder reminder) async {
  try {
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (hasInternet) {
      try {
        await DeleteReminder().deleteReminder(reminder.index.toString());
        return;
      } catch (_) {}
    }
    final isar = await IsarService().db;
    await isar.writeTxn(() async {
      await isar.pendingDeletions.put(
        PendingDeletion()
          ..remoteIndex = reminder.index.toString()
          ..deletedAt = DateTime.now(),
      );
    });
  } catch (_) {}
}

Future<void> _performBackgroundDelete(Reminder reminder) async {
  try {
    await ReminderLocalDataSource().deleteReminder(reminder.id);
  } catch (_) {}
  await _syncRemoteDelete(reminder);
}

// ---------------------------------------------------------------------------
// ✏️ EDIT MODAL (WITH AUTO-CLOSING DATEPICKER)
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
  final datePopoverController = ShadPopoverController();
  TimeOfDay selectedTime = currentTime;
  DateTime selectedDate = currentReminderDate ??
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
    pageBuilder: (ctx, a1, a2) => const SizedBox(),
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          onChanged: (v) => title = v,
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
                          popoverController: datePopoverController,
                          closeOnSelection: true,
                          placeholder: const Text('Select reminder date'),
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
                            datePopoverController.hide();
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
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                                  borderRadius: BorderRadius.circular(12),
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
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: isDark
                                            ? ColorScheme.dark(
                                                primary: AppColors.primary,
                                                onPrimary: Colors.white,
                                                surface: AppColors.surface,
                                                onSurface: AppColors.textPrimary,
                                              )
                                            : ColorScheme.light(
                                                primary: AppColors.primary,
                                                onPrimary: Colors.white,
                                                surface: AppColors.surface,
                                                onSurface: AppColors.textPrimary,
                                              ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  selectedTime = picked;
                                  (context as Element).markNeedsBuild();
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
                                foregroundColor: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                datePopoverController.dispose();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            const Spacer(),
                            ShadButton(
                              backgroundColor: AppColors.primary,
                              child: const Text('Save Changes'),
                              onPressed: () async {
                                final ok = editFormKey.currentState!.saveAndValidate();
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

                                datePopoverController.dispose();

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ShadToaster.of(context).show(
                                    ShadToast(
                                      duration: const Duration(milliseconds: 1500),
                                      backgroundColor: AppColors.success,
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
    pageBuilder: (ctx, a1, a2) => const SizedBox(),
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
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadButton(
                          backgroundColor: const Color(0xFFDC2626),
                          child: const Text('Delete'),
                          onPressed: () {
                            unawaited(flutterLocalNotificationsPlugin.cancel(reminder.index));
                            onDelete?.call(reminder.id);
                            if (context.mounted) {
                              Navigator.of(context).pop(true);
                              ShadToaster.of(context).show(
                                const ShadToast(
                                  duration: Duration(milliseconds: 1500),
                                  backgroundColor: AppColors.success,
                                  title: Text(
                                    'Reminder Deleted',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }
                            unawaited(_performBackgroundDelete(reminder));
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
// 💫 SCROLL BEHAVIOR
// ---------------------------------------------------------------------------
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
