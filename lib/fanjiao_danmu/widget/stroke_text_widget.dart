import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class StrokeTextWidget extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final _StrokeTextPainter _strokeTextPainter;

  Rect get rect => _strokeTextPainter.rect;

  StrokeTextWidget(
    this.text, {
    Key? key,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
    RawLinearGradient? linearGradient,
    double textScaleFactor = 1,
    double strokeWidth = 1,
    double opacity = 1,
    BoxDecoration? decoration,
    EdgeInsets padding = EdgeInsets.zero,
    Color strokeColor = Colors.black,
  })  : _strokeTextPainter = _StrokeTextPainter(
          text,
          textStyle: textStyle,
          linearGradient: linearGradient,
          textScaleFactor: textScaleFactor,
          strokeWidth: strokeWidth,
          strokeColor: strokeColor,
          decoration: decoration,
          padding: padding,
          opacity: opacity,
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _strokeTextPainter.rect.width,
      height: _strokeTextPainter.rect.height,
      child: CustomPaint(
        painter: _strokeTextPainter,
      ),
    );
  }
}

class _StrokeTextPainter extends CustomPainter {
  final Paint _painter;
  final String text;
  final TextStyle textStyle;
  final RawLinearGradient? linearGradient;
  final BoxDecoration? decoration;
  final EdgeInsets padding;
  final double opacity;
  late TextPainter textPainter;
  late TextPainter textStrokePainter;
  late Rect rect;
  late TextSpan textSpan;

  _StrokeTextPainter(
    this.text, {
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
    this.linearGradient,
    this.decoration,
    this.opacity = 1,
    this.padding = EdgeInsets.zero,
    double textScaleFactor = 1,
    double strokeWidth = 1,
    Color strokeColor = Colors.black,
  })  : _painter = Paint()..color = Colors.black.withOpacity(opacity),
        textPainter = TextPainter(textDirection: TextDirection.ltr),
        textStrokePainter = TextPainter(textDirection: TextDirection.ltr) {
    var textStrokeSpanStyle = textStyle.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * textScaleFactor * 2
          ..color = strokeColor);
    TextSpan textStrokeSpan = TextSpan(text: text, style: textStrokeSpanStyle);

    textStrokePainter
      ..text = textStrokeSpan
      ..textScaleFactor = textScaleFactor
      ..layout();
    rect = Rect.fromLTRB(0, 0, textStrokePainter.width + padding.horizontal,
        textStrokePainter.height + padding.vertical);
    if (linearGradient != null) {
      Shader shader = ui.Gradient.linear(
        rect.convert(linearGradient!.from),
        rect.convert(linearGradient!.to),
        linearGradient!.colors,
        linearGradient!.colorStops,
        linearGradient!.tileMode,
        linearGradient!.matrix4,
      );
      textSpan = TextSpan(
        text: text,
        style: textStyle.copyWith(foreground: Paint()..shader = shader),
      );
    } else {
      textSpan = TextSpan(text: text, style: textStyle);
    }
    textPainter
      ..text = textSpan
      ..textScaleFactor = textScaleFactor
      ..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (decoration != null) {
      var boxPainter = decoration!.createBoxPainter();
      boxPainter.paint(canvas, rect.topLeft, ImageConfiguration(size: size));
    }
    canvas.saveLayer(rect, _painter);
    textStrokePainter.paint(canvas, rect.topLeft + padding.topLeft);
    textPainter.paint(canvas, rect.topLeft + padding.topLeft);
    canvas.restore();
  }

  ///shouldRepaint则决定当条件变化时是否需要重画。
  @override
  bool shouldRepaint(_StrokeTextPainter oldDelegate) {
    return oldDelegate.textStyle != textStyle ||
        oldDelegate.text != text ||
        oldDelegate.opacity != opacity ||
        oldDelegate.padding != padding;
  }

  void drawDashedLine(
      Canvas canvas, double left, double right, double y, Paint paint) {
    const double dashWidth = 4;
    const double dashSpace = 4;
    const space = (dashSpace + dashWidth);
    for (double x = left; x < right; x += space) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
    }
  }
}

class RawLinearGradient {
  final LocalPosition from;
  final LocalPosition to;
  final List<Color> colors;
  final List<double>? colorStops;
  final TileMode tileMode;
  final Float64List? matrix4;

  const RawLinearGradient(
    this.from,
    this.to,
    this.colors, [
    this.colorStops,
    this.tileMode = TileMode.clamp,
    this.matrix4,
  ]);
}

extension RectConvert on Rect {
  Offset convert(LocalPosition localPosition) {
    switch (localPosition) {
      case LocalPosition.topLeft:
        return topLeft;
      case LocalPosition.topCenter:
        return topCenter;
      case LocalPosition.topRight:
        return topRight;
      case LocalPosition.centerLeft:
        return centerLeft;
      case LocalPosition.center:
        return center;
      case LocalPosition.centerRight:
        return centerRight;
      case LocalPosition.bottomLeft:
        return bottomLeft;
      case LocalPosition.bottomCenter:
        return bottomCenter;
      case LocalPosition.bottomRight:
        return bottomRight;
      default:
        return center;
    }
  }
}

enum LocalPosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}
