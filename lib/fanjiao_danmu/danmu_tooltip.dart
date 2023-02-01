import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'fanjiao_danmu.dart';

mixin FanjiaoDanmuTooltipMixin {
  Rect _menuRect = Rect.zero;

  Rect get menuRect => _menuRect;

  double? _menuPeakBias;

  double get menuPeakBias => _menuPeakBias ?? 0;

  bool? _menuIsAbove;

  bool get menuIsAbove => _menuIsAbove ?? false;

  Size get menuSize => const Size(96, 35);

  Color get bubbleColor => const Color(0xFF836BFF);

  Widget get tooltipContent;

  bool checkSelect(Offset position, Rect danmuRect, Rect stageRect) {
    double x, y;
    if (danmuRect.left > stageRect.right - danmuRect.height ||
        danmuRect.right < stageRect.left + danmuRect.height) {
      return false;
    }
    x = (position.dx - menuSize.width / 2)
        .clamp(0, stageRect.right - menuSize.width);
    _menuIsAbove = danmuRect.bottom > stageRect.bottom - menuSize.height;
    if (menuIsAbove) {
      y = danmuRect.top - menuSize.height;
    } else {
      y = danmuRect.bottom;
    }
    Offset offset = Offset(x, y);
    _menuRect = offset & menuSize;
    _menuPeakBias = position.dx.clamp(
            math.max(danmuRect.left, stageRect.left) + danmuRect.height / 2,
            math.min(danmuRect.right, stageRect.right) - danmuRect.height / 2) -
        _menuRect.left;
    return true;
  }

  Positioned tooltip() {
    Positioned widget;
    List<Widget>? children;
    if (menuIsAbove) {
      children = [
        Container(
          width: menuSize.width,
          height: menuSize.height - 5,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            color: bubbleColor,
          ),
          child: tooltipContent,
        ),
        Padding(
          padding: EdgeInsets.only(left: menuPeakBias - 5.5),
          child: Image.asset(
            "assets/images/arrow_down.png",
            width: 11,
            height: 5,
            color: bubbleColor,
            package: package,
          ),
        ),
      ];
    } else {
      children = [
        Padding(
          padding: EdgeInsets.only(left: menuPeakBias - 5.5),
          child: Image.asset(
            "assets/images/arrow_up.png",
            width: 11,
            height: 5,
            color: bubbleColor,
            package: package,
          ),
        ),
        Container(
          width: menuSize.width,
          height: menuSize.height - 5,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            color: bubbleColor,
          ),
          child: tooltipContent,
        ),
      ];
    }

    widget = Positioned(
      left: _menuRect.left,
      top: _menuRect.top,
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
    return widget;
  }
}
