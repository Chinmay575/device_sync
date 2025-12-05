import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';

class DisconnectReq {
  Event? event;
  Device device;

  DisconnectReq({this.event = .DISCONNECT, required this.device});

  Map<String, dynamic> toMap() {
    return {'event': event?.name, 'device': device.toMap()};
  }

  factory DisconnectReq.fromMap(Map<String, dynamic> map) {
    return DisconnectReq(
      event: Event.values.parse(map['event']),
      device: .fromMap(map['device']),
    );
  }
}
