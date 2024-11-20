import 'dart:io';
import 'dart:math';

import 'package:get_it/get_it.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class DataHandler {
  static IList<Map<String, dynamic>> _accBuffer = IList();
  static IList<Map<String, dynamic>> _hrBuffer = IList();

  static const int _bufferSize = 50;
  static const int _windowIntervalMillis = 5000;
  static bool _isInserting = false;

  // Initialize the database
  static Future<Database> initDatabase() async {
    final dbPath = await getDatabasePath();
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE acc_raw (
            timestamp INTEGER PRIMARY KEY,
            x REAL,
            y REAL,
            z REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE acc (
            timestamp INTEGER PRIMARY KEY,
            x REAL,
            y REAL,
            z REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE hr (
            timestamp INTEGER PRIMARY KEY,
            rToRInterval INTEGER,
            heartRate INTEGER
          )
        ''');
      },
    );
  }

  // Flush any remaining buffered data to the database
  static Future<void> flushData() async {
    await _insertAccBatch();
    await _insertHrBatch();
  }

  // Clear all data from the database tables
  static Future<void> clearDatabase() async {
    final db = GetIt.instance<Database>();

    try {
      await db.transaction((txn) async {
        await txn.delete('acc_raw');
        await txn.delete('acc');
        await txn.delete('hr');
      });
      print('Database cleared successfully.');
    } catch (e) {
      print('Error clearing database: $e');
    }
  }

  static Future<void> addAccData(
      int timestamp, double x, double y, double z) async {
    _accBuffer =
        _accBuffer.add({'timestamp': timestamp, 'x': x, 'y': y, 'z': z});

    if (_shouldInsertData()) {
      await _insertAccBatch();
    }
  }

  static bool _shouldInsertData() {
    if (_accBuffer.isEmpty) return false;
    final firstTimestamp = _accBuffer.first['timestamp'] as int;
    final lastTimestamp = _accBuffer.last['timestamp'] as int;
    return (lastTimestamp - firstTimestamp) >= _windowIntervalMillis;
  }

  static Future<void> _insertAccBatch() async {
    if (_accBuffer.isNotEmpty && !_isInserting) {
      _isInserting = true;
      final db = GetIt.instance<Database>();

      final List<Map<String, dynamic>> accBufferClone = _accBuffer.unlock;

      try {
        await db.transaction((txn) async {
          for (var data in accBufferClone) {
            await txn.insert(
              'acc_raw',
              data,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }

          final stdDevValues = _calculateStdDev(accBufferClone);
          final avgTimestamp = (accBufferClone.first['timestamp'] +
                  accBufferClone.last['timestamp']) ~/
              2;
          await txn.insert(
            'acc',
            {
              'timestamp': avgTimestamp,
              'x': stdDevValues['x'],
              'y': stdDevValues['y'],
              'z': stdDevValues['z'],
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        });

        _accBuffer = _accBuffer.clear();
      } catch (e) {
        print('Error inserting accelerometer data: $e');
      } finally {
        _isInserting = false;
      }
    }
  }

  static Map<String, double> _calculateStdDev(
      List<Map<String, dynamic>> buffer) {
    List<double> xValues = buffer.map((e) => e['x'] as double).toList();
    List<double> yValues = buffer.map((e) => e['y'] as double).toList();
    List<double> zValues = buffer.map((e) => e['z'] as double).toList();

    return {
      'x': _standardDeviation(xValues),
      'y': _standardDeviation(yValues),
      'z': _standardDeviation(zValues),
    };
  }

  static double _standardDeviation(List<double> values) {
    double mean = values.reduce((a, b) => a + b) / values.length;
    double sumOfSquares =
        values.map((x) => pow(x - mean, 2).toDouble()).reduce((a, b) => a + b);
    return sqrt(sumOfSquares / values.length);
  }

  static Future<void> addHrData(
      int timestamp, int rToRInterval, int? heartRate) async {
    _hrBuffer = _hrBuffer.add({
      'timestamp': timestamp,
      'rToRInterval': rToRInterval,
      'heartRate': heartRate
    });

    if (_hrBuffer.length >= _bufferSize) {
      await _insertHrBatch();
    }
  }

  static Future<void> _insertHrBatch() async {
    if (_hrBuffer.isNotEmpty) {
      final db = GetIt.instance<Database>();

      try {
        final List<Map<String, dynamic>> hrBufferClone = _hrBuffer.unlock;

        await db.transaction((txn) async {
          for (var data in hrBufferClone) {
            await txn.insert(
              'hr',
              data,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        });

        _hrBuffer = _hrBuffer.clear();
      } catch (e) {
        print('Error inserting heart rate data: $e');
      }
    }
  }

  static Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    String dbName = 'polar_sqlite_database.db';
    return join(databasesPath, dbName);
  }

  static Future<void> exportDatabase() async {
    try {
      String dbPath = await getDatabasePath();

      if (await File(dbPath).exists()) {
        Directory? externalDirectory = await getExternalStorageDirectory();
        String downloadsPath =
            '/storage/emulated/0/Download/exported_polar_sqlite_database.db';

        await File(dbPath).copy(downloadsPath);
        print('Database exported to: $downloadsPath');
      } else {
        print('Database file does not exist.');
      }
    } catch (e) {
      print('Error exporting database: $e');
    }
  }
}
