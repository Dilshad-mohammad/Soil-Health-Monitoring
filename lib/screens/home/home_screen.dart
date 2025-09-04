import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blutooth_provider.dart';
import '../../providers/reading_provider.dart';
import '../device_selection_screen.dart';
import '../history_screens.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReadingsProvider>(context, listen: false).loadReadings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soil Monitor'),
        actions: [
          Consumer<BluetoothProvider>(
            builder: (context, bluetoothProvider, _) {
              return IconButton(
                icon: Icon(
                  bluetoothProvider.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                ),
                onPressed: () async {
                  if (bluetoothProvider.isConnected) {
                    await bluetoothProvider.disconnect();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DeviceSelectionScreen()),
                    );
                  }
                },
              );
            },
          ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') {
                Provider.of<AuthProvider>(context, listen: false).signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer<BluetoothProvider>(
              builder: (context, bluetoothProvider, _) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          bluetoothProvider.isConnected
                              ? Icons.check_circle
                              : Icons.error,
                          color: bluetoothProvider.isConnected
                              ? Colors.green
                              : Colors.red,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bluetoothProvider.isConnected
                                ? 'Connected to ${bluetoothProvider.connectedDevice?.name}'
                                : 'Not connected to any device',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 32),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: () => _handleTestButton(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.science, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Test',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: () => _handleReportsButton(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Reports',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            Consumer<ReadingsProvider>(
              builder: (context, readingsProvider, _) {
                if (readingsProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (readingsProvider.latestReading == null) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.sensors_off, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No readings available',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                            Text(
                              'Press "Test" to fetch a new reading',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final latest = readingsProvider.latestReading!;
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Latest Reading',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildReadingWidget(
                                'Temperature',
                                '${latest.temperature.toStringAsFixed(1)}°C',
                                Icons.thermostat,
                                Colors.orange,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildReadingWidget(
                                'Moisture',
                                '${latest.moisture.toStringAsFixed(1)}%',
                                Icons.water_drop,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Recorded: ${_formatDateTime(latest.timestamp)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Spacer(),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('View History'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingWidget(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTestButton() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    final readingsProvider = Provider.of<ReadingsProvider>(context, listen: false);
    if (!bluetoothProvider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please connect to a device first')),
      );
      return;
    }
    try {
      final reading = await bluetoothProvider.fetchNewReading();
      if (reading != null &&
          reading.containsKey('temperature') &&
          reading.containsKey('moisture')) {
        await readingsProvider.saveReading(
          reading['temperature']!,
          reading['moisture']!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New reading saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid reading data received')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reading: $e')),
      );
    }
  }

  void _handleReportsButton() {
    final readingsProvider = Provider.of<ReadingsProvider>(context, listen: false);
    if (readingsProvider.latestReading == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No readings available. Press "Test" to fetch data.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Latest reading displayed above')),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
