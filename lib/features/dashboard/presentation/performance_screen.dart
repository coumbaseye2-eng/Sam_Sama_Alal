import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../transactions/presentation/transactions_controller.dart';

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsControllerProvider);
    final now = DateTime.now();
    final monthTransactions = transactions.where((item) {
      return item.createdAt.year == now.year &&
          item.createdAt.month == now.month;
    }).toList();
    final sales = monthTransactions
        .where((item) => item.type == TransactionType.sale)
        .fold<int>(0, (total, item) => total + item.amount);
    final expenses = monthTransactions
        .where((item) => item.type == TransactionType.expense)
        .fold<int>(0, (total, item) => total + item.amount);
    final net = sales - expenses;
    final saleCount = monthTransactions
        .where((item) => item.type == TransactionType.sale)
        .length;
    final expenseCount = monthTransactions
        .where((item) => item.type == TransactionType.expense)
        .length;
    final maxAmount = [sales, expenses, net.abs(), 1]
        .reduce((value, element) => value > element ? value : element);

    return PrimaryScaffold(
      title: 'Performance',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Ventes',
                  value: '${_formatAmount(sales)} FCFA',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Dépenses',
                  value: '${_formatAmount(expenses)} FCFA',
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Solde net',
                  value: '${_formatAmount(net)} FCFA',
                  color: net >= 0 ? AppColors.primary : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Activités',
                  value: '${monthTransactions.length}',
                  color: AppColors.primaryMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Graphique du mois',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                _PerformanceBar(
                  label: 'Ventes',
                  amount: sales,
                  maxAmount: maxAmount,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                _PerformanceBar(
                  label: 'Dépenses',
                  amount: expenses,
                  maxAmount: maxAmount,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                _PerformanceBar(
                  label: 'Solde net',
                  amount: net.abs(),
                  maxAmount: maxAmount,
                  color: net >= 0 ? AppColors.primary : AppColors.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Activité',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                _ActivityRow(
                  label: 'Transactions de vente',
                  value: saleCount,
                  color: AppColors.success,
                ),
                const SizedBox(height: 10),
                _ActivityRow(
                  label: 'Transactions de dépense',
                  value: expenseCount,
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
        );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

class _PerformanceBar extends StatelessWidget {
  const _PerformanceBar({
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.color,
  });

  final String label;
  final int amount;
  final int maxAmount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = maxAmount <= 0 ? 0.0 : (amount / maxAmount).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '$amount FCFA',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          '$value',
          style: TextStyle(fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}
