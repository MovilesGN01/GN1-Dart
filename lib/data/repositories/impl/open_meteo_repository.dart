import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../weather_repository.dart';
import '../../models/weather_model.dart';

class OpenMeteoRepository implements WeatherRepository {
  static const _url =
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=4.6097&longitude=-74.0817'
      '&hourly=precipitation_probability,temperature_2m,weathercode'
      '&forecast_hours=24'
      '&timezone=America%2FBogota'
      '&current_weather=true';

  @override
  Future<WeatherData> getCurrentWeather() async {
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode != 200) {
      throw Exception('Weather API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final currentWeather = json['current_weather'] as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;

    final temperature = (currentWeather['temperature'] as num).toDouble();
    final weatherCode = (currentWeather['weathercode'] as num).toInt();

    final times = (hourly['time'] as List?)?.map((t) => t.toString()).toList() ?? [];
    final rawList = (hourly['precipitation_probability'] as List?) ?? [];
    final precipList = rawList.map((v) => v == null ? 0.0 : (v as num).toDouble()).toList();

    // Use the API's own current_weather.time to find the current hour index.
    // This is timezone-safe: both strings come from the same API in Bogotá time.
    final currentTimeStr = (currentWeather['time'] as String?) ?? '';
    int currentIdx = 0;
    for (int i = 0; i < times.length; i++) {
      if (times[i] == currentTimeStr) {
        currentIdx = i;
        break;
      }
    }
    debugPrint('[Weather] currentTimeStr=$currentTimeStr currentIdx=$currentIdx');

    // Max precipitation probability for the rest of today from the current hour.
    // For a carpooling app the relevant question is "will it rain TODAY?" —
    // not just the next few hours. A 2 PM rain matters even if it is 3 AM.
    double maxPrecip = 0;
    for (int i = currentIdx; i < precipList.length; i++) {
      final entryDate = i < times.length ? times[i].substring(0, 10) : '';
      final todayDate = currentTimeStr.substring(0, 10);
      if (entryDate != todayDate) break; // stop at midnight
      if (precipList[i] > maxPrecip) maxPrecip = precipList[i];
    }
    debugPrint('[Weather] maxPrecipToday=$maxPrecip%');

    return WeatherData(
      temperature: temperature,
      description: _descriptionFromCode(weatherCode),
      precipitationProbability: maxPrecip.toInt(),
      willRainSoon: maxPrecip >= 40,
      weatherCode: weatherCode,
    );
  }

  void fetchCurrentWithCallback({
    required void Function(WeatherData) onSuccess,
    required void Function(Object) onError,
  }) {
    getCurrentWeather().then(onSuccess).catchError(onError);
  }

  static String _descriptionFromCode(int code) {
    if (code == 0) { return 'Sunny'; }
    if (code <= 3) { return 'Partly Cloudy'; }
    if (code == 45 || code == 48) { return 'Foggy'; }
    if (code == 51 || code == 53 || code == 55 ||
        code == 61 || code == 63 || code == 65) { return 'Rainy'; }
    if (code == 71 || code == 73 || code == 75) { return 'Snowy'; }
    if (code == 80 || code == 81 || code == 82) { return 'Showers'; }
    if (code == 95 || code == 96 || code == 99) { return 'Stormy'; }
    return 'Cloudy';
  }
}
