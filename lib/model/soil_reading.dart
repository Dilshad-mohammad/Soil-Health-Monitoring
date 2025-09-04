import 'package:cloud_firestore/cloud_firestore.dart';

class SoilReading {
  String id;
  double temperature;
  double moisture;
  DateTime timestamp;
  String userId;

  SoilReading({
    required this.id,
    required this.temperature,
    required this.moisture,
    required this.timestamp,
    required this.userId,
  });

  // Convert object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'moisture': moisture,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
    };
  }

  // Create object from Firestore data
  factory SoilReading.fromMap(Map<String, dynamic> map, String docId) {
    return SoilReading(
      id: docId,
      temperature: (map['temperature'] ?? 0).toDouble(),
      moisture: (map['moisture'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
    );
  }

  // Dummy data for testing / showcase
  static List<SoilReading> dummyData = [
    SoilReading(
      id: '1',
      temperature: 25.4,
      moisture: 45.2,
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      userId: 'user123',
    ),
    SoilReading(
      id: '2',
      temperature: 26.1,
      moisture: 50.3,
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      userId: 'user123',
    ),
    SoilReading(
      id: '3',
      temperature: 24.7,
      moisture: 42.8,
      timestamp: DateTime.now().subtract(Duration(days: 3)),
      userId: 'user123',
    ),
    SoilReading(
      id: '4',
      temperature: 27.2,
      moisture: 55.0,
      timestamp: DateTime.now().subtract(Duration(days: 4)),
      userId: 'user123',
    ),
    SoilReading(
      id: '5',
      temperature: 23.9,
      moisture: 40.5,
      timestamp: DateTime.now().subtract(Duration(days: 5)),
      userId: 'user123',
    ),
  ];
}
