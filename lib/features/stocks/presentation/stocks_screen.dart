import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/stock_item.dart';
import 'stocks_controller.dart';

class StocksScreen extends ConsumerStatefulWidget {
  const StocksScreen({super.key});

  @override
  ConsumerState<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends ConsumerState<StocksScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allStocks = ref.watch(stocksControllerProvider);
    final activeStocks = allStocks.where((stock) => !stock.isArchived);
    final stocks = activeStocks.where((stock) {
      final query = _query.toLowerCase().trim();
      if (query.isEmpty) return true;
      return stock.name.toLowerCase().contains(query) ||
          stock.category.toLowerCase().contains(query) ||
          _sku(stock).toLowerCase().contains(query);
    }).toList();
    final totalUnits =
        stocks.fold<int>(0, (sum, stock) => sum + stock.quantity);

    return PrimaryScaffold(
      title: 'Stocks',
      actions: [
        IconButton(
          onPressed: () => _openStockSheet(context),
          icon: const Icon(Icons.add_circle_outline),
        )
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Produits',
                  value: '${stocks.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Unités',
                  value: '$totalUnits',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Faible',
                  value: '${stocks.where((item) => item.isLow).length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher produit, catégorie, SKU...',
            ),
          ),
          const SizedBox(height: 18),
          if (stocks.isEmpty)
            const SectionCard(
                child: Text('Aucun article en stock pour le moment.'))
          else
            ...stocks.map(
              (stock) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onLongPress: () => _openStockActions(context, stock),
                  child: _StockTile(stock: stock, sku: _sku(stock)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openStockSheet(BuildContext context, {StockItem? stock}) async {
    final nameOptions = ref
        .read(stocksControllerProvider)
        .where((item) => !item.isArchived)
        .map((item) => item.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (stock != null && stock.name.trim().isNotEmpty) {
      nameOptions.add(stock.name.trim());
      nameOptions.sort();
    }
    if (!nameOptions.contains('Autre')) {
      nameOptions.add('Autre');
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _StockSheet(
          nameOptions: nameOptions,
          initialStock: stock,
          onSave: ({
            required String name,
            required String category,
            required int quantity,
            required int unitPrice,
            required int alertThreshold,
          }) {
            if (stock == null) {
              ref.read(stocksControllerProvider.notifier).addStock(
                    name: name,
                    category: category,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    alertThreshold: alertThreshold,
                  );
            } else {
              ref.read(stocksControllerProvider.notifier).updateStock(
                    id: stock.id,
                    name: name,
                    category: category,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    alertThreshold: alertThreshold,
                  );
            }
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  Future<void> _openStockActions(BuildContext context, StockItem stock) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openStockSheet(context, stock: stock);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDeleteStock(context, stock);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Déplacer dans la corbeille'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ref
                      .read(stocksControllerProvider.notifier)
                      .archiveStock(stock.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteStock(
    BuildContext context,
    StockItem stock,
  ) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Supprimer le stock ?'),
              content: const Text(
                'Cette action supprimera définitivement ce stock.',
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
    ref.read(stocksControllerProvider.notifier).deleteStock(stock.id);
  }
}

class _StockSheet extends StatefulWidget {
  const _StockSheet({
    required this.onSave,
    required this.nameOptions,
    this.initialStock,
  });

  final List<String> nameOptions;
  final StockItem? initialStock;
  final void Function({
    required String name,
    required String category,
    required int quantity,
    required int unitPrice,
    required int alertThreshold,
  }) onSave;

  @override
  State<_StockSheet> createState() => _StockSheetState();
}

class _StockSheetState extends State<_StockSheet> {
  late final TextEditingController _customNameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _thresholdController;

  String _selectedName = '';

  @override
  void initState() {
    super.initState();
    _customNameController = TextEditingController();
    _categoryController = TextEditingController(text: 'Général');
    _quantityController = TextEditingController(text: '1');
    _unitPriceController = TextEditingController(text: '0');
    _thresholdController = TextEditingController(text: '3');

    final initial = widget.initialStock;
    if (initial != null) {
      _categoryController.text = initial.category;
      _quantityController.text = initial.quantity.toString();
      _unitPriceController.text = initial.unitPrice.toString();
      _thresholdController.text = initial.alertThreshold.toString();
      if (widget.nameOptions.contains(initial.name)) {
        _selectedName = initial.name;
      } else {
        _selectedName = 'Autre';
        _customNameController.text = initial.name;
      }
    } else {
      _selectedName =
          widget.nameOptions.isNotEmpty ? widget.nameOptions.first : 'Autre';
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialStock != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEditing ? 'Modifier le stock' : 'Ajouter un stock',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedName.isEmpty ? null : _selectedName,
            decoration: const InputDecoration(labelText: 'Nom de l’article'),
            items: widget.nameOptions
                .map(
                  (name) => DropdownMenuItem(
                    value: name,
                    child: Text(name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedName = value);
            },
          ),
          if (_selectedName == 'Autre') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customNameController,
              decoration: const InputDecoration(labelText: 'Nom personnalisé'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'Catégorie'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantité'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unitPriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Prix unitaire'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _thresholdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Seuil d’alerte'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(_quantityController.text) ?? 0;
              final unitPrice = int.tryParse(_unitPriceController.text) ?? 0;
              final threshold = int.tryParse(_thresholdController.text) ?? 3;
              final name = _selectedName == 'Autre'
                  ? _customNameController.text
                  : _selectedName;

              widget.onSave(
                name: name,
                category: _categoryController.text,
                quantity: quantity,
                unitPrice: unitPrice,
                alertThreshold: threshold,
              );
            },
            child: Text(isEditing ? 'Mettre à jour' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.stock, required this.sku});

  final StockItem stock;
  final String sku;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  stock.isLow ? AppColors.warningLight : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              stock.isLow
                  ? Icons.warning_amber_outlined
                  : Icons.inventory_2_outlined,
              color: stock.isLow ? AppColors.warning : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sku · ${stock.category}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StockBadge(label: 'stock ${stock.quantity}'),
                    _StockBadge(label: 'seuil ${stock.alertThreshold}'),
                    if (stock.isLow)
                      const _StockBadge(
                        label: 'rupture proche',
                        warning: true,
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
                '${_formatAmount(stock.unitPrice)} FCFA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'prix unitaire',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
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

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.label, this.warning = false});

  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: warning ? AppColors.warningLight : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: warning ? AppColors.warning : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: warning ? AppColors.warning : AppColors.primary,
        ),
      ),
    );
  }
}
