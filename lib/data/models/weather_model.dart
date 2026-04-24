class WeatherData {
  final double temperature;
  final String description;
  final int precipitationProbability;
  final bool willRainSoon;
  final int weatherCode;

  const WeatherData({
    required this.temperature,
    required this.description,
    required this.precipitationProbability,
    required this.willRainSoon,
    required this.weatherCode,
  });

  static const defaultData = WeatherData(
    temperature: 20.0,
    description: 'Sunny',
    precipitationProbability: 0,
    willRainSoon: false,
    weatherCode: 0,
  );
}
