import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// A utility class to handle Bluetooth permissions across platforms
class BluetoothPermissionHandler {
  /// Checks if Bluetooth is enabled on the device
  static Future<bool> isBluetoothEnabled() async {
    try {
      if (Platform.isAndroid) {
        return await Permission.bluetoothConnect.isGranted;
      } else if (Platform.isIOS) {
        return await Permission.bluetooth.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking if Bluetooth is enabled: $e');
      return false;
    }
  }

  /// Checks if Bluetooth is available and permissions are granted
  static Future<bool> checkBluetoothAvailability() async {
    try {
      if (Platform.isAndroid) {
        // On Android, we need both scan and connect permissions
        bool scanGranted = await Permission.bluetoothScan.isGranted;
        bool connectGranted = await Permission.bluetoothConnect.isGranted;

        // For Android 11 and below, location permission is also required for scanning
        bool locationGranted = await Permission.location.isGranted;

        return scanGranted && connectGranted && locationGranted;
      } else if (Platform.isIOS) {
        // On iOS, we just need the Bluetooth permission
        return await Permission.bluetooth.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking Bluetooth availability: $e');
      return false;
    }
  }

  /// Requests all necessary Bluetooth permissions
  static Future<bool> requestBluetoothPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Request Bluetooth Scan permission
        PermissionStatus scanStatus = await Permission.bluetoothScan.request();

        // Request Bluetooth Connect permission
        PermissionStatus connectStatus =
            await Permission.bluetoothConnect.request();

        // Request Location permission (required for Bluetooth scanning on Android 11 and below)
        PermissionStatus locationStatus = await Permission.location.request();

        return scanStatus.isGranted &&
            connectStatus.isGranted &&
            locationStatus.isGranted;
      } else if (Platform.isIOS) {
        // Request Bluetooth permission on iOS
        PermissionStatus status = await Permission.bluetooth.request();
        return status.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting Bluetooth permissions: $e');
      return false;
    }
  }
}
