import 'package:connect/src/domain/bloc/client/client_bloc.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';
import 'package:playerctl/core/player_state.dart';

abstract class Packet<T> {
  Event event;
  T data;

  Packet({required this.event, required this.data});

  Map<String, dynamic> toMap() {
    return {'data': data, 'event': event.name};
  }
}

class EventPacket implements Packet<Map<String, dynamic>> {
  @override
  Map<String, dynamic> data;

  @override
  Event event;

  EventPacket({required this.data, required this.event});

  @override
  Map<String, dynamic> toMap() {
    return {'data': data, 'event': event.name};
  }
}

class ClipBoardPacket implements Packet<String> {
  @override
  String data;

  @override
  Event event;

  ClipBoardPacket({required this.data, required this.event});

  @override
  Map<String, dynamic> toMap() {
    return {'data': data, 'event': event.name};
  }
}

class MediaPacket<T> implements Packet<T> {
  @override
  T data;

  @override
  Event event;

  DevicePlatform platform;

  MediaPacket({
    required this.platform,
    required this.event,
    required this.data,
  });

  @override
  Map<String, dynamic> toMap() {
    return {'data': data, 'event': event.name, 'platform': platform.name};
  }
}

class LinuxMediaPacket implements MediaPacket<PlayerState> {
  @override
  PlayerState data;

  @override
  Event event;

  LinuxMediaPacket({required this.data, required this.event});

  @override
  Map<String, dynamic> toMap() {
    return {'data': data, 'event': event.name, 'platform': platform.name};
  }

  @override
  DevicePlatform platform = .linux;
}

class LinuxMediaCommandPacket implements MediaPacket {
  @override
  dynamic data;

  @override
  Event event = .MEDIA_COMMAND;

  @override
  DevicePlatform platform = .linux;

  MediaCommand command;

  LinuxMediaCommandPacket({required this.command, this.data});

  @override
  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'event': event.name,
      'platform': platform.name,
      'command': command.name,
    };
  }
}

class RemoteInputPacket implements Packet {
  dynamic data;

  @override
  Event event;

  RemoteInputType inputType;

  RemoteInputPacket({
    required this.data,
    required this.event,
    required this.inputType,
  });

  @override
  Map<String, dynamic> toMap() {
    return {'data': data, 'event': event.name, 'inputType': inputType.name};
  }
}
