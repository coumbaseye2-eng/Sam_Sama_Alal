import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/notifications/notification_service.dart';
import 'core/storage/local_storage_service.dart';
import 'firebase_options.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox(LocalStorageService.userBoxName);
  await Hive.openBox(LocalStorageService.transactionBoxName);
  await Hive.openBox(LocalStorageService.notesBoxName);
  await Hive.openBox(LocalStorageService.stocksBoxName);
  await Hive.openBox(LocalStorageService.settingsBoxName);
  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: SamSamaApp()));
}
