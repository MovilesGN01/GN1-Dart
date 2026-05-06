import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/weather_repository.dart';
import '../../data/models/weather_model.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepository _repository;

  WeatherViewModel(this._repository);

  WeatherData? _weather;
  bool _isLoading = false;
  StreamController<WeatherData>? _weatherController;
  Timer? _refreshTimer;
  static const String _prefKey = 'last_weather_json';

  WeatherData? get weather => _weather;
  bool get isLoading => _isLoading;

  Stream<WeatherData> get weatherStream {
    _weatherController ??= StreamController<WeatherData>.broadcast();
    return _weatherController!.stream;
  }

  Future<void> loadWeather() async {
    _isLoading = true;
    notifyListeners();

    try {
      _weather = await _repository.getCurrentWeather();
      _weatherController?.add(_weather!);
      await _saveWeatherToPrefs(_weather!);
      debugPrint('[Weather] loaded from API: ${_weather!.temperature}°C');
    } catch (e) {
      debugPrint('[Weather] API failed: $e');
      final saved = await _loadWeatherFromPrefs();
      if (saved != null) {
        _weather = saved;
        _weatherController?.add(_weather!);
        debugPrint('[Weather] loaded from SharedPreferences: ${saved.temperature}°C');
      } else {
        debugPrint('[Weather] no saved data, using defaultData');
        _weather = WeatherData.defaultData;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startAutoRefresh({
    Duration interval = const Duration(minutes: 15),
  }) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) {
      debugPrint('[Weather] auto-refresh triggered');
      loadWeather();
    });
    final label = interval.inSeconds >= 60
        ? '${interval.inMinutes}min'
        : '${interval.inSeconds}s';
    debugPrint('[Weather] auto-refresh started, interval=$label');
  }

  Future<void> _saveWeatherToPrefs(WeatherData w) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKey,
        jsonEncode({
          'temperature': w.temperature,
          'description': w.description,
          'willRainSoon': w.willRainSoon,
          'precipitationProbability': w.precipitationProbability,
          'weatherCode': w.weatherCode,
        }),
      );
      debugPrint('[Weather] saving to prefs: ${w.temperature}°C');
    } catch (e) {
      debugPrint('[Weather] failed to save prefs: $e');
    }
  }

  Future<WeatherData?> _loadWeatherFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      debugPrint('[Weather] loaded from SharedPreferences');
      return WeatherData(
        temperature: (map['temperature'] as num).toDouble(),
        description: map['description'] as String,
        willRainSoon: map['willRainSoon'] as bool,
        precipitationProbability:
            (map['precipitationProbability'] as num).toInt(),
        weatherCode: (map['weatherCode'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('[Weather] failed to load prefs: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _weatherController?.close();
    super.dispose();
  }
}
