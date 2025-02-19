import 'dart:async';

import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import 'package:polar_variety_sense_example/background_job/sensor_handler.dart';

/// Called from the background fetch plugin on iOS and the workmanager plugin on Android
///
/// It connects to the sensor and reads the sensor memory before sending its content
/// to the API
///
/// @pragma is mandatory if the App is obfuscated or using Flutter 3.1+
@pragma('vm:entry-point')
Future backgroundJobCallback({
  /// The periodic background fetch on iOS is time restricted to 30 seconds
  required bool timeRestricted,
  bool isTestJob = false,
}) async {
  const identifier = 'E985E828';
  final sensorHandler = BackgroundJobSensorHandlerPolar(identifier, Polar());

  try {
    final sensor = await sensorHandler.connect(
      const Duration(seconds: 30),
    );

    debugPrint('Connect Completed');

    final offlineRecordingsType =
        await sensor.getOfflineRecordingStatus(identifier);

    for (final recordingType in offlineRecordingsType) {
      if (recordingType == PolarDataType.ppi) {
        await sensor.stopOfflineRecording(
          identifier,
          PolarDataType.ppi,
        );
      }
    }
    debugPrint('Stop Offline Recording Completed');

    var recordings = await sensor.listOfflineRecordings(identifier);

    for (var r in recordings) {
      debugPrint(r.toJson().toString());
    }

    if (recordings.isNotEmpty) {
      for (final r in recordings) {
        if (r.type == PolarDataType.ppi) {
          final data = await sensor.getOfflinePpiRecord(identifier, r);
          for (var s in data!.data.samples) {
            debugPrint(
                '(HR: ${s.hr}), (PPI: ${s.ppi}), (blockerBit: ${s.blockerBit}), (errorEstimate: ${s.errorEstimate}), (skinContactStatus: ${s.skinContactStatus})');
          }
        }
        await sensor.removeOfflineRecord(identifier, r);
      }
    }

    debugPrint('List Offline Recordings And Removed Completed');
  } catch (e) {
    debugPrint('exception in background task: $e');
  } finally {
    await sensorHandler.disconnect();
  }
}
