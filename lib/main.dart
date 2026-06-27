import 'package:flutter/foundation.dart';
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
      title: 'light it up',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: kIsWeb ? const WebUnsupportedScreen() : const LaunchGate(),
    );
  }
}

class WebUnsupportedScreen extends StatelessWidget {
  const WebUnsupportedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bluetooth_disabled, size: 56, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'This app uses Bluetooth to control your light strip.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The web version can’t connect to BLE devices. Open this app on Android or iOS to find and control your light strip.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
