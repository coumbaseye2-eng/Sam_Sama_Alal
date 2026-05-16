import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/app_transaction.dart';
import '../domain/transaction_type.dart';

final transactionsControllerProvider =
    NotifierProvider<TransactionsController, List<AppTransaction>>(
  TransactionsController.new,
);

final latestTransactionProvider = Provider<AppTransaction?>((ref) {
  final transactions = ref.watch(transactionsControllerProvider);
  return transactions.isEmpty ? null : transactions.first;
});

final balanceProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsControllerProvider);
  return transactions.fold<int>(0, (total, item) => total + item.signedAmount);
});

class TransactionsController extends Notifier<List<AppTransaction>> {
  @override
  List<AppTransaction> build() {
    final transactions =
        ref.read(localStorageServiceProvider).readTransactions();
    Future.microtask(syncPendingTransactions);
    return transactions;
  }

  AppTransaction addTransaction({
    required TransactionType type,
    required int amount,
    required String category,
    required String paymentMethod,
  }) {
    final uid = ref.read(authControllerProvider).user?.uid ?? 'local-user';
    final transaction = AppTransaction(
      id: const Uuid().v4(),
      uid: uid,
      type: type,
      amount: amount,
      category: category,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );

    state = [transaction, ...state];
    ref.read(localStorageServiceProvider).saveTransactions(state);
    _saveTransactionOnline(transaction);
    return transaction;
  }

  Future<void> syncPendingTransactions() async {
    final pending = state.where((transaction) => !transaction.synced).toList();
    for (final transaction in pending) {
      await _saveTransactionOnline(transaction);
    }
  }

  Future<void> restoreOnlineTransactions() async {
    final uid = ref.read(authControllerProvider).user?.uid;
    if (uid == null || uid == 'local-user') {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .doc(uid)
          .collection('items')
          .orderBy('dateHeure', descending: true)
          .get();

      final onlineTransactions = snapshot.docs
          .map((doc) => AppTransaction.fromFirestore(doc.data()))
          .toList();
      final mergedById = <String, AppTransaction>{
        for (final transaction in onlineTransactions)
          transaction.id: transaction,
        for (final transaction in state) transaction.id: transaction,
      };

      state = mergedById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await ref.read(localStorageServiceProvider).saveTransactions(state);
      await syncPendingTransactions();
    } catch (_) {
      await syncPendingTransactions();
    }
  }

  Future<void> _saveTransactionOnline(AppTransaction transaction) async {
    if (transaction.uid == 'local-user') {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(transaction.uid)
          .collection('items')
          .doc(transaction.id)
          .set(transaction.toFirestore(), SetOptions(merge: true));

      _markAsSynced(transaction.id);
    } catch (_) {
      // Hive garde la transaction en attente; elle sera renvoyée plus tard.
    }
  }

  void _markAsSynced(String transactionId) {
    state = [
      for (final transaction in state)
        if (transaction.id == transactionId)
          transaction.copyWith(synced: true)
        else
          transaction,
    ];
    ref.read(localStorageServiceProvider).saveTransactions(state);
  }
}
