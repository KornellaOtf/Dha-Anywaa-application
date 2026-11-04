import 'package:shared_preferences/shared_preferences.dart';

class SavedData {
  // ── Name ─────────────────────────────────────────────────────────────────
  Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name') ?? 'guess';
  }

  Future<void> setName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', value);
  }

  // ── Last visited route (for Continue card) ───────────────────────────────
  Future<String> getLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_route') ?? 'alphabet';
  }

  Future<void> setLastRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_route', route);
  }

  // ── Learned items  key = "<category>_<index>" e.g. "alphabet_3" ──────────
  Future<bool> isLearned(String category, int index) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('learned_${category}_$index') ?? false;
  }

  Future<void> setLearned(String category, int index, {bool value = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('learned_${category}_$index', value);
  }

  /// Returns how many items in [category] are marked learned (out of [total]).
  Future<int> learnedCount(String category, int total) async {
    final prefs = await SharedPreferences.getInstance();
    int count = 0;
    for (int i = 0; i < total; i++) {
      if (prefs.getBool('learned_${category}_$i') ?? false) count++;
    }
    return count;
  }

  // ── Sound enabled ────────────────────────────────────────────────────────
  Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sound_enabled') ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
  }

  // ── Clear all progress (used on log-out if desired) ──────────────────────
  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('learned_') || k == 'last_route');
    for (final k in keys) { await prefs.remove(k); }
  }
}
