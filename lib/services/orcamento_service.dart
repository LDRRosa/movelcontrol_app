import '../models/orcamento.dart';
import 'api_client.dart';

/// Encapsula os endpoints /orcamentos da API.
class OrcamentoService {
  final ApiClient _api;

  OrcamentoService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<Orcamento>> listar() async {
    final dados = await _api.get('/orcamentos');
    if (dados is! List) return [];
    return dados
        .whereType<Map<String, dynamic>>()
        .map(Orcamento.fromJson)
        .toList();
  }

  Future<Orcamento> criar(Orcamento orcamento) async {
    final dados = await _api.post('/orcamentos', orcamento.toJson());
    return Orcamento.fromJson(dados);
  }

  Future<Orcamento> atualizar(Orcamento orcamento) async {
    final dados =
        await _api.put('/orcamentos/${orcamento.id}', orcamento.toJson());
    return Orcamento.fromJson(dados);
  }

  Future<void> excluir(int id) => _api.delete('/orcamentos/$id');
}
