import 'package:flutter/foundation.dart';

import '../models/cliente.dart';
import '../services/api_client.dart';
import '../services/cliente_service.dart';

/// Estado e comandos da aba de Clientes (pessoa física).
class ClienteViewModel extends ChangeNotifier {
  final ClienteService _service;

  ClienteViewModel({ClienteService? service})
      : _service = service ?? ClienteService();

  List<Cliente> _clientes = [];
  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  String _filtro = '';

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;
  bool get vazio => _clientes.isEmpty;

  /// Todos os clientes, ignorando a busca da aba (usado ao montar orçamentos).
  List<Cliente> get todos => List.unmodifiable(_clientes);

  Cliente? buscarPorId(int id) {
    for (final c in _clientes) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Cliente> get clientes {
    final termo = _filtro.toLowerCase();
    final filtrados = termo.isEmpty
        ? _clientes
        : _clientes.where((c) =>
            c.nome.toLowerCase().contains(termo) || c.cpf.contains(termo));
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
      _clientes = await _service.listar();
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
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensagem;
    }
  }
}
