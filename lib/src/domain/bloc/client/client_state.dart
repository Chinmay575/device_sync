part of 'client_bloc.dart';

class ClientState extends Equatable {
  const ClientState({
    // this.connectedDevices = const [],
    this.mediaState,
    this.server,
  });

  // final List<Device> connectedDevices;
  final DeviceConnection? server;
  final PlayerState? mediaState;

  @override
  List<Object?> get props => [server, mediaState];

  ClientState copyWith({
    // List<Device>? connectedDevices,
    PlayerState? mediaState,
    DeviceConnection? device,
  }) {
    return ClientState(
      // connectedDevices: connectedDevices ?? this.connectedDevices,
      mediaState: mediaState ?? this.mediaState,
      server: device ?? server,
    );
  }
}
