import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../fanjiao_danmu.dart';
import '../simulation/clamp_simulation.dart';

class FanjiaoDanmuAdapter<T extends DanmuModel> extends DanmuAdapter<T> {
  final math.Random _random = math.Random();
  // final EdgeInsets padding;
  final List<Queue<DanmuItem<T>>> scrollRows = [];
  final List<DanmuItem<T>?> centerRows = [];
  final Map<String, ImageProvider> imageMap;
  final double rowHeight;
  int? _maxLines;

  int? get maxLines => _maxLines;

  int get _randomScrollLine => _random.nextInt(scrollRows.length - 1);

  double _getPaddingTop(int lineIndex, double itemHeight) =>
      lineIndex * rowHeight + (rowHeight - itemHeight) / 2;

  FanjiaoDanmuAdapter({
    this.rowHeight = 30,
    this.imageMap = const <String, ImageProvider>{},
    double preExtra = 4,
    double iconExtra = 30,
  }) : super(preExtra: preExtra, iconExtra: iconExtra);

  @override
  initData(Rect rect, {int? maxLines}) {
    super.initData(rect);
    scrollRows.clear();
    centerRows.clear();
    var lines = rect.height ~/ rowHeight;
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
    return (item?.isValid ?? false) ? item : null;
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
    for (int i = 0; i < centerRows.length; i++) {
      var centerRow = centerRows[i];
      if (centerRow == null) {
        item = transformText(model);
        double paddingTop = _getPaddingTop(i, item.size.height);
        Offset offset =
            Offset(rect.center.dx - item.size.width / 2, paddingTop);
        item.simulation = ClampSimulation(clampOffset: offset);
        centerRows[i] = item;
        break;
      }
    }
    return item;
  }

  DanmuItem<T>? _getBottomCenterItem(T model) {
    assert(_maxLines != null, "需要先调用 initData()");
    DanmuItem<T>? item;
    for (int i = centerRows.length - 1; i >= 0; i--) {
      var centerRow = centerRows[i];
      if (centerRow == null) {
        item = transformText(model);
        double paddingTop = _getPaddingTop(i, item.size.height);
        Offset offset =
            Offset(rect.center.dx - item.size.width / 2, paddingTop);
        item.simulation = ClampSimulation(clampOffset: offset);
        centerRows[i] = item;
        break;
      }
    }
    return item;
  }

  DanmuItem<T>? _getScrollItem(T model) {
    assert(_maxLines != null, "需要先调用 initData()");
    DanmuItem<T> item = transformText(model);
    var size = item.size;
    int? tempIndex;
    int min = math.min(scrollRows.length ~/ 2, 3);
    HorizontalScrollSimulation? simulation;
    for (int i = 0; i < scrollRows.length; i++) {
      Queue<DanmuItem<T>> row = scrollRows[i];
      simulation =
          HorizontalScrollSimulation(right: rect.width, left: 0, size: size);
      if (row.isEmpty || (row.length == 1 && row.last.isSelected)) {
        simulation.paddingTop = _getPaddingTop(i, size.height);
        item.simulation = simulation;
        row.add(item);
        break;
      } else {
        var rx = simulation
            .offset(
                (model.insertTime - model.startTime).inMicrosecondsPerSecond)
            .dx;
        if (model.isPraise) {
          rx -= iconExtra;
        }
        DanmuItem<T> last;
        bool isEmpty = false;
        last = row.lastWhere(
            (element) => !element.isSelected && !element.flag.isCollisionFree,
            orElse: () {
          simulation!.paddingTop = _getPaddingTop(i, size.height);
          isEmpty = true;
          item.simulation = simulation;
          return item;
        });
        if (isEmpty) {
          row.add(last);
          break;
        }
        var lx = last.simulation
                .offset((model.insertTime - last.model.startTime)
                    .inMicrosecondsPerSecond)
                .dx +
            last.size.width;
        if (rx - lx > preExtra) {
          var endTime =
              (last.endTime - model.startTime).inMicrosecondsPerSecond;
          var dx = simulation.offset(endTime).dx;
          if (model.isPraise) {
            dx -= iconExtra;
          }

          ///如果弹幕放到当前行，则在当前行上一条弹幕消失时，当前添加的弹幕所在位置是否没有超过了中线
          if (dx > rect.center.dx && i <= min) {
            simulation.paddingTop = _getPaddingTop(i, size.height);
            item.simulation = simulation;
            row.add(item);
            break;
          } else if (tempIndex == null && dx > rect.left) {
            tempIndex = i;
          } else if (i > min && tempIndex != null) {
            break;
          }
        }
      }
    }
    if (!item.isValid && simulation != null && tempIndex != null) {
      simulation.paddingTop = _getPaddingTop(tempIndex, size.height);
      item.simulation = simulation;
      scrollRows[tempIndex].add(item);
    }
    if (!item.isValid && model.flag.isCollisionFree) {
      HorizontalScrollSimulation simulation =
          HorizontalScrollSimulation(right: rect.width, left: 0, size: size);
      var index = _randomScrollLine;
      item.simulation = simulation;
      scrollRows[index].add(item);
      simulation.paddingTop = _getPaddingTop(index, size.height);
    }
    return item;
  }

  DanmuItem<T> transformText(T model) {
    if (imageMap.containsKey(model.text)) {
      return DanmuItem(
        model: model,
        imageAsset: imageMap[model.text],
      );
    }
    return DanmuItem(
      model: model,
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
