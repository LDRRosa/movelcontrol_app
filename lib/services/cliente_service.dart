import '../models/cliente.dart';
import 'api_client.dart';

/// Encapsula os endpoints /pf (Pessoa Física) da API.
class ClienteService {
  final ApiClient _api;

  ClienteService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<Cliente>> listar() async {
    try {
      final dados = await _api.get('/pf/listar');
      if (dados is! List) return [];
      return dados
          .whereType<Map<String, dynamic>>()
          .map((json) => Cliente.fromJson(json, id: extrairId(json)))
          .toList();
    } on ApiException catch (e) {
      // A API responde 404 quando não existe nenhuma pessoa física.
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<void> criar(Cliente cliente) =>
      _api.post('/pf/criar', cliente.toJson());

  Future<void> atualizar(Cliente cliente) =>
      _api.put('/pf/atualizar/${cliente.id}', cliente.toJson());

  Future<void> excluir(int id) => _api.delete('/pf/deletar/$id');

  /// O PessoaFisicaResponseDTO não tem o campo "id", mas cada registro
  /// listado traz um link para /pf/{id}. Aceita os dois formatos de links:
  /// "links": [{"rel": ..., "href": ...}] e "_links": {"rel": {"href": ...}}.
  static int? extrairId(Map<String, dynamic> json) {
    if (json['id'] is num) return (json['id'] as num).toInt();

    final hrefs = <String>[];
    void coletar(dynamic link) {
      if (link is Map && link['href'] is String) hrefs.add(link['href']);
      if (link is List) link.forEach(coletar);
    }

    coletar(json['links']);
    if (json['_links'] is Map) {
      (json['_links'] as Map).values.forEach(coletar);
    }

    final regex = RegExp(r'/pf/(\d+)/?$');
    for (final href in hrefs) {
      final match = regex.firstMatch(href);
      if (match != null) return int.parse(match.group(1)!);
    }
    return null;
  }
}
