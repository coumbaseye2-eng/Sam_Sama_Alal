import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/personal_note.dart';

final notesControllerProvider =
    NotifierProvider<NotesController, List<PersonalNote>>(NotesController.new);

class NotesController extends Notifier<List<PersonalNote>> {
  @override
  List<PersonalNote> build() {
    return ref.read(localStorageServiceProvider).readNotes();
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
  }

  void deleteNote(String id) {
    state = state.where((note) => note.id != id).toList();
    ref.read(localStorageServiceProvider).saveNotes(state);
  }
}
