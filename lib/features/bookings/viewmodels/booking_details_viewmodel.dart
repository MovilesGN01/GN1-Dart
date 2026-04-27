import 'package:flutter/material.dart';

import '../data/booking_repository.dart';
import '../models/booking_model.dart';

class BookingDetailsViewModel extends ChangeNotifier {
  BookingDetailsViewModel(this._repository);

  final BookingRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  BookingModel? _booking;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BookingModel? get booking => _booking;

  Future<void> load(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _booking = await _repository.getBookingById(bookingId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}