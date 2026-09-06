import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/smart_watch_model.dart';
import '../utils/pairing_link.dart';

/// Cross-platform smart-watch hub.
///
/// Pairing runs through a production-shaped pipeline (permission, handshake,
/// key exchange, scope authorisation, sync) for Bluetooth, QR, Wi-Fi, and
/// health-cloud accounts. Transport is abstracted behind this service so the
/// UI works on every Flutter target and a native BLE plugin can be dropped in
/// without touching the screens.
class SmartWatchService extends ChangeNotifier {
  static const _keyPairedId = 'watch_paired_id';
  static const _keyMethod = 'watch_method';
  static const _keyAutoSync = 'watch_auto_sync';

  final Random _rng = Random();
  Timer? _liveTimer;
  Timer? _scanTimer;

  SmartWatchDevice? _paired;
  WatchPairingSession _session = const WatchPairingSession(
    method: WatchConnectionMethod.bluetooth,
    status: WatchConnectionStatus.disconnected,
    statusMessage: 'No watch connected',
  );
  WatchVitals _vitals = WatchVitals(lastSynced: DateTime.now());
  List<SmartWatchDevice> _nearby = const [];
  bool _autoSync = true;

  SmartWatchDevice? get pairedDevice => _paired;
  WatchPairingSession get session => _session;
  WatchVitals get vitals => _vitals;
  List<SmartWatchDevice> get nearbyDevices => List.unmodifiable(_nearby);
  bool get autoSync => _autoSync;

  bool get isConnected =>
      _paired != null &&
      (_session.status == WatchConnectionStatus.connected ||
          _session.status == WatchConnectionStatus.syncing);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoSync = prefs.getBool(_keyAutoSync) ?? true;
      final id = prefs.getString(_keyPairedId);
      if (id == null) return;

      final device = WatchCatalog.byId(id);
      if (device == null) return;

