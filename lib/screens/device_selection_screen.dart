import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/blutooth_provider.dart';

class DeviceSelectionScreen extends StatefulWidget {
  const DeviceSelectionScreen({super.key});

  @override
  State<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  bool _isConnecting = false;
  String? _connectingId;
  BluetoothProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<BluetoothProvider>();
      _provider?.scanForDevices();
    });
  }

  @override
  void dispose() {
    _provider?.stopScan();
    super.dispose();
  }

  Future<void> _connect(ScanResult result) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _connectingId = result.device.remoteId.str;
    });

    final provider = context.read<BluetoothProvider>();
    final ok = await provider.connectToDevice(result.device);

    if (!mounted) return;

    setState(() {
      _isConnecting = false;
      _connectingId = null;
    });

    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${result.device.platformName.isNotEmpty ? result.device.platformName : result.device.remoteId.str}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: ${provider.lastError ?? "Unknown error"}')),
      );
    }
  }

  Future<void> _connectToMockDevice() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _connectingId = 'mock_device';
    });

    final provider = context.read<BluetoothProvider>();
    final ok = await provider.connectToMockDevice();

    if (!mounted) return;

    setState(() {
      _isConnecting = false;
      _connectingId = null;
    });

    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Connected to Mock Device')),
      );
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Failed to connect: ${provider.lastError ?? "Unknown error"}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Device'),
        actions: [
          Consumer<BluetoothProvider>(
            builder: (context, bt, _) {
              return IconButton(
                icon: bt.isScanning
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.refresh),
                onPressed: bt.isScanning ? null : () => bt.scanForDevices(),
              );
            },
          ),
        ],
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, bt, _) {
          final list = bt.devices;

          if (bt.isScanning && list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Scanning for devices...'),
                ],
              ),
            );
          }

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'No devices found.\nMake sure Bluetooth is ON and your device is nearby.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => bt.scanForDevices(),
                    child: const Text('Scan Again'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isConnecting ? null : _connectToMockDevice,
                    child: _isConnecting && _connectingId == 'mock_device'
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Connect Mock Device'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              final name = r.device.platformName.isNotEmpty ? r.device.platformName : r.device.remoteId.str;
              final id = r.device.remoteId.str;
              final connecting = _isConnecting && (_connectingId == id);

              return ListTile(
                key: ValueKey(id),
                leading: const Icon(Icons.bluetooth_searching, color: Colors.blue),
                title: Text(name),
                subtitle: Text(id),
                trailing: connecting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: connecting ? null : () => _connect(r),
              );
            },
          );
        },
      ),
    );
  }
}
