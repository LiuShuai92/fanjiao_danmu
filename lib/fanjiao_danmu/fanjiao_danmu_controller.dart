import 'dart:collection';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'adapter/danmu_adapter.dart';
import 'fanjiao_danmu_widget.dart';
import 'listener_helpers.dart';
import 'model/danmu_item_model.dart';

class FanjiaoDanmuController<T extends DanmuModel>
    with
        FanjiaoLocalListenersMixin,
        FanjiaoLocalStatusListenersMixin,
        FanjiaoEagerListenerMixin {
  /// return true 选中并暂停这条弹幕
  final bool Function(DanmuItem<T>, Offset)? onTap;
  final Map<ImageProvider, ImgInfo> _imagesPool = {};
  final List<DanmuItem<T>> _tempList = <DanmuItem<T>>[];
  final ImageProvider? praiseImageProvider;
  Duration startTime = Duration.zero;
  Duration? endTime;
  Queue<DanmuItem<T>> danmuItems = Queue<DanmuItem<T>>();
  DanmuStatus _status = DanmuStatus.stop;
  DanmuStatus _lastReportedStatus = DanmuStatus.dismissed;
  DanmuAdapter<T> adapter;
  int maxSize;
  int filter;

  ///秒
  late double _progress;
  DanmuItem<T>? selected;
  Ticker? _ticker;
  ImgInfo? _iconPraise;
  Duration? _lastElapsedDuration;

  double get progress => _progress;

  DanmuStatus get state => _status;

  bool get isSelected => selected != null;

  ///秒
  set progress(double progress) {
    assert(progress != null);
    clearDanmu();
    _internalSetValue(progress);
    notifyListeners();
    _checkStatusChanged();
  }

  bool get isAnimating => _ticker != null && _ticker!.isActive;

  FanjiaoDanmuController({
    required this.adapter,
    this.maxSize = 100,
    this.onTap,
    this.praiseImageProvider,
    this.filter = DanmuFlag.all,
  });

  setDuration(Duration duration, {
    Duration startTime = Duration.zero,
  }) {
    this.startTime = startTime;
    endTime = startTime + duration;
    _lastElapsedDuration = startTime;
    _progress = startTime.inMicroseconds / Duration.microsecondsPerSecond;
  }

  clearDanmu() {
    danmuItems.clear();
    adapter.clear();
    selected = null;
  }

  addImage(BuildContext context, ImageProvider asset) async {
    var image = await loadImage(context, asset);
    if (image != null) {
      _imagesPool[asset] = ImgInfo(image,
          Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()));
      notifyListeners();
    }
  }

  ImgInfo? getImage(BuildContext context, ImageProvider? asset) {
    if (asset == null) {
      return null;
    }
    if (_imagesPool[asset] == null) {
      _imagesPool[asset] = ImgInfo.empty;
      addImage(context, asset);
      return null;
    } else {
      return _imagesPool[asset];
    }
  }

  ImgInfo? iconPraise(BuildContext context) {
    _iconPraise = getImage(context, praiseImageProvider);
    return _iconPraise;
  }

  setup(BuildContext context, TickerProvider vsync, Rect rect) {
    _ticker = vsync.createTicker(_tick);
    adapter.initData(rect);
  }

  _tick(Duration elapsed) {
    Duration dElapsed = elapsed - (_lastElapsedDuration ?? startTime);
    _lastElapsedDuration = elapsed;
    if ((_status == DanmuStatus.pause && dElapsed > Duration.zero) ||
        dElapsed == Duration.zero) {
      return;
    }
    final double dTime =
        dElapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _progress += dTime;
    assert(progress >= 0.0);
    _internalSetValue(progress);
    if (state == DanmuStatus.completed) {
      _checkStatusChanged();
      clearDanmu();
      notifyListeners();
      return;
    }
    if (danmuItems.isEmpty) {
      return;
    }
    for (var entry in danmuItems) {
      if (entry.position == null) {
        entry.dTime = _progress - entry.startTime;
        entry.position = entry.simulation.offset(_progress - entry.startTime);
      } else {
        Offset? position;
        if (entry.isSelected) {
          position = entry.simulation.isDone(entry.position!, 0);
        } else {
          position = entry.simulation.isDone(entry.position!, dTime);
        }
        if (position == null) {
          _tempList.add(entry);
        } else if (!entry.isSelected) {
          entry.position = position;
        }
      }
    }
    for (var element in _tempList) {
      danmuItems.remove(element);
      adapter.removeItem(element);
    }
    _tempList.clear();
    if (danmuItems.isEmpty) {
      _status = DanmuStatus.idle;
      _checkStatusChanged();
    }
    notifyListeners();
  }

  clearSelection() {
    if (selected != null) {
      selected!.isSelected = false;
      selected = null;
    }
    notifyListeners();
  }

  tapPosition(Offset position) {
    if (isSelected) {
      clearSelection();
      return;
    }
    DanmuItem<T>? selectedTemp;
    for (var entry in danmuItems) {
      if (entry.rect.contains(position)) {
        selectedTemp = entry;
        break;
      }
    }
    if (selectedTemp != null) {
      if (onTap?.call(selectedTemp, position) ?? false) {
        selectedTemp.isSelected = true;
        selected = selectedTemp;
      } else {
        selected = null;
      }
    }
    notifyListeners();
  }

  markRepeated() {
    List<String> temp = [];
    for (var entry in danmuItems) {
      if (!entry.flag.isAnnouncement && temp.contains(entry.text)) {
        ///不去重 高级弹幕 自己发的弹幕 高点赞数的弹幕
        if (!entry.flag.isAdvanced && !entry.isMine && !entry.isHighPraise) {
          entry.flag = entry.flag.addRepeated;
        }
      } else {
        entry.flag = entry.flag.removeRepeated;
        temp.add(entry.text);
      }
    }
  }

  _addEntry(T model) {
    if (model.text.isEmpty) {
      return;
    }
    if (endTime != null &&
        model.startTime >
            endTime!.inMilliseconds / Duration.millisecondsPerSecond) {
      return;
    }
    if (danmuItems.length > maxSize) {
      return;
    }
    for (var element in danmuItems) {
      if (element.id == model.id) {
        return;
      }
      if (!filter.isRepeated) {
        if (element.text == model.text) {
          return;
        }
      }
    }
    if (filter.check(model.flag)) {
      var item = adapter.getItem(model);
      if (item != null) {
        danmuItems.add(item);
      }
    }
  }

  addDanmu(T model) {
    assert(_ticker != null);
    if (model.text.isEmpty) {
      return;
    }
    _addEntry(model);
    if (danmuItems.isNotEmpty && isAnimating && _status == DanmuStatus.idle) {
      _status = DanmuStatus.playing;
      _checkStatusChanged();
    }
  }

  addAllDanmu(Iterable<T> models) {
    assert(_ticker != null);
    if (danmuItems.length > maxSize) {
      return;
    }
    for (var model in models) {
      _addEntry(model);
    }
    if (danmuItems.isNotEmpty && isAnimating && _status == DanmuStatus.idle) {
      _status = DanmuStatus.playing;
      _checkStatusChanged();
    }
  }

  ///秒
  void _internalSetValue(double progress) {
    var newProgress = progress * Duration.microsecondsPerSecond;
    if (endTime != null && newProgress > endTime!.inMicroseconds) {
      _progress =
          endTime!.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
      _status = DanmuStatus.completed;
    } else if (newProgress < startTime.inMicroseconds) {
      _progress =
          startTime.inMilliseconds.toDouble() / Duration.microsecondsPerSecond;
      _status = DanmuStatus.playing;
    } else {
      _progress = progress;
      _status = DanmuStatus.playing;
    }
  }

  pause() {
    assert(_ticker != null);
    _status = DanmuStatus.pause;
    _checkStatusChanged();
  }

  start() {
    assert(_ticker != null);
    if (!_ticker!.isActive) {
      final TickerFuture result = _ticker!.start();
    }
    _status = DanmuStatus.playing;
    _checkStatusChanged();
  }

  stop({bool canceled = true}) {
    assert(_ticker != null);
    _status = DanmuStatus.stop;
    danmuItems.clear();
    _lastElapsedDuration = null;
    _checkStatusChanged();
    _ticker!.stop(canceled: canceled);
  }

  /// flag [DanmuFlag]
  changeFilter(int flag, {bool? need}) {
    if (need == null) {
      filter = filter.change(flag);
    } else if (need) {
      filter = filter.add(flag);
    } else {
      filter = filter.remove(flag);
    }
    notifyListeners();
  }

  _checkStatusChanged() {
    final DanmuStatus newStatus = state;
    if (_lastReportedStatus != newStatus) {
      _lastReportedStatus = newStatus;
      notifyStatusListeners(newStatus);
    }
  }

  @override
  dispose() {
    assert(() {
      if (_ticker == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'FanjiaoDanmuController.dispose() called more than once.'),
          ErrorDescription(
              'A given $runtimeType cannot be disposed more than once.\n'),
          DiagnosticsProperty<FanjiaoDanmuController>(
            'The following $runtimeType object was disposed multiple times',
            this,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ]);
      }
      return true;
    }());
    clearDanmu();
    _ticker!.dispose();
    _ticker = null;
    _imagesPool.clear();
    clearStatusListeners();
    clearListeners();
    super.dispose();
  }
}

