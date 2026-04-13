import 'package:flutter/material.dart';

import '../models/weather_model.dart';
import '../services/weather_service.dart';

enum WeatherStatus { initial, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  WeatherStatus _status = WeatherStatus.initial;
  WeatherModel? _weather;
  String? _errorMessage;

  WeatherStatus get status => _status;
  WeatherModel? get weather => _weather;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == WeatherStatus.loading;
  bool get hasWeather => _status == WeatherStatus.loaded && _weather != null;

  Future<void> fetchWeather() async {
    if (_status == WeatherStatus.loading) return;

    _status = WeatherStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _weather = await _weatherService.fetchWeather();
      _status = WeatherStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = WeatherStatus.error;
    }

    notifyListeners();
  }
}
