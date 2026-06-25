import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bj_led_protocol.dart';

/// Connection state exposed to the UI layer.
enum BleConnectionStatus { disconnected, scanning, connecting, connected, error }

/// Characteristic UUIDs for this BJ_LED device, confirmed by direct
/// testing with nRF Connect: writing to 0xEE02 successfully turned the
/// strip on. 0xEE01 is assumed to be the notify characteristic, though
/// per community findings these devices never actually send notifications.
///
/// If `connect()` fails to find these on your specific board, check
/// nRF Connect's service discovery again — some batches vary.
class BjLedUuids {
  static final serviceUuid = Uuid.parse('0000ee00-0000-1000-8000-00805f9b34fb');
  static final writeCharacteristicUuid =
      Uuid.parse('0000ee02-0000-1000-8000-00805f9b34fb');
  static final notifyCharacteristicUuid =
      Uuid.parse('0000ee01-0000-1000-8000-00805f9b34fb');
}

class BleService {
  BleService._internal();
  static final BleService instance = BleService._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final _statusController = StreamController<BleConnectionStatus>.broadcast();
  Stream<BleConnectionStatus> get statusStream => _statusController.stream;
  BleConnectionStatus _status = BleConnectionStatus.disconnected;
  BleConnectionStatus get status => _status;

  final _devicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;
  final List<DiscoveredDevice> _discoveredDevices = [];

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;

  String? _connectedDeviceId;
  QualifiedCharacteristic? _writeCharacteristic;

  static const _lastDeviceKey = 'bjled_last_device_id';
  static const _lastDeviceNameKey = 'bjled_last_device_name';

  void _setStatus(BleConnectionStatus s) {
    _status = s;
    _statusController.add(s);
  }

  /// Scan for BJ_LED devices. Devices advertise with names starting
  /// with "BJ_LED" and MAC addresses commonly starting FF:FF:xx:xx:xx:xx.
  void startScan({Duration timeout = const Duration(seconds: 10)}) {
    _discoveredDevices.clear();
    _setStatus(BleConnectionStatus.scanning);

    _scanSub?.cancel();
    _scanSub = _ble.scanForDevices(withServices: []).listen(
      (device) {
        final isLikelyMatch = device.name.toUpperCase().contains('BJ_LED') ||
            device.name.toUpperCase().contains('MOHUAN') ||
            device.id.toUpperCase().startsWith('FF:FF');
        if (!isLikelyMatch && device.name.isEmpty) return;

        final existingIndex =
            _discoveredDevices.indexWhere((d) => d.id == device.id);
        if (existingIndex >= 0) {
          _discoveredDevices[existingIndex] = device;
        } else {
          _discoveredDevices.add(device);
        }
        _devicesController.add(List.unmodifiable(_discoveredDevices));
      },
      onError: (e) {
        _setStatus(BleConnectionStatus.error);
      },
    );

    Future.delayed(timeout, stopScan);
  }

  void stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
    if (_status == BleConnectionStatus.scanning) {
      _setStatus(BleConnectionStatus.disconnected);
    }
  }

  /// Connect to a device by ID, discover its writable characteristic,
  /// and remember it for auto-reconnect on next launch.
  Future<void> connect(String deviceId, {String? deviceName}) async {
    stopScan();
    _setStatus(BleConnectionStatus.connecting);

    _connectionSub?.cancel();
    final completer = Completer<void>();

    _connectionSub = _ble
        .connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    )
        .listen(
      (update) async {
        if (update.connectionState == DeviceConnectionState.connected) {
          _connectedDeviceId = deviceId;
          await _saveLastDevice(deviceId, deviceName);
          _writeCharacteristic = QualifiedCharacteristic(
            serviceId: BjLedUuids.serviceUuid,
            characteristicId: BjLedUuids.writeCharacteristicUuid,
            deviceId: deviceId,
          );
          _setStatus(BleConnectionStatus.connected);
          if (!completer.isCompleted) completer.complete();
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          _connectedDeviceId = null;
          _writeCharacteristic = null;
          _setStatus(BleConnectionStatus.disconnected);
        }
      },
      onError: (e) {
        _setStatus(BleConnectionStatus.error);
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        _setStatus(BleConnectionStatus.error);
        throw TimeoutException('Could not connect to device');
      },
    );
  }

  Future<void> disconnect() async {
    await _connectionSub?.cancel();
    _connectionSub = null;
    _connectedDeviceId = null;
    _writeCharacteristic = null;
    _setStatus(BleConnectionStatus.disconnected);
  }

  Future<void> _saveLastDevice(String deviceId, String? deviceName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDeviceKey, deviceId);
    if (deviceName != null) {
      await prefs.setString(_lastDeviceNameKey, deviceName);
    }
  }

  Future<({String id, String? name})?> getLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_lastDeviceKey);
    if (id == null) return null;
    final name = prefs.getString(_lastDeviceNameKey);
    return (id: id, name: name);
  }

  Future<void> _write(List<int> bytes) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw StateError('Not connected to a device');
    }
    await _ble.writeCharacteristicWithoutResponse(
      characteristic,
      value: bytes,
    );
  }

  Future<void> turnOn() => _write(BjLedProtocol.on());
  Future<void> turnOff() => _write(BjLedProtocol.off());
  Future<void> setColor(int r, int g, int b) =>
      _write(BjLedProtocol.setColor(r, g, b));
  Future<void> setColorWithBrightness(
    int r,
    int g,
    int b,
    double brightness,
  ) =>
      _write(BjLedProtocol.setColorWithBrightness(r, g, b, brightness));
  Future<void> setMode(int mode, int speed) =>
      _write(BjLedProtocol.setMode(mode, speed));

  bool get isConnected => _status == BleConnectionStatus.connected;

  void dispose() {
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _statusController.close();
    _devicesController.close();
  }
}
