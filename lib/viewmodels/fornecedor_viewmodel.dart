import 'package:flutter/foundation.dart';

import '../models/fornecedor.dart';
import '../repositories/repositorio_com_cache.dart';
import '../services/api_client.dart';
import '../services/cache_local_service.dart';
import '../services/fornecedor_service.dart';
import 'cliente_viewmodel.dart' show OrdemNome;
import 'lista_offline_mixin.dart';

/// Estado e comandos da aba de Fornecedores.
class FornecedorViewModel extends ChangeNotifier with ListaOffline {
  final FornecedorService _service;
  final RepositorioComCache<Fornecedor> _repositorio;

  FornecedorViewModel({FornecedorService? service, CacheLocal? cache})
      : _service = service ?? FornecedorService(),
        _repositorio = RepositorioComCache<Fornecedor>(
          chave: 'fornecedores',
          cache: cache ?? CacheLocal.padrao(),
          paraJson: (f) => f.toCacheJson(),
          deJson: Fornecedor.fromJson,
        );

  List<Fornecedor> _fornecedores = [];
  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  String _filtro = '';
  OrdemNome _ordem = OrdemNome.az;

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;
  bool get vazio => _fornecedores.isEmpty;
  OrdemNome get ordem => _ordem;

  Fornecedor? buscarPorId(int id) {
    for (final f in _fornecedores) {
      if (f.id == id) return f;
    }
    return null;
  }

  List<Fornecedor> get fornecedores {
    final termo = _filtro.toLowerCase();
    final filtrados = _fornecedores
        .where((f) => !estaOculto(f.id))
        .where((f) =>
            termo.isEmpty ||
            f.nome.toLowerCase().contains(termo) ||
            f.cnpj.contains(termo))
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
      _fornecedores = resultado.dados;
      registrarOrigem(resultado);
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
      reexibir(fornecedor.id!);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensagem;
    }
  }
}
