import 'package:flutter/material.dart';

enum AppLanguage {
  french('fr', 'Francais'),
  wolof('wo', 'Wolof'),
  english('en', 'English');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AppLanguage.french,
    );
  }
}

enum AppThemeChoice {
  system('system', 'Systeme'),
  light('light', 'Clair'),
  dark('dark', 'Sombre');

  const AppThemeChoice(this.code, this.label);

  final String code;
  final String label;

  ThemeMode get themeMode {
    return switch (this) {
      AppThemeChoice.light => ThemeMode.light,
      AppThemeChoice.dark => ThemeMode.dark,
      AppThemeChoice.system => ThemeMode.system,
    };
  }

  static AppThemeChoice fromCode(String? code) {
    return AppThemeChoice.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AppThemeChoice.system,
    );
  }
}

class AppSettings {
  const AppSettings({
    this.language = AppLanguage.french,
    this.theme = AppThemeChoice.system,
    this.notificationsEnabled = true,
  });

  final AppLanguage language;
  final AppThemeChoice theme;
  final bool notificationsEnabled;

  AppSettings copyWith({
    AppLanguage? language,
    AppThemeChoice? theme,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language.code,
      'theme': theme.code,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: AppLanguage.fromCode(json['language'] as String?),
      theme: AppThemeChoice.fromCode(json['theme'] as String?),
      notificationsEnabled: json['notificationsEnabled'] != false,
    );
  }
}
