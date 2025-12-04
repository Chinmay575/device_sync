import 'dart:async';
import 'dart:io';

import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/data/models/device_connection.dart';
import 'package:connect/src/utils/constants/strings/server_config.dart';
import 'package:flutter/material.dart';

abstract class _SocketServer {
  Future<void> start(Device device, {required int port});
}

class SocketServer implements _SocketServer {
  ServerSocket? _serverSocket;

  SocketServer._internal();

  static final SocketServer instance = ._internal();

  String? _ip = "";

  String get ip => _ip ?? "";

  int get port {
    return _serverSocket?.port ?? 0;
  }

  final StreamController<DeviceConnection> _deviceStream =
      StreamController.broadcast();
  Stream<DeviceConnection> get deviceStream => _deviceStream.stream;

  @override
  Future<void> start(Device device, {required int port}) async {
    _ip = device.ip;
    try {
      _serverSocket = await .bind(InternetAddress.anyIPv4, port);
      debugPrint('Server started on port: $port');
      _serverSocket?.listen((Socket client) {
        print("Connection from ${client.address}");
        final device = Device(
          ip: client.remoteAddress.address,
          platform: .unknown,
          port: client.port.toString(),
          deviceName: '',
          model: '',
        );

        DeviceConnection connection = .new(device: device, socket: client);

        _deviceStream.add(connection);
      });
    } on SocketException {
      if (port == ServerConfig.PORT) {
        start(device, port: ServerConfig.PORT + 1);
      }
    }
  }
}
