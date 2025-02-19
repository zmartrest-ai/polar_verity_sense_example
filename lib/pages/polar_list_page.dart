import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import 'package:polar_variety_sense_example/bluetooth_permission_handler.dart';
import 'package:polar_variety_sense_example/data_handler.dart';
import 'package:signals/signals_flutter.dart';

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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Flush remaining data when the app goes to the background or is about to close
      // DataHandler.flushData();
      // await polar.disconnectFromDevice(identifier.value);
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
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                logs.value = [''].toIList();
              },
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
              onPressed: () async {
                log('Connecting to device: ${identifier.value}');
                await polar.connectToDevice(identifier.value);
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
                      if (e.deviceId == 'E985E828') {
                        identifier.value = e.deviceId;
                        log('Found device in scan: ${e.deviceId}');
                      }
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
                    await polar.setLocalTime(identifier.value, DateTime.now());

                    final offlineRecordingStatus =
                        await polar.getOfflineRecordingStatus(identifier.value);

                    if (!offlineRecordingStatus.contains(PolarDataType.ppi)) {
                      await polar.startOfflineRecording(
                        identifier.value,
                        PolarDataType.ppi,
                        settings: PolarSensorSetting(<PolarSettingType, int>{}),
                      );
                    }

                    log('Start Offline Recording');
                  },
                  child: const Text('Start Offline Recording'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final offlineRecordingsType =
                        await polar.getOfflineRecordingStatus(identifier.value);

                    for (final recordingType in offlineRecordingsType) {
                      if (recordingType == PolarDataType.ppi) {
                        await polar.stopOfflineRecording(
                          identifier.value,
                          PolarDataType.ppi,
                        );
                      }
                    }
                    log('Stop Offline Recording');
                  },
                  child: const Text('Stop Offline Recording'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    var recordings =
                        await polar.listOfflineRecordings(identifier.value);

                    log('List Offline Recordings');
                    for (var r in recordings) {
                      log(r.toJson().toString());
                    }

                    if (recordings.isNotEmpty) {
                      for (final r in recordings) {
                        if (r.type == PolarDataType.ppi) {
                          final data = await polar.getOfflinePpiRecord(
                              identifier.value, r);
                          for (var s in data!.data.samples) {
                            debugPrint(
                                '(HR: ${s.hr}), (PPI: ${s.ppi}), (blockerBit: ${s.blockerBit}), (errorEstimate: ${s.errorEstimate}), (skinContactStatus: ${s.skinContactStatus})');
                          }
                        }
                      }
                    }
                  },
                  child: const Text('List Offline Recordings'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    var recordings =
                        await polar.listOfflineRecordings(identifier.value);

                    if (recordings.isNotEmpty) {
                      for (final r in recordings) {
                        await polar.removeOfflineRecord(identifier.value, r);
                      }
                    }
                  },
                  child: const Text('Remove Offline Recordings'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    logs.value = IList();
                  },
                  child: const Text('Clear logs!'),
                ),
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

  void log(String log) {
    logs.value = logs.value.add(log);
  }
}
