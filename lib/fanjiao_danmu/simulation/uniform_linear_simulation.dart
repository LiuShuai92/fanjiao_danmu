import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'danmu_simulation.dart';

class UniformLinearSimulation extends DanmuSimulation {
  UniformLinearSimulation(
    Offset startOffset,
    Offset endOffset,
    Rect rect, {
    Tolerance tolerance = Tolerance.defaultTolerance,
    double duration = 7,
  })  : assert(startOffset != null),
        assert(duration != null),
        assert(endOffset != null),
        assert(endOffset >= Offset.zero),
        start = startOffset,
        v = (endOffset - startOffset) / duration,
        end = endOffset,
        super(rect, tolerance: tolerance, duration: duration);

  final Offset v;
  final Offset start;
  final Offset end;

  @override
  Offset offset(double time) => start + v * time;

  @override
  Offset dOffset(double time) => v * time;

  @override
  Offset? isDone(Offset o, double dt) {
    Offset result = o + dOffset(dt);
    if (rect.contains(result)) {
      return null;
    }
    return result;
  }

  double predictedTime({Offset? offset}) {
    final double x;
    final double y;
    if (offset == null) {
      x = end.dx;
      y = end.dy;
    } else {
      Offset d = end - start;
      x = d.dx > 0 ? math.min(offset.dx, end.dx) : math.max(offset.dx, end.dx);
      y = d.dy > 0 ? math.min(offset.dy, end.dy) : math.max(offset.dy, end.dy);
    }
    final double xt = (x - start.dx) / v.dx;
    final double yt = (y - start.dy) / v.dy;
    var t = math.min(xt, yt);
    return t;
  }
}
