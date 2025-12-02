import 'package:connect/src/utils/constants/strings/enums.dart';

class RemoteMouseData {
  MouseEventType? type;
  Map<String, dynamic> mouseData;

  RemoteMouseData({required this.type, required this.mouseData});

  Map<String, dynamic> toMap() {
    return {'type': type?.name, 'mouseData': mouseData};
  }

  factory RemoteMouseData.fromMap(Map<String, dynamic> map) {
    return RemoteMouseData(
      type: MouseEventType.values.parse(map['type'] as String),
      mouseData: map["mouseData"] as Map<String, dynamic>,
    );
  }
}

class RemoteKeyboardData {}
