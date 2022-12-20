import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'fanjiao_danmu_controller.dart';
import 'model/danmu_item_model.dart';

class FanjiaoDanmuWidget extends StatefulWidget {
  final FanjiaoDanmuController danmuController;
  final Size size;

  Positioned Function()? tooltip;

  FanjiaoDanmuWidget({
    Key? key,
    required this.size,
    required this.danmuController,
    this.tooltip,
  })  : assert(danmuController != null),
        super(key: key);

  @override
  State<FanjiaoDanmuWidget> createState() => _FanjiaoDanmuWidgetState();
}

class _FanjiaoDanmuWidgetState extends State<FanjiaoDanmuWidget>
    with SingleTickerProviderStateMixin {
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
    List<Widget> children = [
      RepaintBoundary(
        child: CustomPaint(
          size: widget.size,
          isComplex: true,
          painter: _FanjiaoDanmuPainter(
            context,
            controller: widget.danmuController,
          ),
        ),
      ),
    ];
    if (widget.danmuController.isSelected) {
      var tooltip = widget.tooltip?.call();
      if(tooltip != null){
        children.add(tooltip);
      }
    }
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: GestureDetector(
        onTapDown: (details) {
          widget.danmuController.tapPosition(details.localPosition);
        },
        child: Stack(
          children: children,
        ),
      ),
    );
  }
}

class _FanjiaoDanmuPainter extends CustomPainter {
  final BuildContext context;
  final FanjiaoDanmuController controller;
  final ImageProvider? iconProvider;
  final double iconWidth;
  final double iconHeight;
  final Paint _painter;
  final TextPainter _textPainter;
  double? height;
  double? width;
  DanmuStatus state = DanmuStatus.stop;

  _FanjiaoDanmuPainter(
    this.context, {
    required this.controller,
    this.iconProvider,
    this.iconWidth = 14,
    this.iconHeight = 14,
  })  : _textPainter = TextPainter(textDirection: TextDirection.ltr),
        _painter = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.danmuItems.isEmpty) {
      return;
    }
    height ??= size.height;
    width ??= size.width;
    for (var entry in controller.danmuItems) {
      if (controller.filter.check(entry.flag)) {
        if (entry.position == null || entry.isSelected) {
          continue;
        }
        drawItem(entry, canvas);
      }
    }
    if (controller.selected != null) {
      drawItem(controller.selected!, canvas);
    }
  }

  void drawItem(DanmuItem<DanmuModel> entry, ui.Canvas canvas) {
    if (entry.isMine) {
      drawBorder(entry, canvas);
    }
    if (entry.spanInfo.isTextSpan) {
      drawText(entry, canvas);
    } else if (entry.spanInfo.iconAsset != null) {
      var imageInfo = controller.getImage(context, entry.spanInfo.iconAsset!);
      if (imageInfo != null &&
          imageInfo.image != null &&
          imageInfo.rect != null) {
        drawImage(imageInfo.image, canvas, imageInfo.rect!, entry.imageRect);
      }
    }
    if (entry.isHighPraise) {
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
    if (entry.spanInfo.textStrokeSpan != null) {
      _textPainter.text = entry.spanInfo.textStrokeSpan;
      _textPainter.layout();
      _textPainter.paint(canvas, entry.position!);
    }
    _textPainter.text = entry.spanInfo.span;
    _textPainter.layout();
    _textPainter.paint(canvas, entry.position!);
  }

  ///绘制单个弹幕边框
  void drawBorder(DanmuItem entry, ui.Canvas canvas) {
    var boxPainter = entry.mineDecoration.createBoxPainter();
    boxPainter.paint(
        canvas, entry.position! - entry.padding.topLeft, entry.configuration);
  }

  ///shouldRepaint则决定当条件变化时是否需要重画。
  @override
  bool shouldRepaint(_FanjiaoDanmuPainter oldDelegate) {
    bool shouldRepaint = controller.state == DanmuStatus.playing ||
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
