import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/data/models/packet.dart';
import 'package:connect/src/domain/repositories/device_repository.dart';
import 'package:connect/src/utils/constants/strings/server_config.dart';
import 'package:flutter/material.dart';

abstract class _SocketServer {
  Future<void> start(Device device, {required int port});
}

class SocketServer implements _SocketServer {
  ServerSocket? _serverSocket;

  SocketServer._internal();

  Socket? _socket;

  static final SocketServer instance = ._internal();

  String? _ip = "";

  String get ip => _ip ?? "";

  int get port {
    return _serverSocket?.port ?? 0;
  }

  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get dataStream => _controller.stream;

  @override
  Future<void> start(Device device, {required int port}) async {
    _ip = device.ip;
    try {
      _serverSocket = await .bind(InternetAddress.anyIPv4, port);
      debugPrint('Server started on port: $port');
      _serverSocket?.listen((Socket client) {
        _handleClient(client);
      });
    } on SocketException catch (e) {
      start(device, port: ServerConfig.PORT + 1);
    }
  }

  void _handleClient(Socket client) {
    _socket = client;
    debugPrint(
      'Connection from ${client.remoteAddress.address}:${client.remotePort}',
    );

    client.listen(
      (Uint8List data) {
        String message = .fromCharCodes(data);
        print(message);

        try {
          final json = jsonDecode(message);
          _controller.add(json);
        } catch (e) {
          debugPrint("Error parsing JSON: $e");
        }
      },
      onError: (error) {
        debugPrint('Client Error: $error');
        _socket = null;
        client.close();
      },
      onDone: () {
        debugPrint('Client disconnected');
        _socket = null;
        client.close();
      },
    );
  }

  void sendPacket(Packet packet) {
    print("send packet called on server ${packet.toMap()}");
    String jsonString = jsonEncode(packet.toMap());
    _socket?.write('$jsonString\n');
  }
}
