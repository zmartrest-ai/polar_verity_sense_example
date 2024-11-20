import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polar_variety_sense_example/app.dart';
import 'package:polar_variety_sense_example/data_handler.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the database singleton in GetIt
  GetIt.instance.registerSingletonAsync<Database>(() async {
    return await DataHandler.initDatabase();
  });

  // Wait for the database to be initialized
  await GetIt.instance.allReady();

  runApp(const MyApp());
}
