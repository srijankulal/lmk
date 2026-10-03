import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lmk/auth/services/google_auth.dart';
import 'package:lmk/components/buildCard.dart';
import 'package:lmk/components/floatActionButton.dart';
import 'package:lmk/data/local/reminder_local.dart';
import 'package:lmk/data/local/user_local.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:lmk/data/repository/remote/post_repo.dart';
import 'package:lmk/services/sync_service.dart';
import 'package:lmk/services/settings_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<Reminder> reminders = [];
  String? token;
  StreamSubscription<InternetStatus>? _connectionSubscription;
  bool _isOnline = true;
  String name = 'User';
  String photoUrl =
      "https://img.icons8.com/?size=100&id=85120&format=png&color=000000";

  // Filter & Search states (matching reference image)
  String _selectedFilter = 'All'; // 'All', 'Active', 'Disabled'
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSyncing = false;

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    setState(() => _isSyncing = true);
    try {
      if (_isOnline) {
        await SyncService().syncFull();
      }
      await _loadReminders();
      if (mounted) {
        HapticFeedback.mediumImpact();
        ShadToaster.of(context).show(
          ShadToast(
            duration: const Duration(milliseconds: 1500),
            backgroundColor: AppColors.primary,
            title: const Text(
              'Sync Complete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            description: Text(
              _isOnline
                  ? 'All reminders synchronized'
                  : 'Offline mode: local database up-to-date',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error refreshing reminders: $e");
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
    _initToken();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
    _initNotifications();
    _load();
    //start listening to connectivity changes
    _subscribeToConnection();
    // Request full-screen intent permission after the first frame so the
    // system has a visible activity to attach the permission dialog to.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestFullScreenPermission();
    });
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final t = await user.getIdToken();
      if (!mounted) return;
      setState(() => token = t);
      await _loadReminders();
    }
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userLocal = await UserLocalDataSource().getUser();
        if (!mounted) return;
        setState(() {
          name = userLocal?.name ?? name;
          photoUrl = userLocal?.photoUrl ?? photoUrl;
        });
      } catch (e) {
        // Silently ignore user load errors
      }
    }
    if (token != null) {
      await _loadReminders();
    }
  }

  void _subscribeToConnection() {
    InternetConnection().hasInternetAccess.then((online) {
      if (mounted) setState(() => _isOnline = online);
    });

    _connectionSubscription = InternetConnection().onStatusChange.listen((
      InternetStatus status,
    ) async {
      final online = status == InternetStatus.connected;
      if (!mounted) return;

      if (online != _isOnline) {
        setState(() => _isOnline = online);
        if (online) {
          await SyncService().syncAll();
        } else {
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: const Text('You are offline'),
              description: const Text('Some actions will be unavailable.'),
            ),
          );
        }
      }
    });
  }

  Future<void> _loadReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    ReminderLocalDataSource localDataSource = ReminderLocalDataSource();
    final localReminders = await localDataSource.getReminders(user.uid);
    if (!mounted) return;
    setState(() {
      reminders = localReminders
          .map(
            (localReminder) => Reminder(
              userId: localReminder.userId,
              id: localReminder.id,
              title: localReminder.title,
              expiry_date: localReminder.expiryDate ?? DateTime.now(),
              reminderDate: localReminder.reminderDate,
              time: _parseTimeOfDay(localReminder.time),
              index: localReminder.index ?? localReminder.id,
              isEnabled: localReminder.isEnabled ?? true,
              issue_date: localReminder.issuedDate ?? DateTime(0, 0, 0),
              isSynced: localReminder.synced ?? false,
            ),
          )
          .toList();
    });
  }

  TimeOfDay _parseTimeOfDay(String? time) {
    if (time == null || !time.contains(':')) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  Future<void> _initNotifications() async {
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
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
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);
  }

  Future<void> _requestFullScreenPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestFullScreenIntentPermission();
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    _searchController.dispose();
    _controller.dispose();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<bool> checkNotificationPermission() async {
    final bool? granted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    return granted ?? false;
  }

  void showPermissionDeniedToast() {
    final theme = ShadTheme.of(context);
    ShadToaster.of(context).show(
      ShadToast.destructive(
        title: const Text('Notifications disabled'),
        description: const Text(
          'Enable notifications in Settings to receive reminders.',
        ),
        action: ShadButton.destructive(
          decoration: ShadDecoration(
            border: ShadBorder.all(
              color: theme.colorScheme.destructiveForeground,
              width: 1,
            ),
          ),
          onPressed: () {
            ShadToaster.of(context).hide();
          },
          child: const Text('Dismiss'),
        ),
      ),
    );
  }

  void showOfflineToast() {
    final theme = ShadTheme.of(context);
    ShadToaster.of(context).show(
      ShadToast.destructive(
        title: const Text('You are offline'),
        description: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(LucideIcons.squarePen, size: 16),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Some actions will be unavailable. Use Manual entry.',
              ),
            ),
          ],
        ),
        action: ShadButton.destructive(
          decoration: ShadDecoration(
            border: ShadBorder.all(
              color: theme.colorScheme.destructiveForeground,
              width: 1,
            ),
          ),
          onPressed: () {
            ShadToaster.of(context).hide();
          },
          child: const Text('Dismiss'),
        ),
      ),
    );
  }

  DateTime _combineReminderDateTime(Reminder r) {
    final date = r.reminderDate ?? r.expiry_date;
    return DateTime(
      date.year,
      date.month,
      date.day,
      r.time.hour,
      r.time.minute,
    );
  }

  MapEntry<Reminder, DateTime>? _upcomingReminder() {
    final now = DateTime.now();
    final entries = reminders
        .where((r) => r.isEnabled)
        .map((r) => MapEntry(r, _combineReminderDateTime(r)))
        .where((e) => e.value.isAfter(now))
        .toList();
    if (entries.isEmpty) return null;
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries.first;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  List<Reminder> get _filteredReminders {
    var list = reminders;
    if (_searchQuery.trim().isNotEmpty) {
      list = list
          .where(
            (r) =>
                r.title.toLowerCase().contains(_searchQuery.trim().toLowerCase()),
          )
          .toList();
    }
    if (_selectedFilter == 'Active') {
      return list.where((r) => r.isEnabled).toList();
    } else if (_selectedFilter == 'Disabled') {
      return list.where((r) => !r.isEnabled).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode;
        final upcoming = _upcomingReminder();
        final filtered = _filteredReminders;
        final activeCount = reminders.where((r) => r.isEnabled).length;
        final totalCount = reminders.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Ambient luxury background orbs
              Positioned(
                top: -60,
                left: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(isDark ? 30 : 20),
                  ),
                ),
              ),
              Positioned(
                top: 240,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withAlpha(isDark ? 25 : 16),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                left: -40,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(isDark ? 22 : 15),
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: const SizedBox.expand(),
              ),

              FadeTransition(
                opacity: _animation,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Header Row: User Avatar & Search/Online Pill
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left: LMK 3D Brand Logo with Live Online Dot & Title
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (!_isOnline) {
                                      showOfflineToast();
                                    } else {
                                      ShadToaster.of(context).show(
                                        const ShadToast(
                                          duration: Duration(seconds: 2),
                                          title: Text('LMK Online'),
                                          description: Text(
                                            'All reminders are synced with cloud.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isDark ? Colors.black : const Color(0xFF2E3A3B))
                                                  .withAlpha(isDark ? 80 : 30),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.asset(
                                            'assets/images/logo.png',
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: AppColors.primary,
                                              child: const Center(
                                                child: Text(
                                                  'LMK',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Glowing Online/Offline Status Dot
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _isOnline ? AppColors.success : AppColors.error,
                                            border: Border.all(
                                              color: AppColors.background,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (_isOnline ? AppColors.success : AppColors.error)
                                                    .withAlpha(160),
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'LMK',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '• let me know',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textTertiary,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Hi, $name',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  // Theme Mode Toggle Button
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      ThemeController.instance.toggleTheme();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.surfaceGlass,
                                        border: Border.all(
                                          color: AppColors.borderSubtle,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.shadow,
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 260),
                                        transitionBuilder: (child, anim) =>
                                            RotationTransition(
                                          turns: anim,
                                          child: ScaleTransition(
                                            scale: anim,
                                            child: child,
                                          ),
                                        ),
                                        child: Icon(
                                          isDark
                                              ? LucideIcons.sun
                                              : LucideIcons.moon,
                                          key: ValueKey(isDark),
                                          size: 17,
                                          color: isDark
                                              ? const Color(0xFFFBBF24)
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Search Toggle Button (Matching reference image)
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _isSearching = !_isSearching;
                                    if (!_isSearching) {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    }
                                  });
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceGlass,
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isSearching
                                        ? LucideIcons.x
                                        : LucideIcons.search,
                                    size: 17,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 3. User Avatar Profile Button
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _showProfileSheet(context);
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.charcoalHeroGradient,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withAlpha(60)
                                          : AppColors.primary.withAlpha(90),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: photoUrl.isNotEmpty &&
                                            !photoUrl.contains('color=000000') &&
                                            (photoUrl.startsWith('http://') ||
                                                photoUrl.startsWith('https://'))
                                        ? Image.network(
                                            photoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Center(
                                              child: Text(
                                                name.trim().isNotEmpty
                                                    ? name.trim()[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              name.trim().isNotEmpty
                                                  ? name.trim()[0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                              ),
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

                  // Optional Search Bar
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 6.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search reminders...',
                            hintStyle: TextStyle(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      LucideIcons.x,
                                      size: 16,
                                      color: AppColors.textTertiary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (v) {
                            setState(() => _searchQuery = v);
                          },
                        ),
                      ),
                    ),

                  // 2. Section Title (Matching Stitch editorial design)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Reminders",
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E2628)
                                    : const Color(0xFFE8EADE),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withAlpha(20)
                                      : const Color(0xFFD6D9C8),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '${activeCount.toString().padLeft(2, '0')} Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFD8DAD0)
                                      : AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "$totalCount total",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Filter Chips Row (Matching Screen 1 in reference image: [All 3] [Already Done] [On Progress])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All',
                            count: totalCount,
                            isSelected: _selectedFilter == 'All',
                            onTap: () => setState(() => _selectedFilter = 'All'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Active',
                            count: activeCount,
                            isSelected: _selectedFilter == 'Active',
                            onTap: () => setState(() => _selectedFilter = 'Active'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Disabled',
                            count: totalCount - activeCount,
                            isSelected: _selectedFilter == 'Disabled',
                            onTap: () =>
                                setState(() => _selectedFilter = 'Disabled'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Upcoming Reminder Highlight Pill
                  if (upcoming != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 2.0,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withAlpha(30),
                              ),
                              child: const Icon(
                                LucideIcons.bellRing,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Next: ${upcoming.key.title} • ${_formatDate(upcoming.value)} at ${upcoming.key.time.format(context)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 4),

                  // 5. Reminder List View with Pull-to-Refresh
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppColors.primary,
                      backgroundColor: isDark ? const Color(0xFF1E2628) : Colors.white,
                      child: _isSyncing && reminders.isEmpty
                          ? _buildSkeletonLoader(isDark)
                          : BuildCard(
                              reminders: filtered,
                              onDelete: (int id) {
                                setState(() {
                                  reminders.removeWhere((r) => r.id == id);
                                });
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: GlassExpandableFab(
        actions: [
          FabAction(
            icon: LucideIcons.images,
            onTap: () async {
              final hasPermission = await checkNotificationPermission();
              if (!hasPermission) {
                showPermissionDeniedToast();
                return;
              }
              if (!_isOnline) {
                showOfflineToast();
                return;
              }
              await picker("gallery");
            },
          ),
          FabAction(
            icon: LucideIcons.camera,
            onTap: () async {
              final hasPermission = await checkNotificationPermission();
              if (!hasPermission) {
                showPermissionDeniedToast();
                return;
              }
              if (!_isOnline) {
                showOfflineToast();
                return;
              }
              await picker("camera");
            },
          ),
          FabAction(
            icon: LucideIcons.squarePen,
            onTap: () async {
              final nav = Navigator.of(context);
              final hasPermission = await checkNotificationPermission();
              if (!hasPermission) {
                showPermissionDeniedToast();
                return;
              }
              if (!mounted) return;
              DocData docData = DocData();
              nav.pushNamed('/docForm', arguments: docData);
            },
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeController.instance.isDarkMode;

    final Color bgColor;
    final Color textColor;
    final Color badgeBg;
    final Color badgeTextColor;
    final Color borderColor;

    if (isSelected) {
      if (isDark) {
        bgColor = const Color(0xCC263234);
        textColor = Colors.white;
        badgeBg = const Color(0xFFFF5722).withAlpha(45);
        badgeTextColor = const Color(0xFFFFB399);
        borderColor = Colors.white.withAlpha(45);
      } else {
        bgColor = const Color(0xFF2E3A3B); // Charcoal Slate from logo
        textColor = Colors.white;
        badgeBg = Colors.white.withAlpha(35);
        badgeTextColor = Colors.white;
        borderColor = const Color(0xFF2E3A3B);
      }
    } else {
      if (isDark) {
        bgColor = const Color(0x66182022);
        textColor = const Color(0xFF838F8D);
        badgeBg = const Color(0xFF13191A);
        badgeTextColor = const Color(0xFF838F8D);
        borderColor = Colors.white.withAlpha(15);
      } else {
        bgColor = const Color(0xFFE8EADE);
        textColor = const Color(0xFF606967);
        badgeBg = const Color(0xFFDCDFD0);
        badgeTextColor = const Color(0xFF606967);
        borderColor = const Color(0xFFE2E4D8);
      }
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: isDark
                    ? Colors.white.withAlpha(35)
                    : const Color(0xFF1C1924).withAlpha(50),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: badgeBg,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: badgeTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ListenableBuilder(
          listenable: Listenable.merge([ThemeController.instance, AppSettings.instance]),
          builder: (context, _) {
            final isDark = ThemeController.instance.isDarkMode;
            final user = FirebaseAuth.instance.currentUser;
            final email = user?.email ?? 'Logged In';
            final activeCount = reminders.where((r) => r.isEnabled).length;

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181524) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: isDark ? const Color(0x30FFFFFF) : const Color(0x15000000),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 90 : 30),
                    blurRadius: 30,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x40FFFFFF) : const Color(0x20000000),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // User Avatar with halo
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(50),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          photoUrl,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF221E30) : const Color(0xFFF7F3FB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$activeCount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Active Tasks',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF221E30) : const Color(0xFFF7F3FB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${reminders.length}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total Reminders',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 1. Notification Sound Selector
                    GestureDetector(
                      onTap: () {
                        _showSoundPicker(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221E30) : const Color(0xFFF5F0FB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0x20FFFFFF) : const Color(0x10000000),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? const Color(0xFF2E2940)
                                        : Colors.white,
                                  ),
                                  child: const Icon(
                                    LucideIcons.bellRing,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Notification Sound",
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      "${AppSettings.instance.currentSoundOption.name} • Tap to change",
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Full-Screen Intent Notification Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF221E30) : const Color(0xFFF5F0FB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0x20FFFFFF) : const Color(0x10000000),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? const Color(0xFF2E2940)
                                      : Colors.white,
                                ),
                                child: const Icon(
                                  LucideIcons.smartphone,
                                  size: 18,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Full-Screen Alert",
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    AppSettings.instance.fullScreenIntent
                                        ? "Full-screen takeover enabled"
                                        : "Standard notification banner",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: AppSettings.instance.fullScreenIntent,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) {
                              HapticFeedback.mediumImpact();
                              AppSettings.instance.setFullScreenIntent(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Cloud Sync Status & Action
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF221E30) : const Color(0xFFF5F0FB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0x20FFFFFF) : const Color(0x10000000),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? const Color(0xFF2E2940)
                                      : Colors.white,
                                ),
                                child: Icon(
                                  LucideIcons.cloud,
                                  size: 18,
                                  color: _isOnline ? const Color(0xFF38BDF8) : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Cloud Sync",
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _isOnline ? "Online & connected" : "Offline mode",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _isSyncing
                                ? null
                                : () async {
                                    await _handleRefresh();
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(80),
                                  width: 0.9,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isSyncing)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      LucideIcons.refreshCw,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isSyncing ? "Syncing..." : "Sync Now",
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. Dark Mode Toggle Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF221E30) : const Color(0xFFF5F0FB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0x20FFFFFF) : const Color(0x10000000),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? const Color(0xFF2E2940)
                                      : Colors.white,
                                ),
                                child: Icon(
                                  isDark ? LucideIcons.moon : LucideIcons.sun,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Dark Mode",
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    isDark ? "Obsidian Velvet theme" : "Warm Linen Paper theme",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: isDark,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) {
                              HapticFeedback.mediumImpact();
                              ThemeController.instance.toggleTheme();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign Out Button
                    GestureDetector(
                      onTap: () async {
                        final nav = Navigator.of(context);
                        nav.pop();
                        await AuthMethods().signOut();
                        if (!mounted) return;
                        nav.pushReplacementNamed('/signIn');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.error.withAlpha(50),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.logOut,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Sign Out",
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LMK — Let Me Know • v1.0.0',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSoundPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (pickerCtx) {
        return ListenableBuilder(
          listenable: AppSettings.instance,
          builder: (context, _) {
            final isDark = ThemeController.instance.isDarkMode;
            final selected = AppSettings.instance.selectedSound;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181524) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark
                      ? const Color(0x30FFFFFF)
                      : const Color(0x15000000),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 100 : 40),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0x40FFFFFF)
                              : const Color(0x20000000),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Notification Sound",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Tap to preview",
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Select your audio alert tone (includes Faahh sound).",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...AppSettings.availableSounds.map((sound) {
                      final isCurrent = sound.id == selected;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await AppSettings.instance
                                .setNotificationSound(sound.id);
                            await AppSettings.instance.previewSound(sound.id);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? (isDark
                                      ? AppColors.primary.withAlpha(40)
                                      : AppColors.primary.withAlpha(20))
                                  : (isDark
                                      ? const Color(0xFF221E30)
                                      : const Color(0xFFF7F3FB)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.primary
                                        .withAlpha(isDark ? 120 : 90)
                                    : (isDark
                                        ? const Color(0x18FFFFFF)
                                        : const Color(0x10000000)),
                                width: isCurrent ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCurrent
                                        ? AppColors.primary
                                        : (isDark
                                            ? const Color(0xFF2E2940)
                                            : Colors.white),
                                  ),
                                  child: Icon(
                                    sound.icon,
                                    size: 17,
                                    color: isCurrent
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : AppColors.secondary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sound.name,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: isCurrent
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sound.description,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                    child: const Icon(
                                      LucideIcons.check,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Featured Hero Card Skeleton
        Container(
          height: 195,
          decoration: BoxDecoration(
            color: isDark ? const Color(0x332E3A3B) : const Color(0xFFE8EADE),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0x20FFFFFF)
                  : const Color(0xFFD6D9C8),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 110,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(25)
                          : Colors.black.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(25)
                          : Colors.black.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 180,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(30)
                      : Colors.black.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(12),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(20)
                          : Colors.black.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Deck Card 1 Skeleton
        Container(
          height: 84,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0x222E3A3B)
                : const Color(0xFFEDEDE2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0x15FFFFFF)
                  : const Color(0xFFE2E4D8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Deck Card 2 Skeleton
        Container(
          height: 84,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0x182E3A3B)
                : const Color(0xFFF1F2E8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0x10FFFFFF)
                  : const Color(0xFFE8EADE),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> picker(String source) async {
    // ... (keep the rest of the picker method as is)
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source == "camera" ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 60, // 0-100 (lower = smaller)
      );

      if (!mounted) return;

      if (image == null) {
        buildErrorToast(context);
        return;
      }
      final img = image.path;
      // final byteSize = await image.length();
      // print(
      //   'Picked image size: $byteSize bytes (${(byteSize / 1024).toStringAsFixed(2)} KB)',
      // );

      PostRepository postRepo = PostRepository();
      final loading = SpinKitFadingCube(color: AppColors.primary, size: 25.0);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        loading,
                        const SizedBox(height: 16),
                        Text(
                          'Processing image...',
                          style: TextStyle(color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
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

      DocData? docData = await postRepo.fetchDocData(img);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (docData == null) {
        if (!mounted) return;
        buildErrorToast(context);
        return;
      }
      Navigator.pushNamed(context, '/docForm', arguments: docData);
    } catch (e) {
      print("Error picking image: $e");
      if (!mounted) return;
      buildErrorToast(context, source);
    }
  }

  void buildErrorToast(BuildContext context, [String which = '']) {
    // ... (keep as is)
    final theme = ShadTheme.of(context);
    ShadToaster.of(context).show(
      ShadToast.destructive(
        title: Text(
          which.isNotEmpty
              ? 'Failed to pick from $which'
              : 'Uh oh! Something went wrong',
        ),
        description: Text(
          which.isNotEmpty
              ? 'There was a problem accessing your $which'
              : 'No image was selected',
        ),
        action: ShadButton.destructive(
          decoration: ShadDecoration(
            border: ShadBorder.all(
              color: theme.colorScheme.destructiveForeground,
              width: 1,
            ),
          ),
          onPressed: which.isNotEmpty
              ? () async {
                  ShadToaster.of(context).hide();
                  await picker(which);
                }
              : () {
                  ShadToaster.of(context).hide();
                },
          child: Text(which.isNotEmpty ? 'Try again' : 'Dismiss'),
        ),
      ),
    );
  }
}
