import 'dart:convert';

enum PresetType { color, mode }

/// A saved preset — either a solid color or an effect mode + speed.
class LedPreset {
  final String id;
  String name;
  final PresetType type;

  // Color fields (used when type == color)
  final int? red;
  final int? green;
  final int? blue;

  // Mode fields (used when type == mode)
  final int? mode;
  final int? speed;

  LedPreset({
    required this.id,
    required this.name,
    required this.type,
    this.red,
    this.green,
    this.blue,
    this.mode,
    this.speed,
  });

  factory LedPreset.color({
    required String id,
    required String name,
    required int red,
    required int green,
    required int blue,
  }) {
    return LedPreset(
      id: id,
      name: name,
      type: PresetType.color,
      red: red,
      green: green,
      blue: blue,
    );
  }

  factory LedPreset.mode({
    required String id,
    required String name,
    required int mode,
    required int speed,
  }) {
    return LedPreset(
      id: id,
      name: name,
      type: PresetType.mode,
      mode: mode,
      speed: speed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'red': red,
        'green': green,
        'blue': blue,
        'mode': mode,
        'speed': speed,
      };

  factory LedPreset.fromJson(Map<String, dynamic> json) {
    return LedPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PresetType.values.firstWhere((t) => t.name == json['type']),
      red: json['red'] as int?,
      green: json['green'] as int?,
      blue: json['blue'] as int?,
      mode: json['mode'] as int?,
      speed: json['speed'] as int?,
    );
  }

  static String encodeList(List<LedPreset> presets) {
    return jsonEncode(presets.map((p) => p.toJson()).toList());
  }

  static List<LedPreset> decodeList(String jsonStr) {
    final decoded = jsonDecode(jsonStr) as List<dynamic>;
    return decoded
        .map((item) => LedPreset.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
