import 'package:connect/src/data/models/notification_data.dart';
import 'package:connect/src/domain/bloc/server/server_bloc.dart';
import 'package:connect/src/presentation/home/views/desktop_file_transfer_page.dart';
import 'package:connect/src/utils/constants/strings/enums.dart';
import 'package:connect/src/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesktopHomePage extends StatefulWidget {
  DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage>
    with TickerProviderStateMixin {
  List<Functionality> functions = [.FILE_TRANSFER, .CLIPBOARD_SYNC];
  late TabController tabController = TabController(
    length: functions.length,
    vsync: this,
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServerBloc, ServerState>(
      listener: (_, __) {},
      builder: (_, state) {
        if (state is ServerReady) {
          return LayoutBuilder(
            builder: (context, constraints) {
              bool isSideBarVisible = constraints.maxWidth > 1000;
              print(constraints);
              return Scaffold(
                appBar: (isSideBarVisible)
                    ? null
                    : AppBar(
                        title: TabBar(
                          controller: tabController,
                          tabs: functions
                              .map((e) => Tab(text: e.Name))
                              .toList(),
                        ),
                      ),
                drawer: (!isSideBarVisible)
                    ? Drawer(width: 500, child: SideBar())
                    : null,
                body: Row(
                  children: [
                    if (isSideBarVisible) Expanded(flex: 1, child: SideBar()),
                    Expanded(
                      flex: 3,
                      child: Container(
                        child: Column(
                          mainAxisSize: .min,
                          children: [
                            AnimatedSwitcher(
                              duration: Duration(seconds: 2),
                              child: (isSideBarVisible)
                                  ? TabBar(
                                      controller: tabController,
                                      tabs: functions
                                          .map((e) => Tab(text: e.Name))
                                          .toList(),
                                    )
                                  : null,
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: tabController,
                                children: functions.map((e) {
                                  if (e == .FILE_TRANSFER &&
                                      state
                                              .devices
                                              .firstOrNull
                                              ?.device
                                              .status ==
                                          .CONNECT_SUCCESS) {
                                    return DesktopFileTransferPage();
                                  }
                                  return Container();
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return Scaffold();
      },
    );
  }
}

class SideBar extends StatelessWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServerBloc, ServerState>(
      builder: (context, state) {
        return Container(
          padding: .all(12),
          color: Colors.grey.shade100,
          child: Column(
            children: [
              Icon(state.devices.firstOrNull?.device.status.icon),
              Text(state.devices.firstOrNull?.device.deviceName ?? ""),
              Text(state.devices.firstOrNull?.device.model ?? ""),
              Text(state.devices.firstOrNull?.device.platform.name ?? ""),
              Text(state.devices.firstOrNull?.device.ip ?? ""),
              SizedBox(height: 32),
              Visibility(
                visible:
                    state.devices.firstOrNull?.notifications.isNotEmpty ??
                    false,
                child: Align(
                  alignment: .topRight,
                  child: TextButton(
                    onPressed: () {
                      context.read<ServerBloc>().add(
                        NotificationClose(
                          id: null,
                          device: state.devices.first,
                        ),
                      );
                    },
                    child: Text("Clear All"),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    NotificationData? e = state
                        .devices
                        .firstOrNull
                        ?.notifications
                        .elementAtOrNull(i);

                    TextEditingController controller = TextEditingController();

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: .all(color: Colors.black),
                        borderRadius: .circular(12),
                      ),
                      padding: .all(12),
                      child: Column(
                        mainAxisSize: .min,
                        children: [
                          Row(
                            mainAxisAlignment: .start,
                            children: [
                              if (e?.appIcon?.isNotEmpty ?? false)
                                Image.memory(
                                  e!.appIcon!,
                                  height: 20,
                                  width: 20,
                                ),
                              SizedBox(width: 16),
                              Text("${e?.appName}"),
                              Spacer(),
                              Text(e?.receivedAt.toString() ?? ""),
                              IconButton(
                                onPressed: () {
                                  context.read<ServerBloc>().add(
                                    NotificationClose(
                                      id: e?.id,
                                      device: state.devices.first,
                                    ),
                                  );
                                },
                                icon: Icon(Icons.close),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (e?.largeIcon?.isNotEmpty ?? false)
                                Image.memory(
                                  e!.largeIcon!,
                                  height: 64,
                                  width: 64,
                                ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: .start,
                                  children: [
                                    Text("${e?.title}"),
                                    Text("${e?.content}"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (e?.canReply ?? false)
                            TextField(
                              controller: controller,
                              decoration: .new(
                                hintText: "Reply...",
                                suffixIcon: InkWell(
                                  onTap: () {
                                    if (controller.text.trim().isNotEmpty) {
                                      context.read<ServerBloc>().add(
                                        NotificationReplyEvent(
                                          device: state.devices.first,
                                          id: e!.id!,
                                          reply: controller.text,
                                        ),
                                      );

                                      controller.clear();
                                    }
                                  },
                                  child: Icon(Icons.send),
                                ),
                                border: UnderlineInputBorder(
                                  borderSide: .new(width: 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  itemCount:
                      state.devices.firstOrNull?.notifications.length ?? 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
