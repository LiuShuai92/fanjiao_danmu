import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../danmu_controller.dart';
import '../simulation/danmu_simulation.dart';
import '../widget/stroke_text_widget.dart';

class DanmuItem<T extends DanmuModel> {
  final T model;
  final ImageProvider? imageAsset;
  final bool _isImage;

  bool get isImage => _isImage;
  late final ImageConfiguration configuration;
  late Size size;
  TextPainter? textPainter;
  TextPainter? textStrokePainter;
  InlineSpan? span;
  InlineSpan? textStrokeSpan;

  bool get isTextSpan => span is TextSpan;

  ///[DanmuFlag] 可能会发生改变 比如[DanmuFlag.repeated]是否是重复内容
  Rect get rect =>
      position == null ? Rect.zero : position! - model.padding.topLeft & size;

  Rect get imageRect => position == null
      ? Rect.zero
      : position! &
          size + model.padding.bottomRight + model.padding.bottomRight;

  Duration get endTime {
    assert(isValid);
    return model.startTime +
        Duration(
            microseconds:
                (_simulation!.duration * Duration.microsecondsPerSecond)
                    .toInt());
  }

  Offset get startPosition {
    assert(isValid);
    return _simulation!.offset(0);
  }

  Offset get endPosition {
    assert(isValid);
    return _simulation!.offset(_simulation!.duration);
  }

  int flag;
  bool isSelected;
  Duration? dTime;
  Offset? position;
  DanmuSimulation? _simulation;

  bool get isValid => _simulation != null;

  DanmuSimulation get simulation {
    assert(isValid);
    return _simulation!;
  }

  set simulation(DanmuSimulation simulation) {
    _simulation = simulation;
  }

  DanmuItem({
    required this.model,
    this.isSelected = false,
    int? flag,
    this.imageAsset,
    Size imageSize = const Size(52, 20),
    double textScaleFactor = 1,
  })  : flag = flag ?? model.flag,
        _isImage = imageAsset != null {
    ///由于绘制时大量layout比较耗时，所以提前用空间换时间
    var padding = model.padding;
    if (isImage) {
      size = imageSize + Offset(padding.horizontal, padding.vertical);
    } else {
      span = model.spans.isEmpty
          ? WidgetSpan(
              child: StrokeTextWidget(
              model.text,
              textStyle: model.textStyle,
              opacity: model.opacity,
              textScaleFactor: textScaleFactor,
              strokeWidth: model.strokeWidth,
            ))
          : TextSpan(children: model.spans, style: model.textStyle);
      textPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = span
        ..setPlaceholderDimensions(
            _layoutChildren(_extractPlaceholderSpans(span!)))
        ..textScaleFactor = textScaleFactor;
      textPainter!.layout();

      var textStyle = span!.style;
      if (textStyle != null) {
        var textStrokeSpanStyle = textStyle.copyWith(
            fontWeight: FontWeight.values[math.min(
                textStyle.fontWeight?.index ?? 0 + 1,
                FontWeight.values.length - 1)],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = Colors.black);
        textStrokeSpan = model.spans.isEmpty
            ? TextSpan(text: model.text, style: textStrokeSpanStyle)
            : TextSpan(children: model.spans, style: textStrokeSpanStyle);

        textStrokePainter = TextPainter(textDirection: TextDirection.ltr)
          ..text = textStrokeSpan
          ..setPlaceholderDimensions(
              _layoutChildren(_extractPlaceholderSpans(textStrokeSpan!)))
          ..textScaleFactor = textScaleFactor;
        textStrokePainter!.layout();
      }
      final double width = textPainter!.width + padding.horizontal;
      final double height = textPainter!.height + padding.vertical;
      size = Size(width, height) + Offset(padding.horizontal, padding.vertical);
    }

    configuration = ImageConfiguration(size: size);
  }

  List<PlaceholderSpan> _extractPlaceholderSpans(InlineSpan span) {
    var placeholderSpans = <PlaceholderSpan>[];
    span.visitChildren((InlineSpan span) {
      if (span is PlaceholderSpan) {
        placeholderSpans.add(span);
      }
      return true;
    });
    return placeholderSpans;
  }

  List<PlaceholderDimensions> _layoutChildren(
      List<PlaceholderSpan> placeholderSpans) {
    final placeholderDimensions =
        List<PlaceholderDimensions>.generate(placeholderSpans.length, (index) {
      var placeholderSpan = placeholderSpans[index];
      var childSize = Size.zero;
      if (placeholderSpan is WidgetSpan) {
        switch (placeholderSpan.child.runtimeType) {
          case Container:
            var child = (placeholderSpan.child as Container);
            var marginSize = child.margin?.collapsedSize;
            var constrainDimensions = child.constraints
                ?.constrainDimensions(double.infinity, double.infinity);
            if (constrainDimensions != null) {
              childSize =
                  Size(constrainDimensions.width, constrainDimensions.height);
            }
            if (marginSize != null) {
              childSize += marginSize.bottomRight(Offset.zero);
            }
            break;
          case SizedBox:
            var child = (placeholderSpan.child as SizedBox);
            childSize = Size(child.width ?? 0, child.height ?? 0);
            break;
          case StrokeTextWidget:
            var child = (placeholderSpan.child as StrokeTextWidget);
            childSize = child.rect.size;
            break;
          default:
            break;
        }
      }
      return PlaceholderDimensions(
        size: childSize,
        alignment: placeholderSpan.alignment,
        baseline: placeholderSpan.baseline,
      );
    });
    return placeholderDimensions;
  }
}

class DanmuModel {
  final int id;
  final List<InlineSpan> spans;
  final String text;
  final bool isMine;

  ///[DanmuFlag] 一个弹幕创建时确定，不会发生改变
  final int flag;
  final TextStyle textStyle;
  final Duration insertTime;
  final Duration startTime;
  final bool isPraise;
  final ImageProvider? imageProvider;
  final String? package;
  final BoxDecoration? decoration;
  final Size imageSize;
  final double strokeWidth;
  final double opacity;
  final EdgeInsets padding;

  String get plainText {
    String plainText = "";
    for (var span in spans) {
      plainText += span.toPlainText(
          includeSemanticsLabels: false, includePlaceholders: false);
    }
    return plainText;
  }

  DanmuModel({
    required this.id,
    required this.text,
    required this.startTime,
    this.spans = const [],
    this.isMine = false,
    this.imageProvider,
    this.isPraise = false,
    this.package,
    this.opacity = 1,
    this.padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    this.strokeWidth = 1,
    this.imageSize = const Size(52, 20),
    this.flag = DanmuFlag.scroll,
    Duration? insertTime,
    Map<String, ImageProvider>? imageMap,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
    BoxDecoration? decoration,
  })  : assert(textStyle != null),
        insertTime = insertTime ?? startTime,
        decoration = decoration ??
            (isMine
                ? const BoxDecoration(
                    color: Color(0xCCFF9C6B),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    border: Border.fromBorderSide(BorderSide(
                        color: Colors.white,
                        width: 1,
                        style: BorderStyle.solid)),
                  )
                : null);
}
