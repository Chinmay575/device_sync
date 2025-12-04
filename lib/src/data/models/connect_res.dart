import 'package:connect/src/data/models/device.dart';

class ConnectRes {
  num? status;
  Device? device;
  String msg;

  ConnectRes({required this.status, required this.device, required this.msg});

  Map<String, dynamic> toMap() {
    return {'status': status, 'device': device?.toMap(), 'msg': msg};
  }

  factory ConnectRes.fromMap(Map<String, dynamic> map) {
    return ConnectRes(
      status: map['status'] as num,
      device: Device.fromMap(map['device']),
      msg: map['msg'],
    );
  }
}
