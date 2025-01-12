import 'package:flutter/material.dart';
import 'package:polar/polar.dart';

/// Example app
class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  static const identifier = 'C36A972B';

  final polar = Polar();
  final logs = ['Service started'];

  PolarExerciseEntry? exerciseEntry;

  @override
  void initState() {
    super.initState();

    polar.searchForDevice().listen((e) {
      log('Found device in scan: ${e.deviceId}');
    }, onError: (e) {
      log('Error in scan: $e');
    });
    polar.batteryLevel.listen((e) => log('Battery: ${e.level}'));
    polar.deviceConnecting.listen((_) {
      log('Device connecting');
    }, onError: (e) {
      log('Device connection error: $e');
    });
    polar.deviceConnected.listen((_) => log('Device connected'));
    polar.deviceDisconnected.listen((_) {
      log('Device disconnected');
    }, onError: (e) {
      log('Device disconnection error: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polar example app'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => RecordingAction.values
                .map((e) => PopupMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onSelected: handleRecordingAction,
            child: const IconButton(
              icon: Icon(Icons.fiber_manual_record),
              disabledColor: Colors.white,
              onPressed: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () {
              log('Disconnecting from device: $identifier');
              polar.disconnectFromDevice(identifier);
            },
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              log('Connecting to device: $identifier');
              polar.connectToDevice(identifier);
              streamWhenReady();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        shrinkWrap: true,
        children: logs.reversed.map(Text.new).toList(),
      ),
    );
  }

  void streamWhenReady() async {
    await polar.sdkFeatureReady.firstWhere(
      (e) =>
          e.identifier == identifier &&
          e.feature == PolarSdkFeature.onlineStreaming,
    );
    final availabletypes =
        await polar.getAvailableOnlineStreamDataTypes(identifier);

    debugPrint('available types: $availabletypes');

    if (availabletypes.contains(PolarDataType.hr)) {
      polar
          .startHrStreaming(identifier)
          .listen((e) => log('Heart rate: ${e.samples.map((e) => e.hr)}'));
    }
    if (availabletypes.contains(PolarDataType.ecg)) {
      polar
          .startEcgStreaming(identifier)
          .listen((e) => log('ECG data received'));
    }
    if (availabletypes.contains(PolarDataType.acc)) {
      polar
          .startAccStreaming(identifier)
          .listen((e) => log('ACC data received'));
    }
  }

  void log(String log) {
    debugPrint(log);
    setState(() {
      logs.add(log);
    });
  }

  Future<void> handleRecordingAction(RecordingAction action) async {
    switch (action) {
      case RecordingAction.start:
        log('Starting recording');

        log('Started recording');
        break;
      case RecordingAction.stop:
        log('Stopping recording');
        await polar.stopRecording(identifier);
        log('Stopped recording');
        break;
      case RecordingAction.status:
        log('Getting recording status');
        final status = await polar.requestRecordingStatus(identifier);
        log('Recording status: $status');
        break;
      case RecordingAction.list:
        log('Listing recordings');
        final entries = await polar.listExercises(identifier);
        log('Recordings: $entries');
        // H10 can only store one recording at a time
        exerciseEntry = entries.first;
        break;
      case RecordingAction.fetch:
        log('Fetching recording');
        if (exerciseEntry == null) {
          log('Exercises not yet listed');
          await handleRecordingAction(RecordingAction.list);
        }
        final entry = await polar.fetchExercise(identifier, exerciseEntry!);
        log('Fetched recording: $entry');
        break;
      case RecordingAction.remove:
        log('Removing recording');
        if (exerciseEntry == null) {
          log('No exercise to remove. Try calling list first.');
          return;
        }
        await polar.removeExercise(identifier, exerciseEntry!);
        log('Removed recording');
        break;
    }
  }
}

enum RecordingAction {
  start,
  stop,
  status,
  list,
  fetch,
  remove,
}
