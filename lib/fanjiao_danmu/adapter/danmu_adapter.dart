import 'package:flutter/widgets.dart';

import '../danmu_item.dart';
import '../danmu_model.dart';

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
