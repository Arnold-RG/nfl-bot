/// Where a health datapoint came from — used for priority and dedupe.
enum HealthDataSource {
  appleHealth,
  healthConnect,
  appleWatch,
  wearOs,
  garmin,
  fitbit,
  strava,
  phoneSensors,
  manual,
  nflBot,
}

extension HealthDataSourceRank on HealthDataSource {
  int get priority => switch (this) {
        HealthDataSource.appleHealth || HealthDataSource.healthConnect => 100,
        HealthDataSource.appleWatch || HealthDataSource.wearOs => 90,
        HealthDataSource.garmin || HealthDataSource.fitbit => 80,
        HealthDataSource.strava => 70,
        HealthDataSource.phoneSensors => 50,
        HealthDataSource.manual => 40,
        HealthDataSource.nflBot => 30,
      };
}

enum HealthEventKind {
  steps,
  activity,
  meal,
  workout,
  sleep,
  water,
  preference,
}

class HealthEvent {
  final String id;
  final HealthEventKind kind;
  final DateTime at;
  final HealthDataSource source;
  final double confidence;
  final Map<String, dynamic> payload;
  final bool duplicateOfPrior;

  const HealthEvent({
    required this.id,
    required this.kind,
    required this.at,
    required this.source,
    required this.confidence,
    required this.payload,
    this.duplicateOfPrior = false,
  });

  HealthEvent copyWith({bool? duplicateOfPrior, double? confidence}) =>
      HealthEvent(
        id: id,
        kind: kind,
        at: at,
        source: source,
        confidence: confidence ?? this.confidence,
        payload: payload,
        duplicateOfPrior: duplicateOfPrior ?? this.duplicateOfPrior,
      );
}

/// Merges likely-duplicate activities instead of double-counting.
class DataSourcePriority {
  static HealthEvent merge(List<HealthEvent> existing, HealthEvent incoming) {
    if (incoming.kind != HealthEventKind.activity &&
        incoming.kind != HealthEventKind.workout) {
      return incoming;
    }

    for (final prior in existing.take(25)) {
      if (prior.kind != incoming.kind) continue;
      final dt = prior.at.difference(incoming.at).inMinutes.abs();
      if (dt > 20) continue;
      final sameType = prior.payload['type'] == incoming.payload['type'] ||
          prior.payload['title'] == incoming.payload['title'];
      if (!sameType) continue;

      if (incoming.source.priority >= prior.source.priority) {
        return incoming.copyWith(confidence: incoming.confidence.clamp(0.5, 1.0));
      }
      return incoming.copyWith(duplicateOfPrior: true, confidence: 0.2);
    }
    return incoming;
  }
}
