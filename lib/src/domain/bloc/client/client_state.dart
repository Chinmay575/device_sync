part of 'client_bloc.dart';

class ClientState extends Equatable {
  const ClientState({
    this.status = .INITIAL,
    this.connectedDevices = const [],
    this.mediaState,
  });
  final ClientConnectionStatus status;
  final List<Device> connectedDevices;
  final PlayerState? mediaState;

  @override
  List<Object?> get props => [connectedDevices, status, mediaState];

  ClientState copyWith({
    ClientConnectionStatus? status,
    List<Device>? connectedDevices,
    PlayerState? mediaState,
  }) {
    return ClientState(
      status: status ?? this.status,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      mediaState: mediaState ?? this.mediaState,
    );
  }
}

enum ClientConnectionStatus {
  INITIAL,
  HANDSHAKE_SENT,
  HANDSHAKE_SUCCESS,
  HANDSHAKE_FAILED,
  CONNECT_SENT,
  CONNECT_SUCCESS,
  CONNECT_FAILED,
  DISCONNECT,
}
