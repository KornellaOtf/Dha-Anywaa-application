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

  AppSettingsNotifier() {
    _load();
  }

  Future<void> _load() async {
    _soundEnabled = await _savedData.getSoundEnabled();
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    await _savedData.setSoundEnabled(value);
  }
}
