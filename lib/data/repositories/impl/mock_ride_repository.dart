// MockImplementation — to be replaced with FirebaseRideRepository in next iteration

import 'package:uniride/data/models/ride_model.dart';
import 'package:uniride/data/repositories/ride_repository.dart';

class MockRideRepository implements RideRepository {
  static final List<RideModel> _mockRides = [
    RideModel(
      id: 'ride_001',
      driverName: 'Maria G.',
      origin: 'Chapinero',
      destination: 'Campus',
      departureTime: DateTime(2026, 4, 8, 7, 20),
      price: 12000,
      seatsAvailable: 2,
      reputationScore: 4.8,
      hasRainForecast: false,
      isFemaleDriver: false,
      eta: '18 min',
    ),
    RideModel(
      id: 'ride_002',
      driverName: 'Andrés R.',
      origin: 'Teusaquillo',
      destination: 'Campus',
      departureTime: DateTime(2026, 4, 8, 7, 35),
      price: 10000,
      seatsAvailable: 1,
      reputationScore: 4.6,
      hasRainForecast: false,
      isFemaleDriver: false,
      eta: '25 min',
    ),
    RideModel(
      id: 'ride_003',
      driverName: 'Camila P.',
      origin: 'Salitre',
      destination: 'Campus',
      departureTime: DateTime(2026, 4, 8, 7, 50),
      price: 14000,
      seatsAvailable: 3,
      reputationScore: 4.9,
      hasRainForecast: false,
      isFemaleDriver: true,
      eta: '30 min',
    ),
  ];

  @override
  Future<List<RideModel>> getAvailableRides() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_mockRides);
  }

  @override
  Future<List<RideModel>> getMatchingRides(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockRides
        .where((ride) => ride.reputationScore >= 4.5)
        .toList();
  }

  @override
  Future<void> reserveRide(String rideId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
