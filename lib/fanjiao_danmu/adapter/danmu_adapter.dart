import 'package:flutter/widgets.dart';

import '../model/danmu_item_model.dart';

///用于计算弹幕插入位置
abstract class DanmuAdapter {
  late Rect rect;
  final double preExtra = 10;
  double iconExtra = 30;

  @mustCallSuper
  initData(Rect rect) {
    this.rect = rect;
  }

  DanmuItem? getItem(DanmuModel model);

  removeItem(DanmuItem item);

  clear();
}
