import 'package:flutter/material.dart';

extension BuildExtension on BuildContext {
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;
}

extension Capitalize on String {
  String get capitalize {
    if (length > 1) {
      return this[0].toUpperCase() + substring(1).toLowerCase();
    }
    return toUpperCase();
  }
}
