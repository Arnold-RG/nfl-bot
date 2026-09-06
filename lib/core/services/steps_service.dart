import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';

/// Live step counting via device pedometer with graceful fallback.
class StepsService {
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  int _baseline = 0;
  int _latestRaw = 0;
  bool _hasBaseline = false;

  final void Function(int steps) onStepsUpdated;
  final void Function(String status)? onStatusUpdated;

  StepsService({
    required this.onStepsUpdated,
    this.onStatusUpdated,
  });

  Future<void> start() async {
    if (kIsWeb) return;
    try {
      _stepSub = Pedometer.stepCountStream.listen(
        (event) {
          _latestRaw = event.steps;
          if (!_hasBaseline) {
            _baseline = event.steps;
            _hasBaseline = true;
          }
          final today = (_latestRaw - _baseline).clamp(0, 999999);
          onStepsUpdated(today);
        },
        onError: (_) {
          // Desktop/web may not support pedometer — keep simulated count.
        },
      );
      _statusSub = Pedometer.pedestrianStatusStream.listen(
        (status) => onStatusUpdated?.call(status.status),
        onError: (_) {},
      );
    } catch (_) {
      // Pedometer unavailable on this platform.
    }
  }

  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
  }
}
