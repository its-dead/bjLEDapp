/// BJ_LED BLE protocol command builder.
///
/// Confirmed working protocol (reverse-engineered from the MohuanLED app,
/// see https://github.com/8none1/bj_led):
///
///   On:           69 96 06 01 01
///   Off:          69 96 02 01 00
///   Set color:    69 96 05 02 <R> <G> <B> [W]   (W optional, strip is RGB-only)
///   Set mode:     69 96 03 03 <mode> <speed>     (mode 00-15 hex, speed 01-0a hex)
///
/// All values are sent as raw byte arrays (not UTF-8 text) to the write
/// characteristic.
library;

class BjLedProtocol {
  static const List<int> _header = [0x69, 0x96];

  /// Turn the strip on.
  static List<int> on() => [..._header, 0x06, 0x01, 0x01];

  /// Turn the strip off.
  static List<int> off() => [..._header, 0x02, 0x01, 0x00];

  /// Set a solid RGB color. Values must be 0-255.
  /// White channel is omitted since most BJ_LED strips are RGB-only;
  /// pass [white] if your specific strip has a 4th channel.
  static List<int> setColor(int r, int g, int b, {int? white}) {
    final clampedR = r.clamp(0, 255);
    final clampedG = g.clamp(0, 255);
    final clampedB = b.clamp(0, 255);
    final command = [..._header, 0x05, 0x02, clampedR, clampedG, clampedB];
    if (white != null) {
      command.add(white.clamp(0, 255));
    }
    return command;
  }

  /// Set an effect mode (0-21 decimal / 0x00-0x15 hex) with a speed
  /// (1 = fastest, 10 = slowest). Values outside this range may behave
  /// unpredictably on the device.
  static List<int> setMode(int mode, int speed) {
    final clampedMode = mode.clamp(0, 0x15);
    final clampedSpeed = speed.clamp(1, 0x0a);
    return [..._header, 0x03, 0x03, clampedMode, clampedSpeed];
  }

  /// Scale an RGB color by a brightness factor (0.0-1.0).
  /// The protocol has no dedicated brightness command; brightness is
  /// achieved by scaling the color channels themselves.
  static List<int> setColorWithBrightness(
    int r,
    int g,
    int b,
    double brightness,
  ) {
    final clamped = brightness.clamp(0.0, 1.0);
    return setColor(
      (r * clamped).round(),
      (g * clamped).round(),
      (b * clamped).round(),
    );
  }

  /// Human-readable hex string for debugging/logging.
  static String toHexString(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}

/// Named effect modes available on BJ_LED strips (00-15 hex / 0-21 decimal).
/// Exact visual effect per index varies slightly by firmware batch;
/// these labels are best-effort based on community testing.
class BjLedModes {
  static const Map<int, String> names = {
    0: 'Mode 1',
    1: 'Mode 2',
    2: 'Mode 3',
    3: 'Mode 4',
    4: 'Mode 5',
    5: 'Mode 6',
    6: 'Mode 7',
    7: 'Mode 8',
    8: 'Mode 9',
    9: 'Mode 10',
    10: 'Mode 11',
    11: 'Mode 12',
    12: 'Mode 13',
    13: 'Mode 14',
    14: 'Mode 15',
    15: 'Mode 16',
    16: 'Mode 17',
    17: 'Mode 18',
    18: 'Mode 19',
    19: 'Mode 20',
    20: 'Mode 21',
    21: 'Mode 22',
  };
}
