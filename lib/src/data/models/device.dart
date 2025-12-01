class Device {
  String ip;
  String port;
  String deviceName;
  String model;
  bool isServer;

  Device({
    required this.isServer,
    required this.ip,
    required this.port,
    required this.deviceName,
    required this.model,
  });

  Device copyWith({
    String? ip,
    String? port,
    String? deviceName,
    String? model,
    bool? isServer,
  }) {
    return Device(
      isServer: isServer ?? this.isServer,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      deviceName: deviceName ?? this.deviceName,
      model: model ?? this.model,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'port': port,
      'deviceName': deviceName,
      'model': model,
      'isServer': isServer,
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      isServer: map['isServer'],
      ip: map['ip'],
      port: map['port'],
      deviceName: map['deviceName'],
      model: map['model'],
    );
  }
}
