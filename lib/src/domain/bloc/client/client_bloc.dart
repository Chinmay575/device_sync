import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:connect/src/data/models/connect_req.dart';
import 'package:connect/src/data/models/connect_res.dart';
import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/data/models/handshake_req.dart';
import 'package:connect/src/data/models/handshake_res.dart';
import 'package:connect/src/data/models/packet.dart';
import 'package:connect/src/domain/repositories/clipboard_repository.dart';
import 'package:connect/src/domain/repositories/device_repository.dart';
import 'package:connect/src/domain/repositories/local_data_repository.dart';
import 'package:connect/src/domain/repositories/socket_client_repository.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';
import 'package:connect/src/utils/constants/strings/pref_keys.dart';
import 'package:connect/src/utils/constants/strings/server_config.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:playerctl/core/player_state.dart';

part 'client_event.dart';
part 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final SocketClient _client = .instance;
  final ClipboardService _clipboardService = .instance;
  final LocalDataRepository _localData = .instance;
  DeviceRepository deviceRepository = DeviceRepository();
  ClientBloc() : super(ClientState(status: .INITIAL)) {
    on<CheckPrevConnection>(onCheckPrevConnection);
    on<ConnectEvent>(onConnectEvent);
    on<HandshakeEvent>(onHandshakeEvent);
    on<SyncClipboard>(onClipboardSync);
    on<MediaEvent>(onMediaEvent);
  }

  onHandshakeEvent(HandshakeEvent event, Emitter<ClientState> emit) async {
    try {
      String ip = event.ip;
      int port = event.port;
      // Map<String, dynamic> m = jsonDecode(connectionString);
      // String serverIP = m["ip"];
      // String serverPort = m["port"];
      await _client.connect(ip, port);
      Device device = await deviceRepository.getDeviceInfo();

      HandshakeReq req = .new(device: device);

      EventPacket packet = .new(data: req.toMap(), event: .HANDSHAKE_REQ);

      _client.sendPacket(packet);

      emit(state.copyWith(status: .HANDSHAKE_SENT));

      await emit.forEach(
        _client.dataStream,
        onData: (data) {
          print("Packet received ${data}, ${data.runtimeType}");

          Event? event = .values.parse((data['event'] ?? "") as String);

          if (event != null) {
            switch (event) {
              case .HANDSHAKE_REQ:
              case .CONNECT_REQ:
                break;
              case .CONNECT_RES:
                ConnectRes res = .fromMap(data["data"]);

                if (res.status == 1) {
                  print(
                    "-------------------------------Connection success----------------------------------------------",
                  );

                  add(SyncClipboard());

                  _localData.set<String>(PrefKeys.serverIP, res.device.ip);

                  return state.copyWith(
                    status: .CONNECT_SUCCESS,
                    connectedDevices: [res.device],
                  );
                } else {
                  return state.copyWith(status: .CONNECT_FAILED);
                }

              case .HANDSHAKE_RES:
                HandshakeRes res = .fromMap(data["data"]);

                print(res.status);

                if (res.status == 1) {
                  ConnectReq req = .new(
                    device: device,
                    secret: res.secret ?? "",
                  );

                  EventPacket packet = .new(
                    data: req.toMap(),
                    event: .CONNECT_REQ,
                  );

                  _client.sendPacket(packet);
                  return state.copyWith(status: .HANDSHAKE_SUCCESS);
                } else {
                  return state.copyWith(status: .HANDSHAKE_FAILED);
                }
              case .CLIPBOARD_SEND:
                _clipboardService.setClipboard(data["data"] as String);
                return state;
              case .MEDIA_DATA_SEND:
                DevicePlatform? platform = .values.parse(
                  data["platform"] as String,
                );
                if (platform == .linux) {
                  PlayerState playerState = .fromJson(data["data"]);
                  return state.copyWith(mediaState: playerState);
                }
              case Event.MEDIA_COMMAND:
                return state;
              case Event.REMOTE_INPUT:
                return state;
            }
          } else {
            debugPrint("Unknown Event ${data["event"]}");
          }
          return state;
        },
      );
    } on Exception catch (e, stk) {
      print(stk);
      emit(ClientState(status: .INITIAL));
      // Map<String, dynamic> m = jsonDecode(event.connectionString);
      // String serverPort = m["port"];
      if (event.port == ServerConfig.PORT) {
        print("Retry called with next port");
        // m["port"] = (int.tryParse(m["port"]) ?? 0 + 1);
        add(event.copyWith(port: event.port + 1));
      }
    }
  }

  onConnectEvent(ConnectEvent event, Emitter<ClientState> emit) async {
    try {
      emit(state.copyWith(status: .CONNECT_SENT));
    } on Exception catch (e) {
      print(e);
      emit(state.copyWith(status: .CONNECT_FAILED));
    }
  }

  FutureOr<void> onClipboardSync(
    SyncClipboard event,
    Emitter<ClientState> emit,
  ) async {
    _clipboardService.initialize();

    await emit.forEach(
      _clipboardService.clipboardStream,
      onData: (data) {
        ClipBoardPacket packet = .new(data: data, event: .CLIPBOARD_SEND);
        _client.sendPacket(packet);
        return state;
      },
    );
  }

  FutureOr<void> onMediaEvent(
    MediaEvent<dynamic> event,
    Emitter<ClientState> emit,
  ) {
    LinuxMediaCommandPacket packet = .new(
      command: event.command,
      data: event.data,
    );

    _client.sendPacket(packet);
  }

  FutureOr<void> onCheckPrevConnection(
    CheckPrevConnection event,
    Emitter<ClientState> emit,
  ) {
    String? ip = _localData.get<String>(PrefKeys.serverIP);
    if (ip?.isNotEmpty ?? false) {
      add(HandshakeEvent(ip: ip ?? "", port: ServerConfig.PORT));
    } else {
      print("No prev connection found");
    }
  }
}
