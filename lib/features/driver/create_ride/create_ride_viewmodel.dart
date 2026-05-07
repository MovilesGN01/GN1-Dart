import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/connectivity/sync_manager.dart';
import '../../../core/location_utils.dart';
import '../../../core/utils/geocoding_service.dart';

class CreateRideViewModel extends ChangeNotifier {
  String origin = '';
  String destination = '';
  DateTime? departureTime;
  int seats = 1;
  double price = 8000;
  bool isLoading = false;
  String? errorMessage;
  bool isOffline = false;

  double? originLat;
  double? originLng;
  double? destinationLat;
  double? destinationLng;

  List<PlaceSuggestion> originSuggestions = [];
  List<PlaceSuggestion> destinationSuggestions = [];
  bool isSearchingOrigin = false;
  bool isSearchingDestination = false;

  StreamSubscription<bool>? _connSub;
  Timer? _originDebounce;
  Timer? _destinationDebounce;

  CreateRideViewModel() {
    _connSub = ConnectivityService().onStatusChanged.listen((online) {
      isOffline = !online;
      notifyListeners();
    });
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void searchOrigin(String query) {
    _originDebounce?.cancel();
    if (query.trim().length < 3) {
      originSuggestions = [];
      isSearchingOrigin = false;
      notifyListeners();
      return;
    }
    isSearchingOrigin = true;
    notifyListeners();
    _originDebounce = Timer(const Duration(milliseconds: 400), () async {
      originSuggestions = await GeocodingService.searchPlaces(query);
      isSearchingOrigin = false;
      notifyListeners();
    });
  }

  void searchDestination(String query) {
    _destinationDebounce?.cancel();
    if (query.trim().length < 3) {
      destinationSuggestions = [];
      isSearchingDestination = false;
      notifyListeners();
      return;
    }
    isSearchingDestination = true;
    notifyListeners();
    _destinationDebounce = Timer(const Duration(milliseconds: 400), () async {
      destinationSuggestions = await GeocodingService.searchPlaces(query);
      isSearchingDestination = false;
      notifyListeners();
    });
  }

  void selectOrigin(PlaceSuggestion place) {
    origin = place.displayName;
    originLat = place.lat;
    originLng = place.lon;
    originSuggestions = [];
    notifyListeners();
  }

  void selectDestination(PlaceSuggestion place) {
    destination = place.displayName;
    destinationLat = place.lat;
    destinationLng = place.lon;
    destinationSuggestions = [];
    notifyListeners();
  }

  // ── Stepper helpers ───────────────────────────────────────────────────────

  void setDepartureTime(DateTime value) {
    departureTime = value;
    notifyListeners();
  }

  void incrementSeats() {
    if (seats < 6) {
      seats++;
      notifyListeners();
    }
  }

  void decrementSeats() {
    if (seats > 1) {
      seats--;
      notifyListeners();
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? validateForm() {
    if (origin.trim().isEmpty) return 'Origin is required';
    if (originLat == null) {
      return 'Select a valid origin from the suggestions';
    }
    if (destination.trim().isEmpty) return 'Destination is required';
    if (destinationLat == null) {
      return 'Select a valid destination from the suggestions';
    }
    if (departureTime == null) return 'Departure time is required';
    if (departureTime!.isBefore(DateTime.now())) {
      return 'Departure time must be in the future';
    }
    if (seats < 1 || seats > 6) return 'Seats must be between 1 and 6';
    if (price < 1000) return 'Price must be at least \$1,000';
    return null;
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<void> createRide(
    BuildContext context,
    String userId,
    String driverName,
    double driverRating,
  ) async {
    final error = validateForm();
    if (error != null) {
      errorMessage = error;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final zone =
          LocationUtils.zoneFromLatLon(originLat!, originLng!) ?? 'Bogotá';

      final payload = {
        'origin': origin.trim(),
        'destination': destination.trim(),
        'originLat': originLat,
        'originLng': originLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'zone': zone,
        'driverId': userId,
        'driverName': driverName,
        'driverRating': driverRating,
        'seatsAvailable': seats,
        'price': price,
        'departureTime': departureTime!.millisecondsSinceEpoch,
      };

      debugPrint('[CreateRide] payload: $payload');

      if (isOffline) {
        await SyncManager().enqueue('create_ride', jsonEncode(payload));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Ride saved offline — will publish when you reconnect'),
            ),
          );
          context.go('/driver/my-rides');
        }
        return;
      }

      final cf = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('createRide');
      final result = await cf.call(payload);
      debugPrint('[CreateRide] CF result: ${result.data}');

      if (context.mounted) {
        context.go('/driver/my-rides');
      }
    } catch (e) {
      debugPrint('[CreateRide] CF error details: ${e.runtimeType}: $e');
      errorMessage = 'Failed to create ride. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _originDebounce?.cancel();
    _destinationDebounce?.cancel();
    super.dispose();
  }
}
