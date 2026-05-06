import '../../../data/models/ride_model.dart';

extension RideEntityExtension on RideModel {
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_rating': driverRating,
      'driver_gender': gender,
      'origin': origin,
      'destination': destination,
      'zone': zone,
      'departure_time': departureTime.millisecondsSinceEpoch,
      'seats_available': seatsAvailable,
      'status': status,
      'price': price,
      'punctuality_rate': punctualityRate,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static RideModel fromDbMap(Map<String, dynamic> m) {
    final gender = (m['driver_gender'] as String?) ?? 'male';
    return RideModel(
      id: m['id'] as String,
      driverId: m['driver_id'] as String,
      driverName: m['driver_name'] as String,
      driverRating: (m['driver_rating'] as num).toDouble(),
      origin: m['origin'] as String,
      destination: m['destination'] as String,
      departureTime:
          DateTime.fromMillisecondsSinceEpoch(m['departure_time'] as int),
      price: (m['price'] as num).toDouble(),
      seatsAvailable: m['seats_available'] as int,
      status: m['status'] as String,
      zone: (m['zone'] as String?) ?? '',
      gender: gender,
      isFemaleDriver: gender.toLowerCase() == 'female',
      punctualityRate: ((m['punctuality_rate'] as num?)?.toDouble()) ?? 0.0,
      hasRainForecast: false,
    );
  }
}
