import 'package:flutter/material.dart';
import 'package:polar_variety_sense_example/app.dart';
import 'package:polar_variety_sense_example/background_job/background_job.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeBackgroundJob();

  runApp(const MyApp());
}
