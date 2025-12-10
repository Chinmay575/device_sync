import 'package:connect/src/utils/constants/strings/routes.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:icons_plus/icons_plus.dart';

enum Event {
  HANDSHAKE_REQ,
  HANDSHAKE_RES,
  CONNECT_REQ,
  CONNECT_RES,
  CLIPBOARD_SEND,
  MEDIA_DATA_SEND,
  MEDIA_COMMAND,
  REMOTE_INPUT,
  DISCONNECT,
  NOTIFICATION_SYNC,
  NOTIFICATION_CLOSE,
  NOTIFICATION_REPLY,
  REMOTE_COMMAND_EXECUTION,
}

enum RemoteCommand {
  SHUTDOWN,
  LOCK,
  REBOOT,
  LOGOUT,
  SUSPEND;

  BoxIconData get icon {
    switch (this) {
      case SHUTDOWN:
        return BoxIcons.bx_power_off;
      case LOCK:
        return BoxIcons.bx_lock;
      case REBOOT:
        return BoxIcons.bx_power_off;
      case LOGOUT:
        return BoxIcons.bx_log_out;
      case SUSPEND:
        return BoxIcons.bx_power_off;
    }
  }

  String get command {
    switch (this) {
      case SHUTDOWN:
        return "systemctl,poweroff";
      case LOCK:
        return "loginctl,lock-session";
      case REBOOT:
        return "systemctl,reboot";
      case SUSPEND:
        return "systemctl,suspend";
      case LOGOUT:
        return "loginctl, terminate-user, \$USER";
    }
  }
}

enum Functionality {
  FILE_TRANSFER,
  CLIPBOARD_SYNC,
  SCREEN_SHARE,
  REMOTE_COMMANDS,
  MEDIA_CONTROLS,
  REMOTE_INPUT_SHARE,
  NOTIFICATION_SYNC;

  String get route {
    switch (this) {
      case Functionality.FILE_TRANSFER:
        return "";
      case Functionality.CLIPBOARD_SYNC:
        return "";
      case Functionality.SCREEN_SHARE:
        return "";
      case Functionality.REMOTE_COMMANDS:
        return Routes.remoteCommandExecution;
      case Functionality.MEDIA_CONTROLS:
        return "";
      case Functionality.REMOTE_INPUT_SHARE:
        return Routes.remoteInput;
      case Functionality.NOTIFICATION_SYNC:
        return "";
    }
  }

  BoxIconData get icon {
    switch (this) {
      case Functionality.FILE_TRANSFER:
        return (BoxIcons.bx_file_blank);
      case Functionality.CLIPBOARD_SYNC:
        return (BoxIcons.bx_clipboard);
      case Functionality.SCREEN_SHARE:
        return (BoxIcons.bx_devices);
      case Functionality.REMOTE_COMMANDS:
        return (BoxIcons.bx_terminal);
      case Functionality.MEDIA_CONTROLS:
        return (BoxIcons.bx_music);
      case Functionality.REMOTE_INPUT_SHARE:
        return (BoxIcons.bx_mouse);
      case Functionality.NOTIFICATION_SYNC:
        return BoxIcons.bx_notification;
    }
  }

  // ignore: non_constant_identifier_names
  String get Name {
    return name.replaceAll('_', ' ');
  }
}

enum DevicePlatform {
  android,
  ios,
  mac,
  linux,
  web,
  windows,
  unknown;

  Widget get icon {
    switch (this) {
      case android:
        return Brand(Brands.android_os);
      case ios:
        return Brand(Brands.ios_logo);
      case mac:
        return Brand(Brands.mac_os_logo);
      case linux:
        return Brand(Brands.linux_mint);
      case web:
        return Brand(Brands.chrome);
      case windows:
        return Brand(Brands.windows_11);
      case unknown:
        return Icon(Icons.laptop);
    }
  }
}

enum MediaCommand {
  PLAY,
  PAUSE,
  SHUFFLE,
  LOOP,
  NEXT,
  PREV,
  PLAYER,
  SEEK,
  VOLUME,
}

extension EnumParser<T extends Enum> on Iterable<T> {
  T? parse(String name) {
    for (var value in this) {
      if (value.name == name) return value;
    }
    return null;
  }
}

enum MouseEventType { MOVE, SCROLL, CLICK }

enum RemoteInputType { MOUSE, KEYBOARD }

enum ConnectionStatus {
  INITIAL,
  HANDSHAKE_SENT,
  HANDSHAKE_SUCCESS,
  HANDSHAKE_FAILED,
  CONNECT_SENT,
  CONNECT_SUCCESS,
  CONNECT_FAILED,
  DISCONNECT;

  IconData? get icon {
    switch (this) {
      case ConnectionStatus.INITIAL:
        return FontAwesomeIcons.plug; // Waiting for power/connection

      case ConnectionStatus.HANDSHAKE_SENT:
        return Icons.waving_hand_outlined; // Initiating contact (Wave)

      case ConnectionStatus.HANDSHAKE_SUCCESS:
        // Solid handshake implies a firm agreement/verification
        return FontAwesomeIcons.handshake;

      case ConnectionStatus.HANDSHAKE_FAILED:
        // Explicit "Agreement Broken" icon
        return FontAwesomeIcons.handshakeSlash;

      case ConnectionStatus.CONNECT_SENT:
        // Using 'sync' or 'transmit' is better than check for "Sent"
        // But keeping your style:
        return Icons.settings_ethernet;

      case ConnectionStatus.CONNECT_SUCCESS:
        // The universal symbol for "Linked/Connected"
        return Icons.link;

      case ConnectionStatus.CONNECT_FAILED:
        // The counterpart to success
        return Icons.link_off;

      case ConnectionStatus.DISCONNECT:
        // Represents shutting down the engine/server
        return Icons.power_off;
    }
  }
}
