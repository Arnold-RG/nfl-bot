/// Smart watch device models, pairing methods, and live vitals.
library;

enum WatchConnectionMethod { bluetooth, qrCode, wifi, account }

enum WatchConnectionStatus {
  disconnected,
  scanning,
  pairing,
  connecting,
  connected,
  syncing,
  error,
}

enum WatchBrand {
  apple,
  samsung,
  garmin,
  fitbit,
  amazfit,
  huawei,
  google,
  other,
}

class SmartWatchDevice {
  final String id;
  final String name;
  final WatchBrand brand;
  final String model;
  final WatchConnectionMethod preferredMethod;
  final int signalStrength; // 0–100
  final int batteryPercent;
  final bool supportsEcg;
  final bool supportsSpo2;
  final bool supportsGps;
  final String firmware;

  const SmartWatchDevice({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.preferredMethod,
    this.signalStrength = 80,
    this.batteryPercent = 100,
    this.supportsEcg = false,
    this.supportsSpo2 = true,
    this.supportsGps = true,
    this.firmware = '1.0.0',
  });

  String get brandLabel {
    switch (brand) {
      case WatchBrand.apple:
        return 'Apple';
      case WatchBrand.samsung:
        return 'Samsung';
      case WatchBrand.garmin:
        return 'Garmin';
      case WatchBrand.fitbit:
        return 'Fitbit';
      case WatchBrand.amazfit:
        return 'Amazfit';
      case WatchBrand.huawei:
        return 'Huawei';
      case WatchBrand.google:
        return 'Google';
      case WatchBrand.other:
        return 'Other';
    }
  }

  SmartWatchDevice copyWith({
    int? signalStrength,
    int? batteryPercent,
    String? firmware,
  }) {
    return SmartWatchDevice(
      id: id,
      name: name,
      brand: brand,
      model: model,
      preferredMethod: preferredMethod,
      signalStrength: signalStrength ?? this.signalStrength,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      supportsEcg: supportsEcg,
      supportsSpo2: supportsSpo2,
      supportsGps: supportsGps,
      firmware: firmware ?? this.firmware,
    );
  }
}

class WatchVitals {
  final int heartRateBpm;
  final int restingHeartRate;
  final int spo2Percent;
  final int stressScore; // 0–100
  final int hrvMs;
  final double skinTempC;
  final int caloriesBurned;
  final int activeMinutes;
  final int steps;
  final double distanceKm;
  final DateTime lastSynced;
  final List<int> heartRateSeries;

  const WatchVitals({
    this.heartRateBpm = 72,
    this.restingHeartRate = 58,
    this.spo2Percent = 98,
    this.stressScore = 32,
    this.hrvMs = 48,
    this.skinTempC = 36.4,
    this.caloriesBurned = 420,
    this.activeMinutes = 38,
    this.steps = 0,
    this.distanceKm = 0,
    required this.lastSynced,
    this.heartRateSeries = const [],
  });

  WatchVitals copyWith({
    int? heartRateBpm,
    int? restingHeartRate,
    int? spo2Percent,
    int? stressScore,
    int? hrvMs,
    double? skinTempC,
    int? caloriesBurned,
    int? activeMinutes,
    int? steps,
    double? distanceKm,
    DateTime? lastSynced,
    List<int>? heartRateSeries,
  }) {
    return WatchVitals(
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      spo2Percent: spo2Percent ?? this.spo2Percent,
      stressScore: stressScore ?? this.stressScore,
      hrvMs: hrvMs ?? this.hrvMs,
      skinTempC: skinTempC ?? this.skinTempC,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      lastSynced: lastSynced ?? this.lastSynced,
      heartRateSeries: heartRateSeries ?? this.heartRateSeries,
    );
  }

  String get stressLabel {
    if (stressScore < 30) return 'Low';
    if (stressScore < 60) return 'Moderate';
    return 'High';
  }

  String get zoneLabel {
    if (heartRateBpm < 100) return 'Rest';
    if (heartRateBpm < 120) return 'Fat burn';
    if (heartRateBpm < 145) return 'Cardio';
    return 'Peak';
  }
}

class WatchPairingSession {
  final WatchConnectionMethod method;
  final WatchConnectionStatus status;
  final String? statusMessage;
  final double progress; // 0–1
  final SmartWatchDevice? device;

  const WatchPairingSession({
    required this.method,
    required this.status,
    this.statusMessage,
    this.progress = 0,
    this.device,
  });

  WatchPairingSession copyWith({
    WatchConnectionMethod? method,
    WatchConnectionStatus? status,
    String? statusMessage,
    double? progress,
    SmartWatchDevice? device,
  }) {
    return WatchPairingSession(
      method: method ?? this.method,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      progress: progress ?? this.progress,
      device: device ?? this.device,
    );
  }
}

/// Catalog of popular watches the hub can discover and pair.
class WatchCatalog {
  static const List<SmartWatchDevice> discoverable = [
    SmartWatchDevice(
      id: 'aw-s10-01',
      name: 'Apple Watch Series 10',
      brand: WatchBrand.apple,
      model: 'Series 10 46mm',
      preferredMethod: WatchConnectionMethod.bluetooth,
      signalStrength: 92,
      batteryPercent: 78,
      supportsEcg: true,
      firmware: '11.2',
    ),
    SmartWatchDevice(
      id: 'gw-u7-02',
      name: 'Galaxy Watch Ultra',
      brand: WatchBrand.samsung,
      model: 'Ultra 47mm',
      preferredMethod: WatchConnectionMethod.bluetooth,
      signalStrength: 88,
      batteryPercent: 64,
      supportsEcg: true,
      firmware: '5.0.1',
    ),
    SmartWatchDevice(
      id: 'gf-965-03',
      name: 'Garmin Forerunner 965',
      brand: WatchBrand.garmin,
      model: 'Forerunner 965',
      preferredMethod: WatchConnectionMethod.wifi,
      signalStrength: 75,
      batteryPercent: 91,
      firmware: '21.20',
    ),
    SmartWatchDevice(
      id: 'fb-sense-04',
      name: 'Fitbit Sense 2',
      brand: WatchBrand.fitbit,
      model: 'Sense 2',
      preferredMethod: WatchConnectionMethod.account,
      signalStrength: 70,
      batteryPercent: 55,
      supportsEcg: true,
      firmware: '60.1.2',
    ),
    SmartWatchDevice(
      id: 'az-gtr4-05',
      name: 'Amazfit GTR 4',
      brand: WatchBrand.amazfit,
      model: 'GTR 4',
      preferredMethod: WatchConnectionMethod.qrCode,
      signalStrength: 82,
      batteryPercent: 88,
      firmware: '8.12.0',
    ),
    SmartWatchDevice(
      id: 'hw-gt5-06',
      name: 'Huawei Watch GT 5',
      brand: WatchBrand.huawei,
      model: 'GT 5 Pro',
      preferredMethod: WatchConnectionMethod.bluetooth,
      signalStrength: 79,
      batteryPercent: 72,
      firmware: '5.0.0.15',
    ),
    SmartWatchDevice(
      id: 'pw-3-07',
      name: 'Pixel Watch 3',
      brand: WatchBrand.google,
      model: 'Pixel Watch 3',
      preferredMethod: WatchConnectionMethod.account,
      signalStrength: 85,
      batteryPercent: 61,
      supportsEcg: true,
      firmware: 'Wear OS 5.1',
    ),
  ];

  static SmartWatchDevice? byId(String id) {
    for (final device in discoverable) {
      if (device.id == id) return device;
    }
    return null;
  }
}
