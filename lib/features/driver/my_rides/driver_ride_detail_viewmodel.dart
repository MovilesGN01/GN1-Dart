import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../data/models/ride_model.dart';
import '../../../data/repositories/impl/firebase_ride_repository.dart';

class DriverRideDetailViewModel extends ChangeNotifier {
  DriverRideDetailViewModel(RideModel ride, this._repository)
      : _ride = ride {
    _originCtrl = TextEditingController(text: ride.origin);
    _destCtrl = TextEditingController(text: ride.destination);
    _priceCtrl = TextEditingController(text: ride.price.toInt().toString());
    _editTime = ride.departureTime;
    _editSeats = ride.seatsAvailable;
  }

  RideModel _ride;
  final FirebaseRideRepository _repository;

  late final TextEditingController _originCtrl;
  late final TextEditingController _destCtrl;
  late final TextEditingController _priceCtrl;
  late DateTime _editTime;
  late int _editSeats;

  bool isEditing = false;
  bool isLoading = false;
  String? errorMessage;

  RideModel get ride => _ride;
  TextEditingController get originCtrl => _originCtrl;
  TextEditingController get destCtrl => _destCtrl;
  TextEditingController get priceCtrl => _priceCtrl;
  DateTime get editTime => _editTime;
  int get editSeats => _editSeats;

  bool get canEdit => _ride.status == 'available' || _ride.status == 'active';

  // True only within the 30-min-before to 15-min-after window
  bool get canStart {
    if (!canEdit) return false;
    final now = DateTime.now();
    final windowOpen = _ride.departureTime.subtract(const Duration(minutes: 30));
    final windowClose = _ride.departureTime.add(const Duration(minutes: 15));
    return now.isAfter(windowOpen) && now.isBefore(windowClose);
  }

  // Hint shown when canEdit but canStart is false (too early)
  String? get startRideHint {
    if (!canEdit) return null;
    final now = DateTime.now();
    final windowOpen = _ride.departureTime.subtract(const Duration(minutes: 30));
    if (now.isBefore(windowOpen)) {
      final mins = windowOpen.difference(now).inMinutes + 1;
      return 'Podrás iniciar el viaje en $mins min';
    }
    return null;
  }

  void startEditing() {
    _originCtrl.text = _ride.origin;
    _destCtrl.text = _ride.destination;
    _priceCtrl.text = _ride.price.toInt().toString();
    _editTime = _ride.departureTime;
    _editSeats = _ride.seatsAvailable;
    isEditing = true;
    errorMessage = null;
    notifyListeners();
  }

  void cancelEditing() {
    isEditing = false;
    errorMessage = null;
    notifyListeners();
  }

  void setEditTime(DateTime dt) {
    _editTime = dt;
    notifyListeners();
  }

  void incrementSeats() {
    if (_editSeats < 6) {
      _editSeats++;
      notifyListeners();
    }
  }

  void decrementSeats() {
    if (_editSeats > 1) {
      _editSeats--;
      notifyListeners();
    }
  }

  String? _validate() {
    if (_originCtrl.text.trim().isEmpty) return 'Origin is required';
    if (_destCtrl.text.trim().isEmpty) return 'Destination is required';
    if (_editTime.isBefore(DateTime.now())) {
      return 'Departure time must be in the future';
    }
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', ''));
    if (price == null || price < 1000) {
      return 'Price must be at least \$1,000';
    }
    return null;
  }

  Future<bool> saveChanges() async {
    final err = _validate();
    if (err != null) {
      errorMessage = err;
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final price = double.parse(_priceCtrl.text.replaceAll(',', ''));
      await _repository.updateRide(
        rideId: _ride.id,
        origin: _originCtrl.text.trim(),
        destination: _destCtrl.text.trim(),
        departureTime: _editTime,
        seatsAvailable: _editSeats,
        price: price,
      );
      _ride = _ride.copyWith(
        origin: _originCtrl.text.trim(),
        destination: _destCtrl.text.trim(),
        departureTime: _editTime,
        seatsAvailable: _editSeats,
        price: price,
      );
      isEditing = false;
      return true;
    } catch (e) {
      debugPrint('[RideDetail] updateRide error: $e');
      errorMessage = 'Failed to update ride. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startRide() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await FirebaseFunctions.instance
          .httpsCallable('startRide')
          .call({'rideId': _ride.id});
      _ride = _ride.copyWith(status: 'in_progress');
      return true;
    } catch (e) {
      debugPrint('[RideDetail] startRide error: $e');
      errorMessage = 'Failed to start ride. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRide() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteRide(_ride.id);
      return true;
    } catch (e) {
      debugPrint('[RideDetail] deleteRide error: $e');
      errorMessage = 'Failed to delete ride. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }
}
