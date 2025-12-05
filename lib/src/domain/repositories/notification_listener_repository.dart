import 'dart:async';
import 'dart:io';
import 'package:connect/src/data/models/notification_data.dart';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';

abstract class _NotificationRepository {
  void initialize();

  void getAllNotifications();

  void dispose();
}

class NotificationListenerRepository implements _NotificationRepository {
  NotificationListenerRepository._internal();
  static final NotificationListenerRepository instance =
      NotificationListenerRepository._internal();

  // 2. Stream & State
  final StreamController<NotificationData> _notificationController =
      StreamController.broadcast();
  Stream<NotificationData> get notificationStream =>
      _notificationController.stream;

  StreamSubscription<ServiceNotificationEvent>? _subscription;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (Platform.isIOS) return;

    if (Platform.isAndroid) {
      bool isGranted = await NotificationListenerService.isPermissionGranted();
      if (!isGranted) {
        debugPrint("Requesting Notification Permission...");
        await NotificationListenerService.requestPermission();
        return;
      }
    }

    _isInitialized = true;
    _startListening();
  }

  void _startListening() {
    _subscription?.cancel();

    _subscription = NotificationListenerService.notificationsStream.listen((
      event,
    ) {
      _processNotification(event);
    }, onError: (e) => debugPrint("Notification Stream Error: $e"));
  }

  void _processNotification(ServiceNotificationEvent evt) {
    if (evt.packageName == null || evt.title == null) return;
    if (evt.packageName == 'com.example.connect') return;

    _notificationController.add(.new(event: evt, receivedAt: .now()));
  }

  // 4. Dispose (From Abstract Class)
  @override
  void dispose() {
    _subscription?.cancel();
    _notificationController.close();
    _isInitialized = false;
  }

  @override
  Future<void> getAllNotifications() async {
    List<ServiceNotificationEvent> e =
        await NotificationListenerService.getActiveNotifications();

    for (var i in e) {
      _processNotification(i);
    }
  }
}
