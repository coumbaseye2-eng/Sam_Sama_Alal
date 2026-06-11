import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';

final expenseCategoriesControllerProvider =
    NotifierProvider<ExpenseCategoriesController, List<String>>(
  ExpenseCategoriesController.new,
);

const defaultExpenseCategories = [
  'Stock',
  'Transport',
  'Loyer',
  'Electricite',
  'Eau',
  'Internet',
  'Salaire',
  'Maintenance',
  'Emballage',
  'Frais mobile money',
  'Autre',
];

class ExpenseCategoriesController extends Notifier<List<String>> {
  late final LocalStorageService _storage;

  @override
  List<String> build() {
    _storage = ref.read(localStorageServiceProvider);
    final savedCategories = _storage.readExpenseCategories();
    final categories =
        savedCategories.isEmpty ? defaultExpenseCategories : savedCategories;
    Future.microtask(_restoreOnlineCategories);
    return categories;
  }

  Future<void> addCategory(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty || _contains(cleaned)) return;
    state = [...state, cleaned];
    await _persist();
  }

  Future<void> updateCategory({
    required String oldName,
    required String newName,
  }) async {
    final cleaned = newName.trim();
    if (cleaned.isEmpty) return;
    if (oldName.toLowerCase() != cleaned.toLowerCase() && _contains(cleaned)) {
      return;
    }

    state = [
      for (final category in state)
        if (category == oldName) cleaned else category,
    ];
    await _persist();
  }

  Future<void> deleteCategory(String name) async {
    final next = state.where((category) => category != name).toList();
    state = next.isEmpty ? ['Autre'] : next;
    await _persist();
  }

  bool _contains(String name) {
    return state
        .any((category) => category.toLowerCase() == name.toLowerCase());
  }

  Future<void> _persist() async {
    await _storage.saveExpenseCategories(state);
    await _saveOnlineCategories();
  }

  Future<void> _restoreOnlineCategories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _storage.saveExpenseCategories(state);
        return;
      }

      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('expenseCategories')
          .get();

      final data = document.data();
      final rawItems = data?['items'];
      if (rawItems is List && rawItems.whereType<String>().isNotEmpty) {
        state = rawItems.whereType<String>().toList();
        await _storage.saveExpenseCategories(state);
      } else {
        await _saveOnlineCategories();
      }
    } catch (error) {
      debugPrint('Expense categories restore failed: $error');
    }
  }

  Future<void> _saveOnlineCategories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('expenseCategories')
          .set({
        'items': state,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('Expense categories sync failed: $error');
    }
  }
}
