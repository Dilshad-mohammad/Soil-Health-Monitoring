import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../model/soil_reading.dart';
import '../providers/reading_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reading History'),
      ),
      body: Consumer<ReadingsProvider>(
        builder: (context, readingsProvider, _) {
          if (readingsProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (readingsProvider.readings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No historical data available'),
                  Text('Start taking readings to see history'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trends', style: Theme.of(context).textTheme.headlineSmall),
                        SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: _buildChart(readingsProvider.readings),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegendItem('Temperature', Colors.orange),
                            _buildLegendItem('Moisture', Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All Readings', style: Theme.of(context).textTheme.headlineSmall),
                        SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: readingsProvider.readings.length,
                          separatorBuilder: (context, index) => Divider(),
                          itemBuilder: (context, index) {
                            final reading = readingsProvider.readings[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(Icons.eco, color: Colors.green.shade600),
                              ),
                              title: Text(
                                '${reading.temperature.toStringAsFixed(1)}°C | ${reading.moisture.toStringAsFixed(1)}%',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(_formatDateTime(reading.timestamp)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(List<SoilReading> readings) {
    if (readings.isEmpty) {
      return Center(child: Text('No data to display'));
    }

    List<SoilReading> chartData = readings.reversed.take(20).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: 10, verticalInterval: 1),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: TextStyle(fontSize: 10));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                  final reading = chartData[value.toInt()];
                  return Text(
                    '${reading.timestamp.hour}:${reading.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 10),
                  );
                }
                return Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: chartData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.temperature);
            }).toList(),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(radius: 4, color: Colors.blue, strokeWidth: 2, strokeColor: Colors.white);
            }),
            belowBarData: BarAreaData(show: true, color: Colors.orange.withValues(alpha: 0.1)),
          ),
          LineChartBarData(
            spots: chartData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.moisture);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(radius: 4, color: Colors.blue, strokeWidth: 2, strokeColor: Colors.white);
            }),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String label = spot.barIndex == 0 ? 'Temp' : 'Moisture';
                String unit = spot.barIndex == 0 ? '°C' : '%';
                Color color = spot.barIndex == 0 ? Colors.orange : Colors.blue;
                return LineTooltipItem(
                  '$label: ${spot.y.toStringAsFixed(1)}$unit',
                  TextStyle(color: color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
