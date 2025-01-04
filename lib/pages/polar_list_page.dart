import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import 'package:polar_variety_sense_example/bluetooth_permission_handler.dart';
import 'package:polar_variety_sense_example/data_handler.dart';
import 'package:polar_variety_sense_example/enums.dart';
import 'package:polar_variety_sense_example/external_storage_permission_handler.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';

class PolarListPage extends StatefulWidget {
  const PolarListPage({super.key});

  static const String routeName = "PolarListPage";

  @override
  State<PolarListPage> createState() => _PolarListPageState();
}

class _PolarListPageState extends State<PolarListPage>
    with WidgetsBindingObserver {
  Signal<String> identifier = signal('');
  final polar = Polar();
  Signal<IList<String>> logs = signal(['Service started'].toIList());
  PolarExerciseEntry? exerciseEntry;

  @override
  void initState() {
    super.initState();

    // Register the observer to listen for lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);

    // Flush data on exit to ensure remaining buffered data is stored
    DataHandler.flushData();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Flush remaining data when the app goes to the background or is about to close
      DataHandler.flushData();
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Polar Lib'),
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
                if (identifier.value.isNotEmpty) {
                  // Ensure there's a device ID
                  log('Attempting to disconnect from device: ${identifier.value}');

                  try {
                    polar.disconnectFromDevice(identifier.value);
                    log('Disconnected from device: ${identifier.value}');
                  } catch (e) {
                    log('Error disconnecting from device: ${e.toString()}');
                  }
                } else {
                  log('No device connected to disconnect from.');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                log('Connecting to device: ${identifier.value}');
                polar.connectToDevice(identifier.value);
                // streamWhenReady();
              },
            ),
          ],
        ),
        body: Watch(
          (context) => SizedBox(
            height: size.height,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await BluetoothPermissionHandler
                        .requestBluetoothPermissions();

                    polar.searchForDevice().listen((e) {
                      identifier.value = e.deviceId;
                      log('Found device in scan: ${e.deviceId}');
                    });

                    polar.batteryLevel
                        .listen((e) => log('Battery: ${e.level}'));
                    polar.deviceConnecting
                        .listen((_) => log('Device connecting'));
                    polar.deviceConnected
                        .listen((_) => log('Device connected'));
                    polar.deviceDisconnected
                        .listen((_) => log('Device disconnected'));
                  },
                  child: const Text('Scan for devices'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await ExternalStoragePermissionHandler
                        .requestExternalStoragePermissions();
                  },
                  child: const Text('Export database'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await DataHandler.clearDatabase();
                    log('Database cleared.');
                  },
                  child: const Text('Clear Database'),
                ),
                // ElevatedButton(
                //   onPressed: () async {
                //     // Request recording settings
                //     var settings = await polar.requestOfflineRecordingSettings(
                //         identifier.value, PolarDataType.acc);

                //     // Start offline recording (with optional encryption)
                //     await polar.startOfflineRecording(
                //         identifier.value, PolarDataType.acc,
                //         settings: settings);

                //     log('Start Offline Recording');
                //   },
                //   child: const Text('Start Offline Recording'),
                // ),
                // ElevatedButton(
                //   onPressed: () async {
                //     // Stop recording
                //     final status =
                //         await polar.getOfflineRecordingStatus(identifier.value);

                //     log('Get Recording Statis ${status.toString()}');
                //   },
                //   child: const Text('Get Recording Status'),
                // ),
                // ElevatedButton(
                //   onPressed: () async {
                //     // Stop recording
                //     await polar.stopOfflineRecording(
                //         identifier.value, PolarDataType.acc);

                //     log('Stop Offline Recording');
                //   },
                //   child: const Text('Stop Offline Recording'),
                // ),
                // ElevatedButton(
                //   onPressed: () async {
                //     // Stop recording
                //     var recordings =
                //         await polar.listOfflineRecordings(identifier.value);

                //     log('List Offline Recordings');
                //     recordings.forEach((r) => log(r.toJson().toString()));

                //     if (recordings.isNotEmpty) {
                //       final record = await polar.getOfflineAccRecord(
                //           identifier.value, recordings[0]);
                //       print("Got here!");
                //     }
                //   },
                //   child: const Text('List Offline Recordings'),
                // ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    shrinkWrap: true,
                    children: logs.value.reversed.map(Text.new).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void streamWhenReady() async {
    await polar.sdkFeatureReady.firstWhere(
      (e) =>
          e.identifier == identifier.value &&
          e.feature == PolarSdkFeature.onlineStreaming,
    );

    final availableTypes =
        await polar.getAvailableOnlineStreamDataTypes(identifier.value);

    if (availableTypes.contains(PolarDataType.acc)) {
      polar.startAccStreaming(identifier.value).listen((e) {
        final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
        final latestSampleTimestamp =
            e.samples.last.timeStamp.millisecondsSinceEpoch;

        for (var sample in e.samples) {
          final timeDifference =
              latestSampleTimestamp - sample.timeStamp.millisecondsSinceEpoch;
          final adjustedTimestamp = currentTimestamp - timeDifference;

          DataHandler.addAccData(adjustedTimestamp, sample.x / 1000,
              sample.y / 1000, sample.z / 1000);
          // log('ACC: X ${sample.x}, Y ${sample.y}, Z ${sample.z}, Adjusted Time: $adjustedTimestamp');
        }
      });
    }

    if (availableTypes.contains(PolarDataType.ppi)) {
      polar.startPpiStreaming(identifier.value).listen((e) {
        // Get the baseline timestamp from the current time
        final baselineTimestamp = DateTime.now().millisecondsSinceEpoch;

        // Initialize cumulative time offset
        int cumulativePpiOffset = 0;

        // Temporary list to store adjusted samples in forward-accumulating order
        final List<Map<String, dynamic>> tempSamples = [];

        for (var sample in e.samples) {
          // Add the sample's PPI interval to the cumulative offset
          cumulativePpiOffset += sample.ppi;

          // Calculate the sample's adjusted timestamp
          final adjustedTimestamp = baselineTimestamp - cumulativePpiOffset;

          // Save the adjusted data in the temporary list
          tempSamples.add({
            'timestamp': adjustedTimestamp,
            'ppi': sample.ppi,
            'hr': sample.hr,
          });
        }

        // Insert each sample in reverse order (oldest to newest)
        for (var sampleData in tempSamples.reversed) {
          DataHandler.addHrData(
            sampleData['timestamp'] as int,
            sampleData['ppi'] as int,
            sampleData['hr'] as int?,
          );
          print(
              'PPI: ${sampleData['ppi']}, HR: ${sampleData['hr']}, Adjusted Time: ${sampleData['timestamp']}');
        }
      });
    }
  }

  Future<void> handleRecordingAction(RecordingAction action) async {
    switch (action) {
      case RecordingAction.start:
        log('Starting recording');
        await polar.startRecording(
          identifier.value,
          exerciseId: const Uuid().v4(),
          interval: RecordingInterval.interval_1s,
          sampleType: SampleType.rr,
        );
        log('Started recording');
        break;
      case RecordingAction.stop:
        log('Stopping recording');
        await polar.stopRecording(identifier.value);
        log('Stopped recording');
        break;
      case RecordingAction.status:
        log('Getting recording status');
        final status = await polar.requestRecordingStatus(identifier.value);
        log('Recording status: $status');
        break;
      case RecordingAction.list:
        log('Listing recordings');
        final entries = await polar.listExercises(identifier.value);
        log('Recordings: $entries');
        exerciseEntry = entries.first;
        break;
      case RecordingAction.fetch:
        log('Fetching recording');
        if (exerciseEntry == null) {
          log('Exercises not yet listed');
          await handleRecordingAction(RecordingAction.list);
        }
        final entry =
            await polar.fetchExercise(identifier.value, exerciseEntry!);
        log('Fetched recording: $entry');
        break;
      case RecordingAction.remove:
        log('Removing recording');
        if (exerciseEntry == null) {
          log('No exercise to remove. Try calling list first.');
          return;
        }
        await polar.removeExercise(identifier.value, exerciseEntry!);
        log('Removed recording');
        break;
    }
  }

  void log(String log) {
    debugPrint(log);
    logs.value = logs.value.add(log);
  }
}
