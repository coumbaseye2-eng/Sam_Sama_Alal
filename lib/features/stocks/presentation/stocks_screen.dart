import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final stocks = ref.watch(stocksControllerProvider).where((stock) {
      final query = _query.toLowerCase().trim();
      if (query.isEmpty) return true;
      return stock.name.toLowerCase().contains(query) ||
          stock.category.toLowerCase().contains(query);
    }).toList();

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
              Expanded(child: SectionCard(child: Text('Total\n${stocks.length}'))),
              SizedBox(width: 10),
              Expanded(
                child: SectionCard(
                  child: Text('Stock faible\n${stocks.where((item) => item.isLow).length}'),
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher un article',
            ),
          ),
          SizedBox(height: 18),
          if (stocks.isEmpty)
            const SectionCard(child: Text('Aucun article en stock pour le moment.'))
          else
            ...stocks.map(
              (stock) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  child: _StockTile(stock: stock),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openStockSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController(text: 'Général');
    final quantityController = TextEditingController(text: '1');
    final unitPriceController = TextEditingController(text: '0');
    final thresholdController = TextEditingController(text: '3');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ajouter un stock',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom de l’article'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantité'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prix unitaire'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Seuil d’alerte'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final quantity = int.tryParse(quantityController.text) ?? 0;
                  final unitPrice = int.tryParse(unitPriceController.text) ?? 0;
                  final threshold = int.tryParse(thresholdController.text) ?? 3;

                  ref.read(stocksControllerProvider.notifier).addStock(
                        name: nameController.text,
                        category: categoryController.text,
                        quantity: quantity,
                        unitPrice: unitPrice,
                        alertThreshold: threshold,
                      );
                  Navigator.of(sheetContext).pop();
                  setState(() {});
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    categoryController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    thresholdController.dispose();
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.stock});

  final StockItem stock;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: stock.isLow ? Colors.orange.shade100 : Colors.green.shade100,
          child: Icon(
            stock.isLow ? Icons.warning_amber_outlined : Icons.inventory_2_outlined,
            color: stock.isLow ? Colors.orange : Colors.green,
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
                '${stock.category} • ${stock.quantity} unité(s)',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Seuil: ${stock.alertThreshold} • Prix: ${stock.unitPrice} FCFA',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
