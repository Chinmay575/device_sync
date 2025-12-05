import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:bixat_key_mouse/bixat_key_mouse.dart';
import 'package:bloc/bloc.dart';
import 'package:connect/src/data/models/connect_req.dart';
import 'package:connect/src/data/models/connect_res.dart';
import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/data/models/device_connection.dart';
import 'package:connect/src/data/models/disconnect_req.dart';
import 'package:connect/src/data/models/handshake_req.dart';
import 'package:connect/src/data/models/handshake_res.dart';
import 'package:connect/src/data/models/notification_data.dart';
import 'package:connect/src/data/models/notification_reply.dart';
import 'package:connect/src/data/models/packet.dart';
import 'package:connect/src/domain/repositories/clipboard_repository.dart';
import 'package:connect/src/domain/repositories/device_repository.dart';
import 'package:connect/src/domain/repositories/notification_repository.dart';
import 'package:connect/src/domain/repositories/socket_server_repository.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';
import 'package:connect/src/utils/constants/strings/server_config.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:playerctl/core/media_player_manager.dart';
import 'package:playerctl/core/player_state.dart';

part 'server_event.dart';
part 'server_state.dart';

class ServerBloc extends Bloc<ServerEvent, ServerState> {
  final SocketServer _socketServer = .instance;
  final ClipboardService _clipboardService = .instance;
  final DeviceRepository _deviceRepository = .new();
  final MediaPlayerManager mediaPlayerManager = .new();
  final NotificationRepository _notificationRepository = .instance;
  ServerBloc() : super(ServerInitial()) {
    on<Initial>(onInitialEvent);
    on<ClipboardSync>(onClipboardSync);
    on<MediaSync>(onMediaSync);
    on<RecieveEvent>(onRecieveEvent);
    on<NotificationClose>(onNotificationClose);
    on<NotificationReplyEvent>(onNotificationReply);
  }

  onInitialEvent(Initial event, Emitter<ServerState> emit) async {
    Device device = await _deviceRepository.getDeviceInfo();

    if (!device.isServer) return;

    await _socketServer.start(device, port: ServerConfig.PORT);

    DeviceConnection connection = .new(device: device, socket: null);

    emit(
      ServerReady(
        serverIP: _socketServer.ip,
        port: _socketServer.port.toString(),
        currentDevice: connection,
      ),
    );

    await emit.forEach(
      _socketServer.deviceStream,
      onData: (newDevice) {
        newDevice.events.listen((data) {
          add(RecieveEvent(device: newDevice, data: data));
        });

        final list = List<DeviceConnection>.from(
          (state as ServerReady).devices,
        );
        if (list.where((e) => e.device.ip == newDevice.device.ip).isEmpty) {
          newDevice.startListening();
          list.add(newDevice);
        }
        return (state as ServerReady).copyWith(devices: list);
      },
    );
  }

  FutureOr<void> onClipboardSync(
    ClipboardSync event,
    Emitter<ServerState> emit,
  ) async {
    _clipboardService.initialize();

    await emit.forEach(
      _clipboardService.clipboardStream,
      onData: (data) {
        ClipBoardPacket packet = .new(data: data, event: .CLIPBOARD_SEND);

        for (var i in state.devices) {
          if (i.device.status == .CONNECT_SUCCESS) {
            i.send(packet);
          }
        }
        return state;
      },
    );
  }

  FutureOr<void> onMediaSync(MediaSync event, Emitter<ServerState> emit) async {
    if (Platform.isLinux) {
      mediaPlayerManager.initialize();

      PlayerState? prevPacket;

      await emit.forEach(
        mediaPlayerManager.stateStream,
        onData: (data) {
          if (data != prevPacket) {
            prevPacket = data;
            LinuxMediaPacket packet = .new(data: data, event: .MEDIA_DATA_SEND);

            for (var i in state.devices) {
              if (i.device.status == .CONNECT_SUCCESS) {
                i.send(packet);
              } else {
                debugPrint(
                  "skipping packet send to ${i.device.ip} ${i.device.status}",
                );
              }
            }
          } else {
            debugPrint("same packet not syncing");
          }

          return state;
        },
      );
    }
  }

