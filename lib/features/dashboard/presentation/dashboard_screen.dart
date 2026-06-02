import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../transactions/presentation/transactions_controller.dart';
import '../../transactions/presentation/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final transactions = ref.watch(transactionsControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final text = _DashboardText.of(settings.language);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  GestureDetector(
                    onTap: () => context.go('/profil'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage: user?.photoUrl != null &&
                              File(user!.photoUrl!).existsSync()
                          ? FileImage(File(user.photoUrl!))
                          : null,
                      child: user?.photoUrl == null ||
                              !File(user!.photoUrl!).existsSync()
                          ? Text(
                              user?.initial ?? 'S',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${text.hello} ${user?.firstName ?? ''}'),
                        Text(
                          text.dashboard,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (settings.notificationsEnabled) {
                        NotificationService.instance.showNotification(
                          title: 'Notifications activées',
                          body:
                              'Sam Sama Allal peut maintenant envoyer des alertes.',
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Notifications desactivees dans Parametres',
                            ),
                          ),
                        );
                      }
                    },
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
                      } else if (value == 'carnet') {
                        context.push('/carnet');
                      } else if (value == 'performance') {
                        context.push('/performance');
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profil',
                        child: Text(text.profile),
                      ),
                      const PopupMenuItem(
                        value: 'stocks',
                        child: Text('Stocks'),
                      ),
                      PopupMenuItem(
                        value: 'ticket',
                        child: Text(text.receipt),
                      ),
                      PopupMenuItem(
                        value: 'historique',
                        child: Text(text.history),
                      ),
                      PopupMenuItem(
                        value: 'performance',
                        child: Text(text.performance),
                      ),
                      PopupMenuItem(
                        value: 'carnet',
                        child: Text(text.notes),
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
                children: [
                  Text(
                    text.quickActions,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextButton(
                    onPressed: () => context.push('/parametres'),
                    child: Text(text.customize),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _QuickActionCard(
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    title: text.sale,
                    subtitle: text.addIncome,
                    onTap: () => context.push('/saisie-vente'),
                  ),
                  _QuickActionCard(
                    icon: Icons.trending_down,
                    color: AppColors.error,
                    title: text.expense,
                    subtitle: text.addExpense,
                    onTap: () => context.push('/saisie-depense'),
                  ),
                  _QuickActionCard(
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.warning,
                    title: 'Stocks',
                    subtitle: text.manage,
                    onTap: () => context.push('/stocks'),
                  ),
                  _QuickActionCard(
                    icon: Icons.bar_chart,
                    color: AppColors.primaryMuted,
                    title: text.performance,
                    subtitle: text.activities,
                    onTap: () => context.push('/performance'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                text.monthSummary,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SummaryCard(
                    title: text.income,
                    amount: totalSales,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: text.expenses,
                    amount: totalExpenses,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: text.netBalance,
                    amount: netTotal,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text.lastTransactions,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/historique'),
                    child: Text(text.seeAll),
                  ),
                ],
              ),
              if (transactions.isEmpty)
                SectionCard(child: Text(text.emptyTransactions))
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

  void _openCustomizeSheet(BuildContext context, _DashboardText text) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  text.customize,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _CustomizeTile(
                  icon: Icons.bar_chart,
                  title: text.performance,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/performance');
                  },
                ),
                _CustomizeTile(
                  icon: Icons.history,
                  title: text.history,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/historique');
                  },
                ),
                _CustomizeTile(
                  icon: Icons.receipt_long_outlined,
                  title: text.receipt,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/ticket');
                  },
                ),
                _CustomizeTile(
                  icon: Icons.sticky_note_2_outlined,
                  title: text.notes,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/carnet');
                  },
                ),
                _CustomizeTile(
                  icon: Icons.person_outline,
                  title: text.profile,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/profil');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardText {
  const _DashboardText({
    required this.hello,
    required this.dashboard,
    required this.profile,
    required this.receipt,
    required this.history,
    required this.settings,
    required this.notes,
    required this.performance,
    required this.quickActions,
    required this.customize,
    required this.sale,
    required this.addIncome,
    required this.expense,
    required this.addExpense,
    required this.fastMode,
    required this.shortcuts,
    required this.manage,
    required this.monthSummary,
    required this.income,
    required this.expenses,
    required this.netBalance,
    required this.lastTransactions,
    required this.seeAll,
    required this.emptyTransactions,
    required this.generate,
    required this.personalNotes,
    required this.activities,
  });

  final String hello;
  final String dashboard;
  final String profile;
  final String receipt;
  final String history;
  final String settings;
  final String notes;
  final String performance;
  final String quickActions;
  final String customize;
  final String sale;
  final String addIncome;
  final String expense;
  final String addExpense;
  final String fastMode;
  final String shortcuts;
  final String manage;
  final String monthSummary;
  final String income;
  final String expenses;
  final String netBalance;
  final String lastTransactions;
  final String seeAll;
  final String emptyTransactions;
  final String generate;
  final String personalNotes;
  final String activities;

  static _DashboardText of(AppLanguage language) {
    return switch (language) {
      AppLanguage.wolof => const _DashboardText(
          hello: 'Nanga def',
          dashboard: 'Tableau bi',
          profile: 'Khar kanam',
          receipt: 'Ticket caisse',
          history: 'Jaar-jaar',
          settings: 'Parametar',
          notes: 'Karnet',
          performance: 'Performance',
          quickActions: 'Jef yu gaaw',
          customize: 'Soppali',
          sale: 'Dama jaay',
          addIncome: 'Yokk xaalis',
          expense: 'Dama fay',
          addExpense: 'Yokk depaas',
          fastMode: 'Mode gaaw',
          shortcuts: 'Yoon yu gatt',
          manage: 'Saytu',
          monthSummary: 'Samare weer wi',
          income: 'Duggal',
          expenses: 'Depaas',
          netBalance: 'Sold net',
          lastTransactions: 'Transaction yu mujj',
          seeAll: 'Gis lepp',
          emptyTransactions: 'Amul transaction leegi.',
          generate: 'Sos',
          personalNotes: 'Not yu boppam',
          activities: 'Aktivite yi',
        ),
      AppLanguage.english => const _DashboardText(
          hello: 'Hello',
          dashboard: 'Dashboard',
          profile: 'Profile',
          receipt: 'Receipt',
          history: 'History',
          settings: 'Settings',
          notes: 'Notebook',
          performance: 'Performance',
          quickActions: 'Quick actions',
          customize: 'Customize',
          sale: 'I sold',
          addIncome: 'Add income',
          expense: 'I spent',
          addExpense: 'Add expense',
          fastMode: 'Fast mode',
          shortcuts: 'Shortcuts',
          manage: 'Manage',
          monthSummary: 'Monthly summary',
          income: 'Income',
          expenses: 'Expenses',
          netBalance: 'Net balance',
          lastTransactions: 'Latest transactions',
          seeAll: 'See all',
          emptyTransactions: 'No transactions yet.',
          generate: 'Generate',
          personalNotes: 'Personal notes',
          activities: 'Activities',
        ),
      AppLanguage.french => const _DashboardText(
          hello: 'Bonjour',
          dashboard: 'Tableau de bord',
          profile: 'Profil',
          receipt: 'Ticket de caisse',
          history: 'Historique',
          settings: 'Parametres',
          notes: 'Carnet',
          performance: 'Performance',
          quickActions: 'Actions rapides',
          customize: 'Personnaliser',
          sale: 'Vente',
          addIncome: 'Ajouter revenu',
          expense: ' Depense',
          addExpense: 'Ajouter depense',
          fastMode: 'Mode rapide',
          shortcuts: 'Raccourcis',
          manage: 'Gerer',
          monthSummary: 'Resume du mois',
          income: 'Revenus',
          expenses: 'Depenses',
          netBalance: 'Solde net',
          lastTransactions: 'Dernieres transactions',
          seeAll: 'Voir tout',
          emptyTransactions: 'Aucune transaction pour le moment.',
          generate: 'Generer',
          personalNotes: 'Notes personnelles',
          activities: 'Activites',
        ),
    };
  }
}

class _CustomizeTile extends StatelessWidget {
  const _CustomizeTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 118),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
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
    );
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
              style:
                  TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9)),
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
              style:
                  TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
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
