import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../repositories/repositorio_com_cache.dart';
import '../services/api_client.dart';
import '../services/cache_local_service.dart';
import '../services/item_service.dart';
import 'lista_offline_mixin.dart';

enum OrdemItem {
  nome('Nome (A-Z)'),
  menorEstoque('Menor estoque'),
  maiorPreco('Maior preço'),
  menorPreco('Menor preço');

  final String rotulo;
  const OrdemItem(this.rotulo);
}

/// Estado e comandos da aba de Itens do estoque.
class ItemViewModel extends ChangeNotifier with ListaOffline {
  final ItemService _service;
  final RepositorioComCache<Item> _repositorio;

  ItemViewModel({
    ItemService? service,
    CacheLocal? cache,
    int estoqueMinimo = 5,
  })  : _service = service ?? ItemService(),
        _estoqueMinimo = estoqueMinimo,
        _repositorio = RepositorioComCache<Item>(
          chave: 'itens',
          cache: cache ?? CacheLocal.padrao(),
          paraJson: (i) => i.toJson(),
          deJson: Item.fromJson,
        );

  List<Item> _itens = [];
  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  String _filtro = '';
  OrdemItem _ordem = OrdemItem.nome;

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;
  bool get vazio => _itens.isEmpty;
  OrdemItem get ordem => _ordem;

  /// Todos os itens visíveis, ignorando a busca (usado em orçamentos/painel).
  List<Item> get todos =>
      List.unmodifiable(_itens.where((i) => !estaOculto(i.id)));

  Item? buscarPorId(int id) {
    for (final i in _itens) {
      if (i.id == id) return i;
    }
    return null;
  }

  // ---------- Estoque baixo ----------

  /// Quantidade abaixo da qual o item tem estoque baixo. A API não tem esse
  /// campo: o valor vem das Configurações (shared_preferences).
  int _estoqueMinimo;
  int get estoqueMinimo => _estoqueMinimo;

  void definirEstoqueMinimo(int valor) {
    _estoqueMinimo = valor;
    notifyListeners();
  }

  bool _somenteEstoqueBaixo = false;
  bool get somenteEstoqueBaixo => _somenteEstoqueBaixo;

  bool estaComEstoqueBaixo(Item item) =>
      item.quantidadeEstoque < _estoqueMinimo;

  /// Itens abaixo do mínimo, do menor estoque para o maior.
  List<Item> get itensEstoqueBaixo => List.unmodifiable(
      todos.where(estaComEstoqueBaixo).toList()
        ..sort((a, b) => a.quantidadeEstoque.compareTo(b.quantidadeEstoque)));

  void mostrarSomenteEstoqueBaixo(bool valor) {
    _somenteEstoqueBaixo = valor;
    notifyListeners();
  }

  // ---------- Lista exibida ----------

  /// Lista para a View: somente leitura, filtrada e ordenada.
  List<Item> get itens {
    final termo = _filtro.toLowerCase();
    final filtrados = todos.where((i) {
      final buscaOk = termo.isEmpty ||
          i.nome.toLowerCase().contains(termo) ||
          i.descricao.toLowerCase().contains(termo);
      final estoqueOk = !_somenteEstoqueBaixo || estaComEstoqueBaixo(i);
      return buscaOk && estoqueOk;
    }).toList();

    filtrados.sort(switch (_ordem) {
      OrdemItem.nome => (a, b) =>
          a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      OrdemItem.menorEstoque => (a, b) =>
          a.quantidadeEstoque.compareTo(b.quantidadeEstoque),
      OrdemItem.maiorPreco => (a, b) => b.precoUnitario.compareTo(a.precoUnitario),
      OrdemItem.menorPreco => (a, b) => a.precoUnitario.compareTo(b.precoUnitario),
    });
    return List.unmodifiable(filtrados);
  }

  void filtrar(String texto) {
    _filtro = texto.trim();
    notifyListeners();
  }

  void ordenarPor(OrdemItem ordem) {
    _ordem = ordem;
    notifyListeners();
  }

  // ---------- Comandos ----------

  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final resultado = await _repositorio.carregar(_service.listar);
      _itens = resultado.dados;
      registrarOrigem(resultado);
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
      reexibir(item.id!); // limpa a marcação de oculto
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensagem;
    }
  }
}
