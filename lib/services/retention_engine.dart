import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

/// The Retention Engine: The algorithm that makes users come back.
///
/// This is the "addiction layer" on top of the learning engine.
/// It handles:
/// - Smart notifications (triggered by user behavior, not spam)
/// - Perfect timing (when users are most likely to engage)
/// - Psychological triggers (streaks, loss aversion, variable rewards)
/// - Comeback mechanics (welcome back bonuses, not shame)
///
/// Philosophy: We want positive addiction (habit formation), not dark patterns.
class RetentionEngine {
  RetentionEngine._();
  static final RetentionEngine instance = RetentionEngine._();

  final _notifications = FlutterLocalNotificationsPlugin();
  
  // ── Storage keys ──────────────────────────────────────────────────────────
  static const _kNotificationsEnabled = 'retention_notifications_enabled';
  static const _kPreferredTime = 'retention_preferred_hour'; // 0-23
  static const _kLastOpenTime = 'retention_last_open_timestamp';
  static const _kNotificationsSent = 'retention_notifications_sent';
  static const _kComebackBonusEligible = 'retention_comeback_eligible';

  // ── Notification timing ───────────────────────────────────────────────────
  static const int defaultNotificationHour = 19; // 7 PM
  static const Duration streakDangerWindow = Duration(hours: 18);
  static const Duration comebackWindow = Duration(days: 3);

  // ── Variable reward messages ──────────────────────────────────────────────
  static final List<String> _streakMessages = [
    'Your streak is on fire!',
    'Keep the momentum going!',
    'Amazing streak! Don\'t break it now!',
    'You\'re unstoppable!',
  ];

  static final List<String> _comebackMessages = [
    'We missed you! Your words are waiting.',
    'Ready to continue learning?',
    'Dëëri jööt? (How are you?) Come learn!',
    'Your progress is still here. Let\'s continue!',
  ];

  static final List<String> _dailyMessages = [
    'Time for your daily practice!',
    'Learn 5 words in 3 minutes today!',
    'Your Daily 5 is ready!',
    'Keep your streak alive!',
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // Initialization
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(initSettings);
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl == null) return false;
    
    // Request POST_NOTIFICATIONS permission (Android 13+)
    final notificationPermission = await androidImpl.requestNotificationsPermission();
    
    // Request exact alarm permission (Android 12+)
    // Note: On Android 12+, exact alarms require explicit permission
    // Users may need to enable this in Settings > Apps > Learn Dha Anywaa > Alarms & reminders
    final exactAlarmPermission = await androidImpl.requestExactAlarmsPermission();
    
    return (notificationPermission ?? false) && (exactAlarmPermission ?? true);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Smart Notification Scheduling
  // ══════════════════════════════════════════════════════════════════════════

