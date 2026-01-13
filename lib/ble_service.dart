import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class BleService {
  
  // 🔒 SINGLETON
  static final BleService instance = BleService._internal();
  BleService._internal();
  factory BleService() => instance;

  // ================= STREAM CONTROLLER =================
  final StreamController<bool> _readyController =
      StreamController<bool>.broadcast();

  Stream<bool> get readyStream => _readyController.stream;

  // ================= CONFIG =================
  static const String esp32DeviceName = "EVA-ESP32";

  static final Guid serviceUuid =
      Guid("12345678-1234-1234-1234-1234567890ab");

  // ✅ FIXED: Match the actual ESP32 characteristic UUID
  static final Guid characteristicUuid =
      Guid("87654321-4321-4321-4321-ba0987654321");

  // ================= STATE =================
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;

  bool _connecting = false;
  bool isReady = false;

  // ================= CONNECT =================
  Future<void> connect() async {
    if (_connecting || isReady) {
      print("Already connecting or connected");
      return;
    }

    _connecting = true;
    print("🔍 BLE SERVICE: Starting connection...");

    try {
      // Check Bluetooth adapter state
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        print("❌ Bluetooth is OFF");
        _connecting = false;
        _readyController.add(false);
        return;
      }

      print("🔍 BLE: Scanning for $esp32DeviceName...");
      
      // Start scan
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15)
      );

      // Wait for ESP32 device
      BluetoothDevice? foundDevice;
      
      await for (final results in FlutterBluePlus.scanResults) {
        for (final result in results) {
          print("📡 Found: ${result.device.platformName}");
          
          if (result.device.platformName == esp32DeviceName) {
            foundDevice = result.device;
            break;
          }
        }
        if (foundDevice != null) break;
      }

      await FlutterBluePlus.stopScan();

      if (foundDevice == null) {
        print("❌ ESP32 not found");
        _connecting = false;
        _readyController.add(false);
        return;
      }

      _device = foundDevice;
      print("✅ ESP32 FOUND: ${_device!.platformName}");

      // Connect to device
      await _device!.connect(autoConnect: false);
      print("✅ Connected to ESP32");

      // Add delay before discovering services
      await Future.delayed(const Duration(milliseconds: 500));

      // Discover services
      print("🔍 Discovering services...");
      final services = await _device!.discoverServices();
      print("📋 Found ${services.length} services");

      // Find our service and characteristic
      for (final service in services) {
        print("   Service: ${service.uuid}");
        
        if (service.uuid == serviceUuid) {
          print("   ✅ Found our service!");
          
          for (final characteristic in service.characteristics) {
            print("      Characteristic: ${characteristic.uuid}");
            
            if (characteristic.uuid == characteristicUuid) {
              _characteristic = characteristic;
              isReady = true;
              
              // Broadcast ready state
              _readyController.add(true);
              
              print("🎉 BLE READY TO SEND DATA");
              _connecting = false;
              return;
            }
          }
        }
      }

      // If we reach here, characteristic wasn't found
      print("❌ Characteristic NOT FOUND");
      print("   Expected: $characteristicUuid");
      _readyController.add(false);
      _connecting = false;

    } catch (e) {
      print("❌ BLE Connection Error: $e");
      _readyController.add(false);
      _connecting = false;
    }
  }

  // ================= SEND =================
  Future<void> sendCommand(String cmd) async {
    if (!isReady || _characteristic == null) {
      print("❌ BLE NOT READY — Command ignored: $cmd");
      return;
    }

    try {
      print("📤 Sending command: $cmd");

      await _characteristic!.write(
        utf8.encode(cmd),
        withoutResponse: false,
      );

      print("✅ Command sent successfully: $cmd");
    } catch (e) {
      print("❌ Send failed: $e");
    }
  }

  // ================= DISCONNECT =================
  Future<void> disconnect() async {
    if (_device != null) {
      await _device!.disconnect();
      isReady = false;
      _readyController.add(false);
      _characteristic = null;
      _device = null;
      print("🔌 Disconnected from ESP32");
    }
  }
}
