import 'package:flutter/foundation.dart';

import 'danmu_controller.dart';

mixin DanmuLazyListenerMixin {
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

mixin DanmuEagerListenerMixin {
  @protected
  void didRegisterListener() { }

  @protected
  void didUnregisterListener() { }

  @mustCallSuper
  void dispose() { }
}

mixin DanmuLocalListenersMixin {
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
          yield DiagnosticsProperty<DanmuLocalListenersMixin>(
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

typedef DanmuStatusListener = Function(DanmuStatus status);

mixin DanmuLocalStatusListenersMixin {
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
    /*if (kDebugMode) {
      print('LiuShuai: DanmuStatus = $status');
    }*/
    final List<DanmuStatusListener> localListeners = List<DanmuStatusListener>.from(_statusListeners);
    for (final DanmuStatusListener listener in localListeners) {
      if (_statusListeners.contains(listener)) {
        listener(status);
      }
    }
  }
}

typedef DanmuTickListener = Function(Duration elapsed);

mixin DanmuTickListenersMixin {
  final ObserverList<DanmuTickListener> _tickListeners = ObserverList<DanmuTickListener>();

  @protected
  void didRegisterListener();

  @protected
  void didUnregisterListener();

  void addTickListener(DanmuTickListener listener) {
    didRegisterListener();
    _tickListeners.add(listener);
  }

  void removeTickListener(DanmuTickListener listener) {
    final bool removed = _tickListeners.remove(listener);
    if (removed) {
      didUnregisterListener();
    }
  }

  @protected
  void clearTickListeners() {
    _tickListeners.clear();
  }

  @protected
  @pragma('vm:notify-debugger-on-exception')
  void notifyTickListeners(Duration elapsed) {
    /*if (kDebugMode) {
      print('LiuShuai: elapsed = $elapsed');
    }*/
    final List<DanmuTickListener> localListeners = List<DanmuTickListener>.from(_tickListeners);
    for (final DanmuTickListener listener in localListeners) {
      if (_tickListeners.contains(listener)) {
        listener(elapsed);
      }
    }
  }
}
