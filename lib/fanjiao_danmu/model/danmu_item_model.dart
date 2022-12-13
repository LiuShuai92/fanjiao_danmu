import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../fanjiao_danmu_controller.dart';
import '../simulation/danmu_simulation.dart';

class DanmuItem<T extends DanmuModel> {
  final T model;
  final int lineNum;
  final DanmuSimulation simulation;

  ///[DanmuFilter] 可能会发生改变 比如[DanmuFilter.repeated]是否是重复内容
  int flag;
  bool isSelected;
  double? dTime;
  Offset? position;
  ui.Image? icon;

  Rect get rect =>
      position == null ? Rect.zero : position! + const Offset(-4, -2) & size;

  double get insertTime => model.insertTime;

  double get startTime => model.startTime;

  double get endTime => startTime + simulation.duration;

  int get id => model.id;

  String get text => model.text;

  TextStyle get textStyle => model.textStyle;

  bool get isHighPraise => model.isHighPraise;

  bool get isSelf => model.isSelf;

  Size size;

  SpanInfo spanInfo;

  InlineSpan? get span => model.span;

  DanmuItem({
    required this.model,
    required this.simulation,
    required this.spanInfo,
    required this.size,
    this.isSelected = false,
    this.lineNum = 0,
  }) : flag = model.flag;
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
  final bool isSelf;

  ///[DanmuFilter] 一个弹幕创建时确定，不会发生改变
  final int flag;
  final TextStyle textStyle;
  final double insertTime;
  final double startTime;
  final bool isHighPraise;
  final ImageProvider? imageProvider;
  final InlineSpan? span;
  final String? package;

  DanmuModel({
    required this.id,
    required this.text,
    required this.startTime,
    this.isSelf = false,
    this.imageProvider,
    this.isHighPraise = false,
    this.span,
    this.package,
    this.flag = DanmuFilter.scroll,
    double? insertTime,
    Map<String, ImageProvider>? imageMap,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
  })  : assert(textStyle != null),
        insertTime = insertTime ?? startTime;
}
