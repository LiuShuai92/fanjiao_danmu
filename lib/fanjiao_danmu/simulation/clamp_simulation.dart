import 'dart:ui';

import 'danmu_simulation.dart';

class ClampSimulation extends DanmuSimulation {
  final Offset clampOffset;

  ClampSimulation({
    required this.clampOffset,
    double duration = 7,
  }) : super(Rect.zero, duration: duration) {
    isFullShown = false;
  }

  @override
  Offset dOffset(double time) => Offset.zero;

  @override
  Offset offset(double time) {
    return clampOffset;
  }

  ClampSimulation copyWith({
    Offset? clampOffset,
    double? duration,
  }) {
    return ClampSimulation(
      clampOffset: clampOffset ?? this.clampOffset,
      duration: duration ?? this.duration,
    );
  }
}
