import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math';

class DatabaseHelper {
  // Initialization function for GetIt registration
  static Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'polar_sqlite_database.db');

    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS acc_raw(timestamp INTEGER PRIMARY KEY, x DOUBLE NOT NULL, y DOUBLE NOT NULL, z DOUBLE NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS acc(timestamp INTEGER PRIMARY KEY, x DOUBLE NOT NULL, y DOUBLE NOT NULL, z DOUBLE NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS hr(timestamp INTEGER PRIMARY KEY, rToRInterval INTEGER NOT NULL, heartRate INTEGER NOT NULL)',
        );
      },
      version: 1,
    );
  }
}

Future<String> getDatabasePath() async {
  // Get the default databases directory path
  final databasesPath = await getDatabasesPath();

  // Replace with your actual database name
  String dbName = 'polar_sqlite_database.db';

  // Return the full path to the database file
  return join(databasesPath, dbName);
}

Future<void> exportDatabase() async {
  try {
    // Get the path of the existing database
    String dbPath = await getDatabasePath();

    // Check if the database exists
    if (await File(dbPath).exists()) {
      // Use the Downloads directory for easier access
      Directory? externalDirectory = await getExternalStorageDirectory();

      // Fallback to Downloads folder if the path is not accessible
      String downloadsPath =
          '/storage/emulated/0/Download/exported_polar_sqlite_database.db';

      // Copy the database file to the Downloads directory
      await File(dbPath).copy(downloadsPath);

      print('Database exported to: $downloadsPath');
    } else {
      print('Database file does not exist.');
    }
  } catch (e) {
    print('Error exporting database: $e');
  }
}

class DataHandler {
  static final List<Map<String, dynamic>> _accBuffer = [];
  static final List<Map<String, dynamic>> _hrBuffer = [];
  static const int _bufferSize = 50;
  static const int _windowIntervalMillis = 5000; // 5 seconds

  // Adding accelerometer data
  static Future<void> addAccData(
      int timestamp, double x, double y, double z) async {
    _accBuffer.add({'timestamp': timestamp, 'x': x, 'y': y, 'z': z});

    // Check if we have accumulated data over the 5-second interval
    if (_shouldInsertData()) {
      await _insertAccBatch();
    }
  }

  // Checks if the buffer contains data over the 5-second interval
  static bool _shouldInsertData() {
    if (_accBuffer.isEmpty) return false;

    // Get the timestamps of the first and last entries
    final firstTimestamp = _accBuffer.first['timestamp'] as int;
    final lastTimestamp = _accBuffer.last['timestamp'] as int;

    // Check if the time difference exceeds 5 seconds (5000 ms)
    return (lastTimestamp - firstTimestamp) >= _windowIntervalMillis;
  }

  // Helper function to calculate standard deviation
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

// Standard deviation calculation for a list of values
  static double _standardDeviation(List<double> values) {
    double mean = values.reduce((a, b) => a + b) / values.length;
    double sumOfSquares =
        values.map((x) => pow(x - mean, 2).toDouble()).reduce((a, b) => a + b);
    return sqrt(sumOfSquares / values.length);
  }

  // Adding heart rate data remains unchanged
  static Future<void> addHrData(
      int timestamp, int rToRInterval, int? heartRate) async {
    _hrBuffer.add({
      'timestamp': timestamp,
      'rToRInterval': rToRInterval,
      'heartRate': heartRate
    });

    if (_hrBuffer.length >= _bufferSize) {
      await _insertHrBatch();
    }
  }

// Batch insert for accelerometer data
  static Future<void> _insertAccBatch() async {
    if (_accBuffer.isNotEmpty) {
      final batchData = List<Map<String, dynamic>>.from(_accBuffer);
      final db = GetIt.instance<Database>();

      try {
        await db.transaction((txn) async {
          for (var data in batchData) {
            await txn.insert(
              'acc',
              data,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        });

        // Log the number of items inserted
        print('Inserted ${batchData.length} accelerometer data entries.');

        // Clear only the inserted data, ensuring we don't exceed bounds
        if (_accBuffer.length >= batchData.length) {
          _accBuffer.removeRange(0, batchData.length);
        } else {
          _accBuffer.clear();
        }
      } catch (e) {
        print('Error inserting accelerometer data: $e');
      }
    }
  }

// Batch insert for heart rate data
  static Future<void> _insertHrBatch() async {
    if (_hrBuffer.isNotEmpty) {
      final batchData = List<Map<String, dynamic>>.from(_hrBuffer);
      final db = GetIt.instance<Database>();

      try {
        await db.transaction((txn) async {
          for (var data in batchData) {
            await txn.insert(
              'hr',
              data,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        });

        // Clear only the inserted data, ensuring we don't exceed bounds
        if (_hrBuffer.length >= batchData.length) {
          _hrBuffer.removeRange(0, batchData.length);
        } else {
          _hrBuffer.clear();
        }
      } catch (e) {
        print('Error inserting heart rate data: $e');
      }
    }
  }

  // Flush remaining data in the buffers on app exit remains unchanged
  static Future<void> flushData() async {
    await _insertAccBatch();
    await _insertHrBatch();
  }

  static Future<void> clearDatabase() async {
    final db = GetIt.instance<Database>();
    await db.delete('acc'); // Clear accelerometer data
    await db.delete('hr'); // Clear heart rate data
  }
}
