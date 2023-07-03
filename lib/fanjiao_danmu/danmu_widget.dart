import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'danmu_controller.dart';
import 'danmu_item.dart';
import 'danmu_model.dart';

class DanmuWidget extends StatefulWidget{
  final DanmuController danmuController;
  final double width;
  final double height;

  Positioned? Function<T extends DanmuModel>(DanmuItem<T>?)? tooltip;

  DanmuWidget({
    Key? key,
    required this.width,
    required this.height,
    required this.danmuController,
    this.tooltip,
  })  : assert(danmuController != null),
        super(key: key);

  @override
  State<DanmuWidget> createState() => _DanmuWidgetState();
}

class _DanmuWidgetState extends State<DanmuWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  TapUpDetails? _tapDownDetails;

  @override
  void initState() {
    super.initState();
    widget.danmuController.setup(context, this,
        Rect.fromLTRB(0, 0, widget.width, widget.height));
    widget.danmuController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    widget.danmuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var danmuController = widget.danmuController;
    var tooltipWidget = widget.tooltip?.call(danmuController.selected);
    List<Widget> children = [];
    List<Widget> frontChildren = [];
    Positioned? selected;
    for (var danmuItem in danmuController.danmuItems) {
      Widget itemWidget;
      if (danmuItem.isImage) {
        itemWidget = Image(
          image: danmuItem.imageAsset!,
          width: danmuItem.size.width,
          height: danmuItem.size.height,
        );
      } else {
        itemWidget =
            Text.rich(danmuItem.span!);
      }
      var model = danmuItem.model;
      if (model.startTime <= danmuController.progress &&
          danmuController.filter.contain(danmuItem.flag)) {
        var positioned = Positioned(
          key: danmuItem.valueKey(),
          left: danmuItem.position?.dx,
          top: danmuItem.position?.dy,
          child: Container(
            child: itemWidget,
            decoration: model.decoration,
            foregroundDecoration: model.foregroundDecoration,
            alignment: model.alignment,
            padding: model.padding,
            margin: model.margin,
          ),
        );
        if (danmuItem.isSelected) {
          selected = positioned;
          continue;
        }
        if (danmuItem.flag.isFront) {
          frontChildren.add(positioned);
          continue;
        }
        children.add(positioned);
      }
    }
    if (frontChildren.isNotEmpty) {
      children.addAll(frontChildren);
    }
    if (selected != null) {
      children.add(selected);
    }
    if (tooltipWidget != null) {
      children.add(tooltipWidget);
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          _tapDownDetails = details;
        },
        onTap: () {
          if (_tapDownDetails != null) {
            danmuController.tapPosition(_tapDownDetails!.localPosition);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: children,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/*class _FanjiaoDanmuPainter extends CustomPainter {
  final BuildContext context;
  final DanmuController controller;
  final double iconWidth;
  final double iconHeight;
  final Paint _painter;

  // final TextPainter _textPainter;
  double? height;
  double? width;
  DanmuStatus state = DanmuStatus.stop;

  _FanjiaoDanmuPainter(
    this.context, {
    required this.controller,
    this.iconWidth = 14,
    this.iconHeight = 14,
  }) : _painter = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.danmuItems.isEmpty) {
      return;
    }
    height ??= size.height;
    width ??= size.width;
    canvas.saveLayer(Rect.fromLTRB(0, 0, size.width, size.height), _painter);
    DanmuItem? selectedEntry;
    for (var entry in controller.danmuItems) {
      if (entry.isSelected) {
        selectedEntry = entry;
        continue;
      }
      if (entry.model.startTime <= controller.progress &&
          controller.filter.check(entry.flag)) {
        if (entry.position == null) {
          continue;
        }
        drawItem(entry, canvas);
      }
    }
    if (selectedEntry != null) {
      drawItem(selectedEntry, canvas);
    }
    canvas.restore();
  }

  void drawItem(DanmuItem<DanmuModel> entry, ui.Canvas canvas) {
    if (entry.model.decoration != null) {
      drawBorder(entry, canvas);
    }
    if (entry.isImage) {
      var imageInfo = controller.getImage(context, entry.imageAsset!);
      if (imageInfo != null &&
          imageInfo.image != null &&
          imageInfo.rect != null) {
        drawImage(imageInfo.image, canvas, imageInfo.rect!, entry.imageRect);
      }
    } else {
      drawText(entry, canvas);
    }
    if (entry.model.isPraise) {
      drawPraise(entry, canvas);
    }
  }

  ///绘制高赞图标
  void drawPraise(DanmuItem entry, ui.Canvas canvas) {
    var iconPraise = controller.iconPraise(context);
    if (iconPraise != null &&
        iconPraise.image != null &&
        iconPraise.rect != null) {
      final double scale = entry.rect.height / iconPraise.rect!.height;
      final double left = entry.rect.left - iconPraise.rect!.width * scale;
      final double top = entry.rect.top;
      final double right = entry.rect.left;
      final double bottom = entry.rect.bottom;
      final Rect dstRect = Rect.fromLTRB(left, top, right, bottom);
      drawImage(iconPraise.image!, canvas, iconPraise.rect!, dstRect);
    }
  }

  ///绘制图片
  void drawImage(
      ui.Image? iconPraise, ui.Canvas canvas, Rect srcRect, Rect dstRect) {
    _painter
      ..color = const Color.fromARGB(200, 0, 0, 0)
      ..style = PaintingStyle.fill;
    if (iconPraise != null) {
      canvas.drawImageRect(iconPraise, srcRect, dstRect, _painter);
    }
  }

  ///绘制文字
  void drawText(DanmuItem entry, ui.Canvas canvas) {
    if (entry.textStrokeSpan != null) {
      entry.textStrokePainter?.paint(canvas, entry.position!);
    }
    entry.textPainter?.paint(canvas, entry.position!);
  }

  ///绘制单个弹幕边框
  void drawBorder(DanmuItem entry, ui.Canvas canvas) {
    assert(entry.model.decoration != null);
    var boxPainter = entry.model.decoration!.createBoxPainter();
    boxPainter.paint(canvas, entry.position! - entry.model.padding.topLeft,
        entry.configuration);
  }

  ///shouldRepaint则决定当条件变化时是否需要重画。
  @override
  bool shouldRepaint(_FanjiaoDanmuPainter oldDelegate) {
    bool shouldRepaint = controller.onceForceRefresh ||
        controller.state == DanmuStatus.playing ||
        oldDelegate.state != controller.state;
    state = controller.state;
    return shouldRepaint;
  }

  void drawDashedLine(
      Canvas canvas, double left, double right, double y, Paint paint) {
    const double dashWidth = 4;
    const double dashSpace = 4;
    const space = (dashSpace + dashWidth);
    for (double x = left; x < right; x += space) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
    }
  }
}*/
