part of 'server_bloc.dart';

sealed class ServerEvent extends Equatable {
  const ServerEvent();
}

class Initial extends ServerEvent {
  @override
  List<Object?> get props => [];
}

class RecieveEvent extends ServerEvent {
  final DeviceConnection device;
  final Map<String, dynamic> data;

  const RecieveEvent({required this.device, required this.data});

  @override
  List<Object?> get props => [device, data];
}

class ClipboardSync extends ServerEvent {
  @override
  List<Object?> get props => [];
}

class MediaSync extends ServerEvent {
  @override
  List<Object?> get props => [];
}

class NotificationClose extends ServerEvent {
  final DeviceConnection device;
  final int? id;

  const NotificationClose({required this.id, required this.device});

  @override
  List<Object?> get props => [id];
}

class NotificationReplyEvent implements NotificationClose {
  NotificationReplyEvent({
    required this.id,
    required this.device,
    required this.reply,
  });

  final String reply;

  @override
  List<Object?> get props => [id, device, reply];

  @override
  final DeviceConnection device;

  @override
  final int id;

  @override
  bool? get stringify => false;
}
