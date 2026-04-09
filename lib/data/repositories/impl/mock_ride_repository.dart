// MockImplementation — to be replaced with FirebaseRideRepository in next iteration
import '../ride_repository.dart';
import '../../models/ride_model.dart';

class MockRideRepository implements RideRepository {
  final List<RideModel> _rides = [
    RideModel(
      id: 'mock-ride-1',
      driverId: 'driver-1',
      driverName: 'Carlos M.',
      driverRating: 4.9,
      origin: 'Chía',
      destination: 'Universidad de los Andes',
      departureTime: DateTime.now().add(const Duration(minutes: 20)),
      price: 8500,
      seatsAvailable: 3,
      status: 'available',
      zone: 'norte',
    ),
    RideModel(
      id: 'mock-ride-2',
      driverId: 'driver-2',
      driverName: 'Laura G.',
      driverRating: 4.7,
      origin: 'Usaquén',
      destination: 'Universidad de los Andes',
      departureTime: DateTime.now().add(const Duration(minutes: 35)),
      price: 7000,
      seatsAvailable: 2,
      status: 'available',
      zone: 'norte',
    ),
  ];

  @override
  Future<List<RideModel>> getAvailableRides() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_rides);
  }

  @override
  Future<List<RideModel>> getMatchingRides(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_rides);
  }

  @override
  Future<void> reserveRide(String rideId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index != -1 && _rides[index].seatsAvailable > 0) {
      _rides[index] = _rides[index].copyWith(
        seatsAvailable: _rides[index].seatsAvailable - 1,
      );
    }
  }
}
