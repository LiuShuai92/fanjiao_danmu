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
    _pointerBias = (position.dx.clamp(
                math.max(danmuRect.left, stageRect.left) + danmuRect.height / 2,
                math.min(danmuRect.right, stageRect.right) -
                    danmuRect.height / 2) -
            _menuRect.left) /
        _menuRect.width;
    return true;
  }

  Positioned? tooltip<T extends DanmuModel>(DanmuItem<T>? selectedItem) {
    if (selectedItem == null) {
      return null;
    }
    return Positioned(
      left: _menuRect.left,
      top: _menuRect.top,
      child: SizedBox(
        height: _menuRect.height,
        width: _menuRect.width,
        child: BubbleBox(
          isUpward: isUpward,
          pointerBias: pointerBias,
          strokeWidth: 1.2,
          radius: 8,
          pointerWidth: 10,
          pointerHeight: 6,
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
