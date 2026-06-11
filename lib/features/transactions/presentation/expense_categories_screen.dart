import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import 'expense_categories_controller.dart';

class ExpenseCategoriesScreen extends ConsumerWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(expenseCategoriesControllerProvider);

    return PrimaryScaffold(
      title: 'Catégories dépenses',
      actions: [
        IconButton(
          tooltip: 'Ajouter une catégorie',
          onPressed: () => _showCategoryDialog(context, ref),
          icon: const Icon(Icons.add),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionCard(
            child: Text(
              'Ajoute, modifie ou supprime les catégories utilisées dans les dépenses.',
            ),
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            const SectionCard(child: Text('Aucune catégorie pour le moment.'))
          else
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Modifier',
                        onPressed: () => _showCategoryDialog(
                          context,
                          ref,
                          currentName: category,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        onPressed: () => _confirmDelete(context, ref, category),
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une catégorie'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    String? currentName,
  }) async {
    final controller = TextEditingController(text: currentName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            currentName == null
                ? 'Ajouter une catégorie'
                : 'Modifier la catégorie',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(currentName == null ? 'Ajouter' : 'Modifier'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (result == null || result.trim().isEmpty) return;
    final notifier = ref.read(expenseCategoriesControllerProvider.notifier);
    if (currentName == null) {
      await notifier.addCategory(result);
    } else {
      await notifier.updateCategory(oldName: currentName, newName: result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String category,
  ) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Supprimer la catégorie ?'),
              content: Text('La catégorie "$category" sera retirée.'),
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
    await ref
        .read(expenseCategoriesControllerProvider.notifier)
        .deleteCategory(category);
  }
}
