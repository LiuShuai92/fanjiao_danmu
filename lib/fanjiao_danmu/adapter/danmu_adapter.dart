import 'package:flutter/widgets.dart';

import '../model/danmu_item_model.dart';

///用于计算弹幕插入位置
abstract class DanmuAdapter<T extends DanmuModel> {
  late Rect rect;

  DanmuAdapter();

  @mustCallSuper
  initData(Rect rect) {
    this.rect = rect;
  }

  DanmuItem<T>? getItem(T model);

  removeItem(DanmuItem<T> item);

  clear();
}
