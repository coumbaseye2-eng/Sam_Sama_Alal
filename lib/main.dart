import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  await Hive.openBox('notesBox');
  await Hive.openBox(LocalStorageService.stocksBoxName);

  runApp(const ProviderScope(child: SamSamaApp()));
}
