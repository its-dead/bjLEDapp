import 'package:flutter/material.dart';
import '../models/led_preset.dart';
import '../services/preset_service.dart';
import '../theme/app_theme.dart';

class PresetsScreen extends StatefulWidget {
  const PresetsScreen({super.key});

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  List<LedPreset> _presets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final presets = await PresetService.instance.loadPresets();
    if (mounted) setState(() => _presets = List.of(presets));
  }

  Future<void> _rename(LedPreset preset) async {
    final controller = TextEditingController(text: preset.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        title: const Text('Rename preset'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    await PresetService.instance.renamePreset(preset.id, newName);
    _load();
  }

  Future<void> _delete(LedPreset preset) async {
    await PresetService.instance.deletePreset(preset.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage presets')),
      body: _presets.isEmpty
          ? Center(
              child: Text(
                'No presets yet.\nSave a color or effect from the Light screen.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: _presets.length,
              onReorder: (oldIndex, newIndex) async {
                await PresetService.instance.reorder(oldIndex, newIndex);
                _load();
              },
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final swatchColor = preset.type == PresetType.color
                    ? Color.fromRGBO(preset.red!, preset.green!, preset.blue!, 1)
                    : AppTheme.surfaceHigh;
                return Card(
                  key: ValueKey(preset.id),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: swatchColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: preset.type == PresetType.mode
                          ? const Icon(Icons.auto_awesome, size: 16, color: AppTheme.textSecondary)
                          : null,
                    ),
                    title: Text(preset.name, style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(
                      preset.type == PresetType.color ? 'Color' : 'Effect mode',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                          onPressed: () => _rename(preset),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFE07A7A)),
                          onPressed: () => _delete(preset),
                        ),
                        const Icon(Icons.drag_handle, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
