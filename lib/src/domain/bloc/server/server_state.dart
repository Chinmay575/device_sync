part of 'server_bloc.dart';

@immutable
sealed class ServerState extends Equatable {
  final String serverIP;
  final String port;
  final Device? currentDevice;
  final List<Device> devices;

  const ServerState({
    required this.serverIP,
    required this.port,
    required this.currentDevice,
    this.devices = const [],
  });
}

final class ServerInitial extends ServerState {
  const ServerInitial({
    super.serverIP = "",
    super.port = "",
    super.devices,
    super.currentDevice,
  });

  @override
  List<Object?> get props => [];
}

class ServerReady extends ServerState {
  const ServerReady({
    required super.serverIP,
    required super.port,
    super.devices = const [],
    super.currentDevice,
  });

  ServerReady copyWith({
    String? serverIP,
    String? port,
    List<Device>? devices,
    Device? currentDevice,
  }) {
    return ServerReady(
      serverIP: serverIP ?? this.serverIP,
      port: port ?? this.port,
      devices: devices ?? this.devices,
      currentDevice: currentDevice ?? this.currentDevice,
    );
  }

  @override
  List<Object?> get props => [serverIP, port, devices, currentDevice];
}
