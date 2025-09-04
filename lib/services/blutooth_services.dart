import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final StreamController<Map<String, double>> _dataController =
  StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get dataStream => _dataController.stream;

  final List<ScanResult> scanResults = [];
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _chars;
  StreamSubscription<List<int>>? _subs;
  String _loading = '';

  bool get isConnected => _connectedDevice != null;

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    scanResults.clear();
    await requestPermissions();
    FlutterBluePlus.startScan(timeout: timeout);
    FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final index = scanResults.indexWhere((s) => s.device.id == r.device.id);
        if (index == -1) {
          scanResults.add(r);
        } else {
          scanResults[index] = r;
        }
      }
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<bool> connectToDevice(ScanResult scanResult,
      {Duration timeout = const Duration(seconds: 10)}) async {
    final device = scanResult.device;
    await device.connect(timeout: timeout, autoConnect: false);
    _connectedDevice = device;

    final services = await device.discoverServices();
    BluetoothCharacteristic? chosenChar;

    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.properties.notify || c.properties.indicate) {
          chosenChar = c;
          break;
        }
      }
      if (chosenChar != null) break;
    }

    if (chosenChar == null) {
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.read) {
            chosenChar = c;
            break;
          }
        }
        if (chosenChar != null) break;
      }
    }

    if (chosenChar == null) {
      return false;
    }

    _chars = chosenChar;

    if (_chars!.properties.notify || _chars!.properties.indicate) {
      await _chars!.setNotifyValue(true);
      _subs = _chars!.value.listen((bytes) {
        _onDataReceived(bytes);
      });
    } else if (_chars!.properties.read) {
      final bytes = await _chars!.read();
      _onDataReceived(bytes);
    }

    return true;
  }

  void _onDataReceived(List<int> bytes) {
    final chunk = utf8.decode(bytes, allowMalformed: true);
    _loading += chunk;
    while (_loading.contains('\n')) {
      final idx = _loading.indexOf('\n');
      final line = _loading.substring(0, idx).trim();
      _loading = _loading.substring(idx + 1);
      if (line.isNotEmpty) _parseData(line);
    }
  }

  void _parseData(String data) {
    final Map<String, String> values = {};
    for (final pair in data.split(',')) {
      final kv = pair.split(':');
      if (kv.length == 2) {
        values[kv[0].trim().toUpperCase()] = kv[1].trim();
      }
    }
    final t = double.tryParse(values['TEMP'] ?? '');
    final m = double.tryParse(values['MOISTURE'] ?? '');
    if (t != null && m != null) {
      _dataController.add({'temperature': t, 'moisture': m});
    }
  }

  Future<void> writeToDevice(List<int> bytes,
      {bool withResponse = true}) async {
    if (_chars == null) return;
    if (_chars!.properties.write || _chars!.properties.writeWithoutResponse) {
      await _chars!.write(bytes, withoutResponse: !withResponse);
    }
  }

  Future<void> disconnect() async {
    await _subs?.cancel();
    _subs = null;
    if (_chars != null &&
        (_chars!.properties.notify || _chars!.properties.indicate)) {
      await _chars!.setNotifyValue(false);
    }
    _chars = null;
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _connectedDevice = null;
    _loading = '';
  }

  void dispose() {
    disconnect();
    _dataController.close();
  }
}
