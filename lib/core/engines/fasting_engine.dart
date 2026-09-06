// Intermittent fasting windows — elapsed / remaining only (no medical claims).

enum FastingProtocol {
  sixteenEight,
  fourteenTen,
  custom,
}

extension FastingProtocolLabel on FastingProtocol {
  String get label => switch (this) {
        FastingProtocol.sixteenEight => '16:8',
        FastingProtocol.fourteenTen => '14:10',
        FastingProtocol.custom => 'Custom',
      };

  /// Fasting window length in hours.
  int get defaultFastHours => switch (this) {
        FastingProtocol.sixteenEight => 16,
        FastingProtocol.fourteenTen => 14,
        FastingProtocol.custom => 16,
      };

  int get eatingWindowHours => switch (this) {
        FastingProtocol.sixteenEight => 8,
        FastingProtocol.fourteenTen => 10,
        FastingProtocol.custom => 8,
      };
}

class FastingStatus {
  final FastingProtocol protocol;
  final DateTime? startedAt;
  final Duration elapsed;
  final Duration remaining;
  final Duration target;
  final bool active;
  final double progress;

  const FastingStatus({
    required this.protocol,
    required this.startedAt,
    required this.elapsed,
    required this.remaining,
    required this.target,
    required this.active,
    required this.progress,
  });

  String get elapsedLabel => _fmt(elapsed);
  String get remainingLabel => active ? _fmt(remaining) : '—';

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class FastingEngine {
  static FastingStatus status({
    required FastingProtocol protocol,
    required DateTime? startedAt,
    int? customFastHours,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final hours = protocol == FastingProtocol.custom
        ? (customFastHours ?? 16)
        : protocol.defaultFastHours;
    final target = Duration(hours: hours);

    if (startedAt == null) {
      return FastingStatus(
        protocol: protocol,
        startedAt: null,
        elapsed: Duration.zero,
        remaining: target,
        target: target,
        active: false,
        progress: 0,
      );
    }

    final elapsed = clock.difference(startedAt);
    final remaining =
        elapsed >= target ? Duration.zero : target - elapsed;
    final progress = (elapsed.inSeconds / target.inSeconds).clamp(0.0, 1.0);

    return FastingStatus(
      protocol: protocol,
      startedAt: startedAt,
      elapsed: elapsed,
      remaining: remaining,
      target: target,
      active: true,
      progress: progress,
    );
  }
}
