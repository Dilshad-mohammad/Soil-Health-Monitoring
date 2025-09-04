import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothProvider extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSub;

  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _lastError;

  final List<ScanResult> devices = [];
  final List<String> _readings = [];

  bool _mockMode = false;
  Timer? _mockTimer;

  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<String> get readings => List.unmodifiable(_readings);
  bool get mockMode => _mockMode;
  String? get lastError => _lastError;

  Future<bool> requestPermissions() async {
    try {
      return await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  Future<void> scanForDevices({Duration timeout = const Duration(seconds: 5)}) async {
    if (_isScanning) return;

    devices.clear();
    _isScanning = true;
    notifyListeners();

    final ok = await requestPermissions();
    if (!ok) {
      _isScanning = false;
      notifyListeners();
      return;
    }

    try {
      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(timeout: timeout);
      await _scanSub?.cancel();

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final idx = devices.indexWhere((d) => d.device.id == r.device.id);
          if (idx == -1) {
            devices.add(r);
          } else {
            devices[idx] = r;
          }
        }
        notifyListeners();
      });

      FlutterBluePlus.isScanning.listen((scanning) {
        _isScanning = scanning;
        notifyListeners();
      });
    } catch (e) {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    _isConnecting = true;
    notifyListeners();

    try {
      await device.connect();
      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      final services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.notify) {
            _dataCharacteristic = char;
            await char.setNotifyValue(true);
            char.value.listen((value) {
              if (value.isNotEmpty) {
                final str = String.fromCharCodes(value);
                _readings.add(str);
                notifyListeners();
              }
            });
          }
        }
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<bool> connectToMockDevice() async {
    _isConnecting = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _isConnected = true;
      _mockMode = true;
      _startMockData();
      return true;
    } catch (_) {
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _isConnected = false;
    _dataCharacteristic = null;
    _stopMockData();
    _mockMode = false;
    notifyListeners();
  }

  Future<Map<String, double>?> fetchNewReading() async {
    if (_readings.isEmpty) return null;

    final latestReading = _readings.last;

    if (_mockMode && latestReading.startsWith('MOCK:')) {
      final temp = 20.0 + (DateTime.now().millisecond % 100) / 10;
      final moisture = 30.0 + (DateTime.now().second % 70);
      return {
        'temperature': double.parse(temp.toStringAsFixed(1)),
        'moisture': double.parse(moisture.toStringAsFixed(1)),
      };
    } else {
      try {
        if (latestReading.contains(',')) {
          final parts = latestReading.split(',');
          double? temp, moisture;

          for (final part in parts) {
            if (part.toUpperCase().contains('TEMP')) {
              temp = double.tryParse(part.split(':').last);
            } else if (part.toUpperCase().contains('MOISTURE') ||
                part.toUpperCase().contains('HUMID')) {
              moisture = double.tryParse(part.split(':').last);
            }
          }

          if (temp != null && moisture != null) {
            return {
              'temperature': temp,
              'moisture': moisture,
            };
          }
        }

        final numbers = RegExp(r'\d+\.?\d*').allMatches(latestReading);
        if (numbers.length >= 2) {
          final numberList = numbers.map((m) => double.parse(m.group(0)!)).toList();
          return {
            'temperature': numberList[0],
            'moisture': numberList[1],
          };
        }
      } catch (_) {}
    }

    return null;
  }

  void clearReadings() {
    _readings.clear();
    notifyListeners();
  }

  void toggleMockMode() {
    _mockMode = !_mockMode;
    if (_mockMode) {
      _startMockData();
    } else {
      _stopMockData();
    }
    notifyListeners();
  }

  void _startMockData() {
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final mockReading = "MOCK:${DateTime.now().millisecondsSinceEpoch}";
      _readings.add(mockReading);
      notifyListeners();
    });
  }

  void _stopMockData() {
    _mockTimer?.cancel();
    _mockTimer = null;
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _mockTimer?.cancel();
    disconnect();
    super.dispose();
  }
}
