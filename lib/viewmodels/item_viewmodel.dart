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

  /// Todos os itens, ignorando a busca da aba (usado ao montar orçamentos).
  List<Item> get todos => List.unmodifiable(_itens);

  Item? buscarPorId(int id) {
    for (final i in _itens) {
      if (i.id == id) return i;
    }
    return null;
  }

  // ---------- Estoque baixo ----------

  /// Quantidade a partir da qual o item é considerado com estoque baixo.
  /// A API não tem esse campo; o valor é uma regra do app.
  static const int estoqueMinimo = 5;

  bool _somenteEstoqueBaixo = false;
  bool get somenteEstoqueBaixo => _somenteEstoqueBaixo;

  static bool estaComEstoqueBaixo(Item item) =>
      item.quantidadeEstoque < estoqueMinimo;

  /// Itens abaixo do mínimo, do menor estoque para o maior.
  List<Item> get itensEstoqueBaixo => List.unmodifiable(
      _itens.where(estaComEstoqueBaixo).toList()
        ..sort((a, b) => a.quantidadeEstoque.compareTo(b.quantidadeEstoque)));

  void mostrarSomenteEstoqueBaixo(bool valor) {
    _somenteEstoqueBaixo = valor;
    notifyListeners();
  }

  /// Lista exposta para a View: somente leitura e já filtrada.
  List<Item> get itens {
    final termo = _filtro.toLowerCase();
    final filtrados = _itens.where((i) {
      final buscaOk = termo.isEmpty ||
          i.nome.toLowerCase().contains(termo) ||
          i.descricao.toLowerCase().contains(termo);
      final estoqueOk = !_somenteEstoqueBaixo || estaComEstoqueBaixo(i);
      return buscaOk && estoqueOk;
    });
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
