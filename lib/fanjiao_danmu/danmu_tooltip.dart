import 'dart:math' as math;

import 'package:fanjiao_danmu/fanjiao_danmu/widget/bubble_box_widget.dart';
import 'package:flutter/widgets.dart';

import 'fanjiao_danmu.dart';

mixin FanjiaoDanmuTooltipMixin {
  Rect _menuRect = Rect.zero;

  double? _pointerBias;

  double get pointerBias => _pointerBias ?? 0;

  bool? _isUpward;

  bool get isUpward => _isUpward ?? true;

  Size get menuSize => const Size(160, 36);

  Widget get tooltipContent;

  bool checkSelect(Offset position, Rect danmuRect, Rect stageRect) {
    double x, y;
    if (danmuRect.left > stageRect.right - danmuRect.height ||
        danmuRect.right < stageRect.left + danmuRect.height) {
      return false;
    }
    x = (position.dx - menuSize.width / 2)
        .clamp(0, stageRect.right - menuSize.width);
    _isUpward = danmuRect.bottom < stageRect.bottom - menuSize.height;
    if (isUpward) {
      y = danmuRect.bottom;
    } else {
      y = danmuRect.top - menuSize.height;
    }
    Offset offset = Offset(x, y);
    _menuRect = offset & menuSize;
    var lowerLimit = math.max(danmuRect.left, stageRect.left) + 4;
    var upperLimit = math.min(danmuRect.right, stageRect.right) - 4;
    if (lowerLimit > upperLimit) {
      _pointerBias =
          ((lowerLimit + upperLimit) / 2 - _menuRect.left) / _menuRect.width;
    } else {
      _pointerBias =
          (position.dx.clamp(lowerLimit, upperLimit) - _menuRect.left) /
              _menuRect.width;
    }
    return true;
  }

  Positioned? tooltip<T extends DanmuModel>(DanmuItem<T>? selectedItem) {
    if (selectedItem == null) {
      return null;
    }
    return Positioned(
      key: selectedItem.valueKey("tooltip"),
      left: _menuRect.left + (isUpward ? 0 : 4),
      top: _menuRect.top + (isUpward ? 4 : 0),
      child: SizedBox(
        height: _menuRect.height,
        width: _menuRect.width,
        child: BubbleBox(
          isUpward: isUpward,
          pointerBias: pointerBias,
          strokeWidth: 1.2,
          borderRadius: 6,
          pointerWidth: 10,
          pointerHeight: 4,
          peakRadius: 3,
          isWrapped: false,
          child: Padding(
            padding: EdgeInsets.only(
              top: isUpward ? 6 : 0,
              bottom: isUpward ? 0 : 6,
            ),
            child: tooltipContent,
          ),
        ),
      ),
    );
  }
}
