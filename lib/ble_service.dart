import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static const String esp32DeviceName = "EVA-ESP32";

  static final Guid serviceUuid =
      Guid("12345678-1234-1234-1234-1234567890ab");

  static final Guid characteristicUuid =
      Guid("abcd1234-5678-90ab-cdef-1234567890ab");

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  bool _connecting = false;

  Future<void> connect() async {
    if (_connecting) return;
    _connecting = true;

    print("BLE SERVICE INSTANCE ACTIVE");

    // Ensure Bluetooth ON
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      print("Bluetooth OFF");
      _connecting = false;
      return;
    }

    print("BLE: Scanning...");

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        final name = r.device.platformName;

        if (name != esp32DeviceName) continue;

        print("ESP32 FOUND via Flutter");

        await FlutterBluePlus.stopScan();

        _device = r.device;

        try {
          await _device!.connect(autoConnect: false);
        } catch (_) {}

        print("Connected to ESP32");

        final services = await _device!.discoverServices();
        for (final s in services) {
          if (s.uuid == serviceUuid) {
            for (final c in s.characteristics) {
              if (c.uuid == characteristicUuid) {
                _characteristic = c;
                print("BLE READY TO SEND DATA");
                _connecting = false;
                return;
              }
            }
          }
        }
      }
    });
  }

 Future<void> sendCommand(String cmd) async {
  if (_characteristic == null) {
    print("BLE not ready (characteristic null)");
    return;
  }

  print("Sending: $cmd");

  await _characteristic!.write(
    utf8.encode(cmd),
    withoutResponse: false, // IMPORTANT
  );

  print("Sent OK: $cmd");
}
}
