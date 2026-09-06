import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests runtime permissions needed for camera, mic, step tracking,
/// and smart-watch pairing over Bluetooth.
class PermissionsService {
  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> requestEssentialPermissions() async {
    if (!_supported) return;

    final permissions = <Permission>[
      Permission.camera,
      Permission.microphone,
      if (defaultTargetPlatform == TargetPlatform.android)
        Permission.activityRecognition,
      if (defaultTargetPlatform == TargetPlatform.iOS)
        Permission.sensors,
    ];

    await _request(permissions);
  }

  /// Requested lazily when the user actually starts a Bluetooth scan, so the
  /// prompt arrives with obvious context instead of at cold start.
  Future<bool> requestBluetoothPermissions() async {
    if (!_supported) return false;

    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    await _request(permissions);

    for (final permission in permissions) {
      try {
        if (!await permission.isGranted) return false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  Future<bool> requestNotificationPermission() async {
    if (!_supported) return false;
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Notification permission unavailable: $e');
      return false;
    }
  }

  Future<void> _request(List<Permission> permissions) async {
    for (final permission in permissions) {
      try {
        final status = await permission.status;
        if (status.isDenied || status.isLimited) {
          await permission.request();
        }
      } catch (e) {
        debugPrint('Permission request skipped for $permission: $e');
      }
    }
  }
}
