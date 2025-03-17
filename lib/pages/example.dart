import 'package:flutter/material.dart';
import 'package:polar/polar.dart';

/// Example app
class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  static const identifier = 'E985E828';

  final polar = Polar();
  final logs = ['Service started'];

  @override
  void initState() {
    super.initState();

    polar.batteryLevel.listen((e) => log('Battery: ${e.level}'));
    polar.deviceConnecting.listen((_) => log('Device connecting'));
    polar.deviceConnected.listen((_) => log('Device connected'));
    polar.deviceDisconnected.listen((_) => log('Device disconnected'));
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Polar example app'),
        ),
        body: SizedBox(
            height: size.height,
            child: Column(children: [
              ElevatedButton(
                onPressed: () async {
                  polar.searchForDevice().listen((e) {
                    if (e.deviceId == 'E985E828') {
                      log('Found device in scan: ${e.deviceId}');
                    }
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
              ElevatedButton(
                onPressed: () async {
                  polar.connectToDevice(identifier);
                },
                child: const Text('Connect to device'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  polar.disconnectFromDevice(identifier);
                },
                child: const Text('Disconnect from device'),
              ),
              ListView(
                padding: const EdgeInsets.all(10),
                shrinkWrap: true,
                children: logs.reversed.map(Text.new).toList(),
              )
            ])),
      ),
    );
  }

  void log(String log) {
    debugPrint(log);
    setState(() {
      logs.add(log);
    });
  }
}
