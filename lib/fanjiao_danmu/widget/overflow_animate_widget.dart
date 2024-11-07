import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class OverflowAnimateWidget extends StatefulWidget {
  final double width;
  final double height;
  final double? maxWidth;
  final double? maxHeight;
  final AlignmentGeometry alignment;

  const OverflowAnimateWidget(
    this.width,
    this.height, {
    Key? key,
    this.maxWidth,
    this.maxHeight,
    this.alignment = Alignment.bottomCenter,
  }) : super(key: key);

  @override
  State<OverflowAnimateWidget> createState() => _OverflowAnimateWidgetState();
}

class _OverflowAnimateWidgetState extends State<OverflowAnimateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _OverflowAnimatePainter(
          widget.width,
          widget.height,
          maxWidth: widget.maxWidth,
          maxHeight: widget.maxHeight,
          alignment: widget.alignment,
        ),
      ),
    );
  }
}

class _OverflowAnimatePainter extends CustomPainter {
  final double width;
  final double height;
  final double? maxWidth;
  final double? maxHeight;
  final AlignmentGeometry alignment;
  final Map<ImageProvider, ImgInfo> _imagesPool = {};

  _OverflowAnimatePainter(
    this.width,
    this.height, {
    this.maxWidth,
    this.maxHeight,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    throw UnimplementedError();
  }

  addImage(BuildContext context, ImageProvider asset) async {
    var image = await loadImage(context, asset);
    if (image != null) {
      _imagesPool[asset] = ImgInfo(image,
          Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()));
      // notifyListeners();
    }
  }

  Future<ImgInfo?> getImageAsync(BuildContext context, ImageProvider? asset)async {
    if (asset == null) {
      return null;
    }
    if (_imagesPool[asset] == null) {
      _imagesPool[asset] = ImgInfo.empty;
      await addImage(context, asset);
      return _imagesPool[asset];
    } else {
      return _imagesPool[asset];
    }
  }

  ImgInfo? getImage(BuildContext context, ImageProvider? asset) {
    if (asset == null) {
      return null;
    }
    if (_imagesPool[asset] == null) {
      _imagesPool[asset] = ImgInfo.empty;
      addImage(context, asset);
      return null;
    } else {
      return _imagesPool[asset];
    }
  }
}

class ImgInfo {
  final ui.Image? image;
  final Rect? rect;
  static const ImgInfo empty = ImgInfo(null, null);

  bool get isEmpty => image == null;

  const ImgInfo(this.image, this.rect);
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
  var img =await completer.future;
  return img;
}
