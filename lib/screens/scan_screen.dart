import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import 'control_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _ble = BleService.instance;
  List<DiscoveredDevice> _devices = [];
  String? _connectingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startScanFlow();
  }

  Future<void> _startScanFlow() async {
    final granted = await _requestPermissions();
    if (!granted) {
      setState(() => _error =
          'Bluetooth and location permissions are needed to find your light strip.');
      return;
    }
    _ble.devicesStream.listen((devices) {
      if (mounted) setState(() => _devices = devices);
    });
    _ble.startScan();
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every(
      (s) => s.isGranted || s.isLimited,
    );
  }

  Future<void> _connect(DiscoveredDevice device) async {
    setState(() {
      _connectingId = device.id;
      _error = null;
    });
    try {
      await _ble.connect(device.id, deviceName: device.name);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ControlScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectingId = null;
        _error = "Couldn't connect. Move closer and try again.";
      });
    }
  }

  @override
  void dispose() {
    _ble.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find your light')),
      body: Column(
        children: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE07A7A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFE07A7A), fontSize: 13),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Searching for BJ_LED devices…',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      'No devices found yet.\nMake sure your light strip is powered on.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isConnecting = _connectingId == device.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: const Icon(Icons.light_mode_outlined,
                              color: AppTheme.textSecondary),
                          title: Text(
                            device.name.isEmpty ? 'Unnamed device' : device.name,
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(device.id,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          trailing: isConnecting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                          onTap: isConnecting ? null : () => _connect(device),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _devices = []);
                  _ble.startScan();
                },
                child: const Text('Scan again'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
