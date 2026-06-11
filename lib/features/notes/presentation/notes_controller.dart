import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/personal_note.dart';

final notesControllerProvider =
    NotifierProvider<NotesController, List<PersonalNote>>(NotesController.new);

class NotesController extends Notifier<List<PersonalNote>> {
  @override
  List<PersonalNote> build() {
    final notes = ref.read(localStorageServiceProvider).readNotes();
    Future.microtask(restoreOnlineNotes);
    return notes;
  }

  void addNote({required String title, required String content}) {
    final now = DateTime.now();
    final note = PersonalNote(
      id: const Uuid().v4(),
      title: title.trim().isEmpty ? 'Sans titre' : title.trim(),
      content: content.trim(),
      createdAt: now,
      updatedAt: now,
    );

    state = [note, ...state];
    ref.read(localStorageServiceProvider).saveNotes(state);
    _saveNoteOnline(note);
  }

  void addDebtNote({
    required String clientName,
    required String content,
    required DebtDirection debtDirection,
    required int initialAmount,
    required String phoneNumber,
    required String nationalId,
    required String photoPath,
  }) {
    final now = DateTime.now();
    final cleanName = clientName.trim();
    final note = PersonalNote(
      id: const Uuid().v4(),
      title: cleanName.isEmpty ? 'Client sans nom' : cleanName,
      content: content.trim(),
      createdAt: now,
      updatedAt: now,
      kind: PersonalNoteKind.debt,
      debtDirection: debtDirection,
      clientName: cleanName,
      phoneNumber: phoneNumber.trim(),
      nationalId: nationalId.trim(),
      photoPath: photoPath.trim(),
      initialAmount: initialAmount,
    );

    state = [note, ...state];
    ref.read(localStorageServiceProvider).saveNotes(state);
    _saveNoteOnline(note);
  }

  void updateNote({
    required String id,
    required String title,
    required String content,
  }) {
    state = [
      for (final note in state)
        if (note.id == id)
          note.copyWith(
            title: title.trim().isEmpty ? 'Sans titre' : title.trim(),
            content: content.trim(),
            updatedAt: DateTime.now(),
          )
        else
          note,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    ref.read(localStorageServiceProvider).saveNotes(state);
    PersonalNote? note;
    for (final item in state) {
      if (item.id == id) {
        note = item;
        break;
      }
    }
    if (note != null) {
      _saveNoteOnline(note);
    }
  }

  void updateDebtNote({
    required String id,
    required String clientName,
    required String content,
    required DebtDirection debtDirection,
    required int initialAmount,
    required String phoneNumber,
    required String nationalId,
    required String photoPath,
  }) {
    final cleanName = clientName.trim();
    state = [
      for (final note in state)
        if (note.id == id)
          note.copyWith(
            title: cleanName.isEmpty ? 'Client sans nom' : cleanName,
            content: content.trim(),
            updatedAt: DateTime.now(),
            kind: PersonalNoteKind.debt,
            debtDirection: debtDirection,
            clientName: cleanName,
            phoneNumber: phoneNumber.trim(),
            nationalId: nationalId.trim(),
            photoPath: photoPath.trim(),
            initialAmount: initialAmount,
          )
        else
          note,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _persistAndSync(id);
  }

  void addDebtPayment({
    required String id,
    required int amount,
    String note = '',
  }) {
    if (amount <= 0) return;
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            updatedAt: DateTime.now(),
            payments: [
              DebtPayment(
                id: const Uuid().v4(),
                amount: amount,
                createdAt: DateTime.now(),
                note: note.trim(),
              ),
              ...item.payments,
            ],
          )
        else
          item,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _persistAndSync(id);
  }

  void deleteNote(String id) {
    state = state.where((note) => note.id != id).toList();
    ref.read(localStorageServiceProvider).saveNotes(state);
    _deleteNoteOnline(id);
  }

  void _persistAndSync(String id) {
    ref.read(localStorageServiceProvider).saveNotes(state);
    PersonalNote? note;
    for (final item in state) {
      if (item.id == id) {
        note = item;
        break;
      }
    }
    if (note != null) {
      _saveNoteOnline(note);
    }
  }

  Future<void> restoreOnlineNotes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == 'local-user') {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notes')
          .doc(uid)
          .collection('items')
          .orderBy('updatedAt', descending: true)
          .get();

      final onlineNotes = snapshot.docs
          .map((doc) => PersonalNote.fromJson(doc.data()))
          .toList();
      final mergedById = <String, PersonalNote>{
        for (final note in onlineNotes) note.id: note,
        for (final note in state) note.id: note,
      };

      state = mergedById.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      await ref.read(localStorageServiceProvider).saveNotes(state);
      for (final note in state) {
        await _saveNoteOnline(note);
      }
    } catch (error) {
      debugPrint('Firestore restoreOnlineNotes error: $error');
      // Les notes locales restent disponibles si Firestore est indisponible.
    }
  }

  Future<void> _saveNoteOnline(PersonalNote note) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('Firestore note skipped: no FirebaseAuth user.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(uid)
          .collection('items')
          .doc(note.id)
          .set(note.toJson(), SetOptions(merge: true));
    } catch (error) {
      debugPrint('Firestore saveNote error: $error');
      // La note reste dans Hive et sera renvoyee lors d'une prochaine session.
    }
  }

  Future<void> _deleteNoteOnline(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('Firestore deleteNote skipped: no FirebaseAuth user.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(uid)
          .collection('items')
          .doc(id)
          .delete();
    } catch (error) {
      debugPrint('Firestore deleteNote error: $error');
      // Suppression locale deja appliquee.
    }
  }
}
