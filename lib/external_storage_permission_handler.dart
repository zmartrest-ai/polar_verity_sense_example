import 'package:permission_handler/permission_handler.dart';
import 'package:polar_variety_sense_example/data_handler.dart';

class ExternalStoragePermissionHandler {
  static Future<void> requestExternalStoragePermissions() async {
    if (await Permission.storage.request().isGranted) {
      // Permission granted, proceed with exporting
      await DataHandler.exportDatabase();
    } else {
      print('Storage permission not granted');
    }
  }
}
