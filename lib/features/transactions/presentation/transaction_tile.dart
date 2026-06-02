import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/app_transaction.dart';
import '../domain/transaction_type.dart';
import 'payment_method_badge.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile(this.transaction,
      {super.key, this.onReceipt, this.onDelete});

  final AppTransaction transaction;
  final VoidCallback? onReceipt;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isSale = transaction.type == TransactionType.sale;
    final sign = isSale ? '+' : '-';
    final color = isSale ? AppColors.primary : AppColors.primaryMuted;
    final title = transaction.productName ?? transaction.category;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  isSale ? AppColors.primary : AppColors.primarySoft,
              child: Icon(
                isSale ? Icons.arrow_upward : Icons.arrow_downward,
                color: isSale ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (isSale && transaction.productName != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${transaction.quantity} x ${transaction.unitPrice} FCFA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      PaymentMethodBadge(
                        method: transaction.paymentMethod,
                        compact: true,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${transaction.type.label} · ${_time(transaction.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$sign${transaction.amount} FCFA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                if (onReceipt != null || onDelete != null) ...[
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    tooltip: 'Actions',
                    onSelected: (value) {
                      if (value == 'ticket') {
                        onReceipt?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onReceipt != null)
                        const PopupMenuItem(
                          value: 'ticket',
                          child: Text('Ticket de caisse'),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