mixin DanmuTooltipMixin{

  Rect? _menuRect;

  Rect get menuRect => _menuRect ?? Rect.zero;

  double? _menupeak;

  double get menupeak => _menupeak ?? 0;

  bool? _menuIsAbove;

  bool get menuIsAbove => _menuIsAbove ?? false;

  Size get menuSize => const Size(96, 35);

  Widget get tooltipContent;

  bool isSelect(DanmuItem danmuItem, Offset position, Rect rect) {
    double x, y;
    if (danmuItem.rect.left >
        rect.right - danmuItem.size.height ||
        danmuItem.rect.right <
            rect.left + danmuItem.size.height) {
      return false;
    }
    x = (position.dx - menuSize.width / 2)
        .clamp(0, rect.right - menuSize.width);
    _menuIsAbove = danmuItem.rect.bottom >
        rect.bottom - menuSize.height;
    if (menuIsAbove) {
      y = danmuItem.rect.top - menuSize.height;
    } else {
      y = danmuItem.rect.bottom;
    }
    Offset offset = Offset(x, y);
    _menuRect = offset & menuSize;
    _menupeak = position.dx.clamp(
        math.max(danmuItem.rect.left, rect.left) +
            danmuItem.size.height / 2,
        math.min(danmuItem.rect.right, rect.right) -
            danmuItem.size.height / 2) -
        menuRect.left;
    return true;
  }

  Positioned tooltip() {
    Positioned widget;
    List<Widget>? children;
    if (menuIsAbove) {
      children = [
        Container(
          width: menuSize.width,
          height: menuSize.height - 5,
          decoration: const BoxDecoration(image: DecorationImage(
              image: AssetImage('assets/images/danmu_report.png'))),
          child: tooltipContent,
        ),
        Padding(
          padding: EdgeInsets.only(left: menupeak - 5),
          child: Image.asset(
            'assets/images/danmu_report_arrow_down.png',
            width: 11,
            height: 5,
          ),
        ),
      ];
    } else {
      children = [
        Padding(
          padding: EdgeInsets.only(left: menupeak - 5),
          child: Image.asset(
            'assets/images/danmu_report_arrow_up.png',
            width: 11,
            height: 5,
          ),
        ),
        Container(
          width: menuSize.width,
          height: menuSize.height - 5,
          decoration: const BoxDecoration(image: DecorationImage(
              image: AssetImage('assets/images/danmu_report.png'))),
          child: tooltipContent,
        ),
      ];
    }
    widget = Positioned(
      left: menuRect.left,
      top: menuRect.top,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
    return widget;
  }
}

typedef DanmuStatusListener = Function(DanmuStatus status);

enum DanmuStatus {
  dismissed,
  playing,
  pause,
  idle,
  completed,
  stop,
}

class ImgInfo {
  final ui.Image? image;
  final Rect? rect;
  static const ImgInfo empty = ImgInfo(null, null);

  bool get isEmpty => image == null;

  const ImgInfo(this.image, this.rect);
}

extension DanmuFlag on int {
  ///普通的滚动弹幕
  static const int scroll = 1;

  ///固定从顶部中间往下开始排序的弹幕
  static const int top = 1 << 1;

  ///固定从底部中间往上开始排序的弹幕
  static const int bottom = 1 << 2;

  ///高级弹幕
  static const int advanced = 1 << 3;

  ///是否允许重复弹幕出现
  static const int repeated = 1 << 4;

  ///是否允许彩色弹幕
  static const int colorful = 1 << 5;

  ///公告
  static const int announcement = 1 << 6;

  ///全部允许
  static const
  int all = DanmuFlag.scroll |
  DanmuFlag.top |
  DanmuFlag.bottom |
  DanmuFlag.advanced |
  DanmuFlag.repeated |
  DanmuFlag.colorful|
  DanmuFlag.announcement;

  bool check(int flag) => this & flag == flag;

  int add(int flag) => this | flag;

  int remove(int flag) => (this | flag) ^ flag;

  int change(int flag) => this ^ flag;

  bool get isScroll => check(scroll);

  bool get isTop => check(top);

  bool get isBottom => check(bottom);

  bool get isAdvanced => check(advanced);

  bool get isRepeated => check(repeated);

  bool get isColorful => check(colorful);

  bool get isAnnouncement => check(announcement);

  int get addScroll => add(scroll);

  int get addTop => add(top);

  int get addBottom => add(bottom);

  int get addAdvanced => add(advanced);

  int get addRepeated => add(repeated);

  int get addColorful => add(colorful);

  int get addAnnouncement => add(announcement);

  int get removeScroll => remove(scroll);

  int get removeTop => remove(top);

  int get removeBottom => remove(bottom);

  int get removeAdvanced => remove(advanced);

  int get removeRepeated => remove(repeated);

  int get removeColorful => remove(colorful);

  int get removeAnnouncement => remove(announcement);

  int get changeScroll => change(scroll);

  int get changeTop => change(top);

  int get changeBottom => change(bottom);

  int get changeAdvanced => change(advanced);

  int get changeRepeated => change(repeated);

  int get changeColorful => change(colorful);

  int get changeAnnouncement => change(announcement);
}
