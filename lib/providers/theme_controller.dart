import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_palette.dart';

/// Persists the selected [AppPalette] and notifies the app to rebuild ThemeData.
class ThemeController extends ChangeNotifier {
  ThemeController({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _prefKey = 'app_palette_id';

  final SharedPreferences? _prefsOverride;
  AppPalette _palette = AppPalette.skyYellow;
  bool _loaded = false;

  AppPalette get palette => _palette;
  String get paletteId => _palette.id;
  bool get isLoaded => _loaded;
  List<AppPalette> get presets => AppPalette.presets;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<void> load() async {
    try {
      final prefs = await _prefs();
      _palette = AppPalette.byId(prefs.getString(_prefKey));
    } catch (e) {
      debugPrint('ThemeController.load: $e');
      _palette = AppPalette.skyYellow;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setPalette(AppPalette palette) async {
    if (palette.id == _palette.id) return;
    _palette = palette;
    notifyListeners();
    try {
      final prefs = await _prefs();
      await prefs.setString(_prefKey, palette.id);
    } catch (e) {
      debugPrint('ThemeController.setPalette: $e');
    }
  }

  Future<void> setPaletteId(String id) => setPalette(AppPalette.byId(id));
}
