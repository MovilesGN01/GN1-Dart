import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../models/ride_model.dart';

// Must be top-level — Isolate.run cannot use instance methods or closures.
class _RankingInput {
  final List<RideModel> rides;
  final double minRating;
  final bool femaleOnly;
  final int minSeats;

  const _RankingInput({
    required this.rides,
    this.minRating = 0,
    this.femaleOnly = false,
    this.minSeats = 1,
  });
}

List<RideModel> _rankAndFilterIsolate(_RankingInput input) {
  double score(RideModel r) =>
      (r.driverRating * 0.5) +
      (r.punctualityRate * 0.3) +
      (r.seatsAvailable * 0.2);

  return input.rides
      .where((r) => r.driverRating >= input.minRating)
      .where((r) => !input.femaleOnly || r.gender == 'female')
      .where((r) => r.seatsAvailable >= input.minSeats)
      .toList()
    ..sort((a, b) => score(b).compareTo(score(a)));
}

class RideRankingService {
  static const int _threshold = 20;

  Future<List<RideModel>> rankAndFilter({
    required List<RideModel> rides,
    double minRating = 0,
    bool femaleOnly = false,
    int minSeats = 1,
  }) async {
    final input = _RankingInput(
      rides: rides,
      minRating: minRating,
      femaleOnly: femaleOnly,
      minSeats: minSeats,
    );

    if (rides.length < _threshold) {
      debugPrint('[Ranking] sync path for ${rides.length} rides');
      return _rankAndFilterIsolate(input);
    }

    debugPrint('[Ranking] using isolate for ${rides.length} rides');
    return Isolate.run(() => _rankAndFilterIsolate(input));
  }
}
