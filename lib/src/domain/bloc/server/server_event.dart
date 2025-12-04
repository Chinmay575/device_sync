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