  FutureOr<void> onRecieveEvent(
    RecieveEvent recieveEvent,
    Emitter<ServerState> emit,
  ) {
    DeviceConnection device = recieveEvent.device;

    Map<String, dynamic> data = recieveEvent.data;

    debugPrint("${data.runtimeType}");

    Event? event = .values.parse((data['event'] ?? "") as String);

    if (event != null) {
      switch (event) {
        case .HANDSHAKE_REQ:
          HandshakeReq req = .fromMap(data["data"]);

          var rng = Random();

          int secret = 100000 + rng.nextInt(900000);

          List<DeviceConnection> devices = state.devices.map((e) {
            if (e.device.ip == req.device.ip) {
              return e.updateDevice(
                platform: req.device.platform,
                deviceName: req.device.deviceName,
                model: req.device.model,
                port: req.device.port,
                status: .HANDSHAKE_SENT,
                secret: secret.toString(),
              );
            }
            return e;
          }).toList();

          HandshakeRes res = .new(status: 1, secret: secret.toString());
          device.send(EventPacket(data: res.toMap(), event: .HANDSHAKE_RES));

          emit((state as ServerReady).copyWith(devices: devices));

          break;

        case .CONNECT_REQ:
          ConnectReq req = .fromMap(data["data"]);
          ConnectRes res;

          Device? updatedDevice = state.devices
              .where((e) => e.device.ip == device.device.ip)
              .firstOrNull
              ?.device;

          if (req.secret == updatedDevice?.secret) {
            res = .new(
              status: 1,
              device: state.currentDevice?.device,
              msg: "Connected Successfully",
            );
            device.send(EventPacket(data: res.toMap(), event: .CONNECT_RES));

            add(ClipboardSync());
            add(MediaSync());

            emit(
              (state as ServerReady).copyWith(
                devices: state.devices.map((e) {
                  if (e.device.ip == req.device.ip) {
                    return e.updateDevice(
                      status: .CONNECT_SUCCESS,
                      deviceName: req.device.deviceName,
                      model: req.device.model,
                      platform: req.device.platform,
                    );
                  }
                  return e;
                }).toList(),
              ),
            );
          } else {
            String reason = "";
            if (req.secret != updatedDevice?.secret) {
              reason = "Incorrect Secret Key";
            } else {
              reason = "Unknown reason";
            }
            res = .new(
              status: 0,
              device: device.device,
              msg: "Connection failed due to $reason",
            );

            device.send(EventPacket(data: res.toMap(), event: .CONNECT_RES));
          }

          break;
        case .CONNECT_RES:
        case .HANDSHAKE_RES:
          debugPrint("Server cannot recieve handshake res");
          break;
        case .CLIPBOARD_SEND:
          _clipboardService.setClipboard(data["data"] as String);
          break;
        case .MEDIA_DATA_SEND:
          break;
        case .MEDIA_COMMAND:
          DevicePlatform? platform = .values.parse(data["platform"] as String);
          if (platform == .linux) {
            MediaCommand? command = .values.parse(data["command"] as String);
            if (command != null) {
              switch (command) {
                case .PLAY:
                  mediaPlayerManager.play();
                  break;
                case .PAUSE:
                  mediaPlayerManager.pause();
                  break;
                case .SHUFFLE:
                  mediaPlayerManager.updateShuffleStatus();
                  break;
                case .LOOP:
                  mediaPlayerManager.updateLoopStatus();
                  break;
                case .NEXT:
                  mediaPlayerManager.next();
                  break;
                case .PREV:
                  mediaPlayerManager.previous();
                  break;
                case .PLAYER:
                  if (data["data"] is String) {
                    mediaPlayerManager.switchPlayer(data["data"]);
                  } else {
                    debugPrint(
                      "Incorrect data type in player switch ${data["data"]}",
                    );
                  }
                  break;
                case .SEEK:
                  break;
                case .VOLUME:
                  if (data["data"] is num) {
                    mediaPlayerManager.setVolume((data["data"] as num).toInt());
                  } else {
                    debugPrint(
                      "Incorrect data type in set  volume ${data["data"]}",
                    );
                  }
                  break;
              }
            }
          }
          break;
        case .REMOTE_INPUT:
          RemoteInputType? inputType = .values.parse(data["inputType"]);

          if (inputType == .MOUSE) {
            MouseEventType? mouseEventType = .values.parse(
              data["data"]["type"],
            );

            if (mouseEventType == .MOVE) {
              num? dx = data["data"]["dx"];
              num? dy = data["data"]["dy"];
              BixatKeyMouse.moveMouse(
                x: (dx ?? 0).toInt(),
                y: (dy ?? 0).toInt(),
                coordinate: .relative,
              );
            } else if (mouseEventType == .CLICK) {
              String? btn = data["data"]["btn"];

              MouseButton? button = .values.parse(btn?.toLowerCase() ?? "");
              if (button != null) {
                BixatKeyMouse.pressMouseButton(button: button);
              }
            }

            debugPrint("parsed mouse event $mouseEventType");
          }

          debugPrint("parsed type $inputType");
          // debugPrint(data["data"]);
          break;
        case .DISCONNECT:
          DisconnectReq req = .fromMap(data);

          state.devices
              .where((e) => e.device.ip == req.device.ip)
              .firstOrNull
              ?.dispose();

          state.devices.removeWhere((e) => e.device.ip == req.device.ip);

          emit((state as ServerReady).copyWith(devices: state.devices));
        case .NOTIFICATION_SYNC:
          NotificationData f = .fromMap(data["data"]);

          _notificationRepository.show(
            id: f.id ?? 1234,
            title: f.title ?? "",
            body: f.content ?? "",
            icon: f.appIcon,
          );

          emit(
            (state as ServerReady).copyWith(
              devices: state.devices.map((e) {
                if (e.device.ip == device.device.ip) {
                  return e.updateNotifications(f);
                }
                return e;
              }).toList(),
            ),
          );

          debugPrint("Noification Recieved: $data");
          break;
        case Event.NOTIFICATION_CLOSE:
          break;
        case Event.NOTIFICATION_REPLY:
          break;
      }
    } else {
      debugPrint("Unknown Event ${data["event"]}");
    }
  }

  FutureOr<void> onNotificationClose(
    NotificationClose event,
    Emitter<ServerState> emit,
  ) {
    AndroidNotificationRemovePacket packet = .new(data: event.id);

    event.device.send(packet);

    emit(
      (state as ServerReady).copyWith(
        devices: state.devices.map((e) {
          if (e.device.ip == event.device.device.ip) {
            return e.removeNotification(event.id);
          }
          return e;
        }).toList(),
      ),
    );
  }

  FutureOr<void> onNotificationReply(
    NotificationReplyEvent event,
    Emitter<ServerState> emit,
  ) {
    NotificationReply reply = .new(id: event.id, reply: event.reply);

    AndroidNotificationReplyPacket packet = .new(data: reply);

    event.device.send(packet);
  }
}
