import '../models/item.dart';
import 'api_client.dart';

/// Encapsula os endpoints /item da API.
class ItemService {
  final ApiClient _api;

  ItemService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<Item>> listar() async {
    final dados = await _api.get('/item/todos');
    if (dados is! List) return [];
    return dados
        .whereType<Map<String, dynamic>>()
        .map(Item.fromJson)
        .toList();
  }

  Future<Item> criar(Item item) async {
    final dados = await _api.post('/item/criar', item.toJson());
    return Item.fromJson(dados);
  }

  Future<Item> atualizar(Item item) async {
    final dados = await _api.put('/item/atualizar/${item.id}', item.toJson());
    return Item.fromJson(dados);
  }

  Future<void> excluir(int id) => _api.delete('/item/deletar/$id');
}
