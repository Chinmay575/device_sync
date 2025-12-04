import 'package:connect/src/utils/constants/strings/enums.dart';

class DeviceConfig {
  Map<Functionality, bool> serviceStatus = {
    .FILE_TRANSFER: true,
    .CLIPBOARD_SYNC: true,
    .SCREEN_SHARE: true,
    .REMOTE_COMMANDS: true,
    .MEDIA_CONTROLS: true,
    .REMOTE_INPUT_SHARE: true,
  };
}
