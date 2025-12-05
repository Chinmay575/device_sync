import 'dart:async';

import 'package:connect/src/utils/constants/strings/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/bloc/client/client_bloc.dart';

class RemoteInputPage extends StatefulWidget {
  const RemoteInputPage({super.key});

  @override
  State<RemoteInputPage> createState() => _RemoteInputPageState();
}

class _RemoteInputPageState extends State<RemoteInputPage>
    with TickerProviderStateMixin {
  late TabController tabBarController = .new(
    vsync: this,
    length: RemoteInputType.values.length,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: MaterialButton(
                height: 48,
                onPressed: () {
                  Map<String, dynamic> d = {
                    'type': MouseEventType.CLICK.name,
                    'btn': 'LEFT',
                  };

                  context.read<ClientBloc>().add(
                    RemoteInputEvent(data: d, type: .MOUSE),
                  );
                },
                color: Colors.grey.shade100,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: MaterialButton(
                height: 48,
                onPressed: () {
                  Map<String, dynamic> d = {
                    'type': MouseEventType.CLICK.name,
                    'btn': 'RIGHT',
                  };

                  context.read<ClientBloc>().add(
                    RemoteInputEvent(data: d, type: .MOUSE),
                  );
                },
                color: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisSize: .min,
        children: [
          SizedBox(
            height: 40,
            child: TabBar(
              isScrollable: false,
              controller: tabBarController,
              tabs: [
                Tab(text: "Trackpad"),
                Tab(text: "Keyboard"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              controller: tabBarController,
              children: [TrackPadTab(), KeyboardTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class TrackPadTab extends StatefulWidget {
  const TrackPadTab({super.key});

  @override
  State<TrackPadTab> createState() => _TrackPadTabState();
}

class _TrackPadTabState extends State<TrackPadTab> {
  final double sensitivity = 2.0;

  final double scrollSensitivity = 3.0;

  double _pendingDx = 0.0;

  double _pendingDy = 0.0;

  // The throttling timer
  Timer? _throttleTimer;

  // Configuration: How often to send (in milliseconds)
  final Duration _interval = const Duration(milliseconds: 20);

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // 1. Accumulate the movement (DO NOT SEND YET)
    _pendingDx += details.delta.dx;
    _pendingDy += details.delta.dy;

    // 2. Ensure the timer is running
    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _throttleTimer = Timer(_interval, _flushPackets);
    }
  }

  void _flushPackets() {
    if (_pendingDx == 0 && _pendingDy == 0) return;

    Map<String, dynamic> d = {
      'type': MouseEventType.MOVE.name,
      'dx': _pendingDx,
      'dy': _pendingDy,
    };

    context.read<ClientBloc>().add(RemoteInputEvent(data: d, type: .MOUSE));

    _pendingDx = 0;
    _pendingDy = 0;

    _throttleTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: _onPanUpdate,

      onTap: () {
        Map<String, dynamic> d = {
          'type': MouseEventType.CLICK.name,
          'btn': 'LEFT',
        };

        context.read<ClientBloc>().add(RemoteInputEvent(data: d, type: .MOUSE));
      },
      onLongPress: () {
        HapticFeedback.mediumImpact(); // Give feedback
        Map<String, dynamic> d = {
          'type': MouseEventType.CLICK.name,
          'btn': 'RIGHT',
        };

        Future.delayed(Duration.zero, () {
          if (context.mounted) {
            context.read<ClientBloc>().add(
              RemoteInputEvent(data: d, type: .MOUSE),
            );
          }
        });
      },
      child: Center(child: Text("Move your finger to move the mouse cursor")),
    );
  }
}

class KeyboardTab extends StatelessWidget {
  const KeyboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
