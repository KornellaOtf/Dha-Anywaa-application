import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Service for managing system notifications.
/// 
/// Handles OTA update notifications and requests necessary permissions.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification system.
  /// Call this once during app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap.
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Payload contains the action (e.g., 'open_update_page')
    // We'll handle navigation in the app
  }

  /// Request notification permission (Android 13+).
  /// Returns true if permission granted.
  Future<bool> requestPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return false;

    // Request permission for Android 13+ (API level 33+)
    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Check if notifications are enabled.
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return false;

    final permitted = await androidPlugin.areNotificationsEnabled();
    return permitted ?? false;
  }

  /// Show an update available notification.
  /// 
  /// [version] - The new version available (e.g., "1.2.14")
  /// [sizeBytes] - APK size in bytes
  /// [mandatory] - Whether the update is mandatory
  Future<void> showUpdateNotification({
    required String version,
    required int sizeBytes,
    required bool mandatory,
  }) async {
    if (!_initialized) await initialize();

    // Check permission first
    final hasPermission = await areNotificationsEnabled();
    if (!hasPermission) {
      debugPrint('Notification permission not granted');
      return;
    }

    final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final title = mandatory 
        ? 'Important Update Available'
        : 'Update Available';
    final body = mandatory
        ? 'Version $version ($sizeMB MB)\nThis update is required to continue using the app.'
        : 'Version $version ($sizeMB MB) is ready to download.';

    final androidDetails = AndroidNotificationDetails(
      'ota_updates',
      'OTA Updates',
      channelDescription: 'Notifications for app updates',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
      category: AndroidNotificationCategory.recommendation,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0, // Notification ID (0 = update notifications)
      title,
      body,
      notificationDetails,
      payload: 'open_update_page', // Used for navigation
    );
  }

  /// Show a download progress notification.
  /// 
  /// [progress] - Download progress (0.0 to 1.0)
  /// [bytesDownloaded] - Bytes downloaded so far
  /// [totalBytes] - Total bytes to download
  Future<void> showDownloadProgress({
    required double progress,
    required int bytesDownloaded,
    required int totalBytes,
  }) async {
    if (!_initialized) await initialize();

    final percentage = (progress * 100).toInt();
    final downloadedMB = (bytesDownloaded / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

    final androidDetails = AndroidNotificationDetails(
      'ota_downloads',
      'OTA Downloads',
      channelDescription: 'Download progress for app updates',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: percentage,
      icon: '@mipmap/ic_launcher',
      ongoing: true, // Cannot be dismissed while downloading
      autoCancel: false,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1, // Notification ID (1 = download progress)
      'Downloading Update',
      '$downloadedMB MB / $totalMB MB ($percentage%)',
      notificationDetails,
    );
  }

  /// Show download complete notification.
  Future<void> showDownloadComplete() async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'ota_updates',
      'OTA Updates',
      channelDescription: 'Notifications for app updates',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.recommendation,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      2, // Notification ID (2 = download complete)
      'Update Ready',
      'Tap to install the update',
      notificationDetails,
      payload: 'install_update',
    );
  }

  /// Cancel download progress notification.
  Future<void> cancelDownloadProgress() async {
    await _notifications.cancel(1); // Cancel download progress notification
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
