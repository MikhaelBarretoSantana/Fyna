import 'package:flutter/material.dart';

/// Notifier global para controlar o tema do app.
/// Permite trocar entre claro, escuro e automático (sistema).
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeNotifier([this._themeMode = ThemeMode.system]);

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  /// Converte string do backend (SYSTEM, LIGHT, DARK) para ThemeMode.
  void setFromString(String theme) {
    switch (theme.toUpperCase()) {
      case 'LIGHT':
        setThemeMode(ThemeMode.light);
        break;
      case 'DARK':
        setThemeMode(ThemeMode.dark);
        break;
      default:
        setThemeMode(ThemeMode.system);
    }
  }

  /// Converte ThemeMode para string do backend.
  static String toBackendString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'LIGHT';
      case ThemeMode.dark:
        return 'DARK';
      default:
        return 'SYSTEM';
    }
  }
}
