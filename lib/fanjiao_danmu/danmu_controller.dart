import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' as foundation;

import 'fanjiao_danmu.dart';
import 'listener_helpers.dart';

class DanmuController<T extends DanmuModel>
    with
        DanmuLocalListenersMixin,
        DanmuLocalStatusListenersMixin,
        DanmuEagerListenerMixin {
  /// return true 选中并暂停这条弹幕
  final bool Function(DanmuItem<T>?, Offset)? onTap;
  final Map<ImageProvider, ImgInfo> _imagesPool = {};
  final List<DanmuItem<T>> _tempList = <DanmuItem<T>>[];
  final ImageProvider? praiseImageProvider;
  Duration startTime = Duration.zero;
  Duration endTime = const Duration(hours: 24);
  Queue<DanmuItem<T>> danmuItems = Queue<DanmuItem<T>>();
  DanmuStatus _status = DanmuStatus.stop;
  DanmuStatus _idleBeforeStatus = DanmuStatus.playing;
  DanmuStatus _lastReportedStatus = DanmuStatus.dispose;
  DanmuAdapter<T> adapter;
  int maxSize;
  int filter;
  DanmuItem<T>? selected;
  Ticker? _ticker;
  ImgInfo? _iconPraise;
  Duration? _progress;
  Duration? _lastElapsedDuration;
  bool _onceForceRefresh = false;
  bool _isFullShown = true;
  bool _isAllFullShown = true;

  /// 弹幕倍速播放
  double rate = 1;

  ///下一桢动画会执行一次强制刷新
  set onceForceRefresh(bool onceForceRefresh) =>
      _onceForceRefresh = onceForceRefresh;

  bool get onceForceRefresh {
    bool result = _onceForceRefresh;
    _onceForceRefresh = false;
    return result;
  }

  DanmuStatus get state => _status;

  bool get isFullShown => _isFullShown;

  bool get isAllFullShown => _isAllFullShown;

  bool get isSelected => selected != null;

  Duration get progress => _progress ?? startTime;

  bool get isEnable => _ticker != null;

  bool get isAnimating => isEnable && _ticker!.isActive;

  set progress(Duration newProgress) {
    Duration oldProgress = _progress ?? startTime;
    _internalSetValue(newProgress);
    _lastElapsedDuration = null;
    if (progress == oldProgress) {
      return;
    }
    _onceForceRefresh = true;
    if (_status == DanmuStatus.idle) {
      _status = _idleBeforeStatus;
    }
    bool isFullShown = true;
    for (var entry in danmuItems) {
      entry.dTime = progress - entry.model.startTime;
      entry.position = entry.simulation
          .offset((progress - entry.model.startTime).inMicrosecondsPerSecond);
      Offset? position = entry.simulation.isDone(entry.position!, 0);
      if (position == null) {
        _tempList.add(entry);
      } else if (!entry.isSelected) {
        entry.position = position;
        if (!entry.simulation.isFullShown) {
          isFullShown = false;
        }
      }
    }
    _isFullShown = isFullShown;
    for (var element in _tempList) {
      danmuItems.remove(element);
      adapter.removeItem(element);
    }
    _tempList.clear();
    if (danmuItems.isEmpty && _status == DanmuStatus.playing) {
      _idleBeforeStatus = _status;
      _status = DanmuStatus.idle;
      _isFullShown = true;
    }
    _checkStatusChanged();
    notifyListeners();
  }

  DanmuController({
    required this.adapter,
    this.maxSize = 100,
    this.onTap,
    this.praiseImageProvider,
    this.filter = DanmuFlag.all,
  });

  setDuration(
    Duration duration, {
    Duration startTime = Duration.zero,
  }) {
    this.startTime = startTime;
    endTime = startTime + duration;
    _progress = startTime;
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
    Duration dElapsed = elapsed - (_lastElapsedDuration ?? elapsed);
    _lastElapsedDuration = elapsed;
    if (_status == DanmuStatus.pause || dElapsed == Duration.zero) {
      return;
    }
    dElapsed *= rate;
    Duration newProgress = progress + dElapsed;
    _internalSetValue(newProgress);
    if (state == DanmuStatus.completed) {
      clearDanmu();
      notifyListeners();
      return;
    }
    if (danmuItems.isEmpty) {
      return;
    }
    bool isFullShown = false;
    bool isAllFullShown = true;
    for (var entry in danmuItems) {
      if (entry.position == null) {
        entry.dTime = progress - entry.model.startTime;
        entry.position = entry.simulation
            .offset((progress - entry.model.startTime).inMicrosecondsPerSecond);
      } else {
        Offset? position;
        if (entry.isSelected) {
          position = entry.simulation.isDone(entry.position!, 0);
        } else {
          position = entry.simulation
              .isDone(entry.position!, dElapsed.inMicrosecondsPerSecond);
        }
        if (position == null) {
          _tempList.add(entry);
        } else if (!entry.isSelected) {
          entry.position = position;
          if (entry.simulation.isFullShown) {
            isFullShown = true;
          } else {
            isAllFullShown = false;
          }
        }
      }
    }
    _isFullShown = isFullShown;
    _isAllFullShown = isAllFullShown;
    for (var element in _tempList) {
      danmuItems.remove(element);
      adapter.removeItem(element);
    }
    _tempList.clear();
    if (danmuItems.isEmpty) {
      _idleBeforeStatus = _status;
      _status = DanmuStatus.idle;
      _isFullShown = true;
    }
    _checkStatusChanged();
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
    DanmuItem<T>? selectedTemp;
    for (var entry in danmuItems) {
      if (entry.rect.contains(position)) {
        selectedTemp = entry;
        break;
      }
    }
    if (selectedTemp != null && filter.check(selectedTemp.flag)) {
      if (onTap?.call(selectedTemp, position) ?? false) {
        selectedTemp.isSelected = true;
        selected = selectedTemp;
      } else {
        selected = null;
      }
    } else {
      onTap?.call(null, position);
    }
    notifyListeners();
  }

  markRepeated() {
    List<String> temp = [];
    for (var entry in danmuItems) {
      if (!entry.flag.isAnnouncement && temp.contains(entry.model.plainText)) {
        ///不去重 高级弹幕 自己发的弹幕 高点赞数的弹幕
        if (!entry.flag.isAdvanced && !entry.model.isMine && !entry.model.isPraise) {
          entry.flag = entry.flag.addRepeated;
        }
      } else {
        entry.flag = entry.flag.removeRepeated;
        temp.add(entry.model.plainText);
      }
    }
  }

  _addEntry(T model) {
    if (model.spans.isEmpty && model.text.isEmpty && model.imageProvider == null) {
      return;
    }
    if (model.startTime > endTime) {
      return;
    }
    if (danmuItems.length > maxSize) {
      return;
    }
    for (var element in danmuItems) {
      if (element.model.id == model.id) {
        return;
      }
      if (!filter.isRepeated) {
        if (element.model.plainText == model.plainText) {
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

  ///最好按照时间顺序插入弹幕
  addDanmu(T model) {
    assert(isEnable);
    _addEntry(model);
    if (danmuItems.isNotEmpty && isAnimating && _status == DanmuStatus.idle) {
      _status = _idleBeforeStatus;
      _onceForceRefresh = true;
      _checkStatusChanged();
    }
  }

  ///传入的列表最好按照时间顺序排序
  addAllDanmu(Iterable<T> models) {
    assert(isEnable);
    if (danmuItems.length > maxSize) {
      return;
    }
    for (var model in models) {
      _addEntry(model);
    }
    if (danmuItems.isNotEmpty && isAnimating && _status == DanmuStatus.idle) {
      _status = _idleBeforeStatus;
      _onceForceRefresh = true;
      _checkStatusChanged();
    }
  }

  _internalSetValue(Duration progress) {
    if (progress > endTime) {
      _progress = endTime;
      _status = DanmuStatus.completed;
      _checkStatusChanged();
    } else if (progress < startTime) {
      _progress = startTime;
    } else {
      _progress = progress;
    }
  }

  pause() {
    assert(isEnable);
    _status = DanmuStatus.pause;
    _checkStatusChanged();
  }

  start() {
    assert(isEnable);
    if (!_ticker!.isActive) {
      final TickerFuture result = _ticker!.start();
    }
    _status = DanmuStatus.playing;
    _checkStatusChanged();
  }

  stop({bool canceled = true}) {
    assert(isEnable);
    danmuItems.clear();
    progress = startTime;
    _lastElapsedDuration = null;
    _checkStatusChanged();
    _ticker!.stop(canceled: canceled);
    _status = DanmuStatus.stop;
  }

  /// flag [DanmuFlag]
  changeFilter(int flag, {bool? isEnable}) {
    if (isEnable == null) {
      filter = filter.change(flag);
    } else if (isEnable) {
      filter = filter.add(flag);
    } else {
      filter = filter.remove(flag);
    }
    _onceForceRefresh = true;
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
          foundation.DiagnosticsProperty<DanmuController<T>>(
            'The following $runtimeType object was disposed multiple times',
            this,
            style: foundation.DiagnosticsTreeStyle.errorProperty,
          ),
        ]);
      }
      return true;
    }());
    clearDanmu();
    _ticker!.dispose();
    _ticker = null;
    _lastElapsedDuration = null;
    _status = DanmuStatus.dispose;
    _imagesPool.clear();
    clearStatusListeners();
    clearListeners();
    super.dispose();
  }
}

