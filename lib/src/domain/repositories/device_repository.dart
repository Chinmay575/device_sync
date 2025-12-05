import 'dart:io';

import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';
import 'package:device_info_plus/device_info_plus.dart';

abstract class _DeviceRepository {
  Future<Device> getDeviceInfo();
}

class DeviceRepository implements _DeviceRepository {
  Future<String?> _getLocalIP() async {
    List<NetworkInterface> interfaces = await NetworkInterface.list();

    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (addr.type == .IPv4 && !addr.isLoopback && !addr.isLinkLocal) {
          return addr.address;
        }
      }
    }
    return null;
  }

  @override
  Future<Device> getDeviceInfo() async {
    String? ip = await _getLocalIP();
    DeviceInfoPlugin info = DeviceInfoPlugin();

    String deviceName = "";
    String deviceModel = "";
    DevicePlatform platform = .unknown;

    if (Platform.isAndroid) {
      AndroidDeviceInfo deviceInfo = await info.androidInfo;
      deviceName = deviceInfo.device;
      deviceModel = deviceInfo.model;
      platform = .android;
    } else if (Platform.isIOS) {
      IosDeviceInfo deviceInfo = await info.iosInfo;
      deviceName = deviceInfo.systemName;
      deviceModel = deviceInfo.model;
      platform = .ios;
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo deviceInfo = await info.macOsInfo;
      deviceName = deviceInfo.computerName;
      deviceModel = deviceInfo.model;
      platform = .mac;
    } else if (Platform.isWindows) {
      WindowsDeviceInfo deviceInfo = await info.windowsInfo;
      deviceName = deviceInfo.computerName;
      deviceModel = deviceInfo.productName;
      platform = .windows;
    } else if (Platform.isLinux) {
      LinuxDeviceInfo deviceInfo = await info.linuxInfo;
      deviceName = deviceInfo.name;
      deviceModel = deviceInfo.prettyName;
      platform = .linux;
    }

    Device device = Device(
      platform: platform,
      ip: ip ?? "",
      port: "0",
      deviceName: deviceName,
      model: deviceModel,
    );

    return device;
  }
}
