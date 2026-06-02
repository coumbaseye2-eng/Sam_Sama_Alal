import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../transactions/presentation/transactions_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameController;
  TextEditingController? _dailyGoalController;
  late String _activityType;
  File? _photoFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController?.dispose();
    _dailyGoalController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Defer loading user-dependent values — use a microtask so `ref` is available in build
    Future.microtask(() => _initFromUser());
  }

  Future<void> _initFromUser() async {
    final auth = ref.read(authControllerProvider);
    final user = auth.user;
    _nameController ??= TextEditingController(text: user?.fullName ?? '');
    _dailyGoalController ??=
        TextEditingController(text: (user?.dailyGoal ?? 0).toString());
    _activityType = user?.activityType ?? 'Boutiquier';

    if (user?.photoUrl != null) {
      try {
        final f = File(user!.photoUrl!);
        if (await f.exists()) {
          _photoFile = f;
        }
      } catch (_) {
        // ignore
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final settings = ref.watch(settingsControllerProvider);
    final balance = ref.watch(balanceProvider);
    final dailyGoal = user?.dailyGoal ?? 0;
    final progress = dailyGoal <= 0 ? 0.0 : (balance / dailyGoal).clamp(0, 1);

    // Ensure controllers exist synchronously if _initFromUser hasn't run yet.
    _nameController ??= TextEditingController(text: user?.fullName ?? '');
    _dailyGoalController ??=
        TextEditingController(text: (user?.dailyGoal ?? 0).toString());
    _activityType = user?.activityType ?? 'Boutiquier';

    return PrimaryScaffold(
      title: 'Profil',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _pickPhoto(),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      backgroundImage:
                          _photoFile != null ? FileImage(_photoFile!) : null,
                      child: _photoFile == null
                          ? Text(
                              user?.initial ?? 'S',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Compte local',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(user?.activityType ?? 'Commerçant'),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.toDouble(),
                            minHeight: 7,
                            backgroundColor: AppColors.primarySoft,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Progress : ${_formatAmount(balance)} / ${_formatAmount(dailyGoal)} FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openEditProfileSheet(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ProfileOptionTile(
                    icon: Icons.language,
                    title: 'Langue',
                    subtitle: settings.language.label,
                    onTap: () => _openLanguageSheet(context),
                  ),
                  const Divider(height: 1),
                  _ProfileOptionTile(
                    icon: Icons.palette_outlined,
                    title: 'Thème',
                    subtitle: settings.theme.label,
                    onTap: () => _openThemeSheet(context),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: settings.notificationsEnabled,
                    onChanged: ref
                        .read(settingsControllerProvider.notifier)
                        .updateNotifications,
                    title: const Text(
                      'Notifications',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text('Rupture de stock, tickets, alertes'),
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primary,
                    ),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ProfileOptionTile(
                    icon: Icons.security_outlined,
                    title: 'Données sécurisées',
                    subtitle: 'Données sauvegardées avec Firebase',
                    onTap: () => _showInfo(
                      context,
                      'Données sécurisées',
                      'Les ventes, stocks, notes et paramètres sont sauvegardés avec Firestore lorsque le compte est connecté.',
                    ),
                  ),
                  const Divider(height: 1),
                  _ProfileOptionTile(
                    icon: Icons.help_outline,
                    title: 'Aide & support',
                    subtitle: 'Questions, assistance et informations',
                    onTap: () => _showInfo(
                      context,
                      'Aide & support',
                      'Pour l’instant, contacte le support du projet Sam Sama Allal. Cette section pourra recevoir une page complète plus tard.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.isLoading ? null : () => _logout(context),
              child: const Text('Déconnexion'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: auth.isLoading ? null : () => _deleteAccount(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              child: const Text('Supprimer le compte'),
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEditProfileSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Modifier le profil',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Nom complet'),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                              ? 'Minimum 2 caractères'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _activityType,
                      decoration:
                          const InputDecoration(labelText: 'Type d’activité'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Boutiquier',
                          child: Text('Boutiquier'),
                        ),
                        DropdownMenuItem(
                          value: 'Vendeur ambulant',
                          child: Text('Vendeur ambulant'),
                        ),
                        DropdownMenuItem(
                          value: 'Restauration',
                          child: Text('Restauration'),
                        ),
                        DropdownMenuItem(
                          value: 'Autre',
                          child: Text('Autre'),
                        ),
                      ],
                      onChanged: (value) {
                        final nextValue = value ?? 'Boutiquier';
                        setState(() => _activityType = nextValue);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _dailyGoalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Objectif journalier (FCFA)',
                      ),
                      validator: (value) {
                        final parsed = int.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed < 0) {
                          return 'Entrez un montant valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final success = await _save();
                        if (sheetContext.mounted && success) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: const Text('Enregistrer les modifications'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openLanguageSheet(BuildContext context) async {
    final settings = ref.read(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Langue',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              SegmentedButton<AppLanguage>(
                selected: {settings.language},
                onSelectionChanged: (value) {
                  controller.updateLanguage(value.first);
                  Navigator.of(sheetContext).pop();
                },
                segments: AppLanguage.values
                    .map(
                      (language) => ButtonSegment<AppLanguage>(
                        value: language,
                        label: Text(language.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openThemeSheet(BuildContext context) async {
    final settings = ref.read(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Thème',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              SegmentedButton<AppThemeChoice>(
                selected: {settings.theme},
                onSelectionChanged: (value) {
                  controller.updateTheme(value.first);
                  Navigator.of(sheetContext).pop();
                },
                segments: AppThemeChoice.values
                    .map(
                      (theme) => ButtonSegment<AppThemeChoice>(
                        value: theme,
                        label: Text(theme.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showInfo(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatAmount(int amount) => amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]} ',
      );

  Future<bool> _save() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          fullName: _nameController?.text ?? '',
          activityType: _activityType,
          dailyGoal: int.tryParse(_dailyGoalController?.text.trim() ?? '') ?? 0,
          photoUrl: _photoFile?.path,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')),
      );
    }
    return success;
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      final tempFile = File(picked.path);
      final appDir = await getApplicationDocumentsDirectory();
      final uid = ref.read(authControllerProvider).user?.uid ?? 'local-user';
      final saved = await tempFile.copy('${appDir.path}/profile_$uid.jpg');

      setState(() => _photoFile = saved);

      // Save immediately (local-first, cloud sync is best-effort inside controller)
      final success =
          await ref.read(authControllerProvider.notifier).updateProfile(
                fullName: _nameController?.text ?? '',
                activityType: _activityType,
                dailyGoal:
                    int.tryParse(_dailyGoalController?.text.trim() ?? '') ?? 0,
                photoUrl: saved.path,
              );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(success
                  ? 'Photo mise à jour'
                  : 'Erreur lors de la sauvegarde de la photo')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de sélectionner la photo')),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) {
      context.go('/welcome');
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Supprimer le compte ?'),
              content: const Text(
                'Cette action supprimera ton compte et toutes les données locales associées.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger),
                  child: const Text('Supprimer'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    final success =
        await ref.read(authControllerProvider.notifier).deleteAccount();
    if (success && context.mounted) {
      context.go('/welcome');
    }
  }
}

class _ProfileOptionTile extends StatelessWidget {
  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primarySoft,
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
