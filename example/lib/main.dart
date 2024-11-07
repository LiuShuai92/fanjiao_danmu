import 'dart:async';
import 'dart:ui' as ui;

import 'package:fanjiao_danmu/fanjiao_danmu/adapter/fanjiao_danmu_adapter.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/danmu_tooltip.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/fanjiao_danmu.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/widget/bubble_box_widget.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/widget/stroke_text_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'jushou_danmu.dart';
import 'my_danmu_model.dart';
import 'my_thumb_shape.dart';
import 'my_track_shape.dart';
import 'utils.dart';
import 'view/path_animation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with FanjiaoDanmuTooltipMixin {
  late DanmuController<MyDanmuModel> danmuController;
  late TextEditingController textController;
  static const Map<String, ImageProvider<Object>> imageMap = {
    '[举手]': AssetImage("assets/images/ic_jy.png"),
    '[bilibili]': AssetImage("assets/images/bilibili.png"),
    '[饭角]': NetworkImage("https://www.fanjiao.co/h5/img/logo.12b2d5a6.png"),
  };

  // Timer? timer;
  Duration duration = const Duration(seconds: 3780);
  bool isPlaying = false;
  int id = 0;
  String selectedText = '';
  List<Widget> otherChildren = [];

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    danmuController = DanmuController(
      adapter: FanjiaoDanmuAdapter(
        rowHeight: 50,
        imageMap: imageMap,
      ),
      onTap: (DanmuItem? danmuItem, Offset position) {
        if (danmuController.isSelected) {
          danmuController.clearSelection(true);
          return false;
        }
        if (danmuItem == null) {
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
      buildOtherChildren: (children) {
        Future.delayed(Duration.zero, () {
          setState(() {
            otherChildren = children;
          });
        });
      },
    );
    danmuController.setDuration(duration);
    textController = TextEditingController()..text = '[饭角]';
  }

  @override
  Widget build(BuildContext context) {
    double radius = params["边框圆角"] ?? 8;
    double strokeWidth = params["边框宽度"] ?? 1.2;
    double pointerBias = params["偏移"] ?? 0.8;
    double pointerWidth = params["指针宽度"] ?? 10;
    double pointerHeight = params["指针高度"] ?? 6;
    double peakRadius = params["顶点圆角"] ?? 3;
    double width = params["宽"] ?? 160;
    double height = params["高"] ?? 36;
    bool testIsUpward = params["朝上"] ?? true;
    double leading = params["leading"] ?? 1;
    double textLineHeight = params["行高"] ?? 1.5;
    double fontSize = params["字号"] ?? 16;
    double maxWidth = params["最大宽度"] ?? 200;
    int maxLines = params["最大行数"] ?? 3;
    double borderPadding = params["边距"] ?? 4;

    return MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: const Text('Danmu example'),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  LayoutBuilder(builder: (context, constraints) {
                    var maxWidth = constraints.maxWidth;
                    if (maxWidth == 0) {
                      maxWidth = ui.window.physicalSize.width /
                          ui.window.devicePixelRatio;
                    }
                    return Container(
                      color: Colors.greenAccent,
                      height: 300,
                      child: RepaintBoundary(
                        child: DanmuWidget(
                          width: maxWidth,
                          height: 300,
                          danmuController: danmuController,
                          tooltip: tooltip,
                        ),
                      ),
                    );
                  }),
                  danmuButton,
                  editDanmu(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                    width: double.infinity,
                    child: const Text(
                      "过滤条件:",
                      style: TextStyle(color: Colors.black87, fontSize: 16),
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
                  Container(
                    color: Colors.amber,
                    height: 200,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            "assets/images/image_background.webp",
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          height: height,
                          width: width,
                          child: BubbleBox(
                            isUpward: testIsUpward,
                            pointerBias: pointerBias,
                            strokeWidth: strokeWidth,
                            borderRadius: radius,
                            pointerWidth: pointerWidth,
                            pointerHeight: pointerHeight,
                            peakRadius: peakRadius,
                            isWrapped: false,
                            filter: ui.ImageFilter.blur(
                              sigmaX: 8,
                              sigmaY: 8,
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: testIsUpward ? pointerHeight : 0,
                                bottom: testIsUpward ? 0 : pointerHeight,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 36,
                                    child: OverflowBox(
                                      maxWidth: 30,
                                      maxHeight: 36,
                                      alignment: Alignment.bottomCenter,
                                      child: Image.asset(
                                        "assets/images/ic_jy.png",
                                        width: 30,
                                        height: 36,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: const Text(
                                              '加一',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  decoration:
                                                      TextDecoration.none,
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1.0,
                                          alignment: Alignment.center,
                                          child: Container(
                                            width: 1.0,
                                            height: 12.0,
                                            color:
                                                Colors.white.withOpacity(0.19),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: const Text(
                                              '复制',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  decoration:
                                                      TextDecoration.none,
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1.0,
                                          alignment: Alignment.center,
                                          child: Container(
                                            width: 1.0,
                                            height: 12.0,
                                            color:
                                                Colors.white.withOpacity(0.19),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: const Text(
                                              '举报',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  decoration:
                                                      TextDecoration.none,
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SwitchItem(
                    "朝上",
                    (isTurnOn) {
                      setState(() {
                        params["朝上"] = isTurnOn;
                      });
                    },
                    isTurnOn: testIsUpward,
                  ),
                  slider("偏移", pointerBias, 0, 1),
                  slider("顶点圆角", peakRadius, 0, 20),
                  slider("指针宽度", pointerWidth, 0, 50),
                  slider("指针高度", pointerHeight, 0, 40),
                  slider("边框圆角", radius, 0, 50),
                  slider("边框宽度", strokeWidth, 0, 10),
                  slider("宽", width, 0, 300),
                  slider("高", height, 0, 200),
                  Container(
                    height: 500,
                    alignment: Alignment.center,
                    child: StrokeTextWidget(
                      '1 要画在文本附"近的装"饰(如下划线)要画在asdasdasdasdasdasd文本附"近的装"饰(如下划线)要画在文本附"近的装"饰(如下划线)要画在文本附"近的装"饰(如下划线)',
                      textAlign: TextAlign.center,
                      strutStyle: StrutStyle(
                          // forceStrutHeight: true,
                          height: textLineHeight,
                          leading: leading),
                      strokeColor: const Color(0xFF836BFF),
                      textScaleFactor: 1.0,
                      strokeWidth: 1,
                      textDecorationPadding: borderPadding,
                      maxLines: maxLines.toInt(),
                      maxWidth: maxWidth,
                      textDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          color: const Color(0XFF000000).withOpacity(0.4)),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: fontSize,
                        decoration: TextDecoration.none,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  slider("字号", fontSize, 5, 40),
                  slider("行高", textLineHeight, 0, 5),
                  slider("leading", leading, 0, 5),
                  slider("最大宽度", maxWidth, 50, 300),
                  slider("最大行数", maxLines, 1, 10),
                  slider("边距", borderPadding, 0, 10),
                  const SizedBox(height: 100, width: 0),
                ],
              ),
            ),
            ...otherChildren,
          ],
        ),
      ),
    );
  }

  SizedBox editDanmu() {
    return SizedBox(
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
                danmuController.addDanmu(MyDanmuModel(
                  id: ++id,
                  likeCount: 10,
                  text: text,
                  decoration: const BoxDecoration(
                    color: Color(0xCCFF9C6B),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    border: Border.fromBorderSide(BorderSide(
                        color: Colors.white,
                        width: 1,
                        style: BorderStyle.solid)),
                  ),
                  startTime: danmuController.progress,
                  textStyle: rngTextStyle,
                  flag: DanmuFlag.announcement | DanmuFlag.collisionFree,
                ));
              },
            ),
          ),
          SizedBox(
            width: 100,
            height: 40,
            child: TextButton(
              onPressed: () {
                danmuController.addDanmu(MyDanmuModel(
                  id: ++id,
                  text: textController.text,
                  flag: DanmuFlag.scroll | DanmuFlag.collisionFree,
                  decoration: const BoxDecoration(
                    color: Color(0xCCFF9C6B),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    border: Border.fromBorderSide(BorderSide(
                        color: Colors.white,
                        width: 1,
                        style: BorderStyle.solid)),
                  ),
                  startTime: danmuController.progress,
                ));
              },
              child: const Text("发送"),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> params = {};

  Widget slider<T extends num>(
      String name, T initialValue, double min, double max) {
    double? currentValue = params[name]?.toDouble();
    if (currentValue == null) {
      params[name] = initialValue;
      currentValue = initialValue.toDouble();
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$name: ${currentValue.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.black87),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              overlayColor: const Color(0x1A836BFE),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackShape: const MyTrackShape(),
              thumbShape: const MyThumbShape(),
              trackHeight: 4,
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: currentValue,
              onChanged: (double value) {
                setState(() {
                  if (initialValue is int) {
                    params[name] = value.toInt();
                  } else {
                    params[name] = value;
                  }
                });
              },
              label: params[name].toString(),
              min: min,
              max: max,
            ),
          ),
        ],
      ),
    );
  }

  Widget get danmuButton => Wrap(
        spacing: 8.0, // gap between adjacent chips
        runSpacing: 4.0, //
        alignment: WrapAlignment.start, //p between lines
        children: [
          getButton(
            "测试",
            () {
              int likeCount = 101;
              String text = rngText;
              danmuController.addDanmu(MyDanmuModel(
                id: ++id,
                likeCount: likeCount,
                text: text,
                alignment: Alignment.bottomCenter,
                margin: const EdgeInsets.only(top: 6, right: 10),
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                decoration: const BoxDecoration(
                  color: Color(0x66000000),
                  border: Border(
                    left: BorderSide(
                        color: Color(0x66FFFFFF),
                        strokeAlign: BorderSide.strokeAlignOutside),
                    top: BorderSide(
                        color: Color(0x66FFFFFF),
                        strokeAlign: BorderSide.strokeAlignOutside),
                    right: BorderSide(
                        color: Color(0x66FFFFFF),
                        strokeAlign: BorderSide.strokeAlignOutside),
                    bottom: BorderSide(
                        color: Color(0x66FFFFFF),
                        strokeAlign: BorderSide.strokeAlignOutside),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                spans: buildTestItemSpans(text, id, likeCount),
                startTime: danmuController.progress,
              ));
            },
          ),
          getButton(
            "普通",
            () {
              danmuController.addDanmu(MyDanmuModel(
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
              danmuController.addDanmu(MyDanmuModel(
                id: ++id,
                text: rngText,
                startTime: danmuController.progress,
                textStyle: rngTextStyle,
                flag:
                    DanmuFlag.colorful | DanmuFlag.scroll | DanmuFlag.clickable,
              ));
            },
          ),
          getButton(
            "全屏弹幕",
            () {
              danmuController.clearDanmu(DanmuFlag.otherStage);
              var list = globalDanmus("来啦来啦！！期待下一集！", danmuController.progress);
              danmuController.addAllDanmu(list);
            },
          ),
          getButton(
            "顶部",
            () {
              danmuController.addDanmu(MyDanmuModel(
                id: ++id,
                text: rngText,
                startTime: danmuController.progress,
                flag: DanmuFlag.top | DanmuFlag.clickable,
              ));
            },
          ),
          getButton(
            "底部",
            () {
              danmuController.addDanmu(MyDanmuModel(
                id: ++id,
                text: rngText,
                startTime: danmuController.progress,
                flag: DanmuFlag.bottom | DanmuFlag.clickable,
              ));
            },
          ),
          getButton(
            "高级",
            () {
              danmuController.addDanmu(MyDanmuModel(
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
              danmuController.addDanmu(MyDanmuModel(
                id: ++id,
                text: rngText,
                decoration: const BoxDecoration(
                  color: Color(0xCCFF9C6B),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  border: Border.fromBorderSide(BorderSide(
                      color: Colors.white, width: 1, style: BorderStyle.solid)),
                ),
                startTime: danmuController.progress,
                textStyle: rngTextStyle,
                flag: DanmuFlag.collisionFree,
              ));
            },
          ),
          getButton(
            "公告",
            () {
              danmuController.addDanmu(MyDanmuModel(
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
              danmuController.addDanmu(MyDanmuModel(
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
              danmuController.addDanmu(MyDanmuModel(
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
              danmuController.addDanmu(MyDanmuModel(
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

  List<InlineSpan> buildTestItemSpans(String text, int id, int likeCount,
      [bool isJushou = false]) {
    onTap() {
      var danmuItem = danmuController.getItem(id);
      if (danmuItem != null) {
        if (!danmuController.isSelected && danmuItem.flag.isClickable) {
          updatePlusOneItem(danmuItem);
          HapticFeedback.vibrate();
        }
      }
    }

    return [
      TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: onTap,
            child: OverflowBox(
              maxWidth: 30,
              maxHeight: 36,
              alignment: Alignment.bottomCenter,
              child: isJushou
                  ? JushouDanmu()
                  : Image.asset(
                      "assets/images/ic_jy.png",
                      width: 30,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ),
      ),
      TextSpan(
        text: "+$likeCount",
        recognizer: TapGestureRecognizer()..onTap = onTap,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    ];
  }

  void updatePlusOneItem(DanmuItem<MyDanmuModel> danmuItem) {
    var model = danmuItem.model;
    var id = model.id;
    var likeCount = model.likeCount + 1;
    danmuItem.pause();
    Future.delayed(const Duration(seconds: 3), () {
      danmuItem.play();
    });
    danmuItem.flag = danmuItem.flag.removeClickable.addOverlay;
    var danmuModel = model.copyWith(
      likeCount: likeCount,
      isLiked: true,
      alignment: Alignment.bottomCenter,
      margin: const EdgeInsets.only(top: 6, right: 10),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC09DF6), Color(0xFF836BFF)],
        ),
        border: Border(
          left: BorderSide(
              color: Color(0x66FFFFFF),
              strokeAlign: BorderSide.strokeAlignOutside),
          top: BorderSide(
              color: Color(0x66FFFFFF),
              strokeAlign: BorderSide.strokeAlignOutside),
          right: BorderSide(
              color: Color(0x66FFFFFF),
              strokeAlign: BorderSide.strokeAlignOutside),
          bottom: BorderSide(
              color: Color(0x66FFFFFF),
              strokeAlign: BorderSide.strokeAlignOutside),
        ),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      spans: buildTestItemSpans(danmuItem.model.text, id, likeCount, true),
    );
    var time = danmuItem.simulation.duration / 2;
    danmuController.updateItem(danmuItem, danmuModel, time: time);
  }

  Widget get filterButton => GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 4,
        ),
        children: [
          SwitchItem(
            "滚动",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFlag.scroll);
            },
            isTurnOn: danmuController.filter.isScroll,
          ),
          SwitchItem(
            "顶部",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFlag.top);
            },
            isTurnOn: danmuController.filter.isTop,
          ),
          SwitchItem(
            "底部",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFlag.bottom);
            },
            isTurnOn: danmuController.filter.isBottom,
          ),
          SwitchItem(
            "彩色",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFlag.colorful);
            },
            isTurnOn: danmuController.filter.isColorful,
          ),
          SwitchItem(
            "高级",
            (isTurnOn) {
              danmuController.changeFilter(DanmuFlag.advanced);
            },
            isTurnOn: danmuController.filter.isAdvanced,
          ),
          SwitchItem(
            "重复",
            (isTurnOn) {
              danmuController.markRepeated();
              danmuController.changeFilter(DanmuFlag.repeated);
            },
            isTurnOn: danmuController.filter.isRepeated,
          ),
          SwitchItem(
            isPlaying ? "播放" : "暂停",
            (isTurnOn) {
              isPlaying = isTurnOn;
              if (isTurnOn) {
                danmuController.start();
              } else {
                danmuController.pause();
              }
            },
            isTurnOn: isPlaying,
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
  Size get tooltipSize => const Size(160, 36);

  @override
  Widget get tooltipContent => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              if (danmuController.isSelected) {
                var danmuItem = danmuController.selected!;
                updatePlusOneItem(danmuItem);
                danmuController.clearSelection();
              }
            },
            child: SizedBox(
              width: 26,
              height: 36,
              child: OverflowBox(
                maxWidth: 30,
                maxHeight: 36,
                alignment: Alignment.bottomRight,
                child: Image.asset(
                  "assets/images/ic_jy.png",
                  width: 30,
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
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
                        var danmuItem = danmuController.selected!;
                        updatePlusOneItem(danmuItem);
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
                    height: 12.0,
                    color: Colors.white.withOpacity(0.19),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        '复制',
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
                      danmuController.clearSelection(true);
                    },
                    behavior: HitTestBehavior.opaque,
                  ),
                ),
                Container(
                  width: 1.0,
                  alignment: Alignment.center,
                  child: Container(
                    width: 1.0,
                    height: 12.0,
                    color: Colors.white.withOpacity(0.19),
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
                      danmuController.clearSelection(true);
                    },
                    behavior: HitTestBehavior.opaque,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class SwitchItem extends StatefulWidget {
  final String text;
  final bool isTurnOn;
  final Function(bool) onTap;

  const SwitchItem(
    this.text,
    this.onTap, {
    Key? key,
    this.isTurnOn = true,
  }) : super(key: key);

  @override
  State<SwitchItem> createState() => _SwitchItemState();
}

class _SwitchItemState extends State<SwitchItem> {
  bool isTurnOn = true;

  @override
  void initState() {
    super.initState();
    isTurnOn = widget.isTurnOn;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      color: isTurnOn ? Colors.amber : Colors.grey,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.text,
            style: const TextStyle(color: Colors.white),
          ),
          Switch(
              value: isTurnOn,
              onChanged: (value) {
                widget.onTap.call(value);
                setState(() {
                  isTurnOn = value;
                });
              })
        ],
      ),
    );
  }
}

class PathAnimationDemo extends StatefulWidget {
  @override
  _PathAnimationDemoState createState() => _PathAnimationDemoState();
}

class _PathAnimationDemoState extends State<PathAnimationDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: PathPainter(_animation),
      ),
    );
  }
}