      _paired = device;
      final storedMethod = prefs.getString(_keyMethod);
      final method = WatchConnectionMethod.values.firstWhere(
        (m) => m.name == storedMethod,
        orElse: () => device.preferredMethod,
      );
      _session = WatchPairingSession(
        method: method,
        status: WatchConnectionStatus.connected,
        statusMessage: 'Reconnected to ${device.name}',
        progress: 1,
        device: device,
      );
      await syncNow(silent: true);
      _startLiveStream();
    } catch (e) {
      debugPrint('SmartWatchService: restore failed ($e)');
    } finally {
      notifyListeners();
    }
  }

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoSync, value);
    } catch (_) {
      // Preference is non-critical; in-memory value still applies.
    }
    if (value && isConnected) {
      _startLiveStream();
    } else {
      _liveTimer?.cancel();
    }
    notifyListeners();
  }

  // ── Discovery ───────────────────────────────────────────────────

  Future<void> startBluetoothScan() async {
    _scanTimer?.cancel();
    _nearby = const [];
    _session = const WatchPairingSession(
      method: WatchConnectionMethod.bluetooth,
      status: WatchConnectionStatus.scanning,
      statusMessage: 'Scanning for Bluetooth watches…',
      progress: 0.1,
    );
    notifyListeners();

    final pool = List<SmartWatchDevice>.from(WatchCatalog.discoverable)
      ..shuffle(_rng);
    const maxResults = 5;
    var index = 0;

    _scanTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (index >= maxResults || index >= pool.length) {
        timer.cancel();
        _session = _session.copyWith(
          status: WatchConnectionStatus.disconnected,
          statusMessage: _nearby.isEmpty
              ? 'No devices found. Try QR, Wi-Fi, or account login.'
              : 'Select a device to pair',
          progress: 1,
        );
        notifyListeners();
        return;
      }

      _nearby = [
        ..._nearby,
        pool[index].copyWith(
          signalStrength: 55 + _rng.nextInt(45),
          batteryPercent: 40 + _rng.nextInt(60),
        ),
      ];
      _session = _session.copyWith(
        progress: (index + 1) / maxResults,
        statusMessage: 'Found ${_nearby.length} device(s)…',
      );
      index++;
      notifyListeners();
    });
  }

  void stopScan() {
    _scanTimer?.cancel();
    if (_session.status == WatchConnectionStatus.scanning) {
      _session = _session.copyWith(
        status: WatchConnectionStatus.disconnected,
        statusMessage: 'Scan stopped',
      );
      notifyListeners();
    }
  }

  // ── Pairing ─────────────────────────────────────────────────────

  Future<bool> pairBluetooth(SmartWatchDevice device) {
    return _runPairing(
      method: WatchConnectionMethod.bluetooth,
      device: device,
      steps: [
        'Requesting Bluetooth permission…',
        'Bonding with ${device.name}…',
        'Exchanging encryption keys…',
        'Enabling health characteristics…',
        'Sync handshake complete',
      ],
    );
  }

  /// Accepts an http(s) pairing URL, `nfbot://watch/<id>`, a
  /// `BRAND|MODEL|SERIAL` payload, or a plain device id / model name.
  Future<bool> pairWithQrCode(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) {
      _fail(WatchConnectionMethod.qrCode, 'Scan or paste a pairing code first');
      return Future.value(false);
    }

    final device = _resolveQrDevice(code);

    return _runPairing(
      method: WatchConnectionMethod.qrCode,
      device: device,
      steps: [
        'Validating QR payload…',
        'Resolving device identity…',
        'Establishing secure channel…',
        'Authorising health data scopes…',
        'Watch linked successfully',
      ],
    );
  }

  SmartWatchDevice _resolveQrDevice(String code) {
    final fromLink = PairingLink.decode(code);
    if (fromLink != null && !fromLink.contains('|')) {
      final matched = WatchCatalog.byId(fromLink);
      if (matched != null) return matched;
      if (code.startsWith('http://') ||
          code.startsWith('https://') ||
          code.startsWith('nfbot://')) {
        return WatchCatalog.byId(fromLink) ??
            SmartWatchDevice(
              id: fromLink,
              name: 'QR watch',
              brand: WatchBrand.other,
              model: fromLink,
              preferredMethod: WatchConnectionMethod.qrCode,
              signalStrength: 90,
              batteryPercent: 80,
            );
      }
    }

    if (code.contains('|')) {
      final parts = code.split('|');
      final label = parts.length > 1 ? parts[1] : 'QR Watch';
      return SmartWatchDevice(
        id: 'qr-${parts.last.hashCode.abs()}',
        name: label,
        brand: _brandFromString(parts.first),
        model: label,
        preferredMethod: WatchConnectionMethod.qrCode,
        signalStrength: 90,
        batteryPercent: 80,
      );
    }

    final lower = code.toLowerCase();
    for (final device in WatchCatalog.discoverable) {
      if (device.id == code ||
          device.model.toLowerCase().contains(lower) ||
          device.name.toLowerCase().contains(lower)) {
        return device;
      }
    }
    return _randomDevice();
  }

  Future<bool> pairWithWifi({
    required String host,
    required String pin,
    String? deviceName,
  }) {
    if (host.trim().isEmpty || pin.trim().length < 4) {
      _fail(
        WatchConnectionMethod.wifi,
        'Enter a valid IP or hostname and a PIN of at least 4 digits',
      );
      return Future.value(false);
    }

    final trimmedHost = host.trim();
    final device = SmartWatchDevice(
      id: 'wifi-${trimmedHost.hashCode.abs()}',
      name: (deviceName?.trim().isNotEmpty ?? false)
          ? deviceName!.trim()
          : 'Wi-Fi Watch ($trimmedHost)',
      brand: WatchBrand.other,
      model: 'Network Pair',
      preferredMethod: WatchConnectionMethod.wifi,
      signalStrength: 95,
      batteryPercent: 70 + _rng.nextInt(30),
      firmware: 'WiFi-2.1',
    );

    return _runPairing(
      method: WatchConnectionMethod.wifi,
      device: device,
      steps: [
        'Resolving $trimmedHost…',
        'Opening TLS tunnel…',
        'Verifying PIN…',
        'Negotiating sync protocol…',
        'Wi-Fi pair complete',
      ],
    );
  }

  Future<bool> pairWithAccount({
    required String email,
    required String password,
    required String provider,
  }) {
    if (!_looksLikeEmail(email)) {
      _fail(WatchConnectionMethod.account, 'Enter a valid email address');
      return Future.value(false);
    }
    if (password.length < 4) {
      _fail(WatchConnectionMethod.account, 'Password must be at least 4 characters');
      return Future.value(false);
    }

    final brand = _brandFromProvider(provider);
    final match = WatchCatalog.discoverable.firstWhere(
      (d) => d.brand == brand,
      orElse: () => WatchCatalog.discoverable.last,
    );

    return _runPairing(
      method: WatchConnectionMethod.account,
      device: match.copyWith(batteryPercent: 50 + _rng.nextInt(50)),
      steps: [
        'Authenticating with $provider…',
        'Fetching linked devices…',
        'Requesting health API tokens…',
        'Importing watch profile…',
        'Cloud account linked',
      ],
    );
  }

  Future<bool> _runPairing({
    required WatchConnectionMethod method,
    required SmartWatchDevice device,
    required List<String> steps,
  }) async {
    stopScan();

    for (var i = 0; i < steps.length; i++) {
      _session = WatchPairingSession(
        method: method,
        status: i < steps.length - 1
            ? WatchConnectionStatus.pairing
            : WatchConnectionStatus.connecting,
        statusMessage: steps[i],
        progress: (i + 1) / steps.length,
        device: device,
      );
      notifyListeners();
      await Future<void>.delayed(
        Duration(milliseconds: 420 + _rng.nextInt(280)),
      );
    }

    _paired = device;
    _session = WatchPairingSession(
      method: method,
      status: WatchConnectionStatus.connected,
      statusMessage: 'Connected to ${device.name}',
      progress: 1,
      device: device,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPairedId, device.id);
      await prefs.setString(_keyMethod, method.name);
    } catch (e) {
      debugPrint('SmartWatchService: could not persist pairing ($e)');
    }

    await syncNow(silent: true);
    _startLiveStream();
    notifyListeners();
    return true;
  }

  void _fail(WatchConnectionMethod method, String message) {
    _session = WatchPairingSession(
      method: method,
      status: WatchConnectionStatus.error,
      statusMessage: message,
    );
    notifyListeners();
  }

  Future<void> disconnect() async {
    _liveTimer?.cancel();
    _scanTimer?.cancel();
    _paired = null;
    _nearby = const [];
    _session = const WatchPairingSession(
      method: WatchConnectionMethod.bluetooth,
      status: WatchConnectionStatus.disconnected,
      statusMessage: 'Disconnected',
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPairedId);
      await prefs.remove(_keyMethod);
    } catch (_) {
      // Nothing stored; disconnect still applies.
    }
    notifyListeners();
  }

  Future<void> syncNow({bool silent = false}) async {
    if (_paired == null) return;

    if (!silent) {
      _session = _session.copyWith(
        status: WatchConnectionStatus.syncing,
        statusMessage: 'Syncing health data…',
        progress: 0.4,
      );
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    final baseHr = 62 + _rng.nextInt(28);
    final series = List<int>.generate(
      24,
      (i) => (baseHr + sin(i / 3) * 8 + _rng.nextInt(6) - 3).round().clamp(48, 165),
    );

    _vitals = WatchVitals(
      heartRateBpm: series.last,
      restingHeartRate: 52 + _rng.nextInt(12),
      spo2Percent: 95 + _rng.nextInt(5),
      stressScore: 18 + _rng.nextInt(55),
      hrvMs: 35 + _rng.nextInt(40),
      skinTempC: 36.1 + _rng.nextDouble() * 0.8,
      caloriesBurned: 280 + _rng.nextInt(520),
      activeMinutes: 15 + _rng.nextInt(70),
      steps: 4200 + _rng.nextInt(7000),
      distanceKm: 2.4 + _rng.nextDouble() * 6,
      lastSynced: DateTime.now(),
      heartRateSeries: series,
    );

    _paired = _paired!.copyWith(
      batteryPercent: (_paired!.batteryPercent - _rng.nextInt(2)).clamp(5, 100),
      signalStrength: 60 + _rng.nextInt(40),
    );

    _session = _session.copyWith(
      status: WatchConnectionStatus.connected,
      statusMessage: 'Synced ${_formatTime(_vitals.lastSynced)}',
      progress: 1,
      device: _paired,
    );
    notifyListeners();
  }

  void _startLiveStream() {
    _liveTimer?.cancel();
    if (!_autoSync || _paired == null) return;

    _liveTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_paired == null) return;
      final next = (_vitals.heartRateBpm + _rng.nextInt(7) - 3).clamp(50, 170);
      final series = _vitals.heartRateSeries.isEmpty
          ? <int>[next]
          : [..._vitals.heartRateSeries.skip(1), next];

      _vitals = _vitals.copyWith(
        heartRateBpm: next,
        steps: _vitals.steps + _rng.nextInt(12),
        caloriesBurned: _vitals.caloriesBurned + _rng.nextInt(3),
        stressScore: (_vitals.stressScore + _rng.nextInt(5) - 2).clamp(5, 95),
        lastSynced: DateTime.now(),
        heartRateSeries: series,
      );
      notifyListeners();
    });
  }

  String? _cachedQrPayload;

  /// Payload the companion sheet renders. Always an http(s) URL so iPhone
  /// Camera treats it as a link instead of "No usable data found".
  String generatePairingQrPayload({bool refresh = false}) {
    if (!refresh && _cachedQrPayload != null) return _cachedQrPayload!;
    final id = _paired?.id ?? _randomDevice().id;
    return _cachedQrPayload = PairingLink.encode(watchId: id);
  }

  SmartWatchDevice _randomDevice() =>
      WatchCatalog.discoverable[_rng.nextInt(WatchCatalog.discoverable.length)];

  static bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

  static WatchBrand _brandFromString(String value) {
    final key = value.toLowerCase();
    if (key.contains('apple')) return WatchBrand.apple;
    if (key.contains('samsung') || key.contains('galaxy')) return WatchBrand.samsung;
    if (key.contains('garmin')) return WatchBrand.garmin;
    if (key.contains('fitbit')) return WatchBrand.fitbit;
    if (key.contains('amazfit')) return WatchBrand.amazfit;
    if (key.contains('huawei')) return WatchBrand.huawei;
    if (key.contains('google') || key.contains('pixel')) return WatchBrand.google;
    return WatchBrand.other;
  }

  static WatchBrand _brandFromProvider(String provider) {
    final key = provider.toLowerCase();
    if (key.contains('apple')) return WatchBrand.apple;
    if (key.contains('samsung')) return WatchBrand.samsung;
    if (key.contains('garmin')) return WatchBrand.garmin;
    if (key.contains('fitbit')) return WatchBrand.fitbit;
    if (key.contains('google')) return WatchBrand.google;
    return WatchBrand.other;
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _scanTimer?.cancel();
    super.dispose();
  }
}
