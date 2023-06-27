import 'package:flutter/material.dart';

import 'danmu_controller.dart';

class DanmuModel {
  final int id;
  final List<InlineSpan> spans;
  final String text;
  final bool isClickable;
  final bool isRepeatable;
  final int flag;
  final double? specifyY;
  final TextStyle textStyle;
  final Duration insertTime;
  final Duration startTime;
  final ImageProvider? imageProvider;
  final String? package;
  final BoxDecoration? decoration;
  final BoxDecoration? foregroundDecoration;
  final AlignmentGeometry? alignment;
  final Size imageSize;
  final double strokeWidth;
  final double opacity;
  final EdgeInsets padding;
  final EdgeInsets margin;

  String get plainText {
    String plainText = "";
    for (var span in spans) {
      plainText += span.toPlainText(
          includeSemanticsLabels: false, includePlaceholders: false);
    }
    return plainText.isEmpty ? text : plainText;
  }

  DanmuModel({
    required this.id,
    required this.text,
    required this.startTime,
    this.spans = const [],
    this.isClickable = true,
    this.specifyY,
    this.imageProvider,
    this.package,
    this.isRepeatable = false,
    this.opacity = 1,
    this.padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    this.margin = const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    this.strokeWidth = 1,
    this.imageSize = const Size(52, 20),
    this.flag = DanmuFlag.scroll | DanmuFlag.clickable,
    this.decoration,
    this.foregroundDecoration,
    this.alignment,
    Duration? insertTime,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
  })  : assert(textStyle != null),
        assert(!flag.isSpecify || specifyY != null, "如果需要指定y坐标，必须传入specifyY值"),
        insertTime = insertTime ?? startTime;

  DanmuModel copyWith({
    int? id,
    String? text,
    Duration? startTime,
    double? specifyY,
    List<InlineSpan>? spans,
    bool? isClickable,
    ImageProvider? imageProvider,
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
    TextStyle? textStyle,
  }) {
    return DanmuModel(
      id: id ?? this.id,
      text: text ?? this.text,
      startTime: startTime ?? this.startTime,
      specifyY: specifyY ?? this.specifyY,
      spans: spans ?? this.spans,
      isClickable: isClickable ?? this.isClickable,
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
