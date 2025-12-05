part of 'client_bloc.dart';

sealed class ClientEvent extends Equatable {
  const ClientEvent();
}

class CheckPrevConnection extends ClientEvent {
  @override
  List<Object?> get props => [];
}

class HandshakeEvent extends ClientEvent {
  final String ip;
  final int port;

  const HandshakeEvent({required this.ip, this.port = ServerConfig.PORT});

  @override
  List<Object?> get props => [ip, port];

  HandshakeEvent copyWith({String? ip, int? port}) {
    return HandshakeEvent(ip: ip ?? this.ip, port: port ?? this.port);
  }
}

class ConnectEvent extends ClientEvent {
  final String connectionString;

  const ConnectEvent({required this.connectionString});

  @override
  List<Object?> get props => [connectionString];
}

class SyncClipboard extends ClientEvent {
  @override
  List<Object?> get props => [];
}

class MediaEvent<T> extends ClientEvent {
  final T? data;
  final MediaCommand command;

  const MediaEvent({this.data, required this.command});

  @override
  List<Object?> get props => [data, command];
}

class RemoteInputEvent<T> extends ClientEvent {
  final RemoteInputType type;
  final T data;

  const RemoteInputEvent({required this.type, required this.data});

  @override
  List<Object?> get props => [type, data];
}

class RecieveEvent extends ClientEvent {
  final Device device;
  final Map<String, dynamic> data;

  const RecieveEvent({required this.device, required this.data});

  @override
  List<Object?> get props => [device, data];
}

class NotificationSyncEvent extends ClientEvent {
  @override
  List<Object?> get props => [];
}
