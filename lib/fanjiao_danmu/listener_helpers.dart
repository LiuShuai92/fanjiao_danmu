import 'package:flutter/foundation.dart';

import 'fanjiao_danmu_controller.dart';

mixin FanjiaoLazyListenerMixin {
  int _listenerCounter = 0;

  @protected
  void didRegisterListener() {
    assert(_listenerCounter >= 0);
    if (_listenerCounter == 0)
      didStartListening();
    _listenerCounter += 1;
  }

  @protected
  void didUnregisterListener() {
    assert(_listenerCounter >= 1);
    _listenerCounter -= 1;
    if (_listenerCounter == 0)
      didStopListening();
  }

  @protected
  void didStartListening();

  @protected
  void didStopListening();

  bool get isListening => _listenerCounter > 0;
}

mixin FanjiaoEagerListenerMixin {
  @protected
  void didRegisterListener() { }

  @protected
  void didUnregisterListener() { }

  @mustCallSuper
  void dispose() { }
}

mixin FanjiaoLocalListenersMixin {
  final ObserverList<VoidCallback> _listeners = ObserverList<VoidCallback>();

  @protected
  void didRegisterListener();

  @protected
  void didUnregisterListener();

  void addListener(VoidCallback listener) {
    didRegisterListener();
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    final bool removed = _listeners.remove(listener);
    if (removed) {
      didUnregisterListener();
    }
  }

  @protected
  void clearListeners() {
    _listeners.clear();
  }

  @protected
  @pragma('vm:notify-debugger-on-exception')
  void notifyListeners() {
    final List<VoidCallback> localListeners = List<VoidCallback>.from(_listeners);
    for (final VoidCallback listener in localListeners) {
      InformationCollector? collector;
      assert(() {
        collector = () sync* {
          yield DiagnosticsProperty<FanjiaoLocalListenersMixin>(
            'The $runtimeType notifying listeners was',
            this,
            style: DiagnosticsTreeStyle.errorProperty,
          );
        };
        return true;
      }());
      try {
        if (_listeners.contains(listener)) {
          listener();
        }
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'fanjiao library',
          context: ErrorDescription('while notifying listeners for $runtimeType'),
          informationCollector: collector,
        ));
      }
    }
  }
}

mixin FanjiaoLocalStatusListenersMixin {
  final ObserverList<DanmuStatusListener> _statusListeners = ObserverList<DanmuStatusListener>();

  @protected
  void didRegisterListener();

  @protected
  void didUnregisterListener();

  void addStatusListener(DanmuStatusListener listener) {
    didRegisterListener();
    _statusListeners.add(listener);
  }

  void removeStatusListener(DanmuStatusListener listener) {
    final bool removed = _statusListeners.remove(listener);
    if (removed) {
      didUnregisterListener();
    }
  }

  @protected
  void clearStatusListeners() {
    _statusListeners.clear();
  }

  @protected
  @pragma('vm:notify-debugger-on-exception')
  void notifyStatusListeners(DanmuStatus status) {
    final List<DanmuStatusListener> localListeners = List<DanmuStatusListener>.from(_statusListeners);
    for (final DanmuStatusListener listener in localListeners) {
      if (_statusListeners.contains(listener)) {
        listener(status);
      }
    }
  }
}
