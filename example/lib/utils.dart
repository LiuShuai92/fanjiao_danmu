import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:fanjiao_danmu/fanjiao_danmu/danmu_controller.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/widget/stroke_text_widget.dart';
import 'package:flutter/material.dart';

import 'my_danmu_model.dart';

var rng = math.Random();

TextStyle get rngTextStyle => TextStyle(
      color: rngColor,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    );

String get rngText {
  double t = rng.nextDouble();
  int max = 20 ~/ (1 + 19 * t);
  String text = "略";
  for (int i = 0; i < max; i++) {
    text += "略";
  }
  return text;
}

double get rngSize => 18.0 + rng.nextInt(35);

double rngDouble(int max) => rng.nextInt(max * 10) / 10;

int rngInt(int max) => rng.nextInt(max);

Color get rngColor =>
    Color.fromARGB(255, rng.nextInt(255), rng.nextInt(255), rng.nextInt(255));

List<MyDanmuModel> globalDanmus(String text, Duration progress){
  return [
    MyDanmuModel(
      id: -1,
      text: text,
      flag: DanmuFlag.scroll |
      DanmuFlag.collisionFree|
      DanmuFlag.specify |
      DanmuFlag.otherStage,
      specifyY: 96,
      spans: [
        WidgetSpan(
          child: StrokeTextWidget(
            text,
            textStyle: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              fontFamily: "AlimamaShuHeiTi",
            ),
            linearGradient: RawLinearGradient(
              LocalPosition.topCenter,
              LocalPosition.bottomCenter,
              [
                const Color(0xFFFFB3AF),
                const Color(0xFFFFFCF0),
                const Color(0xFFFFEA9D),
              ],
              [0, 0.5, 1],
            ),
            strokeWidth: 1.5,
            // opacity: 1,
            strokeColor: const Color(0xFF613427),
          ),
        ),
      ],
      startTime: progress + const Duration(milliseconds: 1200),
    ),
    MyDanmuModel(
      id: -2,
      text: text,
      flag: DanmuFlag.scroll |
      DanmuFlag.collisionFree|
      DanmuFlag.specify |
      DanmuFlag.otherStage,
      specifyY: 189,
      spans: [
        WidgetSpan(
          child: StrokeTextWidget(
            text,
            textStyle: const TextStyle(
              fontSize: 37,
              fontWeight: FontWeight.w800,
              fontFamily: "AlimamaShuHeiTi",
            ),
            linearGradient: RawLinearGradient(
              LocalPosition.topCenter,
              LocalPosition.bottomCenter,
              [
                const Color(0xFFEFFFA9),
                const Color(0xFFFFFEF0),
                const Color(0xFFC9F6FD),
              ],
              [0, 0.5, 1],
            ),
            strokeWidth: 1.5,
            // opacity: 1,
            strokeColor: const Color(0xFF253571),
          ),
        ),
      ],
      startTime: progress + const Duration(milliseconds: 3200),
    ),
    MyDanmuModel(
      id: -3,
      text: text,
      flag: DanmuFlag.scroll |
      DanmuFlag.collisionFree|
      DanmuFlag.specify |
      DanmuFlag.otherStage,
      specifyY: 300,
      spans: [
        WidgetSpan(
          child: StrokeTextWidget(
            text,
            textStyle: const TextStyle(
              fontSize: 33,
              fontWeight: FontWeight.w800,
              fontFamily: "AlimamaShuHeiTi",
            ),
            linearGradient: RawLinearGradient(
              LocalPosition.topCenter,
              LocalPosition.bottomCenter,
              [
                const Color(0xFFE1C6F8),
                const Color(0xFFFFFBEA),
                const Color(0xFFFFA8D9),
              ],
              [0, 0.5, 1],
            ),
            strokeWidth: 1.5,
            // opacity: 1,
            strokeColor: const Color(0xFF41357F),
          ),
        ),
      ],
      startTime: progress,
    ),
    MyDanmuModel(
      id: -4,
      text: text,
      flag: DanmuFlag.scroll |
      DanmuFlag.collisionFree|
      DanmuFlag.specify |
      DanmuFlag.otherStage,
      specifyY: 387,
      spans: [
        WidgetSpan(
          child: StrokeTextWidget(
            text,
            textStyle: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              fontFamily: "AlimamaShuHeiTi",
            ),
            linearGradient: RawLinearGradient(
              LocalPosition.topCenter,
              LocalPosition.bottomCenter,
              [
                const Color(0xFFE1C6F8),
                const Color(0xFFFFFBEA),
                const Color(0xFFFFA8D9),
              ],
              [0, 0.5, 1],
            ),
            strokeWidth: 1.5,
            // opacity: 1,
            strokeColor: const Color(0xFF41357F),
          ),
        ),
      ],
      startTime: progress + const Duration(milliseconds: 2600),
    ),
    MyDanmuModel(
      id: -5,
      text: text,
      flag: DanmuFlag.scroll |
      DanmuFlag.collisionFree|
      DanmuFlag.specify |
      DanmuFlag.otherStage,
      specifyY: 490,
      spans: [
        WidgetSpan(
          child: StrokeTextWidget(
            text,
            textStyle: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              fontFamily: "AlimamaShuHeiTi",
            ),
            linearGradient: RawLinearGradient(
              LocalPosition.topCenter,
              LocalPosition.bottomCenter,
              [
                const Color(0xFFEFFFA9),
                const Color(0xFFFFFEF0),
                const Color(0xFFC9F6FD),
              ],
              [0, 0.5, 1],
            ),
            strokeWidth: 1.5,
            // opacity: 1,
            strokeColor: const Color(0xFF253571),
          ),
        ),
      ],
      startTime: progress + const Duration(milliseconds: 2610),
    ),
    MyDanmuModel(
      id: -6,
      text: text,
      flag: DanmuFlag.scroll |
      DanmuFlag.collisionFree|
      DanmuFlag.specify |
      DanmuFlag.otherStage,
      specifyY: 582,
      spans: [
        WidgetSpan(
          child: StrokeTextWidget(
            text,
            textStyle: const TextStyle(
              fontSize: 33,
              fontWeight: FontWeight.w800,
              fontFamily: "AlimamaShuHeiTi",
            ),
            linearGradient: RawLinearGradient(
              LocalPosition.topCenter,
              LocalPosition.bottomCenter,
              [
                const Color(0xFFFFB3AF),
                const Color(0xFFFFFCF0),
                const Color(0xFFFFEA9D),
              ],
              [0, 0.5, 1],
            ),
            strokeWidth: 1.5,
            // opacity: 1,
            strokeColor: const Color(0xFF613427),
          ),
        ),
      ],
      startTime: progress + const Duration(milliseconds: 2000),
    ),
    MyDanmuModel(
      id: -7,
      text: text,
      flag: DanmuFlag.scroll |
      DanmuFlag.collisionFree|
      DanmuFlag.specify |
      DanmuFlag.otherStage,
      specifyY: 677,
      spans: [
        WidgetSpan(
          child: StrokeTextWidget(
            text,
            textStyle: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              fontFamily: "AlimamaShuHeiTi",
            ),
            linearGradient: RawLinearGradient(
              LocalPosition.topCenter,
              LocalPosition.bottomCenter,
              [
                const Color(0xFFE1C6F8),
                const Color(0xFFFFFBEA),
                const Color(0xFFFFA8D9),
              ],
              [0, 0.5, 1],
            ),
            strokeWidth: 1.5,
            // opacity: 1,
            strokeColor: const Color(0xFF41357F),
          ),
        ),
      ],
      startTime: progress + const Duration(milliseconds: 4500),
    ),
  ];
}