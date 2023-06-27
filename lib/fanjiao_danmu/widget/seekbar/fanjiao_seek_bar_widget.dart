import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'fanjiao_seek_bar_controller.dart';

class FanjiaoSeekBarWidget extends StatefulWidget {
  final Duration initialTime;
  final Duration duration;
  final double progressWidth;
  final Size blockSize;
  final Widget? controlView;
  final bool showPreview;
  final Color trackColor;
  final Color textColor;
  final FanjiaoSeekBarController controller;
  final Function(ProgressEvent event)? gestureListener;
  final Widget Function(Size blockSize, Offset blockOffset)? buildBlock;

  /*Stack buildBlock(Size blockSize, Offset blockOffset) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        SvgPicture.asset(
          'assets/svgs/dot_player.svg',
          width: blockSize.width,
          height: blockSize.height,
          alignment: Alignment.center,
          package: package,
        ),
        Positioned(
          left: blockOffset.dx * 0.15,
          child: SvgPicture.asset(
            'assets/svgs/dot_player_nose.svg',
            width: blockSize.width,
            height: blockSize.height,
            alignment: Alignment.center,
            package: package,
          ),
        ),
        Positioned(
          left: blockOffset.dx * 0.12,
          child: SvgPicture.asset(
            _isClosed
                ? 'assets/svgs/dot_player_eyes_closed.svg'
                : 'assets/svgs/dot_player_eyes.svg',
            width: blockSize.width,
            height: blockSize.height,
            alignment: Alignment.center,
            package: package,
          ),
        ),
      ],
    );
  }*/

  const FanjiaoSeekBarWidget({
    Key? key,
    required this.controller,
    this.duration = const Duration(seconds: 1),
    this.initialTime = Duration.zero,
    this.progressWidth = 4,
    this.gestureListener,
    this.buildBlock,
    this.blockSize = const Size(20, 20),
    this.controlView,
    this.showPreview = false,
    this.trackColor = Colors.white10,
    this.textColor = Colors.white54,
  }) : super(key: key);

  @override
  State<FanjiaoSeekBarWidget> createState() => FanjiaoSeekBarWidgetState();
}

