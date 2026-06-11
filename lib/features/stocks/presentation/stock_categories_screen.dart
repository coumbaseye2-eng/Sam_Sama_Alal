import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/stock_item.dart';
import 'stocks_controller.dart';

class StockCategoriesScreen extends ConsumerWidget {
  const StockCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocks = ref
        .watch(stocksControllerProvider)
        .where((stock) => !stock.isArchived)
        .toList();
    final categories = <String, List<StockItem>>{};
    for (final stock in stocks) {
      categories.putIfAbsent(stock.category, () => []).add(stock);
    }
    final sortedCategories = categories.keys.toList()..sort();

    return PrimaryScaffold(
      title: 'Catégories',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionCard(
            child: Text(
              'Gère ici les catégories et les produits liés. Tu peux modifier, supprimer ou déplacer un produit dans la corbeille.',
            ),
          ),
          const SizedBox(height: 14),
          if (sortedCategories.isEmpty)
            const SectionCard(child: Text('Aucune catégorie pour le moment.'))
          else
            ...sortedCategories.map(
              (category) => _CategorySection(
                category: category,
                products: categories[category]!,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({
    required this.category,
    required this.products,
  });

  final String category;
  final List<StockItem> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$category (${products.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Renommer la catégorie',
                  onPressed: () => _renameCategory(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Supprimer la catégorie',
                  onPressed: () => _deleteCategory(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.danger,
                ),
              ],
            ),
            const Divider(height: 18),
            ...products.map(
              (product) => _ProductRow(product: product),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameCategory(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: category);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Renommer la catégorie'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nouveau nom'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newName == null || newName.trim().isEmpty) return;
    ref.read(stocksControllerProvider.notifier).renameCategory(
          oldCategory: category,
          newCategory: newName,
        );
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Supprimer la catégorie ?'),
              content: const Text(
                'Les produits de cette catégorie seront déplacés dans la corbeille.',
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
    ref
        .read(stocksControllerProvider.notifier)
        .archiveCategory(category: category);
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product});

  final StockItem product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text('${product.quantity} unité(s)'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${product.unitPrice} FCFA · seuil ${product.alertThreshold}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editProduct(context, ref),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Modifier'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(stocksControllerProvider.notifier)
                      .archiveStock(product.id),
                  icon: const Icon(Icons.archive_outlined, size: 16),
                  label: const Text('Corbeille'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _deleteProduct(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProduct(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController(text: product.name);
    final categoryController = TextEditingController(text: product.category);
    final quantityController =
        TextEditingController(text: product.quantity.toString());
    final priceController =
        TextEditingController(text: product.unitPrice.toString());
    final thresholdController =
        TextEditingController(text: product.alertThreshold.toString());

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Modifier le produit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantité'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix unitaire'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Seuil'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(stocksControllerProvider.notifier).updateStock(
                      id: product.id,
                      name: nameController.text,
                      category: categoryController.text,
                      quantity: int.tryParse(quantityController.text) ?? 0,
                      unitPrice: int.tryParse(priceController.text) ?? 0,
                      alertThreshold:
                          int.tryParse(thresholdController.text) ?? 3,
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    categoryController.dispose();
    quantityController.dispose();
    priceController.dispose();
    thresholdController.dispose();
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Supprimer le produit ?'),
              content: Text('Supprimer définitivement ${product.name} ?'),
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
    ref.read(stocksControllerProvider.notifier).deleteStock(product.id);
  }
}
