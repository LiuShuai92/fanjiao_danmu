import 'package:fanjiao_danmu/fanjiao_danmu/danmu_item.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/fanjiao_danmu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DanmakuStage extends MultiChildRenderObjectWidget {
  final Positioned? Function<T extends DanmuModel>(DanmuItem<T>?)? tooltip;

  const DanmakuStage({
    super.key,
    super.children = const <Widget>[],
    this.tooltip,
  });

  // @override
  // MultiChildRenderObjectElement createElement() => _DanmakuElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    var renderBubbleBox = _RenderDanmakuStage();
    updateRenderObject(context, renderBubbleBox);
    return renderBubbleBox;
  }
}

class _RenderDanmakuStage extends RenderProxyBox {
  _RenderDanmakuStage();

}

class _DanmakuElement extends MultiChildRenderObjectElement {

  _DanmakuElement(DanmakuStage super.widget);

  @override
  RenderViewport get renderObject => super.renderObject as RenderViewport;

  /*bool _doingMountOrUpdate = false;
  @override
  void mount(Element? parent, Object? newSlot) {
    assert(!_doingMountOrUpdate);
    _doingMountOrUpdate = true;
    super.mount(parent, newSlot);
    _updateCenter();
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }*/
}
