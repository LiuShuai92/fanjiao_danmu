import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

export 'horizontal_scroll_simulation.dart';
export 'uniform_linear_simulation.dart';

abstract class DanmuSimulation {
  double time = 0;
  bool isFullShown = true;

  DanmuSimulation(
    this.rect, {
    this.tolerance = Tolerance.defaultTolerance,
    this.duration = 7,
  });

  final Rect rect;

  final Tolerance tolerance;

  final double duration;

  Offset offset(double time);

  Offset dOffset(double time);

  /// 通常返回null为结束
  Offset? isDone(Offset o, double dt) {
    time += dt;
    return time > duration ? null : offset(time);
  }

  @override
  String toString() => objectRuntimeType(this, 'DanmuSimulation');
}
