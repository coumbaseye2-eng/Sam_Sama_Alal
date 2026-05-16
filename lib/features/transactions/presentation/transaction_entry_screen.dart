import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../domain/transaction_type.dart';
import 'amount_keypad.dart';
import 'payment_method_badge.dart';
import 'transactions_controller.dart';

class TransactionEntryScreen extends ConsumerStatefulWidget {
  const TransactionEntryScreen({super.key, required this.type});

  final TransactionType type;

  @override
  ConsumerState<TransactionEntryScreen> createState() =>
      _TransactionEntryScreenState();
}

class _TransactionEntryScreenState
    extends ConsumerState<TransactionEntryScreen> {
  String _amount = '';
  String? _category;
  String _paymentMethod = 'Espèces';

  @override
  Widget build(BuildContext context) {
    final isSale = widget.type == TransactionType.sale;
    final categories = isSale
        ? ['Alimentation', 'Habits', 'Électronique', 'Autre']
        : ['Stock', 'Transport', 'Loyer', 'Autre'];
    const paymentMethods = [
      'Espèces',
      'Wave',
      'Orange Money',
      'Free Money',
      'Wizall'
    ];

    return PrimaryScaffold(
      title: isSale ? 'J’ai vendu' : 'J’ai dépensé',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isSale ? AppColors.primary : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_amount.isEmpty ? '0' : _amount} FCFA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSale ? Colors.white : AppColors.primary,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() {
                    _category = _category == category ? null : category;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Moyen de paiement',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in paymentMethods)
                PaymentMethodBadge(
                  method: method,
                  selected: _paymentMethod == method,
                  onTap: () => setState(() => _paymentMethod = method),
                ),
            ],
          ),
          const SizedBox(height: 24),
          AmountKeypad(
              value: _amount,
              onChanged: (value) => setState(() => _amount = value)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _amount.isEmpty ? null : _save,
            child: Text(isSale ? 'Valider la vente' : 'Valider la dépense'),
          ),
        ],
      ),
    );
  }

  void _save() {
    ref.read(transactionsControllerProvider.notifier).addTransaction(
          type: widget.type,
          amount: int.parse(_amount),
          category: _category ?? 'Autre',
          paymentMethod: _paymentMethod,
        );
    context.push('/confirmation');
  }
}
