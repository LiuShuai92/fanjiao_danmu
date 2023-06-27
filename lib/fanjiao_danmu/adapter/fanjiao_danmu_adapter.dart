import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../fanjiao_danmu.dart';
import '../simulation/clamp_simulation.dart';

class FanjiaoDanmuAdapter<T extends DanmuModel> extends DanmuAdapter<T> {
  final math.Random _random = math.Random();

  /// 只是为了方便找出item所在行数
  final List<List<DanmuItem<T>>> scrollRows = [];
  final List<DanmuItem<T>?> centerRows = [];
  final Map<String, ImageProvider> imageMap;
  final double rowHeight;
  bool _isInit = false;
  int? _maxLines;

  int? get maxLines => _maxLines;

  int get _randomRowIndex => _random.nextInt(scrollRows.length - 1);

  double _getY(int lineIndex) => lineIndex * rowHeight;

  FanjiaoDanmuAdapter({
    this.rowHeight = 30,
    this.imageMap = const <String, ImageProvider>{},
  }) : super();

  @override
  initData(Rect rect, {int? maxLines}) {
    super.initData(rect);
    _isInit = true;
    scrollRows.clear();
    centerRows.clear();
    var lines = rect.height ~/ rowHeight;
    _maxLines = math.min(maxLines ?? lines, lines);
    for (int i = 0; i < _maxLines!; i++) {
      scrollRows.add(<DanmuItem<T>>[]);
      centerRows.add(null);
    }
  }

  @override
  clear([int filter = DanmuFlag.all]) {
    for (var scrollRow in scrollRows) {
      scrollRow.removeWhere((element) => filter.pick(element.flag));
    }
    for (int i = 0; i < centerRows.length; i++) {
      centerRows.removeWhere(
          (element) => element == null ? true : filter.pick(element.flag));
    }
  }

  @override
  DanmuItem<T>? getItem(T model) {
    DanmuItem<T>? item;
    if (model.flag.isScroll) {
      item = _getScrollItem(model);
    } else if (model.flag.isSpecify) {
      item = _getSpecifyClampItem(model);
    } else if (model.flag.isTop) {
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
    if (item.flag.isSpecify) {
      return;
    }
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

  DanmuItem<T>? _getSpecifyClampItem(T model) {
    assert(_isInit, "需要先调用 initData()");
    DanmuItem<T>? item = transformText(model);
    Offset offset =
        Offset(rect.center.dx - item.size.width / 2, model.specifyY ?? 0);
    item.simulation = ClampSimulation(clampOffset: offset);
    return item;
  }

  DanmuItem<T>? _getTopCenterItem(T model) {
    assert(_isInit, "需要先调用 initData()");
    DanmuItem<T>? item;
    for (int i = 0; i < centerRows.length; i++) {
      var centerRow = centerRows[i];
      if (centerRow == null) {
        item = transformText(model);
        double y = _getY(i);
        Offset offset = Offset(rect.center.dx - item.size.width / 2, y);
        item.simulation = ClampSimulation(clampOffset: offset);
        centerRows[i] = item;
        break;
      }
    }
    return item;
  }

  DanmuItem<T>? _getBottomCenterItem(T model) {
    assert(_isInit, "需要先调用 initData()");
    DanmuItem<T>? item;
    for (int i = centerRows.length - 1; i >= 0; i--) {
      var centerRow = centerRows[i];
      if (centerRow == null) {
        item = transformText(model);
        double y = _getY(i);
        Offset offset = Offset(rect.center.dx - item.size.width / 2, y);
        item.simulation = ClampSimulation(clampOffset: offset);
        centerRows[i] = item;
        break;
      }
    }
    return item;
  }

  DanmuItem<T>? _getScrollItem(T model) {
    assert(_isInit, "需要先调用 initData()");
    DanmuItem<T> item = transformText(model);
    var marginSize = model.margin.collapsedSize;
    var size = item.size + Offset(marginSize.width, marginSize.height);
    var flag = item.flag;
    if (flag.isSpecify) {
      HorizontalScrollSimulation simulation =
          HorizontalScrollSimulation(right: rect.width, left: 0, size: size);
      item.simulation = simulation;
      simulation.y = model.specifyY ?? 0;
      return item;
    } else if (flag.isCollisionFree) {
      HorizontalScrollSimulation simulation =
          HorizontalScrollSimulation(right: rect.width, left: 0, size: size);
      var index = _randomRowIndex;
      item.simulation = simulation;
      scrollRows[index].add(item);
      simulation.y = _getY(index);
      return item;
    }
    int? tempIndex;
    int min = math.min(scrollRows.length ~/ 2, 3);
    HorizontalScrollSimulation? simulation;
    for (int i = 0; i < scrollRows.length; i++) {
      List<DanmuItem<T>> row = scrollRows[i];
      simulation =
          HorizontalScrollSimulation(right: rect.width, left: 0, size: size);
      if (row.isEmpty || (row.length == 1 && row.last.isPause)) {
        simulation.y = _getY(i);
        item.simulation = simulation;
        row.add(item);
        break;
      } else {
        DanmuItem<T>? last;
        try {
          last = row.lastWhere(
              (element) => !element.isPause && !element.flag.isCollisionFree);
        } catch (e) {
          last = null;
        }
        if (last != null) {
          var lx = last.simulation
                  .offset((model.insertTime - last.model.startTime)
                      .inMicrosecondsPerSecond)
                  .dx +
              last.size.width;
          var rx = simulation
              .offset(
                  (model.insertTime - model.startTime).inMicrosecondsPerSecond)
              .dx;
          if (rx > lx) {
            var endTime =
                (last.endTime - model.startTime).inMicrosecondsPerSecond;
            var dx = simulation.offset(endTime).dx;

            ///如果弹幕放到当前行，则在当前行上一条弹幕消失时，当前添加的弹幕所在位置是否没有超过了中线
            if (dx > rect.center.dx && i <= min) {
              simulation.y = _getY(i);
              item.simulation = simulation;
              row.add(item);
              break;
            } else if (tempIndex == null && dx > rect.left) {
              tempIndex = i;
            } else if (i > min && tempIndex != null) {
              break;
            }
          }
        } else {
          simulation.y = _getY(i);
          item.simulation = simulation;
          row.add(item);
        }
      }
    }
    if (!item.isValid && simulation != null && tempIndex != null) {
      simulation.y = _getY(tempIndex);
      item.simulation = simulation;
      scrollRows[tempIndex].add(item);
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

extension ExtensionList<T> on List<T?> {
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
