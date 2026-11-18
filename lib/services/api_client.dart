import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Erro amigável vindo da API (ou da falta de conexão com ela).
class ApiException implements Exception {
  final String mensagem;
  final int? statusCode;

  ApiException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}

/// Cliente HTTP base: monta a URL, envia JSON, decodifica a resposta
/// e converte erros HTTP em [ApiException]. Não guarda estado.
class ApiClient {
  final http.Client _http;

  /// URL fixa para este cliente (ex.: testar uma URL antes de salvá-la).
  /// Sem ela, usa ApiConfig.baseUrl no momento de cada requisição.
  final String? _urlFixa;

  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _urlFixa = baseUrl;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  String get _base => _urlFixa ?? ApiConfig.baseUrl;

  Uri _uri(String caminho) => Uri.parse('$_base$caminho');

  Future<dynamic> get(String caminho) =>
      _enviar(() => _http.get(_uri(caminho), headers: _headers));

  Future<dynamic> post(String caminho, Map<String, dynamic> corpo) =>
      _enviar(() => _http.post(_uri(caminho),
          headers: _headers, body: jsonEncode(corpo)));

  Future<dynamic> put(String caminho, Map<String, dynamic> corpo) =>
      _enviar(() =>
          _http.put(_uri(caminho), headers: _headers, body: jsonEncode(corpo)));

  Future<void> delete(String caminho) =>
      _enviar(() => _http.delete(_uri(caminho), headers: _headers));

  Future<dynamic> _enviar(Future<http.Response> Function() requisicao) async {
    late final http.Response response;
    try {
      response = await requisicao().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException('Tempo esgotado ao acessar a API em $_base.');
    } catch (_) {
      throw ApiException('Não foi possível conectar à API em '
          '$_base. Verifique se o servidor está rodando.');
    }

    // bodyBytes + utf8 garante acentuação correta.
    final corpo = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (corpo.trim().isEmpty) return null;
      return jsonDecode(corpo);
    }

    throw ApiException(
      _mensagemDeErro(corpo, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  /// A API devolve ErrorResponseDTO ({status, error, message}) na maioria dos
  /// erros, mas em alguns casos devolve só um texto simples.
  String _mensagemDeErro(String corpo, int status) {
    try {
      final json = jsonDecode(corpo);
      if (json is Map && json['message'] is String) {
        final msg = (json['message'] as String).trim();
        if (msg.isNotEmpty) return msg;
      }
    } catch (_) {
      final texto = corpo.trim();
      if (texto.isNotEmpty && texto.length <= 200 && !texto.startsWith('<')) {
        return texto;
      }
    }

    switch (status) {
      case 400:
        return 'Dados inválidos enviados para a API.';
      case 404:
        return 'Registro não encontrado.';
      case 409:
        return 'Registro já cadastrado.';
      default:
        return 'Erro no servidor (HTTP $status).';
    }
  }
}
