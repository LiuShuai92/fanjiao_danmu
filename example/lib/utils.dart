import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flutter/material.dart';

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
