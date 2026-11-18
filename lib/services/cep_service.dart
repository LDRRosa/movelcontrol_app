import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/formatadores.dart';
import 'api_client.dart';

/// Endereço devolvido pelo ViaCEP.
class EnderecoCep {
  final String rua;
  final String bairro;
  final String cidade;
  final String uf;

  const EnderecoCep({
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.uf,
  });

  factory EnderecoCep.fromJson(Map<String, dynamic> json) => EnderecoCep(
        rua: json['logradouro'] ?? '',
        bairro: json['bairro'] ?? '',
        cidade: json['localidade'] ?? '',
        uf: json['uf'] ?? '',
      );
}

/// Consulta a API pública ViaCEP (https://viacep.com.br).
class CepService {
  final http.Client _http;

  CepService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  /// Retorna o endereço, ou null se o CEP não existir.
  Future<EnderecoCep?> buscar(String cep) async {
    final digitos = Formatadores.somenteDigitos(cep);
    if (digitos.length != 8) return null;

    late final http.Response resposta;
    try {
      resposta = await _http
          .get(Uri.parse('https://viacep.com.br/ws/$digitos/json/'))
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      throw ApiException('Sem conexão para consultar o CEP. '
          'Preencha o endereço manualmente.');
    }

    if (resposta.statusCode == 400) return null; // formato inválido
    if (resposta.statusCode != 200) {
      throw ApiException('Não foi possível consultar o CEP agora.');
    }

    final json = jsonDecode(utf8.decode(resposta.bodyBytes));
    // Para CEP inexistente o ViaCEP responde 200 com {"erro": true}.
    if (json is! Map<String, dynamic> || json.containsKey('erro')) return null;
    return EnderecoCep.fromJson(json);
  }
}
