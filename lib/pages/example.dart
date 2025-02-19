import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import 'package:polar_variety_sense_example/bluetooth_permission_handler.dart';
import 'package:signals/signals_flutter.dart';

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  Signal<String> identifier = signal('');

  final polar = Polar();
  Signal<IList<String>> logs = signal(['Service started'].toIList());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Polar example app'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                logs.value = IList(const []);
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                log('Disconnecting from device: $identifier');
                polar.disconnectFromDevice(identifier.value);
              },
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                log('Connecting to device: $identifier');
                polar.connectToDevice(identifier.value);
                streamWhenReady();
              },
            ),
          ],
        ),
        body: Watch(
          (context) => ListView(
            padding: const EdgeInsets.all(10),
            shrinkWrap: true,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await BluetoothPermissionHandler
                      .requestBluetoothPermissions();

                  polar.searchForDevice().listen((e) {
                    identifier.value = e.deviceId;
                    log('Found device in scan: ${e.deviceId}');
                  });

                  polar.batteryLevel.listen((e) => log('Battery: ${e.level}'));
                  polar.deviceConnecting
                      .listen((_) => log('Device connecting'));
                  polar.deviceConnected.listen((_) => log('Device connected'));
                  polar.deviceDisconnected
                      .listen((_) => log('Device disconnected'));
                },
                child: const Text('Scan for devices'),
              ),
              ...logs.value.reversed.map(Text.new).toList()
            ],
          ),
        ));
  }

  void streamWhenReady() async {
    await polar.sdkFeatureReady.firstWhere(
      (e) =>
          e.identifier == identifier.value &&
          e.feature == PolarSdkFeature.onlineStreaming,
    );

    final availabletypes =
        await polar.getAvailableOnlineStreamDataTypes(identifier.value);

    debugPrint('available types: $availabletypes');

    if (availabletypes.contains(PolarDataType.ppi)) {
      polar.startPpiStreaming(identifier.value).listen((e) {
        e.samples.map((s) => {
              log('(HR: ${s.hr}), (PPI: ${s.ppi}), (blockerBit: ${s.blockerBit}), (errorEstimate: ${s.errorEstimate}), (skinContactStatus: ${s.skinContactStatus})')
            });
      });
    }
  }

  void log(String log) {
    debugPrint(log);
    logs.value = logs.value.add(log);
  }
}
