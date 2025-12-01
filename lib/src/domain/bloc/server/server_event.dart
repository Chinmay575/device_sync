part of 'server_bloc.dart';

sealed class ServerEvent extends Equatable {
  const ServerEvent();
}

class Initial extends ServerEvent {
  @override
  List<Object?> get props => [];
}

class ClipboardSync extends ServerEvent {
  @override
  List<Object?> get props => [];
}

class MediaSync extends ServerEvent {
  @override
  List<Object?> get props => throw UnimplementedError();
}
