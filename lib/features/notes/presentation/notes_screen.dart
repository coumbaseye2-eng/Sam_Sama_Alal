import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/personal_note.dart';
import 'notes_controller.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesControllerProvider).where((note) {
      final query = _query.toLowerCase().trim();
      if (query.isEmpty) {
        return true;
      }
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();

    return PrimaryScaffold(
      title: 'Carnet',
      actions: [
        IconButton(
          onPressed: () => _openNoteSheet(context),
          icon: const Icon(Icons.add),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher une note',
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _openNoteSheet(context),
            icon: const Icon(Icons.note_add),
            label: const Text('Nouvelle note'),
          ),
          const SizedBox(height: 18),
          if (notes.isEmpty)
            const SectionCard(
              child: Text('Aucune note pour le moment.'),
            )
          else
            ...notes.map((note) => _NoteCard(
                  note: note,
                  onTap: () => _openNoteSheet(context, note: note),
                  onEdit: () => _openNoteSheet(context, note: note),
                  onDelete: () => ref
                      .read(notesControllerProvider.notifier)
                      .deleteNote(note.id),
                )),
        ],
      ),
    );
  }

  Future<void> _openNoteSheet(BuildContext context,
      {PersonalNote? note}) async {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                note == null ? 'Nouvelle note' : 'Modifier la note',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                minLines: 4,
                maxLines: 8,
                decoration:
                    const InputDecoration(labelText: 'Note personnelle'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text;
                  final content = contentController.text;
                  if (content.trim().isEmpty && title.trim().isEmpty) {
                    Navigator.of(context).pop();
                    return;
                  }

                  if (note == null) {
                    ref.read(notesControllerProvider.notifier).addNote(
                          title: title,
                          content: content,
                        );
                  } else {
                    ref.read(notesControllerProvider.notifier).updateNote(
                          id: note.id,
                          title: title,
                          content: content,
                        );
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        );
      },
    );

    titleController.dispose();
    contentController.dispose();
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final PersonalNote note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SectionCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Icon(Icons.sticky_note_2_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.content.isEmpty ? 'Note vide' : note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(note.updatedAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
