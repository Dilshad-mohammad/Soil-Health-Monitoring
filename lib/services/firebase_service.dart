import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/soil_reading.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'soil_readings';

  Future<void> saveReading(SoilReading reading) async {
    await _firestore.collection(_collection).doc(reading.id).set(reading.toMap());
  }

  Stream<List<SoilReading>> getReadingsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SoilReading.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<List<SoilReading>> getReadingsByDateRange(DateTime start, DateTime end) async {
    QuerySnapshot snapshot = await _firestore
        .collection(_collection)
        .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return SoilReading.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
}
