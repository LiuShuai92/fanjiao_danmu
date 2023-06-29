import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'danmu_model.dart';
import 'simulation/danmu_simulation.dart';
import 'widget/middle_widget.dart';
import 'widget/stroke_text_widget.dart';

class DanmuItem<T extends DanmuModel> extends ContainerBoxParentData<RenderBox> {
  late T _model;
  late int flag;
  bool isSelected = false;
  bool _isPause = false;
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

  bool get isPause => _isPause;

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

  DanmuItem({
    required T model,
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

  void pause() {
    _isPause = true;
  }

  void play() {
    _isPause = false;
  }

  ValueKey valueKey([Object? value]) {
    return ValueKey("${model.id}$value");
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
              ),
            )
          : TextSpan(children: _model.spans, style: _model.textStyle);
      var placeholderDimensions = (layoutChildren ?? _defaultLayoutChildren)
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

  /// 暂时仅支持使用#[Size]、#[Image]、#[Container]、#[StrokeTextWidget]、#[Middle]作为child，
  /// 或者更改#[layoutChildren]参数。
  List<PlaceholderDimensions> _defaultLayoutChildren(
      List<PlaceholderSpan> placeholderSpans) {
    final placeholderDimensions =
        List<PlaceholderDimensions>.generate(placeholderSpans.length, (index) {
      var placeholderSpan = placeholderSpans[index];
      var childSize = Size.zero;
      if (placeholderSpan is WidgetSpan) {
        childSize = getWidgetSize(placeholderSpan.child);
      }
      return PlaceholderDimensions(
        size: childSize,
        alignment: placeholderSpan.alignment,
        baseline: placeholderSpan.baseline,
      );
    });
    return placeholderDimensions;
  }

  Size getWidgetSize(Widget widget) {
    Size childSize = Size.zero;
    switch (widget.runtimeType) {
      case Container:
        widget = (widget as Container);
        var marginSize = widget.margin?.collapsedSize;
        var constrainDimensions = widget.constraints
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
        widget = (widget as SizedBox);
        childSize = Size(widget.width ?? 0, widget.height ?? 0);
        break;
      case StrokeTextWidget:
        widget = (widget as StrokeTextWidget);
        childSize = widget.rect.size;
        break;
      case Image:
        widget = (widget as Image);
        childSize = Size(widget.width ?? 0, widget.height ?? 0);
        break;
      case Middle:
        widget = (widget as Middle);
        childSize = getWidgetSize(widget.child);
        break;
      default:
        throw UnsupportedTypesError(runtimeType);
    }
    return childSize;
  }


// 获取目标Widget相对于另一个Widget的位置
  Offset getWidgetOffset(BuildContext context, GlobalObjectKey targetKey) {
    // 获取目标Widget的RenderObject
    RenderBox targetBox = targetKey.currentContext!.findRenderObject() as RenderBox;

    // 获取目标Widget在全局坐标系中的位置
    Offset targetOffset = targetBox.localToGlobal(Offset.zero);

    // 获取当前Widget的RenderObject
    RenderBox thisBox = context.findRenderObject() as RenderBox;

    // 获取当前Widget在全局坐标系中的位置
    Offset thisOffset = thisBox.localToGlobal(Offset.zero);

    // 计算目标Widget相对于当前Widget的偏移量
    Offset offset = targetOffset - thisOffset;

    return offset;
  }
}

class UnsupportedTypesError<T> extends Error implements TypeError {
  final Type _type;

  UnsupportedTypesError(this._type);

  @override
  String toString() =>
      "默认layoutChildren方法暂时不支持$_type类型的尺寸获取，支持使用Size、Image、Container或StrokeTextWidget，或者更改layoutChildren参数。";
}
