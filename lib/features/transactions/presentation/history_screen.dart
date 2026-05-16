import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/transaction_type.dart';
import 'transaction_tile.dart';
import 'transactions_controller.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  TransactionType? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final transactions =
        ref.watch(transactionsControllerProvider).where((item) {
      final matchesType = _filter == null || item.type == _filter;
      final matchesQuery =
          item.category.toLowerCase().contains(_query.toLowerCase());
      return matchesType && matchesQuery;
    }).toList();

    return PrimaryScaffold(
      title: 'Historique',
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.ios_share))
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
          if (transactions.isEmpty)
            const SectionCard(child: Text('Aucune transaction trouvée.'))
          else
            ...transactions.map(TransactionTile.new),
        ],
      ),
    );
  }
}
