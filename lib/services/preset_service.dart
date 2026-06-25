import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/led_preset.dart';

/// Handles saving, loading, reordering, and deleting presets locally.
class PresetService {
  PresetService._internal();
  static final PresetService instance = PresetService._internal();

  static const _presetsKey = 'bjled_presets';
  final _uuid = const Uuid();

  List<LedPreset> _cache = [];
  bool _loaded = false;

  Future<List<LedPreset>> loadPresets() async {
    if (_loaded) return _cache;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_presetsKey);
    if (raw == null || raw.isEmpty) {
      _cache = _defaultPresets();
      await _save(prefs);
    } else {
      try {
        _cache = LedPreset.decodeList(raw);
      } catch (_) {
        _cache = _defaultPresets();
      }
    }
    _loaded = true;
    return _cache;
  }

  List<LedPreset> _defaultPresets() {
    return [
      LedPreset.color(id: _uuid.v4(), name: 'Warm White', red: 255, green: 180, blue: 100),
      LedPreset.color(id: _uuid.v4(), name: 'Red', red: 255, green: 0, blue: 0),
      LedPreset.color(id: _uuid.v4(), name: 'Blue', red: 0, green: 0, blue: 255),
      LedPreset.color(id: _uuid.v4(), name: 'Green', red: 0, green: 255, blue: 0),
    ];
  }

  Future<void> _save(SharedPreferences prefs) async {
    await prefs.setString(_presetsKey, LedPreset.encodeList(_cache));
  }

  Future<LedPreset> addColorPreset(String name, int r, int g, int b) async {
    final preset = LedPreset.color(id: _uuid.v4(), name: name, red: r, green: g, blue: b);
    _cache.add(preset);
    await _save(await SharedPreferences.getInstance());
    return preset;
  }

  Future<LedPreset> addModePreset(String name, int mode, int speed) async {
    final preset = LedPreset.mode(id: _uuid.v4(), name: name, mode: mode, speed: speed);
    _cache.add(preset);
    await _save(await SharedPreferences.getInstance());
    return preset;
  }

  Future<void> deletePreset(String id) async {
    _cache.removeWhere((p) => p.id == id);
    await _save(await SharedPreferences.getInstance());
  }

  Future<void> renamePreset(String id, String newName) async {
    final preset = _cache.firstWhere((p) => p.id == id);
    preset.name = newName;
    await _save(await SharedPreferences.getInstance());
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _cache.removeAt(oldIndex);
    _cache.insert(newIndex, item);
    await _save(await SharedPreferences.getInstance());
  }

  List<LedPreset> get current => _cache;
}
