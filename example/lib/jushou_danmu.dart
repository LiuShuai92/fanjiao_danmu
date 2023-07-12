import 'package:flutter/material.dart';

class JushouDanmu extends StatefulWidget {
  final Function()? animComplete;

  JushouDanmu({Key? key, this.animComplete}) : super(key: key);

  @override
  State<JushouDanmu> createState() => _JushouDanmuState();
}

class _JushouDanmuState extends State<JushouDanmu> {
  double top = 36;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      top = 0;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          top: top,
          duration: const Duration(milliseconds: 300),
          child: Image.asset(
            "assets/images/ic_jy.png",
            width: 30,
            height: 36,
            fit: BoxFit.fitWidth,
          ),
        ),
      ],
    );
  }
}
