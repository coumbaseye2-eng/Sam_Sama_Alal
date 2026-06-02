import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../profile/domain/app_user.dart';
import '../domain/app_transaction.dart';
import '../domain/transaction_type.dart';

class ReceiptService {
  const ReceiptService();

  Future<File> generateReceiptPdf({
    required AppTransaction transaction,
    required int balanceAfter,
    AppUser? user,
  }) async {
    final pdf = pw.Document();
    final isSale = transaction.type == TransactionType.sale;
    final sign = isSale ? '+' : '-';
    final title = isSale ? 'Ticket de vente' : 'Ticket de depense';
    final reference = transaction.id.length >= 8
        ? transaction.id.substring(0, 8).toUpperCase()
        : transaction.id.toUpperCase();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(18),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'Sam Sama Allal',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text(title)),
              pw.SizedBox(height: 12),
              _line(),
              _row('Ref.', reference),
              _row('Commercant', user?.fullName ?? 'Compte local'),
              _row('Email', user?.email ?? '-'),
              _row('Date', _formatDate(transaction.createdAt)),
              _line(),
              _row('Type', transaction.type.label),
              _row('Categorie', transaction.category),
              if (transaction.productName != null)
                _row('Produit', transaction.productName!),
              if (isSale) _row('Quantite', '${transaction.quantity}'),
              if (isSale)
                _row(
                  'Prix unitaire',
                  '${_formatAmount(transaction.unitPrice)} FCFA',
                ),
              _row('Paiement', transaction.paymentMethod),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  '$sign${_formatAmount(transaction.amount)} FCFA',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              _row('Solde apres', '${_formatAmount(balanceAfter)} FCFA'),
              _line(),
              pw.Center(
                child: pw.Text(
                  'Merci pour votre confiance',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/ticket_$reference.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> downloadReceipt({
    required AppTransaction transaction,
    required int balanceAfter,
    AppUser? user,
  }) async {
    final tempFile = await generateReceiptPdf(
      transaction: transaction,
      balanceAfter: balanceAfter,
      user: user,
    );
    final reference = transaction.id.length >= 8
        ? transaction.id.substring(0, 8).toUpperCase()
        : transaction.id.toUpperCase();
    final directory = await getApplicationDocumentsDirectory();
    final savedFile = File('${directory.path}/ticket_$reference.pdf');
    if (await savedFile.exists()) {
      await savedFile.delete();
    }
    return tempFile.copy(savedFile.path);
  }

  Future<void> shareReceipt({
    required AppTransaction transaction,
    required int balanceAfter,
    AppUser? user,
  }) async {
    final file = await generateReceiptPdf(
      transaction: transaction,
      balanceAfter: balanceAfter,
      user: user,
    );
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Ticket de caisse Sam Sama Allal',
    );
  }

  pw.Widget _line() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Divider(thickness: 0.6),
    );
  }

  pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
        );
  }
}
