import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../fanjiao_danmu.dart';
import '../model/danmu_item_model.dart';
import '../simulation/clamp_simulation.dart';
import 'danmu_adapter.dart';

class FanjiaoDanmuAdapter<T extends DanmuModel> extends DanmuAdapter<T> {
  final Size imageSize;
  final EdgeInsets padding;
  final List<Queue<DanmuItem<T>>> scrollRows = [];
  final List<DanmuItem<T>?> centerRows = [];
  final Map<String, ImageProvider> imageMap;
  final double lineHeight;
  int? _maxLines;

  int? get maxLines => _maxLines;

  double _getPaddingTop(int lineIndex, double textHeight) =>
      lineIndex * lineHeight + (lineHeight - textHeight) / 2;

  FanjiaoDanmuAdapter({
    this.lineHeight = 30,
    this.padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    this.imageSize = const Size(52, 20),
    this.imageMap = const <String, ImageProvider>{},
    double preExtra = 4,
    double iconExtra = 30,
  }) : super(preExtra: preExtra, iconExtra: iconExtra);

  @override
  initData(Rect rect, {int? maxLines}) {
    super.initData(rect);
    scrollRows.clear();
    centerRows.clear();
    var lines = rect.height ~/ lineHeight;
    _maxLines = math.min(maxLines ?? lines, lines);
    for (int i = 0; i < _maxLines!; i++) {
      scrollRows.add(Queue<DanmuItem<T>>());
      centerRows.add(null);
    }
  }

  @override
  clear() {
    for (var element in scrollRows) {
      element.clear();
    }
    for (int i = 0; i < centerRows.length; i++) {
      centerRows[i] = null;
    }
  }

  @override
  DanmuItem<T>? getItem(T model) {
    DanmuItem<T>? item;
    if (model.flag.isTop) {
      item = _getTopCenterItem(model);
    } else if (model.flag.isBottom) {
      item = _getBottomCenterItem(model);
    } else if (model.flag.isAdvanced) {
      ///todo
    } else {
      item = _getScrollItem(model);
    }
    return item;
  }

  @override
  removeItem(DanmuItem<T> item) {
    if (item.flag.isScroll) {
      for (var row in scrollRows) {
        if (row.remove(item)) {
          break;
        }
      }
    } else if (item.flag.isTop || item.flag.isBottom) {
      centerRows.replace(item, null);
    }
  }

  addImageMap(Map<String, ImageProvider> imageMap) {
    imageMap.addAll(imageMap);
  }

  clearImageMap(Map<String, ImageProvider> imageMap) {
    imageMap.clear();
  }

  DanmuItem<T>? _getTopCenterItem(T model) {
    assert(_maxLines != null, "需要先调用 initData()");
    DanmuItem<T>? item;
    final SpanInfo textSpanInfo =
        transformText(model.text, model.textStyle, imageMap: imageMap);
    Size size = _spanSize(textSpanInfo, padding);
    for (int i = 0; i < centerRows.length; i++) {
      var centerRow = centerRows[i];
      if (centerRow == null) {
        double paddingTop = _getPaddingTop(i, size.height);
        Offset offset = Offset(rect.center.dx - size.width / 2, paddingTop);
        item = DanmuItem(
            model: model,
            padding: padding,
            simulation: ClampSimulation(clampOffset: offset),
            spanInfo: textSpanInfo,
            size: size);
        centerRows[i] = item;
        break;
      }
    }
    return item;
  }

  DanmuItem<T>? _getBottomCenterItem(T model) {
    assert(_maxLines != null, "需要先调用 initData()");
    DanmuItem<T>? item;
    final SpanInfo textSpanInfo =
        transformText(model.text, model.textStyle, imageMap: imageMap);
    Size size = _spanSize(textSpanInfo, padding);
    for (int i = centerRows.length - 1; i >= 0; i--) {
      var centerRow = centerRows[i];
      if (centerRow == null) {
        double paddingTop = _getPaddingTop(i, size.height);
        Offset offset = Offset(rect.center.dx - size.width / 2, paddingTop);
        item = DanmuItem(
            model: model,
            padding: padding,
            simulation: ClampSimulation(clampOffset: offset),
            spanInfo: textSpanInfo,
            size: size);
        centerRows[i] = item;
        break;
      }
    }
    return item;
  }

