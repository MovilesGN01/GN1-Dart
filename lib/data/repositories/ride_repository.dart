import '../models/ride_model.dart';

abstract class RideRepository {
  Future<List<RideModel>> getAvailableRides();

  /// Returns rides matching the user's saved route and preferred departure time,
  /// with weather data applied (hasRainForecast flag).
  Future<List<RideModel>> getMatchingRides(String userId);

  Future<void> reserveRide(String rideId, String userId);
}
