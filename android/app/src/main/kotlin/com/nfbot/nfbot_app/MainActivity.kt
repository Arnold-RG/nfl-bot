package com.nfbot.nfbot_app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Native bridge exposing device capability checks the watch hub needs
/// before it attempts a real Bluetooth or Health Connect handshake.
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "com.nfbot.nfbot_app/device"
        const val HEALTH_CONNECT_PACKAGE = "com.google.android.apps.healthdata"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceCapabilities" -> result.success(deviceCapabilities())
                    "isBluetoothEnabled" -> result.success(isBluetoothEnabled())
                    "openBluetoothSettings" -> {
                        startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                        result.success(true)
                    }
                    "isHealthConnectAvailable" -> result.success(isHealthConnectAvailable())
                    "getBatteryLevel" -> {
                        val level = batteryLevel()
                        if (level >= 0) {
                            result.success(level)
                        } else {
                            result.error("UNAVAILABLE", "Battery level unavailable", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun deviceCapabilities(): Map<String, Any> = mapOf(
        "platform" to "android",
        "sdkInt" to Build.VERSION.SDK_INT,
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
        "bluetoothSupported" to (bluetoothAdapter() != null),
        "bluetoothEnabled" to isBluetoothEnabled(),
        "healthConnectAvailable" to isHealthConnectAvailable(),
        "batteryLevel" to batteryLevel()
    )

    private fun bluetoothAdapter(): BluetoothAdapter? {
        val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        return manager?.adapter
    }

    private fun isBluetoothEnabled(): Boolean = bluetoothAdapter()?.isEnabled == true

    private fun isHealthConnectAvailable(): Boolean = try {
        packageManager.getPackageInfo(HEALTH_CONNECT_PACKAGE, 0)
        true
    } catch (e: Exception) {
        false
    }

    private fun batteryLevel(): Int {
        val manager = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        return manager?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
    }
}
