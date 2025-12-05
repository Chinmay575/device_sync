import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:connect/src/data/models/connect_req.dart';
import 'package:connect/src/data/models/connect_res.dart';
import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/data/models/device_connection.dart';
import 'package:connect/src/data/models/handshake_req.dart';
import 'package:connect/src/data/models/handshake_res.dart';
import 'package:connect/src/data/models/notification_reply.dart';
import 'package:connect/src/data/models/packet.dart';
import 'package:connect/src/domain/repositories/clipboard_repository.dart';
import 'package:connect/src/domain/repositories/device_repository.dart';
import 'package:connect/src/domain/repositories/local_data_repository.dart';
import 'package:connect/src/domain/repositories/notification_listener_repository.dart';
import 'package:connect/src/domain/repositories/notification_repository.dart';
import 'package:connect/src/domain/repositories/socket_client_repository.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';
import 'package:connect/src/utils/constants/strings/pref_keys.dart';
import 'package:connect/src/utils/constants/strings/server_config.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart'
    show NotificationListenerService;
import 'package:playerctl/core/player_state.dart';

part 'client_event.dart';
part 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final SocketClient _client = .instance;
  final ClipboardService _clipboardService = .instance;
  final LocalDataRepository _localData = .instance;
  final DeviceRepository deviceRepository = .new();
  final NotificationListenerRepository _notificationListenerRepository =
      .instance;
  final NotificationRepository _notificationRepository = .instance;
  ClientBloc() : super(ClientState()) {
    on<CheckPrevConnection>(onCheckPrevConnection);
    on<ConnectEvent>(onConnectEvent);
    on<HandshakeEvent>(onHandshakeEvent);
    on<SyncClipboard>(onClipboardSync);
    on<MediaEvent>(onMediaEvent);
    on<RemoteInputEvent>(onRemoteInputEvent);
    on<RecieveEvent>(onRecieveEvent);
    on<NotificationSyncEvent>(onNotificationSyncEvent);
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
      debugPrint("$stk");
      emit(
        state.copyWith(device: state.server?.updateDevice(status: .INITIAL)),
      );

      if (event.port == ServerConfig.PORT) {
        debugPrint("Retry called with next port");
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
      debugPrint("$e");
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
    debugPrint("saved ip $ip");
    if (ip?.isNotEmpty ?? false) {
      add(HandshakeEvent(ip: ip ?? "", port: ServerConfig.PORT));
    } else {
      debugPrint("No prev connection found");
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

    debugPrint("Packet received $data, ${data.runtimeType}");

    Event? event = .values.parse((data['event'] ?? "") as String);

    if (event != null) {
      switch (event) {
        case .HANDSHAKE_REQ:
        case .CONNECT_REQ:
          break;
        case .CONNECT_RES:
          ConnectRes res = .fromMap(data["data"]);

          if (res.status == 1) {
            debugPrint(
              "-------------------------------Connection success----------------------------------------------",
            );
            add(SyncClipboard());
            add(NotificationSyncEvent());

            _notificationListenerRepository.getAllNotifications();

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

          // debugPrint(res.status);

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
        case .MEDIA_COMMAND:
          emit(state);
          break;
        case .REMOTE_INPUT:
          emit(state);
          break;
        case .DISCONNECT:
          emit(ClientState());
          break;
        case .NOTIFICATION_SYNC:
          break;
        case .NOTIFICATION_CLOSE:
          int? id = data["data"];
          if (id == null) {
            _notificationRepository.cancelAll();
          } else {
            _notificationRepository.cancel(id);
          }
          break;
        case Event.NOTIFICATION_REPLY:
          NotificationReply reply = .fromMap(data["data"]);
          Future.delayed(Duration.zero, () async {
            List<ServiceNotificationEvent> e =
                await NotificationListenerService.getActiveNotifications();

            ServiceNotificationEvent? notificationEvent = e
                .where((e) => e.id == reply.id)
                .firstOrNull;

            await notificationEvent?.sendReply(reply.reply);
          });
      }
    } else {
      debugPrint("Unknown Event ${data["event"]}");
    }
  }

  FutureOr<void> onNotificationSyncEvent(
    NotificationSyncEvent event,
    Emitter<ClientState> emit,
  ) async {
    await emit.forEach(
      _notificationListenerRepository.notificationStream,
      onData: (data) {
        AndroidNotificationPacket packet = .new(data: data);

        state.server?.send(packet);
        return state;
      },
    );
  }
}
