import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connect/src/data/models/packet.dart';
import 'package:flutter/foundation.dart';

abstract class _SocketClient {
  void connect(String ip, int port);

  void sendPacket(Packet p);
}

class SocketClient implements _SocketClient {
  Socket? socket;

  SocketClient._internal();

  static final SocketClient instance = ._internal();

  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get dataStream => _controller.stream;

  @override
  Future connect(String ip, int port) async {
    try {
      // int p = int.tryParse(port) ?? 0;
      socket = await Socket.connect(ip, port);

      final Map<String, String> _temp = {"data": "Hello from user"};
      print("Send packet called ${_temp}");
      socket?.write('${jsonEncode(_temp)}\n');

      socket?.setOption(SocketOption.tcpNoDelay, true);

      socket?.listen(
        (data) {
          final message = String.fromCharCodes(data);
          print(message);

          try {
            final json = jsonDecode(message);
            _controller.add(json);
          } catch (e, stk) {
            // debugPrint("Error parsing JSON: $e, $stk");
          }
        },
        onError: (error) {
          debugPrint('Server Error: $error');

          // client.close();
        },
        onDone: () {
          debugPrint('Server disconnected');

          // client.close();
        },
      );
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  @override
  void sendPacket(Packet packet) {
    print("Send packet called ${packet.toMap()}");
    String jsonString = jsonEncode(packet.toMap());
    socket?.write('$jsonString\n');
  }
}
