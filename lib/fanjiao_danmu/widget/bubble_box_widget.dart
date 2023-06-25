import 'package:flutter/material.dart';
import 'dart:math' as math;

class BubbleBox extends StatelessWidget {
  final double pointerBias;
  final double strokeWidth;
  final double radius;
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
  final Widget? child;

  const BubbleBox({
    Key? key,
    this.pointerBias = 0.5,
    this.opacity = 0.5,
    this.strokeWidth = 1.2,
    this.color = Colors.black,
    this.strokeColor = Colors.white,
    this.radius = 8,
    this.peakRadius = 3,
    this.pointerWidth = 10,
    this.pointerHeight = 6,
    this.startPadding = 0,
    this.endPadding = 0,
    this.isUpward = true,
    this.isWrapped = true,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleBoxPainter(
        pointerBias: pointerBias,
        strokeWidth: strokeWidth,
        radius: radius,
        opacity: opacity,
        peakRadius: peakRadius,
        pointerWidth: pointerWidth,
        pointerHeight: pointerHeight,
        startPadding: startPadding,
        endPadding: endPadding,
        color: color,
        strokeColor: strokeColor,
        isUpward: isUpward,
      ),
      child: Padding(
        padding: isWrapped
            ? EdgeInsets.only(top: pointerHeight) + EdgeInsets.all(radius)
            : EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

class _BubbleBoxPainter extends CustomPainter {
  final double strokeWidth;
  final double arc;
  double peakRadius;
  double pointerBias;
  Radius radius;
  double startPadding;
  double endPadding;
  double pointerWidth;
  double pointerHeight;
  Paint paintBorderPainter;
  Paint backgroundPainter;
  Paint painter;
  bool isUpward;

  _BubbleBoxPainter({
    this.pointerBias = 0.5,
    this.strokeWidth = 1.2,
    double opacity = 0.4,
    double radius = 8,
    this.peakRadius = 3,
    this.pointerWidth = 10,
    this.pointerHeight = 6,
    this.startPadding = 0,
    this.endPadding = 0,
    this.isUpward = true,
    Color color = Colors.black,
    Color strokeColor = Colors.white,
  })  : painter = Paint()..color = Colors.black.withOpacity(opacity),
        backgroundPainter = Paint()..color = color,
        arc = math.atan(pointerHeight / pointerWidth * 2),
        radius = Radius.circular(radius),
        paintBorderPainter = Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    pointerWidth = width < pointerWidth ? width : pointerWidth;
    pointerHeight = height < pointerHeight ? height : pointerHeight;
    if (pointerWidth < peakRadius) {
      peakRadius = pointerWidth;
    }
    final double halfArcWidth = math.sin(arc) * peakRadius;
    final double l = peakRadius / math.cos(arc);
    var pointerStartX = width * pointerBias - pointerWidth / 2;
    var pointerEndX = width * pointerBias + pointerWidth / 2;
    var minRadius = math.min(width - pointerWidth, height - pointerHeight) / 2;
    if (radius.x > minRadius) {
      radius = Radius.circular(minRadius);
    }
    startPadding = startPadding > radius.x ? startPadding : radius.x;
    endPadding = endPadding > radius.x ? endPadding : radius.x;
    if (pointerStartX < startPadding) {
      pointerStartX = startPadding;
      pointerEndX = startPadding + pointerWidth;
    } else if (pointerEndX > width - endPadding) {
      pointerStartX = width - endPadding - pointerWidth;
      pointerEndX = width - endPadding;
    }
    var arcY = math.tan(arc) * halfArcWidth;
    arcY = pointerHeight < arcY ? pointerHeight : arcY;
    final Path path = Path();
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
      path.lineTo(width - radius.x, pointerHeight);
      path.arcToPoint(Offset(width, pointerHeight + radius.y), radius: radius);
      path.lineTo(width, height - radius.y);
      path.arcToPoint(Offset(width - radius.x, height), radius: radius);
      path.lineTo(radius.x, height);
      path.arcToPoint(Offset(0, height - radius.y), radius: radius);
      path.lineTo(0, pointerHeight + radius.y);
      path.arcToPoint(Offset(radius.x, pointerHeight), radius: radius);
      path.close();
    } else {
      final bottom = height - pointerHeight;
      path.moveTo(pointerStartX, 0);
      path.lineTo(width - radius.x, 0);
      path.arcToPoint(Offset(width, radius.y), radius: radius);
      path.lineTo(width, bottom - radius.y);
      path.arcToPoint(Offset(width - radius.x, bottom), radius: radius);
      path.lineTo(pointerEndX, bottom);
      path.lineTo(pointerEndX - pointerWidth / 2 + halfArcWidth, height - arcY);
      // path.relativeConicTo(-halfArcWidth, arcY, -halfArcWidth * 2, 0, 1);
      path.arcTo(
          Rect.fromCircle(
              center: Offset(pointerEndX - pointerWidth / 2, height - l),
              radius: peakRadius),
          math.pi / 2 - arc,
          arc * 2,
          false);
      path.lineTo(pointerStartX, bottom);
      path.lineTo(radius.x, bottom);
      path.arcToPoint(Offset(0, bottom - radius.y), radius: radius);
      path.lineTo(0, radius.y);
      path.arcToPoint(Offset(radius.x, 0), radius: radius);
      path.close();
    }
    final innerPath = Path();
    innerPath.addPath(path, Offset.zero);
    canvas.saveLayer(path.getBounds().inflate(strokeWidth / 2), painter);
    canvas.drawPath(innerPath, backgroundPainter);
    canvas.drawPath(path, paintBorderPainter);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BubbleBoxPainter oldDelegate) {
    return oldDelegate.pointerBias != pointerBias ||
        oldDelegate.isUpward != isUpward;
  }
}

extension PathEx on Path {
  lineTo2(double x, double y) {
    print('lineTo($x, $y)');
    lineTo(x, y);
  }

  relativeArcToPoint2(
    Offset arcEndDelta, {
    Radius radius = Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    print('relativeArcToPoint(arcEndDelta: $arcEndDelta, radius: $radius)');
    relativeArcToPoint(
      arcEndDelta,
      radius: radius,
      rotation: rotation,
      largeArc: largeArc,
      clockwise: clockwise,
    );
  }
}
