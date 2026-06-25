# BJ_LED Controller

A custom Flutter app for controlling BJ_LED / MohuanLED Bluetooth LE light
strips, with a cleaner UI and proper color + effect presets — built on top
of the reverse-engineered protocol from the original MohuanLED app.

## Before you build: one thing to verify

This app assumes your light's writable characteristic lives under a
parent **service UUID of `0000ee00-0000-1000-8000-00805f9b34fb`**, with:

- `0xEE02` — write characteristic (confirmed working: writing `69 96 06 01 01` turns the strip on)
- `0xEE01` — assumed notify characteristic (the device never actually sends notifications, per community findings)

The **characteristic** UUIDs are confirmed by your own testing. The
**service** UUID (`ee00`) is inferred from the characteristic numbering
pattern and hasn't been independently verified. If the app fails to
connect or write commands:

1. Open nRF Connect, connect to your device, and expand the service that
   contains characteristic `0xEE02`.
2. Note its full UUID.
3. Update `serviceUuid` in `lib/services/ble_service.dart` to match.

## Setup

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) if you don't have it.
2. From this project folder, run:
   ```
   flutter pub get
   ```
3. Connect your Android phone (with USB debugging enabled) or start an emulator.
   Note: BLE doesn't work in most emulators — use a real device.
4. Run the app:
   ```
   flutter run
   ```

## Project structure

```
lib/
  main.dart                       - App entry point, auto-reconnect logic
  models/
    led_preset.dart                - Preset data model (color or mode)
  services/
    bj_led_protocol.dart           - BLE command byte builder (the protocol itself)
    ble_service.dart               - Scanning, connecting, writing via flutter_reactive_ble
    preset_service.dart            - Local storage for presets (shared_preferences)
  screens/
    scan_screen.dart               - Device discovery & connection
    control_screen.dart            - Main color/brightness/effects screen
    presets_screen.dart            - Manage (rename/delete/reorder) presets
  widgets/
    connection_status_pill.dart    - Pulsing connection indicator
  theme/
    app_theme.dart                 - Dark theme tuned to showcase light color
```

## The protocol (for reference)

```
On:           69 96 06 01 01
Off:          69 96 02 01 00
Set color:    69 96 05 02 <R> <G> <B>      (each byte 0x00-0xff)
Set mode:     69 96 03 03 <mode> <speed>   (mode 0x00-0x15, speed 0x01-0x0a)
```

Brightness has no dedicated command — it's implemented by scaling the
RGB values before sending, which is what `setColorWithBrightness` in
`ble_service.dart` does.

Source: protocol reverse-engineered by the community, see
https://github.com/8none1/bj_led

## Known limitations / things to adjust for your setup

- **Effect mode names** (`lib/services/bj_led_protocol.dart`, `BjLedModes`) are
  generic placeholders ("Mode 1", "Mode 2"...) — the exact visual effect per
  index varies by firmware batch. Try each one on your strip and rename them
  to something meaningful (e.g. "Rainbow fade", "Strobe") once you know what
  they do.
- **`applicationId`** in `android/app/build.gradle` is set to
  `com.example.bjled_app` — fine for personal use on your own device, but
  change it before sharing the app or publishing anywhere.
- **Release signing** currently falls back to the debug keystore so
  `flutter run --release` works without extra setup. Set up your own
  keystore before distributing this beyond your own devices.
- This hasn't been run through an actual Flutter build in this environment
  (no Flutter SDK available here), so if `flutter pub get` surfaces a
  version conflict on a dependency, loosen the version pin in `pubspec.yaml`
  for that package.

## Extending it further

Ideas that fit naturally on top of this structure:
- Schedules/automations (e.g. via `flutter_local_notifications` + `workmanager`)
- Android quick settings tile for on/off (requires a small native `TileService` in Kotlin)
- Multiple saved devices instead of just one
- Music/screen-color reactivity
