import 'dart:async';

import 'package:fanjiao_danmu/fanjiao_danmu/fanjiao_danmu.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FanjiaoDanmuController danmuController;
  late TextEditingController textController;
  Timer? timer;
  Duration duration = const Duration(seconds: 3780);
  bool isPlaying = false;
  int id = 0;
  String selectedText = '';

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  // int progress = 0;

  @override
  void initState() {
    super.initState();
    danmuController = FanjiaoDanmuController(
        adapter: FanjiaoDanmuAdapter(imageMap: {
          '[bilibili]': const AssetImage("assets/images/bilibili.png"),
          '[饭角]': const NetworkImage(
              "https://www.fanjiao.co/h5/img/logo.12b2d5a6.png"),
        }),
        praiseImageProvider: const AssetImage("assets/images/icon_duck.png"),
        onTap: (DanmuItem danmuItem) {
          setState(() {
            print('LiuShuai: onTap selectedText = ${danmuItem.text}');
            selectedText = danmuItem.text;
          });
        });

    danmuController.setDuration(duration);

    textController = TextEditingController()..text = '[饭角]';
  }

  @override
  void dispose() {
    danmuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: const Text('Danmu example'),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FanjiaoDanmuWidget(
                size: const Size(375, 300),
                danmuController: danmuController,
              ),
              danmuButton,
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) {
                          danmuController.addDanmu(DanmuModel(
                            id: ++id,
                            text: text,
                            isSelf: true,
                            startTime: danmuController.progress,
                            textStyle: rngTextStyle,
                          ));
                        },
                      ),
                    ),
                    SizedBox(
                        width: 100,
                        height: 40,
                        child: TextButton(
                            onPressed: () {
                              danmuController.addDanmu(DanmuModel(
                                id: ++id,
                                text: textController.text,
                                isSelf: true,
                                startTime: danmuController.progress,
                                textStyle: rngTextStyle,
                              ));
                            },
                            child: const Text("发送"))),
                  ],
                ),
              ),
              filterButton,
              Container(
                color: Colors.greenAccent,
                constraints: const BoxConstraints(minHeight: 40),
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: Text(
                  selectedText,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get filterButton => Wrap(
        spacing: 8.0, // gap between adjacent chips
        runSpacing: 4.0, // gap between lines
        children: [
          SwitchButton(
            "滚动",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFilter.scroll);
            },
            isTurnOn: danmuController.filter.isScroll,
          ),
          SwitchButton(
            "顶部",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFilter.top);
            },
            isTurnOn: danmuController.filter.isTop,
          ),
          SwitchButton(
            "底部",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFilter.bottom);
            },
            isTurnOn: danmuController.filter.isBottom,
          ),
          SwitchButton(
            "彩色",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFilter.colorful);
            },
            isTurnOn: danmuController.filter.isColorful,
          ),
          SwitchButton(
            "高级",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFilter.advanced);
            },
            isTurnOn: danmuController.filter.isAdvanced,
          ),
          SwitchButton(
            "重复",
            (isTurnOn) {
              danmuController.markRepeated();
              danmuController.changeFilter(DanmuFilter.repeated);
            },
            isTurnOn: danmuController.filter.isRepeated,
          ),
          SwitchButton(
            "播放/暂停",
            (isTurnOn) {
              isPlaying = isTurnOn;
              if (isTurnOn) {
                danmuController.start();
              } else {
                danmuController.pause();
              }
            },
            isTurnOn: danmuController.filter.isRepeated,
          ),
        ],
      );

  Widget get danmuButton => Wrap(
        spacing: 8.0, // gap between adjacent chips
        runSpacing: 4.0, //
        alignment: WrapAlignment.start, //p between lines
        children: [
          getButton(
            "普通",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                startTime: danmuController.progress,
              ));
            },
          ),
          getButton(
            "随机彩色",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                startTime: danmuController.progress,
                textStyle: rngTextStyle,
                flag: DanmuFilter.colorful | DanmuFilter.scroll,
              ));
            },
          ),
          getButton(
            "高赞",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                isHighPraise: true,
                startTime: danmuController.progress,
              ));
            },
          ),
          getButton(
            "顶部",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                startTime: danmuController.progress,
                flag: DanmuFilter.top,
              ));
            },
          ),
          getButton(
            "底部",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                startTime: danmuController.progress,
                flag: DanmuFilter.bottom,
              ));
            },
          ),
          getButton(
            "高级",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                startTime: danmuController.progress,
                textStyle: rngTextStyle,
                flag: DanmuFilter.advanced,
              ));
            },
          ),
          getButton(
            "我的",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                isSelf: true,
                startTime: danmuController.progress,
                textStyle: rngTextStyle,
              ));
            },
          ),
          getButton(
            "3秒前",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: '3秒前',
                startTime: danmuController.progress - 3,
                textStyle: rngTextStyle,
              ));
            },
          ),
          getButton(
            "[bilibili]",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: '[bilibili]',
                startTime: danmuController.progress,
                textStyle: rngTextStyle,
              ));
            },
          ),
          getButton(
            "[饭角]",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: '[饭角]',
                startTime: danmuController.progress,
                textStyle: rngTextStyle,
              ));
            },
          ),
        ],
      );

  Widget getButton(String name, Function() onTap,
      {Color color = Colors.redAccent}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints.loose(const Size(82, 40)),
        color: color,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Text(
          name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class SwitchButton extends StatefulWidget {
  final String text;
  final bool isTurnOn;
  final Function(bool) onTap;

  const SwitchButton(
    this.text,
    this.onTap, {
    Key? key,
    this.isTurnOn = true,
  }) : super(key: key);

  @override
  State<SwitchButton> createState() => _SwitchButtonState();
}

class _SwitchButtonState extends State<SwitchButton> {
  bool isTurnOn = true;

  @override
  void initState() {
    super.initState();
    isTurnOn = widget.isTurnOn;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap.call(isTurnOn);
        setState(() {
          isTurnOn = !isTurnOn;
        });
      },
      child: Container(
        constraints: BoxConstraints.loose(const Size(82, 40)),
        color: isTurnOn ? Colors.amber : Colors.grey,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Text(
          widget.text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
