import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'danmu_controller.dart';
import 'model/danmu_item_model.dart';

class DanmuWidget extends StatefulWidget {
  final DanmuController danmuController;
  final Size size;

  Positioned? Function<T extends DanmuModel>(DanmuItem<T>?)? tooltip;

  DanmuWidget({
    Key? key,
    required this.size,
    required this.danmuController,
    this.tooltip,
  })  : assert(danmuController != null),
        super(key: key);

  @override
  State<DanmuWidget> createState() => _DanmuWidgetState();
}

class _DanmuWidgetState extends State<DanmuWidget>
    with SingleTickerProviderStateMixin {
  TapUpDetails? _tapDownDetails;

  @override
  void initState() {
    super.initState();
    widget.danmuController.setup(context, this,
        Rect.fromLTRB(0, 0, widget.size.width, widget.size.height));
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
    // Widget child;
    var tooltipWidget = widget.tooltip?.call(widget.danmuController.selected);
    List<Widget> children = [];
    Positioned? selected;
    for (var danmuItem in widget.danmuController.danmuItems) {
      Widget itemWidget;
      if (danmuItem.isImage) {
        itemWidget = Image(
          image: danmuItem.imageAsset!,
          width: danmuItem.size.width,
          height: danmuItem.size.height,
        );
      } else {
        itemWidget = Text.rich(danmuItem.span!);
      }
      var positioned = Positioned(
        left: danmuItem.position?.dx,
        top: danmuItem.position?.dy,
        child: Container(
          child: itemWidget,
          decoration: danmuItem.model.decoration,
          padding: danmuItem.model.padding,
        ),
      );
      if (danmuItem.isSelected) {
        selected = positioned;
        continue;
      }
      children.add(positioned);
    }
    if (selected != null) {
      children.add(selected);
    }
    if (tooltipWidget != null) {
      children.add(tooltipWidget);
    }
    /*var customPaint = CustomPaint(
      size: widget.size,
      isComplex: true,
      painter: _FanjiaoDanmuPainter(
        context,
        controller: widget.danmuController,
      ),
    );
    if (tooltipWidget != null) {
      child = Stack(
        children: children,
      );
    }else {
      child = customPaint;
    }*/
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          _tapDownDetails = details;
        },
        onTap: () {
          if (_tapDownDetails != null) {
            widget.danmuController.tapPosition(_tapDownDetails!.localPosition);
          }
        },
        // child: child,
        child: Stack(
          children: children,
        ),
      ),
    );
  }
}

class _FanjiaoDanmuPainter extends CustomPainter {
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
}

Future<ui.Image?> loadImage(BuildContext? context, ImageProvider? imageProvider,
    {double? width, double? height}) async {
  assert(context != null);
  if (imageProvider == null) return null;
  ImageStream stream = imageProvider.resolve(createLocalImageConfiguration(
    context!,
    size: width != null && height != null ? Size(width, height) : null,
  ));
  assert(stream != null);
  Completer<ui.Image> completer = Completer<ui.Image>();
  ImageStreamListener? imageStreamListener;
  listener(ImageInfo frame, bool synchronousCall) {
    final ui.Image image = frame.image;
    completer.complete(image);
    stream.removeListener(imageStreamListener!);
  }

  imageStreamListener = ImageStreamListener(listener);
  stream.addListener(imageStreamListener);
  return completer.future;
}