  DanmuItem<T>? _getScrollItem(T model) {
    assert(_maxLines != null, "需要先调用 initData()");

    ///第一次循环只判断前一半的行数或前三行
    DanmuItem<T>? item;
    final SpanInfo textSpanInfo =
        transformText(model.text, model.textStyle, imageMap: imageMap);
    Size size = _spanSize(textSpanInfo, padding);
    for (int i = 0; i < math.min(scrollRows.length / 2, 3); i++) {
      Queue<DanmuItem<T>> row = scrollRows[i];
      HorizontalScrollSimulation simulation =
          HorizontalScrollSimulation(start: rect.width, end: -size.width);
      if (row.isEmpty || row.last.isSelected) {
        simulation.paddingTop = _getPaddingTop(i, size.height);
        item = DanmuItem(
            model: model,
            padding: padding,
            simulation: simulation,
            spanInfo: textSpanInfo,
            size: size);
        row.add(item);
        break;
      } else {
        var rx = simulation.offset(model.insertTime - model.startTime).dx;
        if (model.isPraise) {
          rx -= iconExtra;
        }
        var last = row.lastWhere((element) => !element.isSelected);
        var lx = last.simulation.offset(model.insertTime - last.startTime).dx +
            last.size.width;
        if (rx - lx > preExtra) {
          var lx = simulation.offset(last.endTime - model.startTime).dx;
          if (model.isPraise) {
            lx -= iconExtra;
          }
          if (lx > rect.center.dx) {
            ///如果弹幕放到当前行，则在当前行上一条弹幕消失时，当前添加的弹幕所在位置是否没有超过了中线
            simulation.paddingTop = _getPaddingTop(i, size.height);
            item = DanmuItem(
                model: model,
                padding: padding,
                simulation: simulation,
                spanInfo: textSpanInfo,
                size: size);
            row.add(item);
            break;
          }
        }
      }
    }

    ///如果第一次循环没有找到合适位置，就进行第二次循环
    if (item == null) {
      for (int i = 0; i < scrollRows.length; i++) {
        Queue<DanmuItem<T>> row = scrollRows[i];
        HorizontalScrollSimulation simulation =
            HorizontalScrollSimulation(start: rect.width, end: -size.width);
        if (row.isEmpty || row.last.isSelected) {
          simulation.paddingTop = _getPaddingTop(i, size.height);
          item = DanmuItem(
              model: model,
              padding: padding,
              simulation: simulation,
              spanInfo: textSpanInfo,
              size: size);
          row.add(item);
          break;
        } else {
          var rx = simulation.offset(model.insertTime - model.startTime).dx;
          if (model.isPraise) {
            rx -= iconExtra;
          }
          var last = row.lastWhere((element) => !element.isSelected);
          var lx =
              last.simulation.offset(model.insertTime - last.startTime).dx +
                  last.rect.width;
          if (rx - lx > preExtra) {
            var dx = simulation.offset(last.endTime - model.startTime).dx;
            if (model.isPraise) {
              dx -= iconExtra;
            }
            if (dx > rect.left) {
              ///如果弹幕放到当前行，则在当前行上一条弹幕消失时，当前添加的弹幕所在位置是否没有超过左边界
              simulation.paddingTop = _getPaddingTop(i, size.height);
              item = DanmuItem(
                  model: model,
                  padding: padding,
                  simulation: simulation,
                  spanInfo: textSpanInfo,
                  size: size);
              row.add(item);
              break;
            }
          }
        }
      }
    }
    if (item == null && model.isMine) {
      HorizontalScrollSimulation simulation =
          HorizontalScrollSimulation(start: rect.width, end: -size.width);
      item = DanmuItem(
          model: model,
          padding: padding,
          simulation: simulation,
          spanInfo: textSpanInfo,
          size: size);
      var index = scrollRows.length >> 1;
      scrollRows[index].add(item);
      simulation.paddingTop = _getPaddingTop(index, size.height);
    }
    return item;
  }

  final TextPainter _textPainter =
      TextPainter(textDirection: TextDirection.ltr);

  Size _spanSize(SpanInfo spanInfo, EdgeInsets padding) {
    if (spanInfo.isTextSpan) {
      _textPainter.text = spanInfo.span;
      _textPainter.layout();
      final double width = _textPainter.width + padding.horizontal;
      final double height = _textPainter.height + padding.vertical;
      return Size(width, height);
    } else {
      return imageSize + Offset(padding.horizontal, padding.vertical);
    }
  }

  SpanInfo transformText(String text, TextStyle textStyle,
      {Map<String, ImageProvider>? imageMap}) {
    if (imageMap != null && imageMap.containsKey(text)) {
      return SpanInfo(
        text,
        iconAsset: imageMap[text],
      );
    }
    return SpanInfo(
      text,
      span: TextSpan(text: text, style: textStyle),
      textStrokeSpan: TextSpan(
        text: text,
        style: textStyle.copyWith(
            fontWeight: FontWeight.values[math.min(
                textStyle.fontWeight?.index ?? 0 + 1,
                FontWeight.values.length - 1)],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = Colors.black),
      ),
    );
  }
}

extension ReplaceList<T> on List<T?> {
  bool replace(T? o, T? s) {
    for (int i = 0; i < length; i++) {
      var t = this[i];
      if (t == o) {
        this[i] = s;
        return true;
      }
    }
    return false;
  }
}
