import '../models/weather_model.dart';

abstract class WeatherRepository {
  Future<WeatherData> getCurrentWeather();
}
