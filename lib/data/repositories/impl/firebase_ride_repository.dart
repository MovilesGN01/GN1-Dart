import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../ride_repository.dart';
import '../../models/ride_model.dart';

class FirebaseRideRepository implements RideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<RideModel>> getAvailableRides() async {
    try {
      final snapshot = await _firestore
          .collection('rides')
          .where('status', isEqualTo: 'available')
          .get();

      return snapshot.docs.map((doc) {
        try {
          return RideModel.fromMap(doc.data(), doc.id);
        } catch (e) {
          // ignore: avoid_print
          print('ERROR mapping doc ${doc.id}: $e');
          // ignore: avoid_print
          print('Doc data: ${doc.data()}');
          rethrow;
        }
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('ERROR in getAvailableRides: $e');
      rethrow;
    }
  }

  @override
  Future<List<RideModel>> getMatchingRides(String userId) async {
    // 1. Query available rides
    final snapshot = await _firestore
        .collection('rides')
        .where('status', isEqualTo: 'available')
        .get();

    List<RideModel> rides = snapshot.docs
        .map((doc) => RideModel.fromMap(doc.data(), doc.id))
        .toList();

    // 2. Filter client-side: driverRating >= 4.5
    rides = rides.where((ride) => ride.driverRating >= 4.5).toList();

    // 3. Fetch weather for Bogotá and flag rainy rides
    bool hasRain = false;
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast'
          '?latitude=4.6097&longitude=-74.0817&current_weather=true',
        ),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final currentWeather =
            json['current_weather'] as Map<String, dynamic>;
        final weatherCode = (currentWeather['weathercode'] as num).toInt();
        hasRain = weatherCode >= 61;
      }
    } catch (_) {
      // Weather fetch failure is non-fatal; hasRain stays false
    }

    for (final ride in rides) {
      ride.hasRainForecast = hasRain;
    }

    // 4. Sort: rain rides first, then by driverRating descending
    rides.sort((a, b) {
      if (a.hasRainForecast != b.hasRainForecast) {
        return a.hasRainForecast ? -1 : 1;
      }
      return b.driverRating.compareTo(a.driverRating);
    });

    return rides;
  }

  @override
  Future<void> reserveRide(String rideId, String userId) async {
    final rideRef = _firestore.collection('rides').doc(rideId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);
      if (!snapshot.exists) {
        throw Exception('Ride not found.');
      }

      final seats = (snapshot.data()!['seatsAvailable'] as num?)?.toInt() ?? 0;
      if (seats <= 0) {
        throw Exception('No seats available.');
      }

      transaction.update(rideRef, {
        'seatsAvailable': FieldValue.increment(-1),
      });

      final passengerRef = rideRef.collection('passengers').doc();
      transaction.set(passengerRef, {
        'userId': userId,
        'reservedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
