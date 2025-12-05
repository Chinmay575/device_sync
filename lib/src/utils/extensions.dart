import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_event.dart';

extension BuildExtension on BuildContext {
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;
}

extension Capitalize on String {
  String get capitalize {
    if (length > 1) {
      return this[0].toUpperCase() + substring(1).toLowerCase();
    }
    return toUpperCase();
  }
}

extension Serializer on ServiceNotificationEvent {
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'id': id,
      'canReply': canReply,
      'haveExtraPicture': haveExtraPicture,
      'hasRemoved': hasRemoved,
      'notificationExtrasPicture': base64Encode(extrasPicture?.toList() ?? []),
      'packageName': packageName,
      'appIcon': base64Encode(appIcon?.toList() ?? []),
      'largeIcon': base64Encode(largeIcon?.toList() ?? []),
      'content': content,
    };
  }
}

extension TimeAgo on DateTime {
  String timeAgo() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 5) {
      return 'Just now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }
}
