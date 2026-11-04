import 'package:dha_anywaaa/components/savedData.dart';
import 'package:flutter/material.dart';

/// Simple inherited-widget settings store.
/// Wrap MaterialApp with AppSettingsProvider, then read anywhere via
/// AppSettings.of(context).
class AppSettings extends InheritedNotifier<AppSettingsNotifier> {
  const AppSettings({super.key, required super.notifier, required super.child});

  static AppSettingsNotifier of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<AppSettings>();
    assert(result != null, 'No AppSettings found in context');
    return result!.notifier!;
  }
}

class AppSettingsNotifier extends ChangeNotifier {
  final SavedData _savedData = SavedData();

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  AppSettingsNotifier({
    ThemeMode initialThemeMode = ThemeMode.system,
    bool initialSoundEnabled = true,
  })  : _themeMode = initialThemeMode,
        _soundEnabled = initialSoundEnabled {
    _load();
  }

  Future<void> _load() async {
    _soundEnabled = await _savedData.getSoundEnabled();
    _themeMode = modeFromIndex(await _savedData.getThemeMode());
    notifyListeners();
  }

  static ThemeMode modeFromIndex(int i) {
    switch (i) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    await _savedData.setSoundEnabled(value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _savedData.setThemeMode(mode.index);
  }
}
