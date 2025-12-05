import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class _NotificationRepository {
  void initialize();

  void requestPermissions();

  void show({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  void cancel(int id);

  void cancelAll();

  void dispose();
}

class NotificationRepository implements _NotificationRepository {
  // 1. Singleton Pattern
  NotificationRepository._internal();
  static final NotificationRepository instance =
      NotificationRepository._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // --- ANDROID SETUP ---
    // 'mipmap/ic_launcher' must exist in android/app/src/main/res/
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // --- IOS / MACOS SETUP ---
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false, // We request later
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    // --- LINUX SETUP ---
    // Icons must be placed in linux/flutter/ephemeral/ or assets
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    // --- COMBINE SETTINGS ---
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
          linux: initializationSettingsLinux,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  @override
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  @override
  Future<void> show({
    required int id,
    Uint8List? icon,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Android Details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'connect_channel_id',
          'Connect Notifications',
          channelDescription: 'Notifications from connected devices',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    // iOS/macOS Details
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentSound: true,
      presentBanner: true,
      presentList: true,
    );

    // Linux Details
    final LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.normal,
      icon: (icon != null)
          ? ByteDataLinuxIcon(
              LinuxRawIconData(data: icon, width: 32, height: 32),
            )
          : null,
    );

    // General Details
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // 6. Dismiss All
  @override
  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Handle Tap Action
  void _onNotificationTap(NotificationResponse response) {
    // print("Notification Tapped: ${response.payload}");
    // Navigate or trigger event here
  }

  @override
  void dispose() {}
}
