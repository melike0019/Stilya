class WeatherModel {
  final String cityName;
  final double temperature; // Celsius
  final String condition; // OpenWeatherMap ana kodu (Clear, Rain, Clouds…)
  final String conditionTr; // Türkçe açıklama
  final int humidity; // %
  final double windSpeed; // m/s

  const WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.conditionTr,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final main = json['weather'][0]['main'] as String? ?? 'Clear';
    return WeatherModel(
      cityName: json['name'] as String? ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: main,
      conditionTr: _conditionsTr[main] ?? main,
      humidity: (json['main']['humidity'] as num).toInt(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),
    );
  }

  String get temperatureStr => '${temperature.round()}°C';

  /// Hava durumunu kombine yönlendirme için İngilizce kısa açıklama.
  String get conditionForPrompt =>
      '$conditionTr, $temperatureStr, nem %$humidity';

  static const Map<String, String> _conditionsTr = {
    'Clear': 'Açık ve Güneşli',
    'Clouds': 'Bulutlu',
    'Rain': 'Yağmurlu',
    'Drizzle': 'Hafif Yağmurlu',
    'Thunderstorm': 'Fırtınalı',
    'Snow': 'Karlı',
    'Mist': 'Sisli',
    'Smoke': 'Dumanlı',
    'Haze': 'Puslu',
    'Fog': 'Yoğun Sisli',
    'Sand': 'Kumlu',
    'Tornado': 'Kasırgalı',
  };
}
