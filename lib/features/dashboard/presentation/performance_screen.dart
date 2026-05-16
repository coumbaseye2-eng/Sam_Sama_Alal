import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../transactions/presentation/transactions_controller.dart';

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsControllerProvider);
    final sales = transactions
        .where((item) => item.type == TransactionType.sale)
        .fold<int>(0, (total, item) => total + item.amount);
    final expenses = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<int>(0, (total, item) => total + item.amount);
    final net = sales - expenses;

    return PrimaryScaffold(
      title: 'Performance',
      body: Column(
        children: [
          Row(
            children: [
              Expanded(child: _Metric(label: 'Revenus', value: sales)),
              const SizedBox(width: 10),
              Expanded(child: _Metric(label: 'Dépenses', value: expenses)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Bénéfice', value: net)),
              const SizedBox(width: 10),
              Expanded(
                  child: _Metric(
                      label: 'Transactions', value: transactions.length)),
            ],
          ),
          const SizedBox(height: 18),
          const SectionCard(
            child: Text(
                'Les graphiques fl_chart seront branchés avec les données Hive.'),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
