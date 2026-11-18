import '../models/fornecedor.dart';
import '../models/pedido_fornecedor.dart';
import 'api_client.dart';

/// Encapsula os endpoints /fornecedor da API.
class FornecedorService {
  final ApiClient _api;

  FornecedorService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<Fornecedor>> listar() async {
    final dados = await _api.get('/fornecedor/buscartudo');
    return extrairLista(dados).map(Fornecedor.fromJson).toList();
  }

  Future<Fornecedor> criar(Fornecedor fornecedor) async {
    final dados = await _api.post('/fornecedor/criar', fornecedor.toJson());
    return Fornecedor.fromJson(dados);
  }

  Future<Fornecedor> atualizar(Fornecedor fornecedor) async {
    final dados = await _api.put(
        '/fornecedor/atualizar/${fornecedor.id}', fornecedor.toJson());
    return Fornecedor.fromJson(dados);
  }

  Future<void> excluir(int id) => _api.delete('/fornecedor/deletar/$id');

  /// Pedidos de compra feitos ao fornecedor (lista vazia se não houver).
  Future<List<PedidoFornecedor>> listarPedidos(int fornecedorId) async {
    final dados = await _api.get('/pFornecedor/buscar/fornecedor/$fornecedorId');
    if (dados is! List) return [];
    return dados
        .whereType<Map<String, dynamic>>()
        .map(PedidoFornecedor.fromJson)
        .toList();
  }

  /// /fornecedor/buscartudo devolve uma coleção HATEOAS no formato HAL:
  /// { "_embedded": { "fornecedorResponseDTOList": [ ... ] } }.
  /// Quando não há fornecedores, o "_embedded" não vem.
  static List<Map<String, dynamic>> extrairLista(dynamic dados) {
    if (dados is List) return dados.whereType<Map<String, dynamic>>().toList();
    if (dados is Map && dados['_embedded'] is Map) {
      for (final valor in (dados['_embedded'] as Map).values) {
        if (valor is List) {
          return valor.whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    if (dados is Map && dados['content'] is List) {
      return (dados['content'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return [];
  }
}
