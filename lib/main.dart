import 'package:flutter/material.dart';
import 'services/ble_service.dart';
import 'theme/app_theme.dart';
import 'screens/scan_screen.dart';
import 'screens/control_screen.dart';

void main() {
  runApp(const BjLedApp());
}

class BjLedApp extends StatelessWidget {
  const BjLedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BJ_LED Controller',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const LaunchGate(),
    );
  }
}

/// Decides whether to auto-reconnect to the last-known device or send
/// the user to the scan screen, shown briefly on every app launch.
class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  @override
  void initState() {
    super.initState();
    _attemptAutoReconnect();
  }

  Future<void> _attemptAutoReconnect() async {
    final last = await BleService.instance.getLastDevice();
    if (last == null) {
      _goToScan();
      return;
    }
    try {
      await BleService.instance.connect(last.id, deviceName: last.name);
      _goToControl();
    } catch (_) {
      _goToScan();
    }
  }

  void _goToScan() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  void _goToControl() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ControlScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Looking for your light…',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
