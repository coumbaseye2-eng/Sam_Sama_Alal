import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    String? stockItemId,
    String? productName,
    int quantity = 1,
    int unitPrice = 0,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid ??
        ref.read(authControllerProvider).user?.uid ??
        'local-user';
    final transaction = AppTransaction(
      id: const Uuid().v4(),
      uid: uid,
      type: type,
      amount: amount,
      category: category,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      stockItemId: stockItemId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
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

  void deleteTransaction(AppTransaction transaction) {
    state = state.where((item) => item.id != transaction.id).toList();
    ref.read(localStorageServiceProvider).saveTransactions(state);
    _deleteTransactionOnline(transaction.id);
  }

  Future<void> restoreOnlineTransactions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
    } catch (error) {
      debugPrint('Firestore restoreOnlineTransactions error: $error');
      await syncPendingTransactions();
    }
  }

  Future<void> _saveTransactionOnline(AppTransaction transaction) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('Firestore transaction skipped: no FirebaseAuth user.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(uid)
          .collection('items')
          .doc(transaction.id)
          .set({
        ...transaction.toFirestore(),
        'uid': uid,
      }, SetOptions(merge: true));

      _markAsSynced(transaction.id);
    } catch (error) {
      debugPrint('Firestore saveTransaction error: $error');
      // Hive garde la transaction en attente; elle sera renvoyée plus tard.
    }
  }

  Future<void> _deleteTransactionOnline(String transactionId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('Firestore deleteTransaction skipped: no FirebaseAuth user.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(uid)
          .collection('items')
          .doc(transactionId)
          .delete();
    } catch (error) {
      debugPrint('Firestore deleteTransaction error: $error');
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
