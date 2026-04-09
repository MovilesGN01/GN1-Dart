import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import '../../models/ride_details_model.dart';
import '../../models/ride_model.dart';
import '../ride_repository.dart';

class FirebaseRideRepository implements RideRepository {
  FirebaseRideRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
        _httpClient = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final http.Client _httpClient;

  @override
  Future<List<RideModel>> getAvailableRides() async {
    final snapshot = await _firestore
        .collection('rides')
        .where('status', isEqualTo: 'available')
        .get();

    final rides = snapshot.docs
        .map((doc) => RideModel.fromMap(doc.data(), doc.id))
        .toList();

    rides.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return rides;
  }

  @override
  Future<List<RideModel>> getMatchingRides(String userId) async {
    final snapshot = await _firestore
        .collection('rides')
        .where('status', isEqualTo: 'available')
        .get();

    List<RideModel> rides = snapshot.docs
        .map((doc) => RideModel.fromMap(doc.data(), doc.id))
        .toList();

    rides = rides.where((ride) => ride.driverRating >= 4.5).toList();

    bool hasRain = false;

    try {
      final response = await _httpClient.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast'
          '?latitude=4.6097&longitude=-74.0817&current_weather=true',
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final currentWeather =
            json['current_weather'] as Map<String, dynamic>? ?? {};
        final weatherCode = (currentWeather['weathercode'] as num?)?.toInt();

        const rainyCodes = {
          51, 53, 55,
          61, 63, 65,
          66, 67,
          80, 81, 82,
          95, 96, 99,
        };

        hasRain = weatherCode != null && rainyCodes.contains(weatherCode);
      }
    } catch (_) {
      hasRain = false;
    }

    for (final ride in rides) {
      ride.hasRainForecast = hasRain;
    }

    rides.sort((a, b) {
      final ratingCompare = b.driverRating.compareTo(a.driverRating);
      if (ratingCompare != 0) return ratingCompare;
      return a.departureTime.compareTo(b.departureTime);
    });

    return rides;
  }

  @override
  Future<RideDetailsModel> getRideDetails(String rideId) async {
    try {
      final callable = _functions.httpsCallable(
        'getRideDetails',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 15),
        ),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'rideId': rideId,
      });

      final rawData = result.data;
      return RideDetailsModel.fromMap(
        Map<String, dynamic>.from(rawData),
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_mapFunctionsError(e));
    } catch (_) {
      throw Exception('No se pudieron cargar los detalles del ride.');
    }
  }

  @override
  Future<void> reserveRide(String rideId, String userId) async {
    try {
      final callable = _functions.httpsCallable(
        'reserveRide',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 15),
        ),
      );

      await callable.call<Map<String, dynamic>>({
        'rideId': rideId,
        'userId': userId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_mapFunctionsError(e));
    } catch (_) {
      throw Exception('No se pudo reservar el ride.');
    }
  }

  String _mapFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Debes iniciar sesión para continuar.';
      case 'invalid-argument':
        return 'La solicitud no es válida.';
      case 'not-found':
        return 'No se encontró el ride solicitado.';
      case 'already-exists':
        return 'Ya reservaste este ride.';
      case 'failed-precondition':
        return 'Ya no hay cupos disponibles.';
      case 'deadline-exceeded':
        return 'La operación tardó demasiado. Intenta de nuevo.';
      case 'unavailable':
        return 'El servicio no está disponible en este momento.';
      default:
        return e.message ?? 'Ocurrió un error inesperado.';
    }
  }
}