/// Bu dosyayı `api_config.dart` adıyla kopyala ve anahtarları doldur.
/// Komut: cp lib/core/api_config.example.dart lib/core/api_config.dart
///
/// api_config.dart dosyası .gitignore'a eklenmiştir — GitHub'a gönderilmez.
///
/// OpenWeatherMap (ücretsiz): https://openweathermap.org/api
/// Google Gemini (ücretsiz):  https://aistudio.google.com/app/apikey
class ApiConfig {
  static const String weatherApiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String geminiModel = 'gemini-1.5-flash';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
}
