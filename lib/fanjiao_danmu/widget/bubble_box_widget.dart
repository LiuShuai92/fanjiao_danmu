import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BubbleBox extends SingleChildRenderObjectWidget {
  final double pointerBias;
  final double strokeWidth;
  final double borderRadius;
  final double peakRadius;
  final double pointerWidth;
  final double pointerHeight;
  final double startPadding;
  final double endPadding;
  final double opacity;
  final Color color;
  final Color strokeColor;
  final bool isUpward;
  final bool isWrapped;
  final ImageFilter? filter;
  final BlendMode blendMode;

  BubbleBox({
    required Widget child,
    Key? key,
    this.pointerBias = 0.5,
    this.opacity = 0.5,
    this.strokeWidth = 1.2,
    this.color = Colors.black,
    this.strokeColor = Colors.white,
    this.borderRadius = 8,
    this.peakRadius = 3,
    this.pointerWidth = 10,
    this.pointerHeight = 6,
    this.startPadding = 0,
    this.endPadding = 0,
    this.isUpward = true,
    this.isWrapped = true,
    this.filter,
    this.blendMode = BlendMode.srcOver,
  }) : super(
          key: key,
          child: Padding(
            padding: isWrapped
                ? EdgeInsets.only(
                        top: isUpward ? pointerHeight : 0,
                        bottom: isUpward ? 0 : pointerHeight) +
                    EdgeInsets.all(borderRadius)
                : EdgeInsets.zero,
            child: child,
          ),
        );

  @override
  RenderObject createRenderObject(BuildContext context) {
    var renderBubbleBox = RenderBubbleBox();
    updateRenderObject(context, renderBubbleBox);
    return renderBubbleBox;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderBubbleBox renderObject) {
    renderObject
      ..strokeWidth = strokeWidth
      ..peakRadius = peakRadius
      ..pointerBias = pointerBias
      ..borderRadius = borderRadius
      ..startPadding = startPadding
      ..endPadding = endPadding
      ..pointerWidth = pointerWidth
      ..pointerHeight = pointerHeight
      ..strokeColor = strokeColor
      ..color = color
      ..opacity = opacity
      ..filter = filter
      ..blendMode = blendMode
      ..isUpward = isUpward;
  }
}

class RenderBubbleBox extends RenderProxyBox {
  Color? _color;
  Color? _strokeColor;
  double? _strokeWidth;
  double? _opacity;
  ImageFilter? filter;
  BlendMode blendMode = BlendMode.srcOver;
  late double borderRadius;
  late double peakRadius;
  late double pointerBias;
  late double startPadding;
  late double endPadding;
  late double pointerWidth;
  late double pointerHeight;
  late bool isUpward;
  Paint? _paintBorderPainter;
  Paint? _backgroundPainter;
  Paint? _painter;

  RenderBubbleBox();

  Paint get paintBorderPainter => _paintBorderPainter!;

  set strokeColor(Color value) {
    if (value == _strokeColor) {
      return;
    }
    _strokeColor = value;
    _paintBorderPainter ??= Paint()..style = PaintingStyle.stroke;
    _paintBorderPainter!.color = value;
    markNeedsPaint();
  }

  double get strokeWidth => _strokeWidth!;

  set strokeWidth(double value) {
    if (value == _strokeWidth) {
      return;
    }
    _strokeWidth = value;
    _paintBorderPainter ??= Paint()..style = PaintingStyle.stroke;
    _paintBorderPainter!.strokeWidth = value;
    markNeedsPaint();
  }

  Paint get backgroundPainter => _backgroundPainter!;

  set color(Color value) {
    if (value == _color) {
      return;
    }
    _color = value;
    _backgroundPainter ??= Paint();
    _backgroundPainter!.color = value;
    markNeedsPaint();
  }

  Paint get painter => _painter!;

  set opacity(double value) {
    if (value == _opacity) {
      return;
    }
    _opacity = value;
    _painter ??= Paint();
    _painter!.color = Colors.black.withOpacity(value);
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    paintBackground(offset, context);
    super.paint(context, offset);
  }

