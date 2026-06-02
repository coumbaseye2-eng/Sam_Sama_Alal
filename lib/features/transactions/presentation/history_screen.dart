import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:sam_sama_alal/core/theme/app_colors.dart';
import 'package:sam_sama_alal/core/widgets/primary_scaffold.dart';
import 'package:sam_sama_alal/core/widgets/section_card.dart';
import 'package:sam_sama_alal/features/auth/presentation/auth_controller.dart';
import 'package:sam_sama_alal/features/stocks/presentation/stocks_controller.dart';
import 'package:sam_sama_alal/features/transactions/data/receipt_service.dart';
import 'package:sam_sama_alal/features/transactions/domain/app_transaction.dart';
import 'package:sam_sama_alal/features/transactions/domain/transaction_type.dart';
import 'package:sam_sama_alal/features/transactions/presentation/transaction_tile.dart';
import 'package:sam_sama_alal/features/transactions/presentation/transactions_controller.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const _galleryChannel = MethodChannel('sam_sama_alal/gallery');

  TransactionType? _filter;
  String _query = '';
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final transactions =
        ref.watch(transactionsControllerProvider).where((item) {
      final matchesType = _filter == null || item.type == _filter;
      final query = _query.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          item.category.toLowerCase().contains(query) ||
          (item.productName ?? '').toLowerCase().contains(query) ||
          item.paymentMethod.toLowerCase().contains(query);
      return matchesType && matchesQuery;
    }).toList();
    final balance = ref.watch(balanceProvider);
    final user = ref.watch(authControllerProvider).user;
    final selectedTransactions = transactions
        .where((transaction) => _selectedIds.contains(transaction.id))
        .toList();

    return PrimaryScaffold(
      title: 'Historique',
      actions: [
        IconButton(
          onPressed: transactions.isEmpty
              ? null
              : () => _openExportOptions(
                    context,
                    visibleTransactions: transactions,
                    selectedTransactions: selectedTransactions,
                  ),
          icon: const Icon(Icons.save_alt),
        )
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Rechercher'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tous'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              ChoiceChip(
                label: const Text('Ventes'),
                selected: _filter == TransactionType.sale,
                onSelected: (_) =>
                    setState(() => _filter = TransactionType.sale),
              ),
              ChoiceChip(
                label: const Text('Dépenses'),
                selected: _filter == TransactionType.expense,
                onSelected: (_) =>
                    setState(() => _filter = TransactionType.expense),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (transactions.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedTransactions.isEmpty
                        ? 'Coche les transactions à partager'
                        : '${selectedTransactions.length} transaction(s) sélectionnée(s)',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (selectedTransactions.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_selectedIds.clear),
                    child: const Text('Annuler'),
                  ),
              ],
            ),
          if (selectedTransactions.isNotEmpty) ...[
            const SizedBox(height: 10),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${selectedTransactions.length} transaction(s) prête(s) à exporter',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareHistory(
                            context,
                            transactions: selectedTransactions,
                            fileLabel: 'transactions_selectionnees',
                          ),
                          icon: const Icon(Icons.ios_share),
                          label: const Text('Exporter'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _saveHistoryToDevice(
                            context,
                            transactions: selectedTransactions,
                            fileLabel: 'transactions_selectionnees',
                          ),
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (transactions.isNotEmpty) const SizedBox(height: 8),
          if (transactions.isEmpty)
            const SectionCard(child: Text('Aucune transaction trouvée.'))
          else
            ...transactions.map(
              (transaction) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Checkbox(
                      value: _selectedIds.contains(transaction.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedIds.add(transaction.id);
                          } else {
                            _selectedIds.remove(transaction.id);
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: TransactionTile(
                      transaction,
                      onReceipt: transaction.type != TransactionType.sale
                          ? null
                          : () async {
                              await const ReceiptService().shareReceipt(
                                transaction: transaction,
                                balanceAfter: balance,
                                user: user,
                              );
                            },
                      onDelete: () => _confirmDelete(context, transaction),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppTransaction transaction,
  ) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Supprimer la transaction ?'),
              content: const Text(
                'Cette action supprimera la transaction de l’historique.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Supprimer'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) return;

    if (transaction.type == TransactionType.sale &&
        transaction.stockItemId != null) {
      ref.read(stocksControllerProvider.notifier).increaseStock(
            id: transaction.stockItemId!,
            quantity: transaction.quantity,
          );
    }

    ref
        .read(transactionsControllerProvider.notifier)
        .deleteTransaction(transaction);
    _selectedIds.remove(transaction.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction supprimée')),
      );
    }
  }

  Future<void> _openExportOptions(
    BuildContext context, {
    required List<AppTransaction> visibleTransactions,
    required List<AppTransaction> selectedTransactions,
  }) async {
    final now = DateTime.now();
    final currentMonthTransactions = visibleTransactions.where((transaction) {
      return transaction.createdAt.year == now.year &&
          transaction.createdAt.month == now.month;
    }).toList();

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Exporter l’historique',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choisis quoi exporter, puis partage vers WhatsApp, Bluetooth, galerie/fichiers ou une autre application.',
                ),
                const SizedBox(height: 16),
                if (selectedTransactions.isNotEmpty)
                  _ExportOption(
                    icon: Icons.ios_share,
                    title: 'Partager la sélection',
                    subtitle:
                        'WhatsApp, Bluetooth, galerie/fichiers selon téléphone',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _shareHistory(
                        context,
                        transactions: selectedTransactions,
                        fileLabel: 'transactions_selectionnees',
                      );
                    },
                  ),
                if (selectedTransactions.isNotEmpty)
                  _ExportOption(
                    icon: Icons.save_alt,
                    title: 'Enregistrer la sélection',
                    subtitle: '${selectedTransactions.length} transaction(s)',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _saveHistoryToDevice(
                        context,
                        transactions: selectedTransactions,
                        fileLabel: 'transactions_selectionnees',
                      );
                    },
                  ),
                _ExportOption(
                  icon: Icons.ios_share,
                  title: 'Partager le mois en cours',
                  subtitle: '${currentMonthTransactions.length} transaction(s)',
                  onTap: currentMonthTransactions.isEmpty
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          _shareHistory(
                            context,
                            transactions: currentMonthTransactions,
                            fileLabel:
                                'historique_${now.year}_${now.month.toString().padLeft(2, '0')}',
                          );
                        },
                ),
                _ExportOption(
                  icon: Icons.save_alt,
                  title: 'Enregistrer le mois en cours',
                  subtitle: '${currentMonthTransactions.length} transaction(s)',
                  onTap: currentMonthTransactions.isEmpty
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          _saveHistoryToDevice(
                            context,
                            transactions: currentMonthTransactions,
                            fileLabel:
                                'historique_${now.year}_${now.month.toString().padLeft(2, '0')}',
                          );
                        },
                ),
                _ExportOption(
                  icon: Icons.ios_share,
                  title: 'Partager tout l’historique affiché',
                  subtitle: '${visibleTransactions.length} transaction(s)',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _shareHistory(
                      context,
                      transactions: visibleTransactions,
                      fileLabel: 'historique_transactions',
                    );
                  },
                ),
                _ExportOption(
                  icon: Icons.save_alt,
                  title: 'Enregistrer tout l’historique affiché',
                  subtitle: '${visibleTransactions.length} transaction(s)',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _saveHistoryToDevice(
                      context,
                      transactions: visibleTransactions,
                      fileLabel: 'historique_transactions',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareHistory(
    BuildContext context, {
    required List<AppTransaction> transactions,
    required String fileLabel,
  }) async {
    final csvFile = await _createHistoryCsv(transactions, fileLabel);
    final pdfFile = await _createHistoryPdf(transactions, fileLabel);
    final imageFile = await _createHistoryImage(transactions, fileLabel);

    await Share.shareXFiles(
      [XFile(imageFile.path), XFile(pdfFile.path), XFile(csvFile.path)],
      text: 'Historique Sam Sama Allal',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export prêt : ${pdfFile.path}')),
      );
    }
  }

  Future<void> _saveHistoryToDevice(
    BuildContext context, {
    required List<AppTransaction> transactions,
    required String fileLabel,
  }) async {
    try {
      final csvFile = await _createHistoryCsv(transactions, fileLabel);
      final pdfFile = await _createHistoryPdf(transactions, fileLabel);
      final imageFile = await _createHistoryImage(transactions, fileLabel);
      final galleryUri = await _saveImageToGallery(imageFile, fileLabel);

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final galleryMessage = galleryUri == null
              ? 'Image créée, mais la Galerie Android n’a pas confirmé l’enregistrement. Utilise Partager pour l’envoyer vers Galerie/Fichiers.'
              : 'Image visible dans la Galerie : $galleryUri';

          return AlertDialog(
            title: const Text('Export enregistré'),
            content: Text(
              '$galleryMessage\n\nPDF : ${pdfFile.path}\n\nCSV : ${csvFile.path}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fermer'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Share.shareXFiles(
                    [
                      XFile(imageFile.path),
                      XFile(pdfFile.path),
                      XFile(csvFile.path),
                    ],
                    text: 'Historique Sam Sama Allal',
                  );
                },
                icon: const Icon(Icons.ios_share),
                label: const Text('Partager'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l’enregistrement : $error')),
      );
    }
  }

  Future<File> _createHistoryCsv(
    List<AppTransaction> transactions,
    String fileLabel,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileLabel.csv');
    final buffer = StringBuffer()
      ..writeln(
        'date,type,produit,categorie,quantite,prix_unitaire,montant,paiement',
      );

    for (final transaction in transactions) {
      buffer.writeln([
        transaction.createdAt.toIso8601String(),
        transaction.type.label,
        transaction.productName ?? '',
        transaction.category,
        transaction.quantity,
        transaction.unitPrice,
        transaction.amount,
        transaction.paymentMethod,
      ].map(_csvValue).join(','));
    }

    await file.writeAsString(buffer.toString());
    return file;
  }

  Future<File> _createHistoryImage(
    List<AppTransaction> transactions,
    String fileLabel,
  ) async {
    const width = 1080.0;
    const rowHeight = 86.0;
    final height = (420 + transactions.length * rowHeight).clamp(900, 6000);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height.toDouble()), paint);

    final totalSales = transactions
        .where((item) => item.type == TransactionType.sale)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final totalExpenses = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<int>(0, (sum, item) => sum + item.amount);

    var y = 52.0;
    _drawText(
      canvas,
      'Sam Sama Allal',
      Offset(48, y),
      fontSize: 38,
      fontWeight: FontWeight.w900,
    );
    y += 52;
    _drawText(
      canvas,
      'Historique des transactions',
      Offset(48, y),
      fontSize: 28,
      color: AppColors.textMuted,
    );
    y += 66;

    final summaryPaint = Paint()..color = const Color(0xFFEEEDFE);
    final summaryRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(48, y, width - 96, 138),
      const Radius.circular(18),
    );
    canvas.drawRRect(summaryRect, summaryPaint);
    _drawText(
      canvas,
      'Transactions : ${transactions.length}',
      Offset(78, y + 28),
      fontSize: 26,
      fontWeight: FontWeight.w800,
    );
    _drawText(
      canvas,
      'Ventes : ${_formatAmount(totalSales)} FCFA',
      Offset(78, y + 72),
      fontSize: 24,
      color: AppColors.success,
      fontWeight: FontWeight.w800,
    );
    _drawText(
      canvas,
      'Dépenses : ${_formatAmount(totalExpenses)} FCFA',
      Offset(520, y + 72),
      fontSize: 24,
      color: AppColors.error,
      fontWeight: FontWeight.w800,
    );
    y += 180;

    for (final transaction in transactions.take(60)) {
      final isSale = transaction.type == TransactionType.sale;
      final borderPaint = Paint()
        ..color = const Color(0xFFE0DEF7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final rowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(48, y, width - 96, 72),
        const Radius.circular(12),
      );
      canvas.drawRRect(rowRect, borderPaint);

      _drawText(
        canvas,
        transaction.productName ?? transaction.category,
        Offset(72, y + 13),
        fontSize: 23,
        fontWeight: FontWeight.w900,
      );
      _drawText(
        canvas,
        '${_formatDate(transaction.createdAt)} · ${transaction.paymentMethod}',
        Offset(72, y + 43),
        fontSize: 18,
        color: AppColors.textMuted,
      );
      _drawText(
        canvas,
        '${isSale ? '+' : '-'}${_formatAmount(transaction.amount)} FCFA',
        Offset(760, y + 22),
        fontSize: 24,
        color: isSale ? AppColors.success : AppColors.error,
        fontWeight: FontWeight.w900,
      );
      y += rowHeight;
      if (y > height - 110) break;
    }

    _drawText(
      canvas,
      'Export généré par Sam Sama Allal',
      Offset(48, height.toDouble() - 58),
      fontSize: 20,
      color: AppColors.textMuted,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      '${(await getApplicationDocumentsDirectory()).path}/$fileLabel.png',
    );
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return file;
  }

  Future<String?> _saveImageToGallery(File imageFile, String fileLabel) async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      return await _galleryChannel.invokeMethod<String>(
        'saveImageToGallery',
        {
          'path': imageFile.path,
          'name': '$fileLabel.png',
        },
      );
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double fontSize = 20,
    Color color = AppColors.text,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 320);
    painter.paint(canvas, offset);
  }

  Future<File> _createHistoryPdf(
    List<AppTransaction> transactions,
    String fileLabel,
  ) async {
    final pdf = pw.Document();
    final totalSales = transactions
        .where((item) => item.type == TransactionType.sale)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final totalExpenses = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<int>(0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text(
              'Historique Sam Sama Allal',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Transactions : ${transactions.length}'),
            pw.Text('Ventes : ${_formatAmount(totalSales)} FCFA'),
            pw.Text('Dépenses : ${_formatAmount(totalExpenses)} FCFA'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Date',
                'Type',
                'Produit',
                'Qté',
                'PU',
                'Montant',
                'Paiement',
              ],
              data: [
                for (final transaction in transactions)
                  [
                    _formatDate(transaction.createdAt),
                    transaction.type.label,
                    transaction.productName ?? transaction.category,
                    '${transaction.quantity}',
                    '${transaction.unitPrice}',
                    '${transaction.amount}',
                    transaction.paymentMethod,
                  ],
              ],
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileLabel.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  String _csvValue(Object value) {
    final raw = value.toString().replaceAll('"', '""');
    return '"$raw"';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
        );
  }
}

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      onTap: onTap,
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.ios_share),
    );
  }
}
