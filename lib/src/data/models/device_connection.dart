import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/data/models/disconnect_req.dart';
import 'package:connect/src/data/models/packet.dart';
import 'package:connect/src/domain/bloc/client/client_bloc.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';

class DeviceConnection {
  // 1. The Mutable State (The Device Model)
  Device device;

  // 2. The Active Connection
  final Socket? socket;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();
  StreamSubscription? _sub;

  DeviceConnection({required this.device, this.socket});

  // 3. Expose Stream
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  // 4. Lifecycle Methods
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
              print("Parse Error: $e");
            }
          },
          onDone: () => _handleDisconnect(),
          onError: (e) => _handleDisconnect(),
        );
  }

  void send(Packet packet) {
    try {
      socket?.write('${jsonEncode(packet.toMap())}\n');
    } catch (e) {
      print("Send Error: $e");
    }
  }

  DeviceConnection updateDevice({
    String? ip,
    String? port,
    String? deviceName,
    String? model,
    DevicePlatform? platform,
    ConnectionStatus? status,
    String? secret,
  }) {
    device = device.copyWith(
      ip: ip,
      port: port,
      deviceName: deviceName,
      model: model,
      platform: platform,
      status: status,
      secret: secret,
    );
    return this;
  }

  void _handleDisconnect() {
    DisconnectReq req = DisconnectReq(device: device);
    _eventController.add(req.toMap());
    dispose();
  }

  void dispose() {
    _sub?.cancel();
    _eventController.close();
    socket?.destroy();
  }
}
