import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/personal_note.dart';
import 'note_detail_screen.dart';
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
    final allNotes = ref.watch(notesControllerProvider);
    final notes = allNotes.where((note) {
      final query = _query.toLowerCase().trim();
      if (query.isEmpty) return true;
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.clientName.toLowerCase().contains(query) ||
          note.phoneNumber.toLowerCase().contains(query) ||
          note.nationalId.toLowerCase().contains(query);
    }).toList();

    return PrimaryScaffold(
      title: 'Carnet',
      actions: [
        IconButton(
          tooltip: 'Nouvelle note',
          onPressed: () => _openNoteSheet(context),
          icon: const Icon(Icons.note_add_outlined),
        ),
        IconButton(
          tooltip: 'Nouvelle dette',
          onPressed: () => _openDebtSheet(context),
          icon: const Icon(Icons.person_add_alt_1_outlined),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher une note ou un client',
            ),
          ),
          const SizedBox(height: 14),
          _DebtSummary(notes: allNotes),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openNoteSheet(context),
                  icon: const Icon(Icons.note_add),
                  label: const Text('Note'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDebtSheet(context),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Dette'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (notes.isEmpty)
            const SectionCard(
              child: Text('Aucune information pour le moment.'),
            )
          else
            ...notes.map(
              (note) => _NoteCard(
                note: note,
                onTap: () => _openDetail(note.id),
                onEdit: () => note.kind == PersonalNoteKind.debt
                    ? _openDebtSheet(context, note: note)
                    : _openNoteSheet(context, note: note),
                onDelete: () => ref
                    .read(notesControllerProvider.notifier)
                    .deleteNote(note.id),
              ),
            ),
        ],
      ),
    );
  }

  void _openDetail(String noteId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteDetailScreen(noteId: noteId),
      ),
    );
  }

  Future<void> _openNoteSheet(
    BuildContext context, {
    PersonalNote? note,
  }) async {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  note == null ? 'Nouvelle note' : 'Modifier la note',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
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
          ),
        );
      },
    );

    titleController.dispose();
    contentController.dispose();
  }

  Future<void> _openDebtSheet(
    BuildContext context, {
    PersonalNote? note,
  }) async {
    final nameController = TextEditingController(text: note?.clientName ?? '');
    final phoneController =
        TextEditingController(text: note?.phoneNumber ?? '');
    final nationalIdController =
        TextEditingController(text: note?.nationalId ?? '');
    final amountController = TextEditingController(
      text: note?.initialAmount == 0 ? '' : note?.initialAmount.toString(),
    );
    final contentController = TextEditingController(text: note?.content ?? '');
    var direction = note?.debtDirection ?? DebtDirection.customerOwesMe;
    var photoPath = note?.photoPath ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      note == null ? 'Nouvelle dette' : 'Modifier la dette',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final image = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (image == null) return;
                          setSheetState(() => photoPath = image.path);
                        },
                        child: _ClientAvatar(photoPath: photoPath, radius: 38),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<DebtDirection>(
                      segments: const [
                        ButtonSegment(
                          value: DebtDirection.customerOwesMe,
                          label: Text('Il me doit'),
                        ),
                        ButtonSegment(
                          value: DebtDirection.iOweCustomer,
                          label: Text('Je dois'),
                        ),
                      ],
                      selected: {direction},
                      onSelectionChanged: (value) {
                        setSheetState(() => direction = value.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Nom du client'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nationalIdController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro d’identité nationale',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Montant total'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Information générale',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final amount =
                            int.tryParse(amountController.text.trim()) ?? 0;
                        if (nameController.text.trim().isEmpty && amount <= 0) {
                          Navigator.of(context).pop();
                          return;
                        }

                        final notifier =
                            ref.read(notesControllerProvider.notifier);
                        if (note == null) {
                          notifier.addDebtNote(
                            clientName: nameController.text,
                            content: contentController.text,
                            debtDirection: direction,
                            initialAmount: amount,
                            phoneNumber: phoneController.text,
                            nationalId: nationalIdController.text,
                            photoPath: photoPath,
                          );
                        } else {
                          notifier.updateDebtNote(
                            id: note.id,
                            clientName: nameController.text,
                            content: contentController.text,
                            debtDirection: direction,
                            initialAmount: amount,
                            phoneNumber: phoneController.text,
                            nationalId: nationalIdController.text,
                            photoPath: photoPath,
                          );
                        }
                        Navigator.of(context).pop();
                      },
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    nationalIdController.dispose();
    amountController.dispose();
    contentController.dispose();
  }
}

class _DebtSummary extends StatelessWidget {
  const _DebtSummary({required this.notes});

  final List<PersonalNote> notes;

  @override
  Widget build(BuildContext context) {
    final debts = notes.where((note) => note.kind == PersonalNoteKind.debt);
    final receivable = debts
        .where((note) => note.debtDirection == DebtDirection.customerOwesMe)
        .fold<int>(0, (sum, note) => sum + note.remainingAmount);
    final payable = debts
        .where((note) => note.debtDirection == DebtDirection.iOweCustomer)
        .fold<int>(0, (sum, note) => sum + note.remainingAmount);
    final paid = debts.where((note) => note.isDebtPaid).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'À recevoir',
            value: '${_formatAmount(receivable)} FCFA',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'À payer',
            value: '${_formatAmount(payable)} FCFA',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Remboursé',
            value: '$paid',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
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
              if (note.kind == PersonalNoteKind.debt)
                _ClientAvatar(photoPath: note.photoPath)
              else
                const CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(
                    Icons.sticky_note_2_outlined,
                    color: AppColors.primary,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: note.kind == PersonalNoteKind.debt
                    ? _DebtCardContent(note: note)
                    : _PlainNoteContent(note: note),
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
}

class _PlainNoteContent extends StatelessWidget {
  const _PlainNoteContent({required this.note});

  final PersonalNote note;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _DebtCardContent extends StatelessWidget {
  const _DebtCardContent({required this.note});

  final PersonalNote note;

  @override
  Widget build(BuildContext context) {
    final progress = note.initialAmount == 0
        ? 0.0
        : (note.paidAmount / note.initialAmount).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                note.clientName.isEmpty ? note.title : note.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            _StatusBadge(note: note),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          note.debtDirection == DebtDirection.customerOwesMe
              ? 'Le client me doit'
              : 'Je dois au client',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 6),
        Text(
          'Avance ${_formatAmount(note.paidAmount)} / '
          '${_formatAmount(note.initialAmount)} FCFA · '
          'reste ${_formatAmount(note.remainingAmount)} FCFA',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.note});

  final PersonalNote note;

  @override
  Widget build(BuildContext context) {
    final paid = note.isDebtPaid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: paid ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        paid ? 'Payé' : 'En cours',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: paid ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.photoPath, this.radius = 22});

  final String photoPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final file = photoPath.isEmpty ? null : File(photoPath);
    if (file != null && file.existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(file),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      child: Icon(
        Icons.person_outline,
        color: AppColors.primary,
        size: radius,
      ),
    );
  }
}

String _formatAmount(int amount) {
  return amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]} ',
      );
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
