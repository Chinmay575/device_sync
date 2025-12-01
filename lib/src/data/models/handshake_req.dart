import 'package:connect/src/data/models/device.dart';

class HandshakeReq {
  Device device;

  HandshakeReq({required this.device});

  Map<String, dynamic> toMap() {
    return {'device': device.toMap()};
  }

  factory HandshakeReq.fromMap(Map<String, dynamic> map) {
    return HandshakeReq(device: Device.fromMap(map['device']));
  }
}
