import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

abstract class _SocketClient {
  Future<Socket> connect(String ip, int port);
}

class SocketClient implements _SocketClient {
  SocketClient._internal();

  static final SocketClient instance = ._internal();

  @override
  Future<Socket> connect(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port);

      final Map<String, String> temp = {"data": "Hello from user"};
      // print("Send packet called $_temp");
      socket.write('${jsonEncode(temp)}\n');
      socket.setOption(SocketOption.tcpNoDelay, true);
      return socket;
    } catch (e) {
      debugPrint("$e");
      rethrow;
    }
  }
}
