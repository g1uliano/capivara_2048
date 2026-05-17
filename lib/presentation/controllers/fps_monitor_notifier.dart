import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FpsMonitorNotifier extends Notifier<bool> {
  // state = true: drops detectados, exibir dialog
  // Janela de 120 frames (~2s a 60fps) para filtrar picos pontuais de GC.
  // Threshold de 25ms (~40fps) — dispara se o device rodar abaixo de 40fps
  // de forma sustentada (perceptível como travamento).
  static const _windowSize = 120;
  static const _thresholdMicros = 25000; // 25ms = ~40fps

  TimingsCallback? _callback;
  final List<int> _frameMicros = [];

  @override
  bool build() {
    ref.onDispose(stop);
    return false;
  }

  void start() {
    if (_callback != null || state) return;
    _callback = _onTimings;
    SchedulerBinding.instance.addTimingsCallback(_callback!);
  }

  void stop() {
    if (_callback == null) return;
    SchedulerBinding.instance.removeTimingsCallback(_callback!);
    _callback = null;
    _frameMicros.clear();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!ref.mounted || state) return;
    for (final t in timings) {
      final us =
          t.buildDuration.inMicroseconds + t.rasterDuration.inMicroseconds;
      _frameMicros.add(us);
      if (_frameMicros.length > _windowSize) _frameMicros.removeAt(0);
    }
    if (_frameMicros.length < _windowSize) return;
    final avg = _frameMicros.reduce((a, b) => a + b) / _windowSize;
    if (avg > _thresholdMicros) {
      stop();
      state = true;
    }
  }
}

final fpsMonitorProvider = NotifierProvider<FpsMonitorNotifier, bool>(
  FpsMonitorNotifier.new,
);
