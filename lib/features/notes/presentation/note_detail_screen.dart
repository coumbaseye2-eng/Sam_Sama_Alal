import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/personal_note.dart';
import 'notes_controller.dart';

class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesControllerProvider);
    PersonalNote? note;
    for (final item in notes) {
      if (item.id == noteId) {
        note = item;
        break;
      }
    }

    if (note == null) {
      return const PrimaryScaffold(
        title: 'Carnet',
        body: SectionCard(child: Text('Information introuvable.')),
      );
    }

    if (note.kind == PersonalNoteKind.debt) {
      return _DebtDetail(note: note);
    }

    return PrimaryScaffold(
      title: note.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Text(note.content.isEmpty ? 'Note vide' : note.content),
          ),
          const SizedBox(height: 12),
          Text(
            'Dernière modification : ${_formatDate(note.updatedAt)}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _DebtDetail extends ConsumerWidget {
  const _DebtDetail({required this.note});

  final PersonalNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = note.initialAmount == 0
        ? 0.0
        : (note.paidAmount / note.initialAmount).clamp(0.0, 1.0);

    return PrimaryScaffold(
      title: note.clientName.isEmpty ? note.title : note.clientName,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              children: [
                _ClientAvatar(photoPath: note.photoPath),
                const SizedBox(height: 10),
                Text(
                  note.clientName.isEmpty ? note.title : note.clientName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note.debtDirection == DebtDirection.customerOwesMe
                      ? 'Ce client me doit de l’argent'
                      : 'Je dois de l’argent à ce client',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: note.phoneNumber.trim().isEmpty
                            ? null
                            : () => _launchPhone(note.phoneNumber),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Appel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: note.phoneNumber.trim().isEmpty
                            ? null
                            : () => _launchWhatsapp(note.phoneNumber),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Évolution de la dette',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _AmountTile(
                        label: 'Montant',
                        value: note.initialAmount,
                        color: AppColors.text,
                      ),
                    ),
                    Expanded(
                      child: _AmountTile(
                        label: 'Avance',
                        value: note.paidAmount,
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _AmountTile(
                        label: note.isDebtPaid ? 'Remboursé' : 'Reste',
                        value: note.remainingAmount,
                        color: note.isDebtPaid
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: note.isDebtPaid
                      ? null
                      : () => _showPaymentDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une avance'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations générales',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                _InfoLine(label: 'Téléphone', value: note.phoneNumber),
                _InfoLine(
                  label: 'Numéro d’identité',
                  value: note.nationalId,
                ),
                _InfoLine(label: 'Note', value: note.content),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Historique des avances',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (note.payments.isEmpty)
                  const Text('Aucune avance enregistrée.')
                else
                  ...note.payments.map(
                    (payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatAmount(payment.amount)} FCFA',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  payment.note.isEmpty
                                      ? _formatDate(payment.createdAt)
                                      : '${_formatDate(payment.createdAt)} · ${payment.note}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context, WidgetRef ref) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<({int amount, String note})>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ajouter une avance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(amountController.text.trim()) ?? 0;
                Navigator.of(dialogContext).pop(
                  (amount: amount, note: noteController.text),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    amountController.dispose();
    noteController.dispose();

    if (result == null || result.amount <= 0) return;
    ref.read(notesControllerProvider.notifier).addDebtPayment(
          id: note.id,
          amount: result.amount,
          note: result.note,
        );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    await _launchExternal(Uri(scheme: 'tel', path: phoneNumber.trim()));
  }

  Future<void> _launchWhatsapp(String phoneNumber) async {
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    await _launchExternal(Uri.parse('https://wa.me/$digits'));
  }

  Future<void> _launchExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 3),
        Text(
          '${_formatAmount(value)} FCFA',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(child: Text(value.trim().isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final file = photoPath.isEmpty ? null : File(photoPath);
    if (file != null && file.existsSync()) {
      return CircleAvatar(
        radius: 42,
        backgroundImage: FileImage(file),
      );
    }

    return const CircleAvatar(
      radius: 42,
      backgroundColor: AppColors.primarySoft,
      child: Icon(Icons.person_outline, color: AppColors.primary, size: 42),
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
