import 'dart:typed_data';

import 'package:notification_listener_service/notification_event.dart';

class NotificationData implements ServiceNotificationEvent {
  @override
  Uint8List? appIcon;

  @override
  bool? canReply;

  @override
  String? content;

  @override
  Uint8List? extrasPicture;

  @override
  bool? hasRemoved;

  @override
  bool? haveExtraPicture;

  @override
  int? id;

  @override
  Uint8List? largeIcon;

  @override
  String? packageName;

  @override
  String? title;

  DateTime? receivedAt;

  @override
  Future<bool> sendReply(String message) async {
    return false;
  }

  NotificationData({required ServiceNotificationEvent event, this.receivedAt}) {
    appIcon = event.appIcon;
    canReply = event.canReply;
    content = event.content;
    packageName = event.packageName;
    extrasPicture = event.extrasPicture;
    hasRemoved = event.hasRemoved;
    haveExtraPicture = event.haveExtraPicture;
    id = event.id;
    largeIcon = event.largeIcon;
    title = event.title;
    onGoing = event.onGoing;
    appName = event.appName;
  }

  Map<String, dynamic> toMap() {
    return {
      'appIcon': appIcon,
      'canReply': canReply,
      'content': content,
      'extrasPicture': extrasPicture,
      'hasRemoved': hasRemoved,
      'haveExtraPicture': haveExtraPicture,
      'id': id,
      'largeIcon': largeIcon,
      'packageName': packageName,
      'title': title,
      'appName': appName,
      'receivedAt': receivedAt?.toIso8601String(),
    };
  }

  factory NotificationData.fromMap(Map<String, dynamic> map) {
    for (var i in map.entries) {
      if (i.value is List<dynamic>) {
        map[i.key] = Uint8List.fromList(List<int>.from(i.value));
      }
    }

    return NotificationData(
      event: .fromMap(map),
      receivedAt: DateTime.tryParse(map['receivedAt']),
    );
  }

  @override
  bool? onGoing;

  @override
  String? appName;
}
