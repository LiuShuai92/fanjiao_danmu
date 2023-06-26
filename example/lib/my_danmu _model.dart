import 'package:fanjiao_danmu/fanjiao_danmu/fanjiao_danmu.dart';
import 'package:flutter/material.dart';

class MyDanmuModel extends DanmuModel {
  int likeCount;
  bool isLiked;

  MyDanmuModel({
    this.likeCount = 0,
    this.isLiked = false,
    required int id,
    required String text,
    required Duration startTime,
    List<InlineSpan> spans = const [],
    ImageProvider? imageProvider,
    String? package,
    bool isRepeatable = false,
    double opacity = 1,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    EdgeInsets margin = const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    double strokeWidth = 1,
    Size imageSize = const Size(52, 20),
    int flag = DanmuFlag.scroll | DanmuFlag.clickable,
    BoxDecoration? decoration,
    BoxDecoration? foregroundDecoration,
    AlignmentGeometry? alignment,
    Duration? insertTime,
    TextStyle textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
  }) : super(
          id: id,
          text: text,
          startTime: startTime,
          spans: spans,
          imageProvider: imageProvider,
          package: package,
          isRepeatable: isRepeatable,
          opacity: opacity,
          padding: padding,
          margin: margin,
          strokeWidth: strokeWidth,
          imageSize: imageSize,
          flag: flag,
          decoration: decoration,
          foregroundDecoration: foregroundDecoration,
          alignment: alignment,
          insertTime: insertTime,
          textStyle: textStyle,
        );

  @override
  MyDanmuModel copyWith(
      {int? id,
      int? likeCount,
      String? text,
      Duration? startTime,
      List<InlineSpan>? spans,
      bool? isLiked,
      bool? isClickable,
      ImageProvider<Object>? imageProvider,
      String? package,
      bool? isRepeatable,
      double? opacity,
      EdgeInsets? padding,
      EdgeInsets? margin,
      double? strokeWidth,
      Size? imageSize,
      int? flag,
      BoxDecoration? decoration,
      BoxDecoration? foregroundDecoration,
      AlignmentGeometry? alignment,
      Duration? insertTime,
      TextStyle? textStyle}) {
    return MyDanmuModel(
      id: id ?? this.id,
      likeCount: likeCount ?? this.likeCount,
      text: text ?? this.text,
      startTime: startTime ?? this.startTime,
      spans: spans ?? this.spans,
      isLiked: isLiked ?? this.isLiked,
      imageProvider: imageProvider ?? this.imageProvider,
      package: package ?? this.package,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      opacity: opacity ?? this.opacity,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      imageSize: imageSize ?? this.imageSize,
      flag: flag ?? this.flag,
      decoration: decoration ?? this.decoration,
      foregroundDecoration: foregroundDecoration ?? this.foregroundDecoration,
      alignment: alignment ?? this.alignment,
      insertTime: insertTime ?? this.insertTime,
      textStyle: textStyle ?? this.textStyle,
    );
  }
}