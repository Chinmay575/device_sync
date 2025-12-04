import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:connect/src/data/models/connect_req.dart';
import 'package:connect/src/data/models/connect_res.dart';
import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/data/models/device_connection.dart';
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
  final DeviceRepository deviceRepository = .new();
  ClientBloc() : super(ClientState()) {
    on<CheckPrevConnection>(onCheckPrevConnection);
    on<ConnectEvent>(onConnectEvent);
    on<HandshakeEvent>(onHandshakeEvent);
    on<SyncClipboard>(onClipboardSync);
    on<MediaEvent>(onMediaEvent);
    on<RemoteInputEvent>(onRemoteInputEvent);
    on<RecieveEvent>(onRecieveEvent);
  }

  onHandshakeEvent(HandshakeEvent event, Emitter<ClientState> emit) async {
    try {
      String ip = event.ip;
      int port = event.port;
      Socket socket = await _client.connect(ip, port);
      Device device = await deviceRepository.getDeviceInfo();

      DeviceConnection connection = DeviceConnection(
        device: device,
        socket: socket,
      );

      connection.startListening();

      HandshakeReq req = .new(device: device);

      EventPacket packet = .new(data: req.toMap(), event: .HANDSHAKE_REQ);

      connection.send(packet);

      emit(
        state.copyWith(
          device: connection.updateDevice(status: .HANDSHAKE_SENT),
        ),
      );

      connection.events.listen((data) {
        add(RecieveEvent(device: connection.device, data: data));
      });
    } on Exception catch (e, stk) {
      print(stk);
      emit(
        state.copyWith(device: state.server?.updateDevice(status: .INITIAL)),
      );

      if (event.port == ServerConfig.PORT) {
        print("Retry called with next port");
        add(event.copyWith(port: event.port + 1));
      }
    }
  }

  onConnectEvent(ConnectEvent event, Emitter<ClientState> emit) async {
    try {
      emit(
        state.copyWith(
          device: state.server?.updateDevice(status: .CONNECT_SENT),
        ),
      );
    } on Exception catch (e) {
      print(e);
      emit(
        state.copyWith(
          device: state.server?.updateDevice(status: .CONNECT_FAILED),
        ),
      );
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
        state.server?.send(packet);
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

    state.server?.send(packet);
  }

  FutureOr<void> onCheckPrevConnection(
    CheckPrevConnection event,
    Emitter<ClientState> emit,
  ) {
    String? ip = _localData.get<String>(PrefKeys.serverIP);
    print("saved ip ${ip}");
    if (ip?.isNotEmpty ?? false) {
      add(HandshakeEvent(ip: ip ?? "", port: ServerConfig.PORT));
    } else {
      print("No prev connection found");
    }
  }

  FutureOr<void> onRemoteInputEvent(
    RemoteInputEvent<dynamic> event,
    Emitter<ClientState> emit,
  ) {
    RemoteInputPacket packet = .new(
      data: event.data,
      event: .REMOTE_INPUT,
      inputType: event.type,
    );

    state.server?.send(packet);
  }

  FutureOr<void> onRecieveEvent(
    RecieveEvent recieveEvent,
    Emitter<ClientState> emit,
  ) {
    Map<String, dynamic> data = recieveEvent.data;

    Device device = recieveEvent.device;

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

            _localData.set<String>(PrefKeys.serverIP, res.device?.ip ?? "");

            emit(
              state.copyWith(
                device: state.server?.updateDevice(status: .CONNECT_SUCCESS),
              ),
            );
          } else {
            emit(
              state.copyWith(
                device: state.server?.updateDevice(status: .CONNECT_FAILED),
              ),
            );
          }
          break;

        case .HANDSHAKE_RES:
          HandshakeRes res = .fromMap(data["data"]);

          print(res.status);

          if (res.status == 1) {
            ConnectReq req = .new(device: device, secret: res.secret ?? "");

            EventPacket packet = .new(data: req.toMap(), event: .CONNECT_REQ);

            state.server?.send(packet);
            emit(
              state.copyWith(
                device: state.server?.updateDevice(status: .HANDSHAKE_SUCCESS),
              ),
            );
          } else {
            emit(
              state.copyWith(
                device: state.server?.updateDevice(status: .HANDSHAKE_FAILED),
              ),
            );
          }
          break;
        case .CLIPBOARD_SEND:
          _clipboardService.setClipboard(data["data"] as String);
          emit(state);
          break;
        case .MEDIA_DATA_SEND:
          DevicePlatform? platform = .values.parse(data["platform"] as String);
          if (platform == .linux) {
            PlayerState playerState = .fromJson(data["data"]);
            emit(state.copyWith(mediaState: playerState));
          }
          break;
        case Event.MEDIA_COMMAND:
          emit(state);
          break;
        case Event.REMOTE_INPUT:
          emit(state);
          break;
        case Event.DISCONNECT:
          emit(ClientState());
          break;
      }
    } else {
      debugPrint("Unknown Event ${data["event"]}");
    }
  }
}
