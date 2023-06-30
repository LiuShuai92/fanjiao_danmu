import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'danmu_model.dart';
import 'simulation/danmu_simulation.dart';
/*
class DanmuItem extends SingleChildRenderObjectWidget {
  final int id;
  final String? text;
  final Duration? startTime;
  final Offset? position;
  final int? flag;
  final double opacity;
  final bool isPause;

  const DanmuItem({
    Key? key,
    required Widget child,
    required this.id,
    this.text,
    this.startTime,
    this.position,
    this.flag,
    this.opacity = 1,
    this.isPause = false,
  }) : super(
          key: key,
          child: child,
        );

  @override
  RenderObject createRenderObject(BuildContext context) {
    var renderBubbleBox = DanmuItemBox();
    updateRenderObject(context, renderBubbleBox);
    return renderBubbleBox;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant DanmuItemBox renderObject) {
    *//*renderObject
      ..text = text
      ..startTime = startTime
      ..position = position
      ..flag = flag;*//*
  }
}

class DanmuItemRender extends RenderProxyBox {
  late int id;
  late String? text;
  late Duration? startTime;
  late Offset? position;
  late int? flag;
  late double opacity;
  late bool isPause;
*//*
  late int flag;
  bool isSelected = false;
  bool _isPause = false;
  Duration? dTime;
  late ImageConfiguration configuration;
  TextPainter? textPainter;
  TextPainter? textStrokePainter;
  InlineSpan? span;
  InlineSpan? textStrokeSpan;
  DanmuSimulation? _simulation;
  T get model => _model;

  bool get isPause => _isPause;

  bool get isTextSpan => span is TextSpan;

  Rect get rect =>
      position == null ? Rect.zero : (position! + model.margin.topLeft & size);

  Rect get imageRect => position == null
      ? Rect.zero
      : position! & size + model.margin.bottomRight;*//*

  Duration get endTime {
    assert(isValid);
    return startTime! +
        Duration(
          microseconds:
              (_simulation!.duration * Duration.microsecondsPerSecond).toInt(),
        );
  }

  Duration get startTime => model.startTime;

  Offset get startPosition {
    assert(isValid);
    return _simulation!.offset(0);
  }

  Offset get endPosition {
    assert(isValid);
    return _simulation!.offset(_simulation!.duration);
  }

  bool get isValid => _simulation != null;

  DanmuSimulation get simulation {
    assert(isValid);
    return _simulation!;
  }

  set simulation(DanmuSimulation simulation) {
    _simulation = simulation;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }
    var rect = offset & size;
  }
}*/
