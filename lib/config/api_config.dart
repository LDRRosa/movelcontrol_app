import 'package:flutter/foundation.dart';

/// Configuração de acesso à API MovelControl (Spring Boot, porta 8080).
class ApiConfig {
  /// Permite sobrescrever a URL na execução:
  /// flutter run --dart-define=API_URL=http://192.168.0.10:8080
  static const String _urlDefinida = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_urlDefinida.isNotEmpty) return _urlDefinida;

    // No emulador Android, "localhost" é o próprio emulador;
    // o computador hospedeiro é acessado por 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const Duration timeout = Duration(seconds: 10);
}
