import 'package:flutter/foundation.dart';

import '../../data/repositories/weather_repository.dart';
import '../../data/models/weather_model.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepository _repository;

  WeatherViewModel(this._repository);

  WeatherData? _weather;
  bool _isLoading = false;

  WeatherData? get weather => _weather;
  bool get isLoading => _isLoading;

  Future<void> loadWeather() async {
    _isLoading = true;
    notifyListeners();

    _weather = await _repository.getCurrentWeather();

    _isLoading = false;
    notifyListeners();
  }
}
