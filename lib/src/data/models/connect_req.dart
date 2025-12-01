import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/data/models/handshake_req.dart';

class ConnectReq extends HandshakeReq {
  String secret;

  ConnectReq({required super.device, required this.secret});

  @override
  Map<String, dynamic> toMap() {
    return {'secret': secret, 'device': device.toMap()};
  }

  factory ConnectReq.fromMap(Map<String, dynamic> map) {
    return ConnectReq(
      secret: map['secret'],
      device: Device.fromMap(map['device']),
    );
  }
}
