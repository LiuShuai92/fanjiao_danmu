import 'dart:collection';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'fanjiao_danmu.dart';
import 'listener_helpers.dart';
import 'simulation/clamp_simulation.dart';

class DanmuController<T extends DanmuModel>
    with
        DanmuLocalListenersMixin,
        DanmuLocalStatusListenersMixin,
        DanmuEagerListenerMixin,
        DanmuTickListenersMixin {
  /// return true 选中并暂停这条弹幕
  final bool Function(DanmuItem<T>?, Offset)? onTap;
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
  int _filter;
  DanmuItem<T>? selected;
  Ticker? _ticker;
  Duration? _progress;
  Duration? _lastElapsedDuration;
  bool _isFullShown = true;
  bool _isAllFullShown = true;

  /// 弹幕倍速播放
  double rate = 1;

  DanmuStatus get state => _status;

  bool get isFullShown => _isFullShown;

  bool get isAllFullShown => _isAllFullShown;

  bool get isSelected => selected != null;

  Duration? get lastElapsedDuration => _lastElapsedDuration;

  Duration get progress => _progress ?? startTime;

  bool get isEnable => _ticker != null;

  bool get isAnimating => isEnable && _ticker!.isActive;

  int get filter => _filter;

  set filter(int filter) {
    _filter = filter;
    notifyListeners();
  }

  set progress(Duration newProgress) {
    Duration oldProgress = _progress ?? startTime;
    _internalSetValue(newProgress);
    _lastElapsedDuration = null;
    if (progress == oldProgress) {
      return;
    }
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
      } else if (!entry.isPause) {
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
    int filter = DanmuFlag.all,
  }): _filter = filter;

  setDuration(
    Duration duration, {
    Duration startTime = Duration.zero,
  }) {
    this.startTime = startTime;
    endTime = startTime + duration;
    _progress = startTime;
  }

  clearDanmu([int filter = DanmuFlag.all]) {
    danmuItems.removeWhere((element) => filter.pick(element.flag));
    adapter.clear(filter);
    selected = null;
    notifyListeners();
  }

  setup(BuildContext context, TickerProvider vsync, Rect rect) {
    _ticker = vsync.createTicker(_tick);
    adapter.initData(rect);
  }

  updateItem(DanmuItem<T> item, T model, {double? time, Offset? position}) {
    item.updateModel(model);
    updateSimulation(item);
    if (position != null) {
      item.position = position;
    } else if (time != null) {
      item.position = item.simulation.offset(time);
    }
    notifyListeners();
  }

  updateSimulation(DanmuItem<T> item) {
    var simulation = item.simulation;
    switch (simulation.runtimeType) {
      case ClampSimulation:
        var clampSimulation = simulation as ClampSimulation;
        Offset offset = Offset(
            adapter.rect.center.dx - item.size.width / 2, item.position!.dy);
        item.simulation = clampSimulation.copyWith(clampOffset: offset);
        break;
      case HorizontalScrollSimulation:
        var horizontalScrollSimulation =
            simulation as HorizontalScrollSimulation;
        item.simulation = horizontalScrollSimulation.copyWith(size: item.size);
        break;
      default:
        break;
    }
  }

  _tick(Duration elapsed) {
    Duration dElapsed = elapsed - (_lastElapsedDuration ?? elapsed);
    _lastElapsedDuration = elapsed;
    // notifyTickListeners(elapsed);
    if (_status == DanmuStatus.pause || dElapsed == Duration.zero) {
      return;
    }
    dElapsed *= rate;
    Duration newProgress = progress + dElapsed;
    _internalSetValue(newProgress);
    if (state == DanmuStatus.completed) {
      clearDanmu();
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
        if (entry.isPause) {
          position = entry.simulation.isDone(entry.position!, 0);
        } else {
          position = entry.simulation
              .isDone(entry.position!, dElapsed.inMicrosecondsPerSecond);
        }
        if (position == null) {
          _tempList.add(entry);
        } else if (!entry.isPause) {
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

  clearSelection([bool isAutoPlay = false]) {
    if (selected != null) {
      selected!.isSelected = false;
      if (isAutoPlay) {
        selected!.play();
      }
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
    if (selectedTemp != null && selectedTemp.flag.isClickable) {
      if (onTap?.call(selectedTemp, position) ?? false) {
        selectedTemp.isSelected = true;
        selectedTemp.pause();
        selected = selectedTemp;
      } else {
        selected = null;
      }
    } else {
      onTap?.call(null, position);
    }
    notifyListeners();
  }

  /// 将已添加的内容重复的弹幕标记出来
  markRepeated() {
    List<String> temp = [];
    for (var entry in danmuItems) {
      if (!entry.flag.isAnnouncement && temp.contains(entry.model.plainText)) {
        if (!entry.model.isRepeatable) {
          entry.flag = entry.flag.addRepeated;
        }
      } else {
        entry.flag = entry.flag.removeRepeated;
        temp.add(entry.model.plainText);
      }
    }
  }

  _addEntry(T model) {
    if (model.spans.isEmpty &&
        model.text.isEmpty &&
        model.imageProvider == null) {
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
    if (filter.contain(model.flag)) {
      var item = adapter.getItem(model);
      if (item != null) {
        item.position = item.simulation
            .offset((progress - item.model.startTime).inMicrosecondsPerSecond);
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
  changeFilter(int flag, [bool? isEnable]) {
    if (isEnable == null) {
      filter = filter.change(flag);
    } else if (isEnable) {
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

  DanmuItem<T>? getItem(int id) {
    for (var item in danmuItems) {
      if (item.model.id == id) {
        return item;
      }
    }
    return null;
  }

  void updateView() {
    notifyListeners();
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
    clearTickListeners();
    clearStatusListeners();
    clearListeners();
    super.dispose();
  }
}

enum DanmuStatus {
  dispose,
  playing,
  pause,
  idle,
  completed,
  stop,
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

  ///可点击
  static const int clickable = 1 << 8;

  ///指定y坐标
  static const int specify = 1 << 9;

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
      DanmuFlag.specify |
      DanmuFlag.collisionFree |
      DanmuFlag.clickable;

  bool pick(int flag) => this & flag != none;

  bool contain(int flag) => this & flag == flag;

  int add(int flag) => this | flag;

  int remove(int flag) => (this | flag) ^ flag;

  int change(int flag) => this ^ flag;

  bool get isScroll => contain(scroll);

  bool get isTop => contain(top);

  bool get isBottom => contain(bottom);

  bool get isAdvanced => contain(advanced);

  bool get isRepeated => contain(repeated);

  bool get isColorful => contain(colorful);

  bool get isAnnouncement => contain(announcement);

  bool get isCollisionFree => contain(collisionFree);

  bool get isClickable => contain(clickable);

  bool get isSpecify => contain(specify);

  int get addScroll => add(scroll);

  int get addTop => add(top);

  int get addBottom => add(bottom);

  int get addAdvanced => add(advanced);

  int get addRepeated => add(repeated);

  int get addColorful => add(colorful);

  int get addAnnouncement => add(announcement);

  int get addCollisionFree => add(collisionFree);

  int get addClickable => add(clickable);

  int get addSpecify => add(specify);

  int get removeScroll => remove(scroll);

  int get removeTop => remove(top);

  int get removeBottom => remove(bottom);

  int get removeAdvanced => remove(advanced);

  int get removeRepeated => remove(repeated);

  int get removeColorful => remove(colorful);

  int get removeAnnouncement => remove(announcement);

  int get removeCollisionFree => remove(collisionFree);

  int get removeClickable => remove(clickable);

  int get removeSpecify => remove(specify);

  int get changeScroll => change(scroll);

  int get changeTop => change(top);

  int get changeBottom => change(bottom);

  int get changeAdvanced => change(advanced);

  int get changeRepeated => change(repeated);

  int get changeColorful => change(colorful);

  int get changeAnnouncement => change(announcement);

  int get changeCollisionFree => change(collisionFree);

  int get changeClickable => change(clickable);

  int get changeSpecify => change(specify);
}
