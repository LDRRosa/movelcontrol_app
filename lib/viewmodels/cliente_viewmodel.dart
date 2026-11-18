import 'package:flutter/foundation.dart';

import '../models/cliente.dart';
import '../repositories/repositorio_com_cache.dart';
import '../services/api_client.dart';
import '../services/cache_local_service.dart';
import '../services/cliente_service.dart';
import 'lista_offline_mixin.dart';

enum OrdemNome {
  az('Nome (A-Z)'),
  za('Nome (Z-A)');

  final String rotulo;
  const OrdemNome(this.rotulo);
}

/// Estado e comandos da aba de Clientes (pessoa física).
class ClienteViewModel extends ChangeNotifier with ListaOffline {
  final ClienteService _service;
  final RepositorioComCache<Cliente> _repositorio;

  ClienteViewModel({ClienteService? service, CacheLocal? cache})
      : _service = service ?? ClienteService(),
        _repositorio = RepositorioComCache<Cliente>(
          chave: 'clientes',
          cache: cache ?? CacheLocal.padrao(),
          paraJson: (c) => c.toCacheJson(),
          deJson: (json) => Cliente.fromJson(json),
        );

  List<Cliente> _clientes = [];
  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  String _filtro = '';
  OrdemNome _ordem = OrdemNome.az;

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;
  bool get vazio => _clientes.isEmpty;
  OrdemNome get ordem => _ordem;

  /// Todos os clientes visíveis, ignorando a busca (usado em orçamentos).
  List<Cliente> get todos =>
      List.unmodifiable(_clientes.where((c) => !estaOculto(c.id)));

  Cliente? buscarPorId(int id) {
    for (final c in _clientes) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Cliente> get clientes {
    final termo = _filtro.toLowerCase();
    final filtrados = todos
        .where((c) =>
            termo.isEmpty ||
            c.nome.toLowerCase().contains(termo) ||
            c.cpf.contains(termo))
        .toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return List.unmodifiable(
        _ordem == OrdemNome.az ? filtrados : filtrados.reversed);
  }

  void filtrar(String texto) {
    _filtro = texto.trim();
    notifyListeners();
  }

  void ordenarPor(OrdemNome ordem) {
    _ordem = ordem;
    notifyListeners();
  }

  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final resultado = await _repositorio.carregar(_service.listar);
      _clientes = resultado.dados;
      registrarOrigem(resultado);
    } on ApiException catch (e) {
      _erro = e.mensagem;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// A resposta de criar/atualizar não traz o id do cliente, por isso a lista
  /// é recarregada da API depois de salvar.
  Future<String?> salvar(Cliente cliente) async {
    _salvando = true;
    notifyListeners();
    try {
      if (cliente.id == null) {
        await _service.criar(cliente);
      } else {
        await _service.atualizar(cliente);
      }
    } on ApiException catch (e) {
      _salvando = false;
      notifyListeners();
      return e.mensagem;
    }
    await carregar();
    _salvando = false;
    notifyListeners();
    return null;
  }

  Future<String?> excluir(Cliente cliente) async {
    try {
      await _service.excluir(cliente.id!);
      _clientes = _clientes.where((c) => c.id != cliente.id).toList();
      reexibir(cliente.id!);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensagem;
    }
  }
}
