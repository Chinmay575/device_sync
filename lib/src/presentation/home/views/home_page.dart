import 'dart:io';
import 'dart:math';

import 'package:connect/src/data/models/device.dart';
import 'package:connect/src/domain/bloc/client/client_bloc.dart';
import 'package:connect/src/domain/bloc/server/server_bloc.dart';
import 'package:connect/src/presentation/home/views/desktop_home_page.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';
import 'package:connect/src/utils/constants/strings/server_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connect/src/utils/extensions.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return DesktopHomePage();
    }
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.devices),
            onPressed: () {
              showDialog(context: context, builder: (_) => _ConnectionDialog());
            },
          ),
        ],
      ),
      drawer: Drawer(),
      body: SingleChildScrollView(
        child: Container(
          width: context.width,
          padding: .all(16.w),
          child: Column(
            crossAxisAlignment: .center,
            mainAxisSize: .min,
            children: [_Devices(), _Media(), _Functionality()],
          ),
        ),
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media();

  @override
  Widget build(BuildContext context) {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS || kIsWeb) {
      return SizedBox.shrink();
    }
    return BlocConsumer<ClientBloc, ClientState>(
      listener: (context, state) {},
      builder: (context, state) {
        // print(state.mediaState);

        if (state.mediaState == null) {
          return SizedBox.shrink();
        }
        return SliderTheme(
          data: SliderThemeData(thumbShape: .noThumb),
          child: Card(
            child: Container(
              padding: .all(16),
              width: context.width,
              child: Column(
                mainAxisSize: .min,
                children: [
                  _buildPlayerSelector(state, context),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Image.network(
                          buildImageArt(state),
                          height: 100,
                          width: 100,
                          errorBuilder: (_, __, ___) {
                            return Icon(Icons.image);
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              state.mediaState?.currentMedia.title ?? "",
                              softWrap: true,
                              maxLines: 2,
                              overflow: .ellipsis,
                              textAlign: .start,
                            ),
                            Text(
                              state.mediaState?.currentMedia.album ?? "",
                              softWrap: true,
                              maxLines: 2,
                              overflow: .ellipsis,
                              textAlign: .start,
                            ),
                            Text(
                              state.mediaState?.currentMedia.artist ?? "",
                              softWrap: true,
                              maxLines: 2,
                              overflow: .ellipsis,
                              textAlign: .start,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: .spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.shuffle),
                        onPressed: () {
                          context.read<ClientBloc>().add(
                            MediaEvent(command: .SHUFFLE),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_previous),
                        onPressed: () {
                          context.read<ClientBloc>().add(
                            MediaEvent(command: .PREV),
                          );
                        },
                      ),
                      Visibility(
                        visible:
                            state.mediaState?.currentMedia.status == "Playing",
                        replacement: IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () {
                            context.read<ClientBloc>().add(
                              MediaEvent(command: .PLAY),
                            );
                          },
                        ),
                        child: IconButton(
                          icon: Icon(Icons.pause_circle_outline),
                          onPressed: () {
                            context.read<ClientBloc>().add(
                              MediaEvent(command: .PAUSE),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next),
                        onPressed: () {
                          context.read<ClientBloc>().add(
                            MediaEvent(command: .NEXT),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.loop),
                        onPressed: () {
                          context.read<ClientBloc>().add(
                            MediaEvent(command: .LOOP),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          formatTime(
                            state.mediaState?.currentMedia.position ?? 0,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Slider.adaptive(
                          value: (state.mediaState?.currentMedia.position ?? 0)
                              .toDouble(),

                          onChanged: (val) {
                            context.read<ClientBloc>().add(
                              MediaEvent<double>(data: val, command: .SEEK),
                            );
                          },
                          min: 0,
                          max: max(
                            (state.mediaState?.currentMedia.length ?? 1)
                                .toDouble(),
                            (state.mediaState?.currentMedia.position ?? 0)
                                .toDouble(),
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 1,
                        child: Text(
                          formatTime(
                            state.mediaState?.currentMedia.length ?? 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(flex: 1, child: Icon(Icons.volume_down)),

                      Expanded(
                        flex: 6,
                        child: Slider.adaptive(
                          value: (state.mediaState?.volume ?? 0).toDouble(),

                          onChanged: (val) {
                            context.read<ClientBloc>().add(
                              MediaEvent<double>(data: val, command: .VOLUME),
                            );
                          },
                          min: 0,
                          max: 100,
                        ),
                      ),
                      Expanded(flex: 1, child: Icon(Icons.volume_up)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _buildPlayerSelector(ClientState state, BuildContext context) {
    if (state.mediaState?.availablePlayers.isEmpty ?? true) {
      return SizedBox.shrink();
    } else {
      return Row(
        children:
            state.mediaState?.availablePlayers
                .map(
                  (e) => _buildPlayerTile(
                    context,
                    e,
                    state.mediaState?.selectedPlayer,
                  ),
                )
                .toList() ??
            [],
      );
    }
  }

  Widget _buildPlayerTile(
    BuildContext context,
    String? playerName,
    String? selected,
  ) {
    String name = (playerName?.split('.').firstOrNull ?? "").capitalize;
    return InkWell(
      onTap: () {
        context.read<ClientBloc>().add(
          MediaEvent(command: .PLAYER, data: playerName),
        );
      },
      child: Container(
        padding: .all(8),
        decoration: BoxDecoration(
          color: (playerName == selected) ? Colors.green : Colors.grey,
          borderRadius: .circular(100),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            _buildPlayerIcon(playerName),
            SizedBox(width: 8),
            Text(name, style: .new(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerIcon(String? playerName) {
    if (playerName?.contains("spotify") ?? false) {
      return Brand(Brands.spotify, size: 16);
    }
    if (playerName?.contains("brave") ?? false) {
      return Brand(Brands.brave_web_browser, size: 16);
    }

    if (playerName?.contains("vlc") ?? false) {
      return Brand(Brands.vlc, size: 16);
    }

    return Icon(Icons.music_note, size: 16, color: Colors.white);
  }

  String buildImageArt(ClientState state) {
    String ip = state.server?.device.ip ?? "";
    String path = state.mediaState?.currentMedia.artUrl ?? "";
    if (path.contains('0.0.0.0')) {
      path = path.replaceAll("0.0.0.0", ip);
    }
    return path;
  }
}

class _Devices extends StatelessWidget {
  const _Devices();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServerBloc, ServerState>(
      builder: (_, state) {
        if (state is ServerReady &&
            (state.currentDevice?.device.isServer ?? false)) {
          return Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              Text("Connected Devices: "),
              SizedBox(height: 16.h),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  separatorBuilder: (_, __) => SizedBox(width: 16.w),
                  scrollDirection: .horizontal,
                  itemBuilder: (_, i) {
                    Device device = state.devices[i].device;
                    return SizedBox(
                      height: 160,
                      width: 160,
                      child: Card(
                        elevation: 4,
                        margin: .all(2),
                        child: Column(
                          mainAxisAlignment: .center,
                          children: [
                            Text(device.deviceName),
                            Text(device.model),
                            Text(device.ip),
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: state.devices.length,
                  shrinkWrap: true,
                ),
              ),
            ],
          );
        }
        return Container();
      },
    );
  }
}

class _Functionality extends StatelessWidget {
  const _Functionality();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: .only(top: 16),
      width: context.width,
      child: Wrap(
        crossAxisAlignment: .center,
        alignment: .center,
        spacing: 16,
        runSpacing: 16,
        children: Functionality.values
            .map((e) => _CustomGridTile(functionality: e))
            .toList(),
      ),
    );
  }
}

class _CustomGridTile extends StatelessWidget {
  const _CustomGridTile({required this.functionality});

  final Functionality functionality;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: 160,
      child: InkWell(
        onTap: () {
          if (functionality.route.isNotEmpty) {
            Navigator.pushNamed(context, functionality.route);
          }
        },
        child: Card(
          elevation: 4,
          margin: .zero,
          child: Column(
            crossAxisAlignment: .center,
            mainAxisAlignment: .center,
            children: [
              Icon(functionality.icon, size: 32),
              SizedBox(height: 12),
              Text(functionality.Name),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionDialog extends StatelessWidget {
  _ConnectionDialog();

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: .circular(8)),
        child: Container(
          padding: .symmetric(horizontal: 16, vertical: 20),
          child: BlocBuilder<ClientBloc, ClientState>(
            builder: (context, state) {
              if (state.server == null) {
                return Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,
                  children: [
                    Text("Connect Manually"),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ipController,
                            decoration: .new(hintText: "IP Address"),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            if (ipController.value.text.isNotEmpty) {
                              Navigator.pop(context);
                              context.read<ClientBloc>().add(
                                HandshakeEvent(
                                  ip: ipController.value.text,
                                  port: ServerConfig.PORT,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                mainAxisSize: .min,
                children: [
                  Text("Connection Status ${state.server?.device.status.name}"),
                  Text(state.server?.device.deviceName ?? ""),
                  Text(state.server?.device.model ?? ""),
                  Text(state.server?.device.ip ?? ""),
                ],
              );
            },
          ),
        ),
      );
    }
    return BlocBuilder<ServerBloc, ServerState>(
      bloc: context.read<ServerBloc>(),
      builder: (_, state) {
        return Dialog(child: builder(state));
      },
    );
  }

  final TextEditingController ipController = .new();

  Widget builder(ServerState state) {
    // print(state.runtimeType);
    if (state is ServerReady) {
      return Container(
        padding: .all(16),
        child: Column(
          crossAxisAlignment: .center,
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          children: [
            SizedBox(
              height: 160,
              child: QrImageView(data: state.serverIP, size: 160),
            ),
            Text("Connect Manually: "),
            SizedBox(height: 16),
            InkWell(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: state.serverIP));
              },
              child: Text(state.serverIP),
            ),
            SizedBox(height: 16),
          ],
        ),
      );
    } else {
      return Text("Server Not Started");
    }
  }
}

String formatTime(int milliseconds) {
  var secs = milliseconds ~/ 1000000;
  var hours = (secs ~/ 3600).toString().padLeft(2, '0');
  var minutes = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
  var seconds = (secs % 60).toString().padLeft(2, '0');

  // Optional: Only show hours if the time is greater than 1 hour
  if (hours == "00") {
    return "$minutes:$seconds";
  }

  return "$hours:$minutes:$seconds";
}
