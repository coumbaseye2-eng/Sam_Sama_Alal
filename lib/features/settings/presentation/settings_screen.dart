import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/app_settings.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final text = _SettingsText.of(settings.language);

    return PrimaryScaffold(
      title: text.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.language, title: text.language),
                const SizedBox(height: 12),
                SegmentedButton<AppLanguage>(
                  selected: {settings.language},
                  onSelectionChanged: (value) {
                    controller.updateLanguage(value.first);
                  },
                  segments: AppLanguage.values
                      .map(
                        (language) => ButtonSegment<AppLanguage>(
                          value: language,
                          label: Text(text.languageLabel(language)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.palette_outlined, title: text.theme),
                const SizedBox(height: 12),
                SegmentedButton<AppThemeChoice>(
                  selected: {settings.theme},
                  onSelectionChanged: (value) {
                    controller.updateTheme(value.first);
                  },
                  segments: AppThemeChoice.values
                      .map(
                        (theme) => ButtonSegment<AppThemeChoice>(
                          value: theme,
                          label: Text(text.themeLabel(theme)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: SwitchListTile(
              value: settings.notificationsEnabled,
              onChanged: controller.updateNotifications,
              title: Text(text.notifications),
              subtitle: Text(text.notificationsSubtitle),
              secondary: const Icon(Icons.notifications_active_outlined),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _SettingsText {
  const _SettingsText({
    required this.title,
    required this.language,
    required this.theme,
    required this.notifications,
    required this.notificationsSubtitle,
    required this.languages,
    required this.themes,
  });

  final String title;
  final String language;
  final String theme;
  final String notifications;
  final String notificationsSubtitle;
  final Map<AppLanguage, String> languages;
  final Map<AppThemeChoice, String> themes;

  String languageLabel(AppLanguage language) => languages[language]!;

  String themeLabel(AppThemeChoice theme) => themes[theme]!;

  static _SettingsText of(AppLanguage language) {
    return switch (language) {
      AppLanguage.wolof => const _SettingsText(
          title: 'Parametaru app bi',
          language: 'Lammiin',
          theme: 'Melokaan',
          notifications: 'Yegle yi',
          notificationsSubtitle:
              'Yegle su stock bi jeexee walla ticket bi amee',
          languages: {
            AppLanguage.french: 'Farase',
            AppLanguage.wolof: 'Wolof',
            AppLanguage.english: 'Angale',
          },
          themes: {
            AppThemeChoice.system: 'Systeme',
            AppThemeChoice.light: 'Leer',
            AppThemeChoice.dark: 'Lendem',
          },
        ),
      AppLanguage.english => const _SettingsText(
          title: 'Settings',
          language: 'Language',
          theme: 'Theme',
          notifications: 'Notifications',
          notificationsSubtitle: 'Alerts for low stock and ticket downloads',
          languages: {
            AppLanguage.french: 'French',
            AppLanguage.wolof: 'Wolof',
            AppLanguage.english: 'English',
          },
          themes: {
            AppThemeChoice.system: 'System',
            AppThemeChoice.light: 'Light',
            AppThemeChoice.dark: 'Dark',
          },
        ),
      AppLanguage.french => const _SettingsText(
          title: 'Parametres',
          language: 'Langue',
          theme: 'Theme',
          notifications: 'Notifications',
          notificationsSubtitle:
              'Alertes pour les ruptures et les tickets telecharges',
          languages: {
            AppLanguage.french: 'Francais',
            AppLanguage.wolof: 'Wolof',
            AppLanguage.english: 'Anglais',
          },
          themes: {
            AppThemeChoice.system: 'Systeme',
            AppThemeChoice.light: 'Clair',
            AppThemeChoice.dark: 'Sombre',
          },
        ),
    };
  }
}
