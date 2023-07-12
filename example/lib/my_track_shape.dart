import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MyTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const MyTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    assert(context != null);
    assert(offset != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    assert(enableAnimation != null);
    assert(textDirection != null);
    assert(thumbCenter != null);
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor);
    final Paint activePaint = Paint();
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;
    final Paint leftTrackPaint;
    final Paint rightTrackPaint;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final double bias = thumbCenter.dx / trackRect.width;
    Shader shader;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        shader = ui.Gradient.linear(
          trackRect.centerLeft,
          trackRect.centerRight,
          [
            const Color(0XFFE5C6FF),
            getBiasColor(0XFFE5C6FF, 0XFF836BFF, bias),
          ],
        );
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        shader = ui.Gradient.linear(
          trackRect.centerRight,
          trackRect.centerLeft,
          [
            const Color(0XFFE5C6FF),
            getBiasColor(0XFFE5C6FF, 0XFF836BFF, bias),
          ],
        );
        break;
    }
    activePaint.shader = shader;

    final Radius trackRadius = Radius.circular(trackRect.height / 2);
    final Radius activeTrackRadius =
        Radius.circular((trackRect.height + additionalActiveTrackHeight) / 2);

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        trackRect.top,
        thumbCenter.dx,
        trackRect.bottom,
        topLeft: (textDirection == TextDirection.ltr)
            ? activeTrackRadius
            : trackRadius,
        bottomLeft: (textDirection == TextDirection.ltr)
            ? activeTrackRadius
            : trackRadius,
      ),
      leftTrackPaint,
    );
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        thumbCenter.dx,
        trackRect.top,
        trackRect.right,
        trackRect.bottom,
        topRight: (textDirection == TextDirection.rtl)
            ? activeTrackRadius
            : trackRadius,
        bottomRight: (textDirection == TextDirection.rtl)
            ? activeTrackRadius
            : trackRadius,
      ),
      rightTrackPaint,
    );
  }
}

Color getBiasColor(int startColorValue, int endColorValue, double bias) {
  if (bias < 0) return Color(startColorValue);
  if (bias > 1) return Color(endColorValue);
  final startValueA = (startColorValue & 0xFF000000) >> 24;
  final startValueR = (startColorValue & 0x00FF0000) >> 16;
  final startValueG = (startColorValue & 0x0000FF00) >> 8;
  final startValueB = startColorValue & 0x000000FF;

  final endValueA = (endColorValue & 0xFF000000) >> 24;
  final endValueR = (endColorValue & 0x00FF0000) >> 16;
  final endValueG = (endColorValue & 0x0000FF00) >> 8;
  final endValueB = endColorValue & 0x000000FF;

  final biasValueA = startValueA + ((endValueA - startValueA) * bias).floor();
  final biasValueR = startValueR + ((endValueR - startValueR) * bias).floor();
  final biasValueG = startValueG + ((endValueG - startValueG) * bias).floor();
  final biasValueB = startValueB + ((endValueB - startValueB) * bias).floor();
  var biasColorValue =
      (biasValueA << 24) + (biasValueR << 16) + (biasValueG << 8) + biasValueB;
  return Color(biasColorValue);
}
