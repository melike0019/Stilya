/// Bu dosya şablon/örnek dosyadır — GitHub'a gönderilmesi normaldir.
///
/// KURULUM:
///   1. run_config.sh (Mac/Linux) veya run_config.bat (Windows) dosyasını
///      proje kök dizininde oluştur (bu dosyalar .gitignore'da).
///   2. İçine gerçek anahtarlarını yaz.
///   3. Uygulamayı o betikle çalıştır:
///        bash run_config.sh          (Mac/Linux)
///        run_config.bat              (Windows)
///
/// Alternatif — VS Code launch.json:
///   "toolArgs": [
///     "--dart-define=WEATHER_API_KEY=XXX",
///     "--dart-define=GROQ_API_KEY=XXX"
///   ]
///
/// Anahtar kaynakları (ücretsiz):
///   OpenWeatherMap : https://openweathermap.org/api
///   Groq           : https://console.groq.com
class ApiConfig {
  // Hava durumu — OpenWeatherMap
  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: '',
  );
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  // Yapay zeka — Groq (ücretsiz, OpenAI uyumlu)
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );
  static const String groqModel   = 'llama-3.3-70b-versatile';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
}