typedef DanmuStatusListener = Function(DanmuStatus status);

enum DanmuStatus {
  dispose,
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

extension DurationExtension on Duration {
  double get inMicrosecondsPerSecond =>
      inMicroseconds / Duration.microsecondsPerSecond;

  double get inMillisecondsPerSecond =>
      inMilliseconds / Duration.millisecondsPerSecond;
}

extension SecondDoubleToDuration on double {
  Duration get inSecondToDuration =>
      Duration(microseconds: (this * Duration.microsecondsPerSecond).toInt());
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

  ///无碰撞体积
  static const int collisionFree = 1 << 7;

  ///全部不允许
  static const int none = 0;

  ///全部允许
  static const int all = DanmuFlag.scroll |
      DanmuFlag.top |
      DanmuFlag.bottom |
      DanmuFlag.advanced |
      DanmuFlag.repeated |
      DanmuFlag.colorful |
      DanmuFlag.announcement |
      DanmuFlag.collisionFree;

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

  bool get isCollisionFree => check(collisionFree);

  int get addScroll => add(scroll);

  int get addTop => add(top);

  int get addBottom => add(bottom);

  int get addAdvanced => add(advanced);

  int get addRepeated => add(repeated);

  int get addColorful => add(colorful);

  int get addAnnouncement => add(announcement);

  int get addCollisionFree => add(collisionFree);

  int get removeScroll => remove(scroll);

  int get removeTop => remove(top);

  int get removeBottom => remove(bottom);

  int get removeAdvanced => remove(advanced);

  int get removeRepeated => remove(repeated);

  int get removeColorful => remove(colorful);

  int get removeAnnouncement => remove(announcement);

  int get removeCollisionFree => remove(collisionFree);

  int get changeScroll => change(scroll);

  int get changeTop => change(top);

  int get changeBottom => change(bottom);

  int get changeAdvanced => change(advanced);

  int get changeRepeated => change(repeated);

  int get changeColorful => change(colorful);

  int get changeAnnouncement => change(announcement);

  int get changeCollisionFree => change(collisionFree);
}
