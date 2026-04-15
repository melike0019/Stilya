/// Bu dosyayı `api_config.dart` adıyla kopyala ve anahtarları doldur.
/// Komut: cp lib/core/api_config.example.dart lib/core/api_config.dart
///
/// api_config.dart dosyası .gitignore'a eklenmiştir — GitHub'a gönderilmez.
///
/// OpenWeatherMap (ücretsiz): https://openweathermap.org/api
/// Groq (ücretsiz, kart gerekmez): https://console.groq.com
class ApiConfig {
  // Hava durumu — OpenWeatherMap
  static const String weatherApiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  // Yapay zeka — Groq (ücretsiz, OpenAI uyumlu)
  static const String groqApiKey = 'YOUR_GROQ_API_KEY';
  static const String groqModel   = 'llama-3.3-70b-versatile';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
}
