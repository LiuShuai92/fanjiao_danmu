import 'dart:async';

import 'package:fanjiao_danmu/fanjiao_danmu/adapter/fanjiao_danmu_adapter.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/danmu_tooltip.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/fanjiao_danmu.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/widget/stroke_text_widget.dart';
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

class _MyAppState extends State<MyApp> with FanjiaoDanmuTooltipMixin {
  late DanmuController danmuController;
  late TextEditingController textController;
  Timer? timer;
  Duration duration = const Duration(seconds: 3780);
  bool isPlaying = false;
  int id = 0;
  String selectedText = '';

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    danmuController = DanmuController(
      adapter: FanjiaoDanmuAdapter(rowHeight: 40, imageMap: {
        '[举手]': const AssetImage("assets/images/ic_jy.png"),
        '[bilibili]': const AssetImage("assets/images/bilibili.png"),
        '[饭角]': const NetworkImage(
            "https://www.fanjiao.co/h5/img/logo.12b2d5a6.png"),
      }),
      praiseImageProvider: const AssetImage("assets/images/icon_duck.png"),
      onTap: (DanmuItem? danmuItem, Offset position) {
        if (danmuController.isSelected) {
          danmuController.clearSelection();
          return false;
        }
        if (danmuItem == null || danmuItem.flag.isAnnouncement) {
          return false;
        }
        var result =
            checkSelect(position, danmuItem.rect, danmuController.adapter.rect);
        if (result) {
          setState(() {
            selectedText = danmuItem.model.text;
          });
        }
        return result;
      },
    );

    danmuController.setDuration(duration);

    textController = TextEditingController()..text = '[饭角]';
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
              Container(
                color: Colors.greenAccent,
                child: LayoutBuilder(builder: (context, constraints) {
                  return DanmuWidget(
                    size: Size(constraints.maxWidth, 300),
                    danmuController: danmuController,
                    tooltip: tooltip,
                  );
                }),
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
                            isMine: true,
                            startTime: danmuController.progress,
                            textStyle: rngTextStyle,
                            flag: DanmuFlag.announcement |
                                DanmuFlag.collisionFree,
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
                                isMine: true,
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
              danmuController.changeFilter(DanmuFlag.scroll);
            },
            isTurnOn: danmuController.filter.isScroll,
          ),
          SwitchButton(
            "顶部",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFlag.top);
            },
            isTurnOn: danmuController.filter.isTop,
          ),
          SwitchButton(
            "底部",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFlag.bottom);
            },
            isTurnOn: danmuController.filter.isBottom,
          ),
          SwitchButton(
            "彩色",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFlag.colorful);
            },
            isTurnOn: danmuController.filter.isColorful,
          ),
          SwitchButton(
            "高级",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFlag.advanced);
            },
            isTurnOn: danmuController.filter.isAdvanced,
          ),
          SwitchButton(
            "重复",
            (isTurnOn) {
              danmuController.markRepeated();
              danmuController.changeFilter(DanmuFlag.repeated);
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
            isTurnOn: !isPlaying,
          ),
        ],
      );

  Widget get danmuButton => Wrap(
        spacing: 8.0, // gap between adjacent chips
        runSpacing: 4.0, //
        alignment: WrapAlignment.start, //p between lines
        children: [
          getButton(
            "测试",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: "晚安",
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF836BFF), Color(0xFFC09DF6)],
                  ),
                  border: Border(
                    left: BorderSide(color: Color(0x66FFFFFF)),
                    top: BorderSide(color: Color(0x66FFFFFF)),
                    right: BorderSide(color: Color(0x66FFFFFF)),
                    bottom: BorderSide(color: Color(0x66FFFFFF)),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                spans: [
                  TextSpan(
                      text: "晚安",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      )),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.bottom,
                    child: Container(
                      width: 30,
                      height: 36,
                      margin: const EdgeInsets.only(left: 4, right: 4),
                      child: Image.asset("assets/images/ic_jy.png"),
                    ),
                  ),
                  TextSpan(
                      text: "+101",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      )),
                  WidgetSpan(
                    child: StrokeTextWidget(
                      "来啦来啦！！期待下一集！",
                      textStyle: const TextStyle(
                        fontSize: 26,
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
                      opacity: 0.8,
                      strokeColor: const Color(0xFF41357F),
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xCCFF9C6B),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        border: Border.fromBorderSide(BorderSide(
                            color: Colors.white,
                            width: 1,
                            style: BorderStyle.solid)),
                      ),
                    ),
                  ),
                ],
                startTime: danmuController.progress,
              ));
            },
          ),
          getButton(
            "普通",
                () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                opacity: 0.8,
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
                flag: DanmuFlag.colorful | DanmuFlag.scroll,
              ));
            },
          ),
          getButton(
            "高赞",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                isPraise: true,
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
                flag: DanmuFlag.top,
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
                flag: DanmuFlag.bottom,
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
                flag: DanmuFlag.advanced,
              ));
            },
          ),
          getButton(
            "我的",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                isMine: true,
                startTime: danmuController.progress,
                textStyle: rngTextStyle,
                flag: DanmuFlag.announcement | DanmuFlag.collisionFree,
              ));
            },
          ),
          getButton(
            "公告",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: rngText,
                startTime: danmuController.progress,
                textStyle: rngTextStyle,
                flag: DanmuFlag.announcement,
              ));
            },
          ),
          getButton(
            "3秒前",
            () {
              danmuController.addDanmu(DanmuModel(
                id: ++id,
                text: '3秒前',
                startTime:
                    danmuController.progress - const Duration(seconds: 3),
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
          getButton(
            "1倍速",
            () {
              danmuController.rate = 1;
            },
          ),
          getButton(
            "1.5倍速",
            () {
              danmuController.rate = 1.5;
            },
          ),
          getButton(
            "2倍速",
            () {
              danmuController.rate = 2;
            },
          ),
          getButton(
            "3倍速",
            () {
              danmuController.rate = 3;
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

  @override
  Widget get tooltipContent => Row(
        children: [
          Expanded(
            child: GestureDetector(
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  '加一',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
              ),
              onTap: () {
                if (danmuController.isSelected) {
                  danmuController.addDanmu(DanmuModel(
                    id: ++id,
                    text: danmuController.selected!.model.text,
                    isMine: true,
                    startTime: danmuController.progress,
                  ));
                  danmuController.clearSelection();
                }
              },
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Container(
            width: 1.0,
            alignment: Alignment.center,
            child: Container(
              width: 1.0,
              height: 6.0,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          Expanded(
            child: GestureDetector(
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  '举报',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
              ),
              onTap: () {
                danmuController.clearSelection();
              },
              behavior: HitTestBehavior.opaque,
            ),
          ),
        ],
      );
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
