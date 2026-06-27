import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the appearance choice — follow the system, force light, or force dark —
/// and exposes it as the [ThemeMode] handed to `MaterialApp`. The palette itself
/// rides on `ThemeData` (see `AppPalette`), so changing the mode updates every
/// widget that reads `context.colors`. The choice is persisted, so it sticks
/// across launches.
class ThemeController extends ChangeNotifier {
  ThemeController(this._mode);

  /// Stores the mode as a string ('system' | 'light' | 'dark').
  static const String _prefKey = 'theme_mode';

  /// Legacy boolean key from the light/dark-only version, migrated on read.
  static const String _legacyKey = 'theme_dark';

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Set the appearance mode explicitly, then persist.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _encode(mode));
    } catch (_) {
      // Persisting is best-effort; a failure just means the choice won't
      // survive the next launch. The in-session switch already took effect.
    }
  }

  /// Reads the saved mode, or `null` if the user has never chosen — the caller
  /// then defaults to following the system. Migrates the legacy `theme_dark`
  /// boolean so an existing dark choice carries over.
  static Future<ThemeMode?> loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefKey);
      if (stored != null) return _decode(stored);
      final legacyDark = prefs.getBool(_legacyKey);
      if (legacyDark != null) {
        return legacyDark ? ThemeMode.dark : ThemeMode.light;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _decode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
