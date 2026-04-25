import '../models/ride_details_model.dart';
import '../models/ride_model.dart';

abstract class RideRepository {
  Future<List<RideModel>> getAvailableRides();
  Future<List<RideModel>> getMatchingRides(String userId);
  Future<RideDetailsModel> getRideDetails(String rideId);
  Future<void> reserveRide(
    String rideId,
    String userId, {
    String selectedMeetingPoint = '',
    String pickupReference = '',
  });
}
