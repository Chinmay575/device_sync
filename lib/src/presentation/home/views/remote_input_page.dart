import 'package:flutter/material.dart';

class TrackpadPage extends StatelessWidget {
  // Sensitivity Multipliers
  final double sensitivity = 2.0;
  final double scrollSensitivity = 3.0;

  // void _send(BuildContext context, String type, Map<String, dynamic> data) {
  //   // context.read<ClientBloc>().add(
  //   //     SendPacketEvent(event: Event.INPUT_MOUSE, data: {"type": type, ...data})
  //   // );
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212), // Dark trackpad surface
      // width: double.infinity,
      // height: double.infinity,
      child: GestureDetector(
        // behavior: HitTestBehavior.translucent,
        //
        // // 1. MOUSE MOVE (One Finger)
        // onPanUpdate: (details) {
        //   // _send(context, 'move', {
        //   //   'dx': details.delta.dx * sensitivity,
        //   //   'dy': details.delta.dy * sensitivity
        //   // });
        // },
        //
        // // 2. SCROLL (Two Fingers)
        // // onScaleUpdate fires when 2 pointers are down.
        // // We use the focalPointDelta for scrolling logic.
        // onScaleUpdate: (details) {
        //   // Check if it's a scroll (drag) rather than a zoom (scale)
        //   if (details.scale == 1.0) {
        //     // _send(context, 'scroll', {
        //     //   'dy': details.focalPointDelta.dy * scrollSensitivity
        //     // });
        //   }
        // },
        //
        // // 3. LEFT CLICK (Tap)
        // // onTap: () => _send(context, 'click', {'btn': 'left'}),
        //
        // // 4. RIGHT CLICK (Two Finger Tap is hard in standard Flutter)
        // // Workaround: Use Double Tap or Long Press for Right Click
        // onLongPress: () {
        //   // HapticFeedback.mediumImpact(); // Give feedback
        //   // _send(context, 'click', {'btn': 'right'});
        // },
      ),
    );
  }
}
