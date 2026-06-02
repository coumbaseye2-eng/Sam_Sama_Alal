import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../../stocks/domain/stock_item.dart';
import '../../stocks/presentation/stocks_controller.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final List<_CartLine> _cart = [];
  String _amount = '';
  String? _category;
  String _paymentMethod = 'Espèces';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSale = widget.type == TransactionType.sale;
    if (isSale) {
      return _buildSaleScreen(context);
    }
    return _buildExpenseScreen(context);
  }

  Widget _buildSaleScreen(BuildContext context) {
    final stocks = ref
        .watch(stocksControllerProvider)
        .where((stock) => stock.quantity > 0)
        .toList();
    final query = _searchController.text.toLowerCase().trim();
    final suggestions = query.isEmpty
        ? stocks.take(4).toList()
        : stocks.where((stock) {
            final sku = _sku(stock).toLowerCase();
            return stock.name.toLowerCase().contains(query) ||
                stock.category.toLowerCase().contains(query) ||
                sku.contains(query);
          }).toList();
    final totalItems = _cart.fold<int>(0, (sum, line) => sum + line.quantity);
    final totalAmount =
        _cart.fold<int>(0, (sum, line) => sum + line.totalPrice);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvelle vente'),
            Text(
              _cart.isEmpty ? 'ticket #00428' : '${_cart.length} produits',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Rechercher un produit, SKU...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_searchController.text.trim().isEmpty)
                    const Text(
                      'tapez, scannez, ou choisissez ci-dessous',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  const SizedBox(height: 16),
                  if (stocks.isEmpty)
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Aucun produit disponible.',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ajoute d’abord des produits dans le stock.',
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/stocks'),
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('Aller au stock'),
                          ),
                        ],
                      ),
                    )
                  else if (query.isEmpty) ...[
                    const Text(
                      'SUGGESTIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final stock in suggestions)
                          ActionChip(
                            label: Text('+${stock.name}'),
                            onPressed: () => _addToCart(stock),
                          ),
                      ],
                    ),
                  ] else ...[
                    SectionCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final stock in suggestions)
                            _SuggestionTile(
                              stock: stock,
                              sku: _sku(stock),
                              onTap: () => _addToCart(stock),
                            ),
                          if (suggestions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Aucun produit trouvé.'),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    _cart.isEmpty
                        ? 'PANIER'
                        : 'DANS LE PANIER : ${_cart.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_cart.isEmpty)
                    Container(
                      height: 78,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.textMuted,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'les produits ajoutés apparaîtront ici',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    ..._cart.map(
                      (line) => _CartLineCard(
                        line: line,
                        sku: _sku(line.stock),
                        onIncrement: () => _increment(line.stock.id),
                        onDecrement: () => _decrement(line.stock.id),
                        onRemove: () => _remove(line.stock.id),
                      ),
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
                      for (final method in _paymentMethods)
                        PaymentMethodBadge(
                          method: method,
                          selected: _paymentMethod == method,
                          onTap: () => setState(() => _paymentMethod = method),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total · $totalItems article(s)'),
                        Text(
                          '${_formatAmount(totalAmount)} FCFA',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _cart.isEmpty ? null : _saveSale,
                      child: const Text('Encaisser →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseScreen(BuildContext context) {
    final categories = [
      'Stock',
      'Transport',
      'Loyer',
      'Electricite',
      'Eau',
      'Internet',
      'Salaire',
      'Maintenance',
      'Emballage',
      'Frais mobile money',
      'Autre',
    ];

    return PrimaryScaffold(
      title: 'Dépense',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_amount.isEmpty ? '0' : _amount} FCFA',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
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
          const SizedBox(height: 24),
          AmountKeypad(
            value: _amount,
            onChanged: (value) => setState(() => _amount = value),
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
              for (final method in _paymentMethods)
                PaymentMethodBadge(
                  method: method,
                  selected: _paymentMethod == method,
                  onTap: () => setState(() => _paymentMethod = method),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _amount.isEmpty ? null : _saveExpense,
            child: const Text('Valider la dépense'),
          ),
        ],
      ),
    );
  }

  void _addToCart(StockItem stock) {
    final index = _cart.indexWhere((line) => line.stock.id == stock.id);
    setState(() {
      if (index == -1) {
        _cart.add(_CartLine(stock: stock));
      } else if (_cart[index].quantity < stock.quantity) {
        _cart[index] =
            _cart[index].copyWith(quantity: _cart[index].quantity + 1);
      }
      _searchController.clear();
    });
  }

  void _increment(String stockId) {
    final index = _cart.indexWhere((line) => line.stock.id == stockId);
    if (index == -1) return;
    final line = _cart[index];
    if (line.quantity >= line.stock.quantity) return;
    setState(() {
      _cart[index] = line.copyWith(quantity: line.quantity + 1);
    });
  }

  void _decrement(String stockId) {
    final index = _cart.indexWhere((line) => line.stock.id == stockId);
    if (index == -1) return;
    final line = _cart[index];
    if (line.quantity <= 1) return;
    setState(() {
      _cart[index] = line.copyWith(quantity: line.quantity - 1);
    });
  }

  void _remove(String stockId) {
    setState(() {
      _cart.removeWhere((line) => line.stock.id == stockId);
    });
  }

  void _saveSale() {
    for (final line in _cart) {
      final updated = ref.read(stocksControllerProvider.notifier).decreaseStock(
            id: line.stock.id,
            quantity: line.quantity,
          );
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock insuffisant : ${line.stock.name}')),
        );
        return;
      }
    }

    for (final line in _cart) {
      ref.read(transactionsControllerProvider.notifier).addTransaction(
            type: TransactionType.sale,
            amount: line.totalPrice,
            category: line.stock.category,
            paymentMethod: _paymentMethod,
            stockItemId: line.stock.id,
            productName: line.stock.name,
            quantity: line.quantity,
            unitPrice: line.stock.unitPrice,
          );
    }
    context.push('/confirmation');
  }

  void _saveExpense() {
    ref.read(transactionsControllerProvider.notifier).addTransaction(
          type: TransactionType.expense,
          amount: int.parse(_amount),
          category: _category ?? 'Autre',
          paymentMethod: _paymentMethod,
        );
    context.push('/confirmation');
  }

  String _sku(StockItem stock) {
    final prefix = stock.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(3)
        .join();
    final idPart = stock.id.length >= 3
        ? stock.id.substring(0, 3).toUpperCase()
        : stock.id.toUpperCase();
    return '${prefix.isEmpty ? 'PRD' : prefix}-$idPart';
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
        );
  }
}

