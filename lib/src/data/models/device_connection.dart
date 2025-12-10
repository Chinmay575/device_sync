// ignore_for_file: must_be_immutable

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/data/models/disconnect_req.dart';
import 'package:connect/src/data/models/notification_data.dart';
import 'package:connect/src/data/models/packet.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class DeviceConnection extends Equatable {
  // --- DATA (Immutable State) ---
  final Device device;
  final List<NotificationData> notifications;

  // --- LOGIC (Connection Handles) ---
  // These are excluded from 'props' but preserved during copyWith
  final Socket? socket;
  final StreamController<Map<String, dynamic>> _eventController;

  // _sub must be mutable because startListening() is called after initialization
  StreamSubscription? _sub;

  // --- CONSTRUCTORS ---

  // 1. Private Constructor: Used internally by copyWith to preserve connection state
  DeviceConnection._internal({
    required this.device,
    required this.notifications,
    required this.socket,
    required StreamController<Map<String, dynamic>> controller,
    this.connectionSubscription,
  }) : _eventController = controller,
       _sub = connectionSubscription;

  // 2. Public Constructor: Used when first creating the connection
  DeviceConnection({required this.device, this.socket})
    : notifications = const [],
      _eventController = StreamController.broadcast(),
      _sub = null,
      connectionSubscription = null;

  // Temporary holder for the subscription when copying
  final StreamSubscription? connectionSubscription;

  // --- GETTERS ---
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  // --- LOGIC METHODS ---

  void startListening() {
    if (_sub != null) return; // Already listening

    _sub = socket
        ?.cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.trim().isEmpty) return;
            try {
              _eventController.add(jsonDecode(line));
            } catch (e) {
              debugPrint("Parse Error: $e");
            }
          },
          onDone: () => _handleDisconnect(),
          onError: (e) => _handleDisconnect(),
        );
  }

  void send(Packet packet) {
    // debugPrint("send packet called ${packet.data}");
    try {
      socket?.write('${jsonEncode(packet.toMap())}\n');
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  void _handleDisconnect() {
    DisconnectReq req = DisconnectReq(device: device);
    if (!_eventController.isClosed) {
      _eventController.add(req.toMap());
    }
    dispose();
  }

  void dispose() {
    _sub?.cancel();
    if (!_eventController.isClosed) _eventController.close();
    socket?.destroy();
  }

  // --- STATE UPDATE METHODS (CopyWith Pattern) ---

  /// Creates a NEW instance with updated Device data
  DeviceConnection updateDevice({
    String? ip,
    String? port,
    String? deviceName,
    String? model,
    DevicePlatform? platform,
    ConnectionStatus? status,
    String? secret,
  }) {
    return DeviceConnection._internal(
      // Create new Device model
      device: device.copyWith(
        ip: ip,
        port: port,
        deviceName: deviceName,
        model: model,
        platform: platform,
        status: status,
        secret: secret,
      ),
      // Keep existing Data/Logic
      notifications: notifications,
      socket: socket,
      controller: _eventController,
      connectionSubscription: _sub,
    );
  }

  /// Creates a NEW instance with a NEW list containing the notification
  DeviceConnection updateNotifications(NotificationData event) {
    // Avoid duplicates if necessary
    if (notifications.any(
      (e) => e.id == event.id && e.content == event.content,
    )) {
      return this;
    }

    return DeviceConnection._internal(
      device: device,
      // Create a NEW List reference (Crucial for BLoC rebuilds)
      notifications: List.from(notifications)..add(event),
      // Keep existing Logic
      socket: socket,
      controller: _eventController,
      connectionSubscription: _sub,
    );
  }

  DeviceConnection removeNotification(int? id) {
    // Avoid duplicates if necessary
    if (id == null) {
      notifications.clear();
    } else {
      notifications.removeWhere((e) => e.id == id);
    }

    return DeviceConnection._internal(
      device: device,
      // Create a NEW List reference (Crucial for BLoC rebuilds)
      notifications: List.from(notifications),
      // Keep existing Logic
      socket: socket,
      controller: _eventController,
      connectionSubscription: _sub,
    );
  }

  // --- EQUATABLE ---
  // Only check 'device' and 'notifications'.
  // Ignore socket/streams for equality checks so rebuilds are pure.
  @override
  List<Object?> get props => [device, notifications];
}
