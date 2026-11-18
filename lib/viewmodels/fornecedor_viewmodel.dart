import 'package:flutter/foundation.dart';

import '../models/fornecedor.dart';
import '../services/api_client.dart';
import '../services/fornecedor_service.dart';

/// Estado e comandos da aba de Fornecedores.
class FornecedorViewModel extends ChangeNotifier {
  final FornecedorService _service;

  FornecedorViewModel({FornecedorService? service})
      : _service = service ?? FornecedorService();

  List<Fornecedor> _fornecedores = [];
  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  String _filtro = '';

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;
  bool get vazio => _fornecedores.isEmpty;

  Fornecedor? buscarPorId(int id) {
    for (final f in _fornecedores) {
      if (f.id == id) return f;
    }
    return null;
  }

  List<Fornecedor> get fornecedores {
    final termo = _filtro.toLowerCase();
    final filtrados = termo.isEmpty
        ? _fornecedores
        : _fornecedores.where((f) =>
            f.nome.toLowerCase().contains(termo) || f.cnpj.contains(termo));
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
      _fornecedores = await _service.listar();
    } on ApiException catch (e) {
      _erro = e.mensagem;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<String?> salvar(Fornecedor fornecedor) async {
    _salvando = true;
    notifyListeners();
    try {
      if (fornecedor.id == null) {
        final criado = await _service.criar(fornecedor);
        _fornecedores = [..._fornecedores, criado];
      } else {
        final atualizado = await _service.atualizar(fornecedor);
        _fornecedores = [
          for (final f in _fornecedores) f.id == atualizado.id ? atualizado : f
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

  Future<String?> excluir(Fornecedor fornecedor) async {
    try {
      await _service.excluir(fornecedor.id!);
      _fornecedores =
          _fornecedores.where((f) => f.id != fornecedor.id).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensagem;
    }
  }
}
