import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/barista_ble_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'ui/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage
  final storageService = await StorageService.init();

  // Initialize Native BLE Service
  final bleService = BaristaBleService(storageService: storageService);

  // Request Runtime Permissions on Mobile & Desktop Platforms
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
    await _requestBlePermissions();
  }

  runApp(BaristaStudioApp(
    bleService: bleService,
    storageService: storageService,
  ));
}

Future<void> _requestBlePermissions() async {
  try {
    if (Platform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await Permission.bluetooth.request();
    }
  } catch (e) {
    debugPrint('Error requesting permissions: $e');
  }
}

class BaristaStudioApp extends StatelessWidget {
  final BaristaBleService bleService;
  final StorageService storageService;

  const BaristaStudioApp({
    super.key,
    required this.bleService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barista Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeShell(
        bleService: bleService,
        storageService: storageService,
      ),
    );
  }
}
