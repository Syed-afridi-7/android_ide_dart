import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_ide/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestStoragePermissions();
  runApp(const MyApp());
}

Future<void> _requestStoragePermissions() async {
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }
}
