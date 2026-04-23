import 'dart:convert';

import 'package:http/http.dart' as http;

import '../weather_repository.dart';
import '../../models/weather_model.dart';

class OpenMeteoRepository implements WeatherRepository {
  static const _url =
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=4.6097&longitude=-74.0817'
      '&hourly=precipitation_probability,temperature_2m,weathercode'
      '&forecast_hours=1'
      '&timezone=America%2FBogota'
      '&current_weather=true';

  @override
  Future<WeatherData> getCurrentWeather() async {
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode != 200) return WeatherData.defaultData;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final currentWeather = json['current_weather'] as Map<String, dynamic>;
      final hourly = json['hourly'] as Map<String, dynamic>;

      final temperature =
          (currentWeather['temperature'] as num).toDouble();
      final weatherCode =
          (currentWeather['weathercode'] as num).toInt();

      // Fix 1 — Null-safe precipitation parsing
      final rawList = (hourly['precipitation_probability'] as List?) ?? [];
      final precipList =
          rawList.map((v) => v == null ? 0 : (v as num).toInt()).toList();

      // Precipitation probability for the next hour only
      final maxPrecip = precipList.isEmpty ? 0 : precipList.first;

      return WeatherData(
        temperature: temperature,
        description: _descriptionFromCode(weatherCode),
        precipitationProbability: maxPrecip,
        willRainSoon: maxPrecip >= 10,
        weatherCode: weatherCode,
      );
    } catch (_) {
      return WeatherData.defaultData;
    }
  }

  static String _descriptionFromCode(int code) {
    if (code == 0) return 'Sunny';
    if (code <= 3) return 'Partly Cloudy';
    if (code == 45 || code == 48) return 'Foggy';
    if (code == 51 || code == 53 || code == 55 ||
        code == 61 || code == 63 || code == 65) return 'Rainy';
    if (code == 71 || code == 73 || code == 75) return 'Snowy';
    if (code == 80 || code == 81 || code == 82) return 'Showers';
    if (code == 95 || code == 96 || code == 99) return 'Stormy';
    return 'Cloudy';
  }
}
