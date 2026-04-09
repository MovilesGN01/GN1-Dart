import '../../models/ride_details_model.dart';
@override
Future<RideDetailsModel> getRideDetails(String rideId) async {
  return RideDetailsModel(
    id: rideId,
    driverId: 'mock-driver',
    driverName: 'Maria G.',
    driverRating: 4.8,
    driverPhotoUrl: '',
    origin: 'Chapinero',
    destination: 'Campus',
    departureTime: DateTime.now().add(const Duration(minutes: 20)),
    estimatedDurationMinutes: 18,
    price: 12000,
    seatsAvailable: 2,
    status: 'available',
    zone: 'Chapinero',
    pickupAddress: 'Cra. 13 #57-39',
    pickupReference: 'Frente a la portería',
    vehicleBrand: 'Mazda',
    vehicleModel: '2',
    vehicleColor: 'Gris plata',
    vehiclePlate: 'KQW219',
    amenities: ['AC', 'No smoking'],
    badges: ['HIGH RELIABILITY'],
    notes: 'Salgo puntual.',
    isFemaleDriver: false,
    isReservedByCurrentUser: false,
  );
}

@override
Future<void> reserveRide(String rideId) async {
  await Future.delayed(const Duration(milliseconds: 500));
}