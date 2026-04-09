import 'package:uniride/data/models/ride_model.dart';

abstract class RideRepository {
  Future<List<RideModel>> getAvailableRides();
  Future<List<RideModel>> getMatchingRides(String userId);
  Future<void> reserveRide(String rideId, String userId);
}
