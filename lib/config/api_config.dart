import 'package:flutter/foundation.dart';

/// Configuração de acesso à API MovelControl (Spring Boot, porta 8080).
class ApiConfig {
  /// Permite sobrescrever a URL na execução:
  /// flutter run --dart-define=API_URL=http://192.168.0.10:8080
  static const String _urlDefinida = String.fromEnvironment('API_URL');

  /// URL escolhida na tela de Configurações (salva com shared_preferences).
  static String? _urlPersonalizada;

  /// URL usada quando o usuário não configurou nenhuma.
  static String get urlPadrao {
    if (_urlDefinida.isNotEmpty) return _urlDefinida;

    // No emulador Android, "localhost" é o próprio emulador;
    // o computador hospedeiro é acessado por 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static String get baseUrl => _urlPersonalizada ?? urlPadrao;

  static bool get usandoUrlPersonalizada => _urlPersonalizada != null;

  /// Define (ou remove, com null/vazio) a URL personalizada.
  static void definirUrl(String? url) {
    final texto = url?.trim() ?? '';
    _urlPersonalizada =
        texto.isEmpty ? null : texto.replaceAll(RegExp(r'/+$'), '');
  }

  static const Duration timeout = Duration(seconds: 10);
}
