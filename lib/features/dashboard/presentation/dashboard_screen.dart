import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../transactions/presentation/transactions_controller.dart';
import '../../transactions/presentation/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final transactions = ref.watch(transactionsControllerProvider);
    final balance = ref.watch(balanceProvider);
    final goal = user?.dailyGoal ?? 0;
    final progress = goal <= 0 ? 0.0 : (balance / goal).clamp(0.0, 1.0);
    final totalSales = transactions
        .where((item) => item.type == TransactionType.sale)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final totalExpenses = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final netTotal = totalSales - totalExpenses;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionsControllerProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      user?.initial ?? 'S',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour ${user?.firstName ?? ''}'),
                        const Text(
                          'Tableau de bord',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/ticket'),
                    icon: const Icon(Icons.notifications_none),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu),
                    onSelected: (value) {
                      if (value == 'profil') {
                        context.push('/profil');
                      } else if (value == 'stocks') {
                        context.push('/stocks');
                      } else if (value == 'ticket') {
                        context.push('/ticket');
                      } else if (value == 'historique') {
                        context.push('/historique');
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'profil',
                        child: Text('Profil'),
                      ),
                      PopupMenuItem(
                        value: 'stocks',
                        child: Text('Stocks'),
                      ),
                      PopupMenuItem(
                        value: 'ticket',
                        child: Text('Ticket de caisse'),
                      ),
                      PopupMenuItem(
                        value: 'historique',
                        child: Text('Historique'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color(0xFF6C62D4),
                      Color(0xFF8A7CFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33534AB7),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -6,
                      child: Image.asset(
                        'assets/images/wallet.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Solde actuel',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatAmount(balance)} FCFA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(progress * 100).round()}% de l’objectif journalier',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Actions rapides',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Personnaliser',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickActionCard(
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    title: 'J’ai vendu',
                    subtitle: 'Ajouter revenu',
                    onTap: () => context.push('/saisie-vente'),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCard(
                    icon: Icons.trending_down,
                    color: AppColors.error,
                    title: 'J’ai dépensé',
                    subtitle: 'Ajouter dépense',
                    onTap: () => context.push('/saisie-depense'),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCard(
                    icon: Icons.sync_alt,
                    color: AppColors.primary,
                    title: 'Mode rapide',
                    subtitle: 'Raccourcis',
                    onTap: () => context.push('/mode-rapide'),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCard(
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.warning,
                    title: 'Stocks',
                    subtitle: 'Gérer',
                    onTap: () => context.push('/stocks'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Résumé du mois',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SummaryCard(
                    title: 'Revenus',
                    amount: totalSales,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: 'Dépenses',
                    amount: totalExpenses,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: 'Solde net',
                    amount: netTotal,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Dernières transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/historique'),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              if (transactions.isEmpty)
                const SectionCard(
                    child: Text('Aucune transaction pour le moment.'))
              else
                ...transactions.take(3).map(TransactionTile.new),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(int amount) => amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]} ',
      );
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.18),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternDots extends StatelessWidget {
  const _PatternDots({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DotsPainter(color),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const dotRadius = 2.2;
    const gap = 10.0;
    for (double y = 0; y <= size.height; y += gap) {
      for (double x = 0; x <= size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 8),
            Text(
              '${amount >= 0 ? '+' : ''}${_formatAmount(amount)} FCFA',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ce mois',
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) => amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]} ',
      );
}
