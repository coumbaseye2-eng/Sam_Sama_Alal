import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/notes/domain/personal_note.dart';
import '../../features/profile/domain/app_user.dart';
import '../../features/settings/domain/app_settings.dart';
import '../../features/stocks/domain/stock_item.dart';
import '../../features/transactions/domain/app_transaction.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class LocalStorageService {
  static const userBoxName = 'userBox';
  static const transactionBoxName = 'transactionBox';
  static const notesBoxName = 'notesBox';
  static const stocksBoxName = 'stocksBox';
  static const settingsBoxName = 'settingsBox';

  Box get _userBox => Hive.box(userBoxName);
  Box get _transactionBox => Hive.box(transactionBoxName);
  Box get _notesBox => Hive.box(notesBoxName);
  Box get _stocksBox => Hive.box(stocksBoxName);
  Box get _settingsBox => Hive.box(settingsBoxName);

  AppUser? readUser() {
    final data = _userBox.get('currentUser');
    if (data is Map) {
      return AppUser.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  bool readIsLoggedIn() {
    return _userBox.get('isLoggedIn', defaultValue: false) == true;
  }

  Future<void> saveUser(AppUser user, {required bool isLoggedIn}) async {
    await _userBox.put('currentUser', user.toJson());
    await _userBox.put('isLoggedIn', isLoggedIn);
  }

  Future<void> saveLoginState(bool isLoggedIn) async {
    await _userBox.put('isLoggedIn', isLoggedIn);
  }

  List<AppTransaction> readTransactions() {
    final rawItems = _transactionBox.get('items', defaultValue: <dynamic>[]);
    if (rawItems is! List) {
      return const [];
    }

    return rawItems
        .whereType<Map>()
        .map((item) => AppTransaction.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveTransactions(List<AppTransaction> transactions) async {
    await _transactionBox.put(
      'items',
      transactions.map((item) => item.toJson()).toList(),
    );
  }

  List<PersonalNote> readNotes() {
    final rawItems = _notesBox.get('items', defaultValue: <dynamic>[]);
    if (rawItems is! List) {
      return const [];
    }

    return rawItems
        .whereType<Map>()
        .map((item) => PersonalNote.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveNotes(List<PersonalNote> notes) async {
    await _notesBox.put(
      'items',
      notes.map((item) => item.toJson()).toList(),
    );
  }

  List<StockItem> readStocks() {
    final rawItems = _stocksBox.get('items', defaultValue: <dynamic>[]);
    if (rawItems is! List) {
      return const [];
    }

    return rawItems
        .whereType<Map>()
        .map((item) => StockItem.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveStocks(List<StockItem> stocks) async {
    await _stocksBox.put(
      'items',
      stocks.map((item) => item.toJson()).toList(),
    );
  }

  AppSettings readSettings() {
    final data = _settingsBox.get('appSettings');
    if (data is Map) {
      return AppSettings.fromJson(Map<String, dynamic>.from(data));
    }
    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('appSettings', settings.toJson());
  }

  Future<void> clearAccountData() async {
    await _userBox.clear();
    await _transactionBox.clear();
    await _notesBox.clear();
    await _stocksBox.clear();
  }
}
