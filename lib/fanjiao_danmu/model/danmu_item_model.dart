import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../danmu_controller.dart';
import '../simulation/danmu_simulation.dart';
import '../widget/stroke_text_widget.dart';

class DanmuItem<T extends DanmuModel> {
  late T _model;
  late int flag;
  bool isSelected;
  Duration? dTime;
  Offset? position;
  final ImageProvider? imageAsset;
  late ImageConfiguration configuration;
  late Size size;
  TextPainter? textPainter;
  TextPainter? textStrokePainter;
  InlineSpan? span;
  InlineSpan? textStrokeSpan;
  DanmuSimulation? _simulation;

  T get model => _model;
  late bool _isImage;

  bool get isImage => _isImage;

  bool get isTextSpan => span is TextSpan;

  Rect get rect =>
      position == null ? Rect.zero : (position! + model.margin.topLeft & size);

  Rect get imageRect => position == null
      ? Rect.zero
      : position! & size + model.margin.bottomRight;

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

  bool get isValid => _simulation != null;

  DanmuSimulation get simulation {
    assert(isValid);
    return _simulation!;
  }

  set simulation(DanmuSimulation simulation) {
    _simulation = simulation;
  }

  DanmuItem({
    required T model,
    this.isSelected = false,
    int? flag,
    this.imageAsset,
    Size imageSize = const Size(52, 20),
    double textScaleFactor = 1,
    Function(List<PlaceholderSpan>)? layoutChildren,
  }) {
    updateModel(
      model,
      flag: flag ?? model.flag,
      imageSize: imageSize,
      textScaleFactor: textScaleFactor,
      layoutChildren: layoutChildren,
    );
  }

  void updateModel(
    model, {
    int? flag,
    ui.Size imageSize = const Size(52, 20),
    double textScaleFactor = 1,
    Function(List<PlaceholderSpan>)? layoutChildren,
  }) {
    _model = model;
    if (flag != null) {
      this.flag = flag;
    }
    _isImage = imageAsset != null;
    var padding = _model.padding;
    if (isImage) {
      size = imageSize + Offset(padding.horizontal, padding.vertical);
    } else {
      span = _model.spans.isEmpty
          ? WidgetSpan(
              child: StrokeTextWidget(
              _model.text,
              textStyle: _model.textStyle,
              opacity: _model.opacity,
              textScaleFactor: textScaleFactor,
              strokeWidth: _model.strokeWidth,
            ))
          : TextSpan(children: _model.spans, style: _model.textStyle);
      var placeholderDimensions = (layoutChildren ?? _layoutChildren)
          .call(_extractPlaceholderSpans(span!));
      textPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = span
        ..setPlaceholderDimensions(placeholderDimensions)
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
        textStrokeSpan = _model.spans.isEmpty
            ? TextSpan(text: _model.text, style: textStrokeSpanStyle)
            : TextSpan(children: _model.spans, style: textStrokeSpanStyle);

        textStrokePainter = TextPainter(textDirection: TextDirection.ltr)
          ..text = textStrokeSpan
          ..setPlaceholderDimensions(placeholderDimensions)
          ..textScaleFactor = textScaleFactor;
        textStrokePainter!.layout();
      }
      final double width = textPainter!.width + padding.horizontal;
      final double height = textPainter!.height + padding.vertical;
      size = Size(width, height);
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
          case Image:
            var child = (placeholderSpan.child as Image);
            childSize = Size(child.width ?? 0, child.height ?? 0);
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
  final bool isClickable;
  final bool isRepeatable;
  final int flag;
  final TextStyle textStyle;
  final Duration insertTime;
  final Duration startTime;
  final ImageProvider? imageProvider;
  final String? package;
  final BoxDecoration? decoration;
  final BoxDecoration? foregroundDecoration;
  final AlignmentGeometry? alignment;
  final Size imageSize;
  final double strokeWidth;
  final double opacity;
  final EdgeInsets padding;
  final EdgeInsets margin;

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
    this.isClickable = true,
    this.imageProvider,
    this.package,
    this.isRepeatable = false,
    this.opacity = 1,
    this.padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    this.margin = const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    this.strokeWidth = 1,
    this.imageSize = const Size(52, 20),
    this.flag = DanmuFlag.scroll | DanmuFlag.clickable,
    this.decoration,
    this.foregroundDecoration,
    this.alignment,
    Duration? insertTime,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
  })  : assert(textStyle != null),
        insertTime = insertTime ?? startTime;

  DanmuModel copyWith({
    int? id,
    String? text,
    Duration? startTime,
    List<InlineSpan>? spans,
    bool? isClickable,
    ImageProvider? imageProvider,
    String? package,
    bool? isRepeatable,
    double? opacity,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? strokeWidth,
    Size? imageSize,
    int? flag,
    BoxDecoration? decoration,
    BoxDecoration? foregroundDecoration,
    AlignmentGeometry? alignment,
    Duration? insertTime,
    TextStyle? textStyle,
  }) {
    return DanmuModel(
      id: id ?? this.id,
      text: text ?? this.text,
      startTime: startTime ?? this.startTime,
      spans: spans ?? this.spans,
      isClickable: isClickable ?? this.isClickable,
      imageProvider: imageProvider ?? this.imageProvider,
      package: package ?? this.package,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      opacity: opacity ?? this.opacity,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      imageSize: imageSize ?? this.imageSize,
      flag: flag ?? this.flag,
      decoration: decoration ?? this.decoration,
      foregroundDecoration: foregroundDecoration ?? this.foregroundDecoration,
      alignment: alignment ?? this.alignment,
      insertTime: insertTime ?? this.insertTime,
      textStyle: textStyle ?? this.textStyle,
    );
  }
}
