// Regression tests for the app's saved-preference behaviour.
//
// The previous file was the untouched Flutter counter template, which never
// applied to this app (there is no counter) and crashed because it pumped
// `MyApp` without its required `AppSettings` ancestor. These tests cover the
// real behaviour instead and, importantly, the theme-persistence bug:
// an explicit Light/Dark choice must survive a relaunch and must NOT fall back
// to the system (which may be dark) just because the device is in dark mode.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dha_anywaaa/app_settings.dart';
import 'package:dha_anywaaa/components/savedData.dart';

void main() {
  test('theme index maps to the right ThemeMode', () {
    expect(AppSettingsNotifier.modeFromIndex(0), ThemeMode.system);
    expect(AppSettingsNotifier.modeFromIndex(1), ThemeMode.light);
    expect(AppSettingsNotifier.modeFromIndex(2), ThemeMode.dark);
    expect(AppSettingsNotifier.modeFromIndex(99), ThemeMode.system);
  });

  test('saved theme mode round-trips through SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    expect(await SavedData().getThemeMode(), 1);
  });

  test('an explicit Light selection is applied synchronously on startup',
      () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 1});
    // This is the exact call main() makes from the preloaded prefs value.
    final notifier = AppSettingsNotifier(
      initialThemeMode: AppSettingsNotifier.modeFromIndex(1),
    );
    expect(notifier.themeMode, ThemeMode.light);
    // Let the async refresh in the constructor settle before tearing down.
    await Future<void>.delayed(Duration.zero);
    expect(notifier.themeMode, ThemeMode.light);
    notifier.dispose();
  });

  test('setThemeMode persists the chosen mode as its index', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = AppSettingsNotifier();

    await notifier.setThemeMode(ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('theme_mode'), ThemeMode.light.index);
    expect(notifier.themeMode, ThemeMode.light);

    await notifier.setThemeMode(ThemeMode.dark);
    expect(prefs.getInt('theme_mode'), ThemeMode.dark.index);

    notifier.dispose();
  });
}