class FanjiaoSeekBarWidgetState extends State<FanjiaoSeekBarWidget> {
  double _effectiveTime = 0;
  double _progressTime = 0;
  double _previewTime = 0;
  double _durationMilliseconds = 1000;
  Duration _duration = const Duration(seconds: 1);
  double _maxDeltaTime = 0;
  double _maxOffset = 0;
  Offset _blockOffset = Offset.zero;
  bool _previewVisible = false;
  bool _isClosed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final controllerProgress =
        widget.controller.progress.inMilliseconds.toDouble();
    _progressTime = controllerProgress == 0.0
        ? widget.initialTime.inMilliseconds.toDouble()
        : controllerProgress;
    _previewTime = _progressTime;
    _maxOffset = widget.blockSize.width / 2;
    resetDuration();
    widget.controller.addProgressChangeListener((progress) {
      setProgress(progress);
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.clearListeners();
  }

  @override
  void didUpdateWidget(covariant FanjiaoSeekBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    resetDuration();
  }

  void resetDuration() {
    if (_duration != widget.duration) {
      _duration = widget.duration;
      if (_duration.inMilliseconds < _progressTime) {
        _progressTime = _duration.inMilliseconds.toDouble();
        _previewTime = _progressTime;
      }
      _durationMilliseconds = _duration.inMilliseconds.toDouble();
      _durationMilliseconds =
          _durationMilliseconds == 0 ? 1000 : _durationMilliseconds;

      if (_duration.inMinutes < 1) {
        _maxDeltaTime = _durationMilliseconds;
      } else {
        _maxDeltaTime = _durationMilliseconds - 60000;
        _maxDeltaTime = 60000 + _maxDeltaTime / 30;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color blockColor = Colors.amber;
    var progressDuration = Duration(milliseconds: _progressTime.toInt());
    final timeStr =
        progressDuration.toTimeString(showHours: _duration.inHours > 0);
    var blockDuration = Duration(milliseconds: _previewTime.toInt());
    final blockDurationStr =
        blockDuration.toTimeString(showHours: _duration.inHours > 0);
    final durationStr = _duration.toTimeString();
    var gestureSettings = MediaQuery.maybeOf(context)?.gestureSettings;
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () {
            return TapGestureRecognizer();
          },
          (TapGestureRecognizer instance) {
            instance
              ..onTapDown = (TapDownDetails details) {}
              ..gestureSettings = gestureSettings;
          },
        ),

        ///滑动屏幕
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
          (HorizontalDragGestureRecognizer instance) {
            instance
              ..onStart = (DragStartDetails details) {
                _previewVisible = true;
                cancelAnimation();
                widget.gestureListener?.call(
                    ProgressEvent(true, EventType.onStart, _progressTime));
              }
              ..onEnd = (DragEndDetails details) {
                _blockOffset = Offset.zero;
                _progressTime = _previewTime;
                _previewVisible = false;
                setState(() {});
                startAnimation();
                widget.gestureListener
                    ?.call(ProgressEvent(true, EventType.onEnd, _progressTime));
              }
              ..onUpdate = (DragUpdateDetails details) {
                _previewTime += _maxDeltaTime *
                    details.delta.dx /
                    MediaQuery.of(context).size.width;
                if (_previewTime < 0) {
                  _previewTime = 0;
                } else if (_previewTime > _durationMilliseconds) {
                  _previewTime = _durationMilliseconds;
                }

                double blockOffsetDx = _blockOffset.dx;
                blockOffsetDx += (details.delta.dx / 2);
                if (blockOffsetDx > _maxOffset) {
                  _blockOffset = Offset(_maxOffset, _blockOffset.dy);
                } else if (blockOffsetDx < -_maxOffset) {
                  _blockOffset = Offset(-_maxOffset, _blockOffset.dy);
                } else {
                  _blockOffset += details.delta / 2;
                }
                setState(() {});
                widget.gestureListener?.call(
                    ProgressEvent(true, EventType.onUpdate, _previewTime));
              }
              ..gestureSettings = gestureSettings;
          },
        ),
      },
      child: Stack(
        alignment: Alignment.bottomLeft,
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 30,
                child: LayoutBuilder(builder: (context, covariant) {
                  final blockPosition =
                      _previewTime / _durationMilliseconds * covariant.maxWidth;
                  final previewPosition = _previewTime /
                      _durationMilliseconds *
                      (covariant.maxWidth - 60);
                  final progress = _progressTime /
                      _durationMilliseconds *
                      covariant.maxWidth;
                  return RawGestureDetector(
                    gestures: <Type, GestureRecognizerFactory>{
                      TapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              TapGestureRecognizer>(
                        () => TapGestureRecognizer(),
                        (TapGestureRecognizer instance) {
                          instance
                            ..onTapDown = (TapDownDetails details) {
                              _previewTime = _durationMilliseconds *
                                  details.localPosition.dx /
                                  covariant.maxWidth;
                              cancelAnimation();
                            }
                            ..onTap = () {
                              _progressTime = _previewTime;
                              setState(() {});
                              startAnimation();
                              widget.gestureListener?.call(ProgressEvent(
                                  false, EventType.onEnd, _progressTime));
                            }
                            ..gestureSettings = gestureSettings;
                        },
                      ),
                      HorizontalDragGestureRecognizer:

                          ///滑动进度条
                          GestureRecognizerFactoryWithHandlers<
                              HorizontalDragGestureRecognizer>(
                        () => HorizontalDragGestureRecognizer(),
                        (HorizontalDragGestureRecognizer instance) {
                          instance
                            ..onStart = (DragStartDetails details) {
                              _previewVisible = true;
                              widget.gestureListener?.call(ProgressEvent(
                                  false, EventType.onStart, _progressTime));
                              cancelAnimation();
                            }
                            ..onEnd = (DragEndDetails details) {
                              setState(() {
                                _blockOffset = Offset.zero;
                                if (_effectiveTime != null) {
                                  if ((_effectiveTime - _previewTime).abs() /
                                          _durationMilliseconds >
                                      0.002) {
                                    _progressTime = _previewTime;
                                  } else {
                                    _progressTime = _effectiveTime;
                                  }
                                } else {
                                  _progressTime = _previewTime;
                                }
                                _previewTime = _progressTime;
                                _previewVisible = false;
                              });
                              widget.gestureListener?.call(ProgressEvent(
                                  false, EventType.onEnd, _progressTime));
                              startAnimation();
                            }
                            ..onUpdate = (DragUpdateDetails details) {
                              _previewTime = _durationMilliseconds *
                                  details.localPosition.dx /
                                  covariant.maxWidth;
                              if (_previewTime < 0) {
                                _previewTime = 0;
                              } else if (_previewTime > _durationMilliseconds) {
                                _previewTime = _durationMilliseconds;
                              }

                              double blockOffsetDx = _blockOffset.dx;
                              blockOffsetDx += details.delta.dx / 2;
                              if (blockOffsetDx > _maxOffset) {
                                _blockOffset =
                                    Offset(_maxOffset, _blockOffset.dy);
                              } else if (blockOffsetDx < -_maxOffset) {
                                _blockOffset =
                                    Offset(-_maxOffset, _blockOffset.dy);
                              } else {
                                _blockOffset += details.delta / 2;
                              }
                              setState(() {});
                              double previewTime = _previewTime;
                              widget.gestureListener?.call(ProgressEvent(
                                  false, EventType.onUpdate, previewTime));
                              Future.delayed(const Duration(milliseconds: 37))
                                  .then((value) {
                                setState(() {
                                  _effectiveTime = previewTime;
                                });
                              });
                            }
                            ..gestureSettings = gestureSettings;
                        },
                      ),
                    },
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        ///总进度条
                        Positioned(
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.trackColor,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(3)),
                            ),
                            alignment: Alignment.center,
                            height: widget.progressWidth,
                          ),
                        ),

                        ///进度条
                        Positioned(
                          left: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0XFFE5C6FF),
                                  getBiasColor(0XFFE5C6FF, 0XFF836BFF,
                                      _progressTime / _durationMilliseconds),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(3),
                              ),
                            ),
                            alignment: Alignment.center,
                            height: widget.progressWidth,
                            width: progress,
                          ),
                        ),

                        ///滑块
                        Positioned(
                          left: blockPosition - widget.blockSize.width / 2,
                          child: widget.buildBlock
                                  ?.call(widget.blockSize, _blockOffset) ??
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black45),
                                ),
                              ),
                        ),

                        ///时间预览
                        Positioned(
                          left: previewPosition,
                          top: -30,
                          child: Visibility(
                            visible: widget.showPreview && _previewVisible,
                            child: Container(
                              color: Colors.grey,
                              alignment: Alignment.center,
                              height: 30,
                              width: 60,
                              child: Text(
                                blockDurationStr,
                                style: TextStyle(
                                  color: blockColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ///当前进度时间
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  ///视频时长
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      durationStr,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ]..insert(0, widget.controlView ?? const SizedBox()),
      ),
    );
  }

  void startAnimation() {
    _timer?.cancel();
    if (!_isClosed) {
      setState(() {
        _isClosed = true;
      });
    }
    _timer = Timer(const Duration(milliseconds: 200), () async {
      setState(() {
        _isClosed = true;
      });
      await Future.delayed(const Duration(milliseconds: 20));
      setState(() {
        _isClosed = false;
      });
    });
  }

  void cancelAnimation() {
    _timer?.cancel();
    if (_isClosed) {
      setState(() {
        _isClosed = false;
      });
    }
  }

  void setProgress(Duration progress) {
    var milliseconds = progress.inMilliseconds;
    if (milliseconds <= _durationMilliseconds) {
      setState(() {
        _progressTime = milliseconds.toDouble();
        if (!_previewVisible) {
          _previewTime = _progressTime;
        }
      });
    }
  }

  @override
  void didRegisterListener() {}

  @override
  void didUnregisterListener() {}
}

