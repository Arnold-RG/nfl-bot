import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceCapabilities {
  final String platform;
  final String model;
  final String manufacturer;
  final bool bluetoothSupported;
  final bool bluetoothEnabled;
  final bool healthConnectAvailable;
  final int batteryLevel;

  const DeviceCapabilities({
    required this.platform,
    required this.model,
    required this.manufacturer,
    required this.bluetoothSupported,
    required this.bluetoothEnabled,
    required this.healthConnectAvailable,
    required this.batteryLevel,
  });

  /// Conservative defaults for platforms without a native bridge yet.
  static DeviceCapabilities unknown(String platform) => DeviceCapabilities(
        platform: platform,
        model: 'unknown',
        manufacturer: 'unknown',
        bluetoothSupported: false,
        bluetoothEnabled: false,
        healthConnectAvailable: false,
        batteryLevel: -1,
      );
}

/// Talks to the native layer for capabilities the Dart side cannot inspect,
/// so the watch hub can explain *why* a pairing method is unavailable.
class DeviceBridgeService {
  static const _channel = MethodChannel('com.nfbot.nfbot_app/device');

  DeviceCapabilities? _cached;
  DeviceCapabilities? get cached => _cached;

  bool get _bridgeAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<DeviceCapabilities> capabilities({bool refresh = false}) async {
    if (_cached != null && !refresh) return _cached!;

    if (!_bridgeAvailable) {
      _cached = DeviceCapabilities.unknown(
        kIsWeb ? 'web' : defaultTargetPlatform.name,
      );
      return _cached!;
    }

    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getDeviceCapabilities',
      );
      _cached = DeviceCapabilities(
        platform: raw?['platform']?.toString() ?? 'android',
        model: raw?['model']?.toString() ?? 'unknown',
        manufacturer: raw?['manufacturer']?.toString() ?? 'unknown',
        bluetoothSupported: raw?['bluetoothSupported'] == true,
        bluetoothEnabled: raw?['bluetoothEnabled'] == true,
        healthConnectAvailable: raw?['healthConnectAvailable'] == true,
        batteryLevel: (raw?['batteryLevel'] as num?)?.round() ?? -1,
      );
    } on PlatformException catch (e) {
      debugPrint('DeviceBridgeService: capability lookup failed (${e.message})');
      _cached = DeviceCapabilities.unknown('android');
    } on MissingPluginException {
      _cached = DeviceCapabilities.unknown('android');
    }

    return _cached!;
  }

  Future<bool> isBluetoothEnabled() async {
    if (!_bridgeAvailable) return false;
    try {
      return await _channel.invokeMethod<bool>('isBluetoothEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openBluetoothSettings() async {
    if (!_bridgeAvailable) return;
    try {
      await _channel.invokeMethod<void>('openBluetoothSettings');
    } catch (e) {
      debugPrint('DeviceBridgeService: could not open Bluetooth settings ($e)');
    }
  }
}
