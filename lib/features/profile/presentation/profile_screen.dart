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

    // Ensure controllers exist synchronously if _initFromUser hasn't run yet.
    _nameController ??= TextEditingController(text: user?.fullName ?? '');
    _dailyGoalController ??=
        TextEditingController(text: (user?.dailyGoal ?? 0).toString());
    _activityType = user?.activityType ?? 'Boutiquier';

    return PrimaryScaffold(
      title: 'Profil',
      body: Form(
        key: _formKey,
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
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(user?.email ?? 'adresse@mail.com'),
                        Text(user?.activityType ?? 'Commerçant'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nom complet'),
                    validator: (value) => value == null || value.trim().length < 2
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
                    onChanged: (value) => setState(
                      () => _activityType = value ?? 'Boutiquier',
                    ),
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
                    onPressed: auth.isLoading ? null : _save,
                    child: auth.isLoading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer les modifications'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Actions du compte',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: auth.isLoading ? null : () => _logout(context),
                    child: const Text('Se déconnecter'),
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
                ],
              ),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).updateProfile(
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
      final success = await ref.read(authControllerProvider.notifier).updateProfile(
            fullName: _nameController?.text ?? '',
            activityType: _activityType,
            dailyGoal: int.tryParse(_dailyGoalController?.text.trim() ?? '') ?? 0,
            photoUrl: saved.path,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Photo mise à jour' : 'Erreur lors de la sauvegarde de la photo')),
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
    if (mounted) {
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
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

    final success = await ref.read(authControllerProvider.notifier).deleteAccount();
    if (success && mounted) {
      context.go('/welcome');
    }
  }
}