const _paymentMethods = [
  'Espèces',
  'Wave',
  'Orange Money',
  'Free Money',
  'Wizall',
];

class _CartLine {
  const _CartLine({required this.stock, this.quantity = 1});

  final StockItem stock;
  final int quantity;

  int get totalPrice => stock.unitPrice * quantity;

  _CartLine copyWith({int? quantity}) {
    return _CartLine(
      stock: stock,
      quantity: quantity ?? this.quantity,
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.stock,
    required this.sku,
    required this.onTap,
  });

  final StockItem stock;
  final String sku;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _ProductThumb(isLow: stock.isLow),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '$sku · ${stock.unitPrice} FCFA · stock ${stock.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'tap pour ajouter',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({
    required this.line,
    required this.sku,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final _CartLine line;
  final String sku;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _ProductThumb(isLow: line.stock.isLow),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.stock.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$sku · stock ${line.stock.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QtyButton(icon: Icons.remove, onTap: onDecrement),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${line.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _QtyButton(icon: Icons.add, onTap: onIncrement),
                      const Spacer(),
                      GestureDetector(
                        onLongPress: onRemove,
                        child: const Text(
                          'maintenir = supprimer',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_formatAmount(line.totalPrice)} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'PU ${_formatAmount(line.stock.unitPrice)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.isLow});

  final bool isLow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isLow ? AppColors.warningLight : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(
        isLow ? Icons.warning_amber_outlined : Icons.inventory_2_outlined,
        color: isLow ? AppColors.warning : AppColors.primary,
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.text),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
