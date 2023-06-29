import 'package:fanjiao_danmu/fanjiao_danmu/danmu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'danmu_controller.dart';
import 'danmu_model.dart';

class DanmuLayoutWidget extends MultiChildRenderObjectWidget {
  final double width;
  final double height;
  final DanmuController danmuController;

  Positioned? Function<T extends DanmuModel>(DanmuItem<T>?)? tooltip;

  DanmuLayoutWidget({
    required this.width,
    required this.height,
    required this.danmuController,
    required List<Widget> children,
    this.tooltip,
    Key? key,
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    var danmuLayoutRenderBox = DanmuLayoutRenderBox();
    updateRenderObject(context, danmuLayoutRenderBox);
    return danmuLayoutRenderBox;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant DanmuLayoutRenderBox renderObject) {
    renderObject
      ..width = width
      ..height = height;
  }
}

class DanmuLayoutRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, DanmuItem>,
        RenderBoxContainerDefaultsMixin<RenderBox, DanmuItem> {
  double? _width;
  double? _height;

  double get width => _width ?? 0;

  double get height => _height ?? 0;

  set width(double value) {
    if (value == _width) {
      return;
    }
    _width = value;
    if (_height == null) {
      return;
    }
    size = Size(width, height);
  }

  set height(double value) {
    if (value == _height) {
      return;
    }
    _height = value;
    if (_width == null) {
      return;
    }
    size = Size(width, height);
  }

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! DanmuItem) {
      ///todo
      child.parentData = null;
    }
  }

  @override
  void performLayout() {
    /*if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
  }
    Size computeSize = computeSizeForNoChild(constraints);
    _width ??= computeSize.width;
    _height ??= computeSize.height;*/
    size = Size(width, height);

    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(constraints, parentUsesSize: true);
      final DanmuItem parentData = child.parentData! as DanmuItem;

      child = parentData.nextSibling;
    }
  }

  /*@override
  void markNeedsLayout() {
    // TODO: implement markNeedsLayout
    super.markNeedsLayout();
  }

  @override
  void markNeedsPaint() {
    // TODO: implement markNeedsPaint
    super.markNeedsPaint();
  }*/
}
