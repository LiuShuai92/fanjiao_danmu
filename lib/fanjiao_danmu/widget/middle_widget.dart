import 'package:flutter/material.dart';

class Middle extends StatelessWidget {
  final Widget child;

  const Middle({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
