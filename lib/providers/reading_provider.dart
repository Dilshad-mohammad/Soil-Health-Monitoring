import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/soil_reading.dart';

class ReadingsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<SoilReading> _readings = [];
  SoilReading? _latestReading;
  bool _isLoading = false;

  List<SoilReading> get readings => _readings;
  SoilReading? get latestReading => _latestReading;
  bool get isLoading => _isLoading;

  Future<void> saveReading(double temperature, double moisture) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final reading = SoilReading(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        temperature: temperature,
        moisture: moisture,
        timestamp: DateTime.now(),
        userId: user.uid,
      );

      await _firestore
          .collection('soil_readings')
          .doc(reading.id)
          .set(reading.toMap());

      _latestReading = reading;
      await loadReadings();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadReadings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('soil_readings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _readings = snapshot.docs.map((doc) {
        return SoilReading.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (_readings.isNotEmpty) {
        _latestReading = _readings.first;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
