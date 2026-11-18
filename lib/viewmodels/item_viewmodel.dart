import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../services/api_client.dart';
import '../services/item_service.dart';

/// Estado e comandos da aba de Itens do estoque.
class ItemViewModel extends ChangeNotifier {
  final ItemService _service;

  ItemViewModel({ItemService? service}) : _service = service ?? ItemService();

  List<Item> _itens = [];
  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  String _filtro = '';

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;
  bool get vazio => _itens.isEmpty;

  /// Lista exposta para a View: somente leitura e já filtrada.
  List<Item> get itens {
    final termo = _filtro.toLowerCase();
    final filtrados = termo.isEmpty
        ? _itens
        : _itens.where((i) =>
            i.nome.toLowerCase().contains(termo) ||
            i.descricao.toLowerCase().contains(termo));
    return List.unmodifiable(filtrados);
  }

  void filtrar(String texto) {
    _filtro = texto.trim();
    notifyListeners();
  }

  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _itens = await _service.listar();
    } on ApiException catch (e) {
      _erro = e.mensagem;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Cria (id nulo) ou atualiza o item. Retorna a mensagem de erro, ou null.
  Future<String?> salvar(Item item) async {
    _salvando = true;
    notifyListeners();
    try {
      if (item.id == null) {
        final criado = await _service.criar(item);
        _itens = [..._itens, criado];
      } else {
        final atualizado = await _service.atualizar(item);
        _itens = [
          for (final i in _itens) i.id == atualizado.id ? atualizado : i
        ];
      }
      return null;
    } on ApiException catch (e) {
      return e.mensagem;
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }

  /// Exclui o item. Retorna a mensagem de erro, ou null.
  Future<String?> excluir(Item item) async {
    try {
      await _service.excluir(item.id!);
      _itens = _itens.where((i) => i.id != item.id).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensagem;
    }
  }
}