  /// Call this every time the app opens
  Future<void> onAppOpen() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLastOpenTime, DateTime.now().millisecondsSinceEpoch);
    
    // Cancel any pending notifications since they opened the app
    await _notifications.cancelAll();
    
    // Re-schedule if enabled
    final enabled = p.getBool(_kNotificationsEnabled) ?? false;
    if (enabled) {
      await _scheduleNextNotification();
    }
  }

  /// Enable notifications and set preferred time
  Future<void> enableNotifications({int? preferredHour}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotificationsEnabled, true);
    await p.setInt(_kPreferredTime, preferredHour ?? defaultNotificationHour);
    await _scheduleNextNotification();
  }

  /// Disable all notifications
  Future<void> disableNotifications() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotificationsEnabled, false);
    await _notifications.cancelAll();
  }

  /// The smart algorithm: decides WHEN and WHAT to send
  Future<void> _scheduleNextNotification() async {
    final p = await SharedPreferences.getInstance();
    final enabled = p.getBool(_kNotificationsEnabled) ?? false;
    if (!enabled) return;

    final hour = p.getInt(_kPreferredTime) ?? defaultNotificationHour;
    final lastOpen = p.getInt(_kLastOpenTime) ?? 0;
    final lastOpenTime = DateTime.fromMillisecondsSinceEpoch(lastOpen);
    final timeSinceOpen = DateTime.now().difference(lastOpenTime);

    // ── Decide notification type based on behavior ────────────────────────
    NotificationType type;
    Duration delay;

    if (timeSinceOpen > comebackWindow) {
      // Haven't opened in 3+ days → Comeback notification (urgent, friendly)
      type = NotificationType.comeback;
      delay = Duration(hours: 1); // Send soon
    } else if (timeSinceOpen > streakDangerWindow) {
      // Haven't opened today but streak is in danger → Streak reminder
      type = NotificationType.streakDanger;
      delay = _timeUntilNextHour(hour);
    } else {
      // Active user → Regular daily reminder
      type = NotificationType.daily;
      delay = _timeUntilTomorrow(hour);
    }

    await _scheduleNotification(type, delay);
  }

  Future<void> _scheduleNotification(NotificationType type, Duration delay) async {
    final (title, body) = _getNotificationContent(type);
    final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

    await _notifications.zonedSchedule(
      0, // notification ID
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Learning Reminder',
          channelDescription: 'Reminds you to practice Dha Anywaa daily',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Log it
    final p = await SharedPreferences.getInstance();
    final sent = p.getInt(_kNotificationsSent) ?? 0;
    await p.setInt(_kNotificationsSent, sent + 1);
  }

  (String, String) _getNotificationContent(NotificationType type) {
    final random = Random();
    
    switch (type) {
      case NotificationType.streakDanger:
        final msg = _streakMessages[random.nextInt(_streakMessages.length)];
        return ('Streak Alert!', msg);
      
      case NotificationType.comeback:
        final msg = _comebackMessages[random.nextInt(_comebackMessages.length)];
        return ('Welcome back!', msg);
      
      case NotificationType.daily:
        final msg = _dailyMessages[random.nextInt(_dailyMessages.length)];
        return ('Learn Dha Anywaa', msg);
    }
  }

  Duration _timeUntilNextHour(int targetHour) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, targetHour);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next.difference(now);
  }

  Duration _timeUntilTomorrow(int targetHour) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final targetTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, targetHour);
    return targetTime.difference(now);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Comeback Bonus System
  // ══════════════════════════════════════════════════════════════════════════

  /// Check if user is eligible for a comeback bonus
  Future<bool> isComebackEligible() async {
    final p = await SharedPreferences.getInstance();
    final lastOpen = p.getInt(_kLastOpenTime) ?? 0;
    final lastOpenTime = DateTime.fromMillisecondsSinceEpoch(lastOpen);
    final timeSinceOpen = DateTime.now().difference(lastOpenTime);
    
    return timeSinceOpen >= comebackWindow;
  }

  /// Grant comeback bonus (call when they open after 3+ days)
  Future<int> claimComebackBonus() async {
    final p = await SharedPreferences.getInstance();
    final eligible = await isComebackEligible();
    
    if (!eligible) return 0;
    
    // Give them a nice XP bonus
    const bonusXp = 50;
    await p.setInt(_kComebackBonusEligible, 0); // Mark as claimed
    
    return bonusXp;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Analytics & Settings
  // ══════════════════════════════════════════════════════════════════════════

  Future<RetentionStats> getStats() async {
    final p = await SharedPreferences.getInstance();
    return RetentionStats(
      notificationsEnabled: p.getBool(_kNotificationsEnabled) ?? false,
      preferredHour: p.getInt(_kPreferredTime) ?? defaultNotificationHour,
      totalNotificationsSent: p.getInt(_kNotificationsSent) ?? 0,
      lastOpenTime: DateTime.fromMillisecondsSinceEpoch(
        p.getInt(_kLastOpenTime) ?? 0,
      ),
    );
  }

  /// Check if the app can schedule exact alarms (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl == null) return false;
    
    // On Android 12+, check if SCHEDULE_EXACT_ALARM permission is granted
    return await androidImpl.canScheduleExactNotifications() ?? false;
  }
}

enum NotificationType {
  daily,
  streakDanger,
  comeback,
}

class RetentionStats {
  final bool notificationsEnabled;
  final int preferredHour;
  final int totalNotificationsSent;
  final DateTime lastOpenTime;

  const RetentionStats({
    required this.notificationsEnabled,
    required this.preferredHour,
    required this.totalNotificationsSent,
    required this.lastOpenTime,
  });

  Duration get timeSinceOpen => DateTime.now().difference(lastOpenTime);
}
