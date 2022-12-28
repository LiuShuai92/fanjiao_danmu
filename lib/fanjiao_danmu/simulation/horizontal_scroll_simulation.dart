import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'danmu_simulation.dart';

class HorizontalScrollSimulation extends DanmuSimulation {
  HorizontalScrollSimulation({
    required this.right,
    required this.left,
    required this.size,
    this.paddingTop = 0,
    Tolerance tolerance = Tolerance.defaultTolerance,
    double duration = 7,
  })  : v = (left - size.width - right) / duration,
        super(Rect.fromLTRB(left - size.width, 0, right, double.infinity),
            tolerance: tolerance, duration: duration);

  final double right;
  final double left;
  final double v;
  final Size size;
  double paddingTop;

  @override
  Offset dOffset(double time) {
    return Offset(v * time, 0);
  }

  @override
  Offset offset(double time) => Offset(right + v * time, paddingTop);

  @override
  Offset? isDone(Offset o, double dt) {
    Offset result = o + dOffset(dt);
    var dx = result.dx;
    if (dx < rect.left) {
      return null;
    } else if (!isFullShown && dx > rect.right - size.width) {
      isFullShown = true;
    }
    return result;
  }
}
