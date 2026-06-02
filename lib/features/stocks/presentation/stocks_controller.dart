import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/stock_item.dart';

final stocksControllerProvider =
    NotifierProvider<StocksController, List<StockItem>>(
  StocksController.new,
);

class StocksController extends Notifier<List<StockItem>> {
  @override
  List<StockItem> build() {
    final stocks = ref.read(localStorageServiceProvider).readStocks();
    Future.microtask(restoreOnlineStocks);
    return stocks;
  }

  StockItem addStock({
    required String name,
    required String category,
    required int quantity,
    int unitPrice = 0,
    int alertThreshold = 3,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid ??
        ref.read(authControllerProvider).user?.uid ??
        'local-user';
    final stock = StockItem(
      id: const Uuid().v4(),
      uid: uid,
      name: name.trim().isEmpty ? 'Article' : name.trim(),
      category: category.trim().isEmpty ? 'Général' : category.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
      alertThreshold: alertThreshold,
      updatedAt: DateTime.now(),
    );

    state = [stock, ...state];
    ref.read(localStorageServiceProvider).saveStocks(state);
    _saveStockOnline(stock);
    final settings = ref.read(settingsControllerProvider);
    if (settings.notificationsEnabled && stock.isLow) {
      NotificationService.instance.showStockAlert(
        itemName: stock.name,
        quantity: stock.quantity,
      );
    }
    return stock;
  }

  void deleteStock(String id) {
    state = state.where((stock) => stock.id != id).toList();
    ref.read(localStorageServiceProvider).saveStocks(state);
    _deleteStockOnline(id);
  }

  void archiveStock(String id) {
    StockItem? selected;
    for (final stock in state) {
      if (stock.id == id) {
        selected = stock;
        break;
      }
    }
    if (selected == null || selected.isArchived) {
      return;
    }

    final updatedStock = selected.copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );

    state = [
      for (final stock in state)
        if (stock.id == id) updatedStock else stock,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    ref.read(localStorageServiceProvider).saveStocks(state);
    _saveStockOnline(updatedStock);
  }

  bool decreaseStock({
    required String id,
    required int quantity,
  }) {
    StockItem? selected;
    for (final stock in state) {
      if (stock.id == id) {
        selected = stock;
        break;
      }
    }

    if (selected == null || quantity <= 0 || selected.quantity < quantity) {
      return false;
    }

    final updatedStock = selected.copyWith(
      quantity: selected.quantity - quantity,
      updatedAt: DateTime.now(),
    );

    state = [
      for (final stock in state)
        if (stock.id == id) updatedStock else stock,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    ref.read(localStorageServiceProvider).saveStocks(state);
    _saveStockOnline(updatedStock);

    final settings = ref.read(settingsControllerProvider);
    if (settings.notificationsEnabled && updatedStock.isLow) {
      NotificationService.instance.showStockAlert(
        itemName: updatedStock.name,
        quantity: updatedStock.quantity,
      );
    }
    return true;
  }

  bool increaseStock({
    required String id,
    required int quantity,
  }) {
    StockItem? selected;
    for (final stock in state) {
      if (stock.id == id) {
        selected = stock;
        break;
      }
    }

    if (selected == null || quantity <= 0) {
      return false;
    }

    final updatedStock = selected.copyWith(
      quantity: selected.quantity + quantity,
      updatedAt: DateTime.now(),
    );

    state = [
      for (final stock in state)
        if (stock.id == id) updatedStock else stock,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    ref.read(localStorageServiceProvider).saveStocks(state);
    _saveStockOnline(updatedStock);
    return true;
  }

  Future<void> restoreOnlineStocks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == 'local-user') {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stocks')
          .doc(uid)
          .collection('items')
          .orderBy('updatedAt', descending: true)
          .get();

      final onlineStocks =
          snapshot.docs.map((doc) => StockItem.fromJson(doc.data())).toList();
      final mergedById = <String, StockItem>{
        for (final stock in onlineStocks) stock.id: stock,
        for (final stock in state) stock.id: stock,
      };

      state = mergedById.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      await ref.read(localStorageServiceProvider).saveStocks(state);
      for (final stock in state) {
        await _saveStockOnline(stock);
      }
    } catch (error) {
      debugPrint('Firestore restoreOnlineStocks error: $error');
      // Les stocks locaux restent disponibles si Firestore est indisponible.
    }
  }

  Future<void> _saveStockOnline(StockItem stock) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('Firestore stock skipped: no FirebaseAuth user.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('stocks')
          .doc(uid)
          .collection('items')
          .doc(stock.id)
          .set({
        ...stock.toJson(),
        'uid': uid,
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Firestore saveStock error: $error');
      // Le stock reste dans Hive et sera renvoye lors d'une prochaine session.
    }
  }

  Future<void> _deleteStockOnline(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('Firestore deleteStock skipped: no FirebaseAuth user.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('stocks')
          .doc(uid)
          .collection('items')
          .doc(id)
          .delete();
    } catch (error) {
      debugPrint('Firestore deleteStock error: $error');
    }
  }

  void updateStock({
    required String id,
    required String name,
    required String category,
    required int quantity,
    required int unitPrice,
    required int alertThreshold,
  }) {
    StockItem? selected;
    for (final stock in state) {
      if (stock.id == id) {
        selected = stock;
        break;
      }
    }
    if (selected == null) {
      return;
    }

    final updatedStock = selected.copyWith(
      name: name.trim().isEmpty ? selected.name : name.trim(),
      category: category.trim().isEmpty ? selected.category : category.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
      alertThreshold: alertThreshold,
      updatedAt: DateTime.now(),
    );

    state = [
      for (final stock in state)
        if (stock.id == id) updatedStock else stock,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    ref.read(localStorageServiceProvider).saveStocks(state);
    _saveStockOnline(updatedStock);
    final settings = ref.read(settingsControllerProvider);
    if (settings.notificationsEnabled && updatedStock.isLow) {
      NotificationService.instance.showStockAlert(
        itemName: updatedStock.name,
        quantity: updatedStock.quantity,
      );
    }
  }
}
