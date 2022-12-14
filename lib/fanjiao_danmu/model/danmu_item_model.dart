import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../fanjiao_danmu_controller.dart';
import '../simulation/danmu_simulation.dart';

class DanmuItem<T extends DanmuModel> {
  final T model;
  final int lineNum;
  final DanmuSimulation simulation;
  final EdgeInsets padding;
  final ImageConfiguration configuration;
  late final TextPainter? textStrokePainter;
  late final TextPainter textPainter;
  Size size;
  SpanInfo spanInfo;

  ///[DanmuFlag] 可能会发生改变 比如[DanmuFlag.repeated]是否是重复内容
  int flag;
  bool isSelected;
  double? dTime;
  Offset? position;
  ui.Image? icon;

  Rect get rect =>
      position == null ? Rect.zero : position! - padding.topLeft & size;

  Rect get imageRect => position == null
      ? Rect.zero
      : position! & size + padding.bottomRight + padding.bottomRight;

  double get insertTime => model.insertTime;

  double get startTime => model.startTime;

  double get endTime => startTime + simulation.duration;

  Offset get startPosition => simulation.offset(0);

  Offset get endPosition => simulation.offset(simulation.duration);

  int get id => model.id;

  String get text => model.text;

  TextStyle get textStyle => model.textStyle;

  bool get isHighPraise => model.isPraise;

  bool get isMine => model.isMine;

  BoxDecoration get mineDecoration => model.mineDecoration;

  DanmuItem({
    required this.model,
    required this.simulation,
    required this.spanInfo,
    required this.size,
    this.padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    this.isSelected = false,
    this.lineNum = 0,
  })  : flag = model.flag,
        configuration = ImageConfiguration(size: size) {
    if (spanInfo.isTextSpan) {
      ///由于绘制时大量layout比较耗时，所以提前用空间换时间
      if (spanInfo.textStrokeSpan != null) {
        textStrokePainter = TextPainter(textDirection: TextDirection.ltr)
          ..text = spanInfo.textStrokeSpan;
        textStrokePainter!.layout();
      }
      textPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = spanInfo.span;
      textPainter.layout();
    }
  }
}

/*
    loadImage(context, widget.iconProvider,
        width: widget.iconWidth, height: widget.iconHeight)
        .then((image) {
      setState(() {
        icon = image;
      });
    });*/

class SpanInfo {
  final String text;

  final InlineSpan? span;

  final InlineSpan? textStrokeSpan;

  final ImageProvider? iconAsset;

  bool get isTextSpan => span != null && span is TextSpan;

  SpanInfo(this.text, {this.span, this.iconAsset, this.textStrokeSpan});
}

class DanmuModel {
  final int id;
  final String text;
  final bool isMine;

  ///[DanmuFlag] 一个弹幕创建时确定，不会发生改变
  final int flag;
  final TextStyle textStyle;
  final double insertTime;
  final double startTime;
  final bool isPraise;
  final ImageProvider? imageProvider;
  final String? package;

  ///用于"我的"弹幕
  final BoxDecoration mineDecoration;

  DanmuModel({
    required this.id,
    required this.text,
    required this.startTime,
    this.isMine = false,
    this.imageProvider,
    this.isPraise = false,
    this.package,
    this.flag = DanmuFlag.scroll,
    double? insertTime,
    Map<String, ImageProvider>? imageMap,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
    this.mineDecoration = const BoxDecoration(
      color: Color(0xCCFF9C6B),
      borderRadius: BorderRadius.all(Radius.circular(12)),
      border: Border.fromBorderSide(
          BorderSide(color: Colors.white, width: 1, style: BorderStyle.solid)),
    ),
  })  : assert(textStyle != null),
        insertTime = insertTime ?? startTime;
}
