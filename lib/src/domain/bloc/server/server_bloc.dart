import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:connect/src/data/models/connect_req.dart';
import 'package:connect/src/data/models/connect_res.dart';
import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/data/models/handshake_req.dart';
import 'package:connect/src/data/models/handshake_res.dart';
import 'package:connect/src/data/models/packet.dart';
import 'package:connect/src/domain/repositories/clipboard_repository.dart';
import 'package:connect/src/domain/repositories/device_repository.dart';
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
  ServerBloc() : super(ServerInitial()) {
    on<Initial>(onInitialEvent);
    on<ClipboardSync>(onClipboardSync);
    on<MediaSync>(onMediaSync);
  }

  onInitialEvent(Initial event, Emitter<ServerState> emit) async {
    Device device = await _deviceRepository.getDeviceInfo();

    if (!device.isServer) return;

    await _socketServer.start(device, port: ServerConfig.PORT);

    emit(
      ServerReady(
        serverIP: _socketServer.ip,
        port: _socketServer.port.toString(),
        currentDevice: device,
      ),
    );

    await emit.forEach(
      _socketServer.dataStream,
      onData: (data) {
        print(data.runtimeType);

        Event? event = .values.parse((data['event'] ?? "") as String);

        if (event != null) {
          switch (event) {
            case .HANDSHAKE_REQ:
              HandshakeReq req = .fromMap(data["data"]);

              if (state.devices
                  .where((e) => e.ip == req.device.ip)
                  .isNotEmpty) {
                HandshakeRes res = .new(
                  status: 0,
                  msg: "Device already connected",
                );
                _socketServer.sendPacket(
                  EventPacket(data: res.toMap(), event: .HANDSHAKE_RES),
                );
              } else {
                HandshakeRes res = .new(status: 1, secret: "1234");
                _socketServer.sendPacket(
                  EventPacket(data: res.toMap(), event: .HANDSHAKE_RES),
                );
              }

              break;

            case .CONNECT_REQ:
              ConnectReq req = .fromMap(data["data"]);
              ConnectRes res;

              bool isAlreadyConnected = state.devices
                  .where((e) => e.ip == req.device.ip)
                  .isNotEmpty;

              if (req.secret == "1234" && !isAlreadyConnected) {
                res = .new(
                  status: 1,
                  device: device,
                  msg: "Connected Successfully",
                );
                _socketServer.sendPacket(
                  EventPacket(data: res.toMap(), event: .CONNECT_RES),
                );

                add(ClipboardSync());
                add(MediaSync());

                List<Device> devices = [...state.devices];
                devices.add(req.device);

                if (state is ServerReady) {
                  return (state as ServerReady).copyWith(devices: devices);
                } else {
                  return ServerReady(
                    serverIP: _socketServer.ip,
                    port: _socketServer.port.toString(),
                    devices: devices,
                    currentDevice: device,
                  );
                }
              } else {
                String reason = "";
                if (req.secret != "1234") {
                  reason = "Incorrect Secret Key";
                } else if (isAlreadyConnected) {
                  reason = "Device already connected";
                } else {
                  reason = "Unknown reason";
                }
                res = .new(
                  status: 0,
                  device: device,
                  msg: "Connection failed due to $reason",
                );

                _socketServer.sendPacket(
                  EventPacket(data: res.toMap(), event: .CONNECT_RES),
                );
              }

              break;
            case .CONNECT_RES:
            case .HANDSHAKE_RES:
              print("Server cannot recieve handshake res");
              break;
            case Event.CLIPBOARD_SEND:
              _clipboardService.setClipboard(data["data"] as String);
            case Event.MEDIA_DATA_SEND:
              break;
            case Event.MEDIA_COMMAND:
              DevicePlatform? platform = .values.parse(
                data["platform"] as String,
              );
              if (platform == .linux) {
                MediaCommand? command = .values.parse(
                  data["command"] as String,
                );
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
                        mediaPlayerManager.setVolume(
                          (data["data"] as num).toInt(),
                        );
                      } else {
                        debugPrint(
                          "Incorrect data type in set  volume ${data["data"]}",
                        );
                      }
                      break;
                  }
                }
              }
            case Event.REMOTE_INPUT:
            // handle all cases
          }
        } else {
          debugPrint("Unknown Event ${data["event"]}");
        }
        return state;
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
        _socketServer.sendPacket(packet);
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
            _socketServer.sendPacket(packet);
          }

          return state;
        },
      );
    }
  }
}
