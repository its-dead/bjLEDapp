import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/ble_service.dart';
import '../services/preset_service.dart';
import '../models/led_preset.dart';
import '../services/bj_led_protocol.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_pill.dart';
import 'scan_screen.dart';
import 'presets_screen.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final _ble = BleService.instance;
  Color _currentColor = const Color(0xFFE8A87C);
  double _brightness = 1.0;
  bool _isOn = true;
  List<LedPreset> _presets = [];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final presets = await PresetService.instance.loadPresets();
    if (mounted) setState(() => _presets = presets);
  }

  Future<void> _applyColor(Color color) async {
    setState(() => _currentColor = color);
    if (!_isOn) return;
    await _ble.setColorWithBrightness(
      color.red,
      color.green,
      color.blue,
      _brightness,
    );
  }

  Future<void> _applyBrightness(double value) async {
    setState(() => _brightness = value);
    if (!_isOn) return;
    await _ble.setColorWithBrightness(
      _currentColor.red,
      _currentColor.green,
      _currentColor.blue,
      _brightness,
    );
  }

  Future<void> _toggleOn(bool value) async {
    setState(() => _isOn = value);
    if (value) {
      await _ble.turnOn();
      await _applyColor(_currentColor);
    } else {
      await _ble.turnOff();
    }
  }

  Future<void> _applyPreset(LedPreset preset) async {
    if (preset.type == PresetType.color) {
      final color = Color.fromRGBO(preset.red!, preset.green!, preset.blue!, 1);
      setState(() {
        _currentColor = color;
        _isOn = true;
      });
      await _ble.turnOn();
      await _applyColor(color);
    } else {
      setState(() => _isOn = true);
      await _ble.turnOn();
      await _ble.setMode(preset.mode!, preset.speed!);
    }
  }

  Future<void> _openSaveDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        title: const Text('Save preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Movie night'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await PresetService.instance.addColorPreset(
      name,
      (_currentColor.red * _brightness).round(),
      (_currentColor.green * _brightness).round(),
      (_currentColor.blue * _brightness).round(),
    );
    await _loadPresets();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "$name"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Light'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ConnectionStatusPill(
                status: _ble.status,
                onTap: () {
                  if (!_ble.isConnected) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero: current color preview, the "light" itself
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _isOn
                      ? _currentColor.withOpacity(0.9)
                      : AppTheme.surface,
                  boxShadow: _isOn
                      ? [
                          BoxShadow(
                            color: _currentColor.withOpacity(0.45),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isOn ? 'On' : 'Off',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _isOn ? Colors.black.withOpacity(0.75) : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: _isOn,
                      onChanged: _toggleOn,
                      activeColor: Colors.black.withOpacity(0.75),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text('Color', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ColorPicker(
                    pickerColor: _currentColor,
                    onColorChanged: _applyColor,
                    enableAlpha: false,
                    labelTypes: const [],
                    pickerAreaHeightPercent: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Brightness', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.brightness_low, color: AppTheme.textSecondary, size: 18),
                  Expanded(
                    child: Slider(
                      value: _brightness,
                      onChanged: _applyBrightness,
                      activeColor: _currentColor,
                    ),
                  ),
                  const Icon(Icons.brightness_high, color: AppTheme.textSecondary, size: 18),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Presets', style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _openSaveDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Save current'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    final swatchColor = preset.type == PresetType.color
                        ? Color.fromRGBO(preset.red!, preset.green!, preset.blue!, 1)
                        : AppTheme.surfaceHigh;
                    return GestureDetector(
                      onTap: () => _applyPreset(preset),
                      child: Container(
                        width: 84,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: swatchColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.divider, width: 1.5),
                              ),
                              child: preset.type == PresetType.mode
                                  ? const Icon(Icons.auto_awesome,
                                      color: AppTheme.textSecondary, size: 20)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              preset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PresetsScreen()),
                    );
                    _loadPresets();
                  },
                  child: const Text('Manage presets'),
                ),
              ),

              const SizedBox(height: 16),
              Text('Effects', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _ModeSelector(
                onApply: (mode, speed) async {
                  setState(() => _isOn = true);
                  await _ble.turnOn();
                  await _ble.setMode(mode, speed);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatefulWidget {
  final Future<void> Function(int mode, int speed) onApply;
  const _ModeSelector({required this.onApply});

  @override
  State<_ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<_ModeSelector> {
  int _selectedMode = 0;
  double _speed = 5;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BjLedModes.names.entries.map((entry) {
                final selected = _selectedMode == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMode = entry.key),
                  selectedColor: AppTheme.surfaceHigh,
                  backgroundColor: AppTheme.background,
                  labelStyle: TextStyle(
                    color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: AppTheme.divider),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Speed', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Expanded(
                  child: Slider(
                    value: _speed,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => setState(() => _speed = v),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onApply(_selectedMode, _speed.round()),
                child: const Text('Apply effect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
