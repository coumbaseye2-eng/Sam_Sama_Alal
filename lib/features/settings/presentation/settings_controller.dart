import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/app_settings.dart';

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  late final LocalStorageService _storage;

  @override
  AppSettings build() {
    _storage = ref.read(localStorageServiceProvider);
    final settings = _storage.readSettings();
    Future.microtask(restoreOnlineSettings);
    return settings;
  }

  Future<void> updateLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await _storage.saveSettings(state);
    await _saveSettingsOnline();
  }

  Future<void> updateTheme(AppThemeChoice theme) async {
    state = state.copyWith(theme: theme);
    await _storage.saveSettings(state);
    await _saveSettingsOnline();
  }

  Future<void> updateNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _storage.saveSettings(state);
    await _saveSettingsOnline();
  }

  Future<void> restoreOnlineSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == 'local-user') {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('app')
          .get();
      final data = snapshot.data();
      if (data == null) {
        await _saveSettingsOnline();
        return;
      }

      state = AppSettings.fromJson(data);
      await _storage.saveSettings(state);
    } catch (error) {
      debugPrint('Firestore restoreOnlineSettings error: $error');
      // Les parametres locaux restent appliques si Firestore est indisponible.
    }
  }

  Future<void> _saveSettingsOnline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('Firestore settings skipped: no FirebaseAuth user.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('app')
          .set({
        ...state.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Firestore saveSettings error: $error');
      // Les parametres restent sauvegardes dans Hive en attendant Firestore.
    }
  }
}
