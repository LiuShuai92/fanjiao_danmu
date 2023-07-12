import 'package:flutter/material.dart';

class MyThumbShape extends SliderComponentShape {
  const MyThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.fromRadius(8);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    Paint paint = Paint();
    canvas.drawCircle(
      center,
      8,
      paint
        ..style = PaintingStyle.fill
        ..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      8,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x1A836BFE),
    );
    canvas.drawCircle(
      center,
      3,
      paint
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF836BFF),
    );
  }
}