  void paintBackground(Offset offset, PaintingContext context) {
    var rect = offset & size;
    final width = size.width;
    final height = size.height;
    pointerWidth = width < pointerWidth ? width : pointerWidth;
    pointerHeight = height < pointerHeight ? height : pointerHeight;
    if (pointerWidth < peakRadius) {
      peakRadius = pointerWidth;
    }
    final arc = math.atan(pointerHeight / pointerWidth * 2);
    final double halfArcWidth = math.sin(arc) * peakRadius;
    final double l = peakRadius / math.cos(arc);
    var pointerStartX = width * pointerBias - pointerWidth / 2;
    var pointerEndX = width * pointerBias + pointerWidth / 2;
    var minRadius = math.min(width - pointerWidth, height - pointerHeight) / 2;
    if (borderRadius > minRadius) {
      borderRadius = minRadius;
    }
    Radius radius = Radius.circular(borderRadius);
    startPadding = startPadding > borderRadius ? startPadding : borderRadius;
    endPadding = endPadding > borderRadius ? endPadding : borderRadius;
    if (pointerStartX < startPadding) {
      pointerStartX = startPadding;
      pointerEndX = startPadding + pointerWidth;
    } else if (pointerEndX > width - endPadding) {
      pointerStartX = width - endPadding - pointerWidth;
      pointerEndX = width - endPadding;
    }
    var arcY = math.tan(arc) * halfArcWidth;
    arcY = pointerHeight < arcY ? pointerHeight : arcY;
    Path path = Path();
    if (isUpward) {
      path.moveTo(pointerStartX, pointerHeight);
      path.lineTo(pointerStartX + pointerWidth / 2 - halfArcWidth, arcY);
      // path.relativeConicTo(halfArcWidth, -arcY, halfArcWidth * 2, 0, 1);
      path.arcTo(
          Rect.fromCircle(
              center: Offset(pointerStartX + pointerWidth / 2, l),
              radius: peakRadius),
          -math.pi / 2 - arc,
          arc * 2,
          false);
      path.lineTo(pointerEndX, pointerHeight);
      path.lineTo(width - borderRadius, pointerHeight);
      path.arcToPoint(Offset(width, pointerHeight + borderRadius),
          radius: radius);
      path.lineTo(width, height - borderRadius);
      path.arcToPoint(Offset(width - borderRadius, height), radius: radius);
      path.lineTo(borderRadius, height);
      path.arcToPoint(Offset(0, height - borderRadius), radius: radius);
      path.lineTo(0, pointerHeight + borderRadius);
      path.arcToPoint(Offset(borderRadius, pointerHeight), radius: radius);
      path.close();
    } else {
      final bottom = height - pointerHeight;
      path.moveTo(pointerStartX, 0);
      path.lineTo(width - borderRadius, 0);
      path.arcToPoint(Offset(width, borderRadius), radius: radius);
      path.lineTo(width, bottom - borderRadius);
      path.arcToPoint(Offset(width - borderRadius, bottom), radius: radius);
      path.lineTo(pointerEndX, bottom);
      path.lineTo(pointerEndX - pointerWidth / 2 + halfArcWidth, height - arcY);
      path.arcTo(
          Rect.fromCircle(
              center: Offset(pointerEndX - pointerWidth / 2, height - l),
              radius: peakRadius),
          math.pi / 2 - arc,
          arc * 2,
          false);
      path.lineTo(pointerStartX, bottom);
      path.lineTo(borderRadius, bottom);
      path.arcToPoint(Offset(0, bottom - borderRadius), radius: radius);
      path.lineTo(0, borderRadius);
      path.arcToPoint(Offset(borderRadius, 0), radius: radius);
      path.close();
    }
    path = path.shift(offset);
    final innerPath = Path();
    innerPath.addPath(path, Offset.zero);
    var inflateRect = rect.inflate(strokeWidth / 2);
    if (filter != null) {
      context.pushClipPath(
        needsCompositing,
        const Offset(0, 0),
        inflateRect,
        path,
        (PaintingContext innerContext, Offset innerOffset) {
          innerContext.pushLayer(
              BackdropFilterLayer(
                filter: filter,
                blendMode: blendMode,
              ),
              (PaintingContext innerContext, Offset innerOffset) {},
              innerOffset);
        },
      );
    }
    Canvas canvas = context.canvas;
    canvas.saveLayer(inflateRect, painter);
    canvas.drawPath(innerPath, backgroundPainter);
    canvas.drawPath(path, paintBorderPainter);
    canvas.restore();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;
}
