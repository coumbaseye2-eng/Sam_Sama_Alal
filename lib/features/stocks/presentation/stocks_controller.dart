import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/stock_item.dart';

final stocksControllerProvider =
    NotifierProvider<StocksController, List<StockItem>>(
  StocksController.new,
);

class StocksController extends Notifier<List<StockItem>> {
  @override
  List<StockItem> build() {
    return ref.read(localStorageServiceProvider).readStocks();
  }

  StockItem addStock({
    required String name,
    required String category,
    required int quantity,
    int unitPrice = 0,
    int alertThreshold = 3,
  }) {
    final stock = StockItem(
      id: const Uuid().v4(),
      uid: 'local-user',
      name: name.trim().isEmpty ? 'Article' : name.trim(),
      category: category.trim().isEmpty ? 'Général' : category.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
      alertThreshold: alertThreshold,
      updatedAt: DateTime.now(),
    );

    state = [stock, ...state];
    ref.read(localStorageServiceProvider).saveStocks(state);
    return stock;
  }

  void deleteStock(String id) {
    state = state.where((stock) => stock.id != id).toList();
    ref.read(localStorageServiceProvider).saveStocks(state);
  }
}

