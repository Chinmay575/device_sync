import 'package:connect/src/utils/constants/strings/enums.dart';

import '../../domain/bloc/client/client_bloc.dart';

class Device {
  String ip;
  String port;
  String deviceName;
  String model;
  DevicePlatform platform;
  ConnectionStatus status;
  String? secret;
  bool get isServer =>
      platform == .linux || platform == .windows || platform == .mac;

  Device({
    required this.platform,
    required this.ip,
    required this.port,
    required this.deviceName,
    required this.model,
    this.secret,
    this.status = .INITIAL,
  });

  Device copyWith({
    String? ip,
    String? port,
    String? deviceName,
    String? model,
    DevicePlatform? platform,
    ConnectionStatus? status,
    String? secret,
  }) {
    return Device(
      platform: platform ?? this.platform,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      deviceName: deviceName ?? this.deviceName,
      model: model ?? this.model,
      status: status ?? this.status,
      secret: secret ?? this.secret,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'port': port,
      'deviceName': deviceName,
      'model': model,
      'platform': platform.name,
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      platform:
          DevicePlatform.values.parse(map['platform'] as String) ?? .unknown,
      ip: map['ip'],
      port: map['port'],
      deviceName: map['deviceName'],
      model: map['model'],
    );
  }
}
