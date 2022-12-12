import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'danmu_simulation.dart';

class HorizontalScrollSimulation extends DanmuSimulation {
  HorizontalScrollSimulation({
    required this.start,
    required this.end,
    this.paddingTop = 0,
    this.reverse = false,
    Tolerance tolerance = Tolerance.defaultTolerance,
    double duration = 7,
  })  : v = (end - start) / duration,
        super(Rect.fromLTRB(end, 0, start, double.infinity),
            tolerance: tolerance, duration: duration);

  final double start;
  final double end;
  final double v;
  double paddingTop;
  bool reverse;

  @override
  Offset dOffset(double time) {
    return Offset(v * time, 0);
  }

  @override
  Offset offset(double time) => Offset(start + v * time, paddingTop);

  @override
  Offset? isDone(Offset o, double dt) {
    Offset result = o + dOffset(dt);
    var dx = result.dx;
    if (reverse) {
      if (dx > rect.right) {
        return null;
      }
    } else {
      if (dx < rect.left) {
        return null;
      }
    }
    return result;
  }

  double predictedTime({double? x}) {
    if (x == null) {
      x = end;
    } else {
      final double d = end - start;
      x = end > start ? math.min(d, end) : math.max(d, end);
    }
    final double t = (x - start) / v;
    return t;
  }
}