Color getBiasColor(int startColorValue, int endColorValue, double bias) {
  if (bias < 0) return Color(startColorValue);
  if (bias > 1) return Color(endColorValue);
  final startValueA = (startColorValue & 0xFF000000) >> 24;
  final startValueR = (startColorValue & 0x00FF0000) >> 16;
  final startValueG = (startColorValue & 0x0000FF00) >> 8;
  final startValueB = startColorValue & 0x000000FF;

  final endValueA = (endColorValue & 0xFF000000) >> 24;
  final endValueR = (endColorValue & 0x00FF0000) >> 16;
  final endValueG = (endColorValue & 0x0000FF00) >> 8;
  final endValueB = endColorValue & 0x000000FF;

  final biasValueA = startValueA + ((endValueA - startValueA) * bias).floor();
  final biasValueR = startValueR + ((endValueR - startValueR) * bias).floor();
  final biasValueG = startValueG + ((endValueG - startValueG) * bias).floor();
  final biasValueB = startValueB + ((endValueB - startValueB) * bias).floor();
  var biasColorValue =
      (biasValueA << 24) + (biasValueR << 16) + (biasValueG << 8) + biasValueB;
  return Color(biasColorValue);
}

enum EventType { onStart, onEnd, onUpdate }

class ProgressEvent {
  final EventType type;
  final double progress;
  final bool isPreview;

  String get progressStr =>
      Duration(milliseconds: progress.toInt()).toTimeString();

  ProgressEvent(this.isPreview, this.type, this.progress);
}

extension DurationExtension on Duration {
  String toTimeString({bool? showHours}) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    if (inMicroseconds < 0) {
      return "-${-this}";
    }
    String twoDigitMinutes =
        twoDigits(inMinutes.remainder(Duration.minutesPerHour));
    String twoDigitSeconds =
        twoDigits(inSeconds.remainder(Duration.secondsPerMinute));
    String twoDigitHours = twoDigits(inHours);
    return showHours ?? inHours > 0
        ? "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds"
        : "$twoDigitMinutes:$twoDigitSeconds";
  }
}
