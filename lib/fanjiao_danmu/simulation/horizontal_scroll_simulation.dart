import 'dart:ui';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'danmu_simulation.dart';

class HorizontalScrollSimulation extends DanmuSimulation {
  final double right;
  final double left;
  final double v;
  final Size size;
  double y;

  HorizontalScrollSimulation({
    required this.size,
    required this.right,
    required this.left,
    this.y = 0,
    Tolerance tolerance = Tolerance.defaultTolerance,
    double duration = 7,
  })  : v = (left - size.width - right) / duration,
        super(Rect.fromLTRB(left - size.width, 0, right, double.infinity),
            tolerance: tolerance, duration: duration) {
    isFullShown = false;
  }

  @override
  Offset dOffset(double time) {
    return Offset(v * time, 0);
  }

  @override
  Offset offset(double time) => Offset(stageRect.right + v * time, y);

  @override
  Offset? isDone(Offset o, double dt) {
    Offset result = o + dOffset(dt);
    var dx = result.dx;
    if (dx < stageRect.left) {
      return null;
    } else if (!isFullShown && dx < stageRect.right - size.width) {
      isFullShown = true;
    }
    return result;
  }

  HorizontalScrollSimulation copyWith({
    Size? size,
    double? right,
    double? left,
    double? y,
    Tolerance? tolerance,
    double? duration,
  }) {
    return HorizontalScrollSimulation(
      size: size ?? this.size,
      right: right ?? this.right,
      left: left ?? this.left,
      y: y ?? this.y,
      tolerance: tolerance ?? this.tolerance,
      duration: duration ?? this.duration,
    );
  }
}
