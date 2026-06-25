import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';

/// A small status pill with a dot that pulses gently when connected,
/// mimicking the breathing glow of the LED strip itself rather than
/// using a generic colored badge.
class ConnectionStatusPill extends StatefulWidget {
  final BleConnectionStatus status;
  final String? deviceName;
  final VoidCallback onTap;

  const ConnectionStatusPill({
    super.key,
    required this.status,
    required this.onTap,
    this.deviceName,
  });

  @override
  State<ConnectionStatusPill> createState() => _ConnectionStatusPillState();
}

class _ConnectionStatusPillState extends State<ConnectionStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _dotColor() {
    switch (widget.status) {
      case BleConnectionStatus.connected:
        return const Color(0xFF7FD8C4);
      case BleConnectionStatus.connecting:
      case BleConnectionStatus.scanning:
        return const Color(0xFFE8A87C);
      case BleConnectionStatus.error:
        return const Color(0xFFE07A7A);
      case BleConnectionStatus.disconnected:
        return AppTheme.textSecondary;
    }
  }

  String _label() {
    switch (widget.status) {
      case BleConnectionStatus.connected:
        return widget.deviceName ?? 'Connected';
      case BleConnectionStatus.connecting:
        return 'Connecting…';
      case BleConnectionStatus.scanning:
        return 'Scanning…';
      case BleConnectionStatus.error:
        return 'Connection error';
      case BleConnectionStatus.disconnected:
        return 'Not connected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _dotColor();
    final isActive = widget.status == BleConnectionStatus.connected;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final scale = isActive
                    ? 1.0 + (_pulseController.value * 0.6)
                    : 1.0;
                final opacity = isActive
                    ? 1.0 - (_pulseController.value * 0.4)
                    : 1.0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isActive)
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color.withOpacity(opacity * 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              _label(),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
