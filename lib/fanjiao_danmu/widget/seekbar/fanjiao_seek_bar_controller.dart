import 'package:flutter/foundation.dart';


typedef ProgressChange = void Function(Duration progress);
class FanjiaoSeekBarController {
  Duration progress;
  final ObserverList<ProgressChange> _onProgressChange = ObserverList<ProgressChange>();

  FanjiaoSeekBarController({this.progress = Duration.zero});

  setProgress(Duration progress) {
    this.progress = progress;
    for (var observer in _onProgressChange) {
      observer.call(progress);
    }
  }

  void addProgressChangeListener(ProgressChange listener) {
    _onProgressChange.add(listener);
  }

  void removeProgressChangeListener(ProgressChange listener) {
    _onProgressChange.remove(listener);
  }

  void clearListeners() {
    _onProgressChange.clear();
  }
}
