import 'package:flutter/foundation.dart';

import '../models/orcamento.dart';
import '../repositories/repositorio_com_cache.dart';
import '../services/api_client.dart';
import '../services/cache_local_service.dart';
import '../services/orcamento_service.dart';
import 'lista_offline_mixin.dart';

enum OrdemOrcamento {
  maisRecentes('Mais recentes'),
  maisAntigos('Mais antigos'),
  maiorValor('Maior valor'),
  menorValor('Menor valor'),
  cliente('Cliente (A-Z)');

  final String rotulo;
  const OrdemOrcamento(this.rotulo);
}

/// Estado e comandos da aba de Orçamentos (listagem, filtros e persistência).
class OrcamentoViewModel extends ChangeNotifier with ListaOffline {
  final OrcamentoService _service;
  final RepositorioComCache<Orcamento> _repositorio;

  OrcamentoViewModel({OrcamentoService? service, CacheLocal? cache})
      : _service = service ?? OrcamentoService(),
        _repositorio = RepositorioComCache<Orcamento>(
          chave: 'orcamentos',
          cache: cache ?? CacheLocal.padrao(),
          paraJson: (o) => o.toCacheJson(),
          deJson: Orcamento.fromJson,
        );

  List<Orcamento> _orcamentos = [];
  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  String _busca = '';
  StatusOrcamento? _statusFiltro;
  OrdemOrcamento _ordem = OrdemOrcamento.maisRecentes;

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;
  bool get vazio => _orcamentos.isEmpty;
  StatusOrcamento? get statusFiltro => _statusFiltro;
  OrdemOrcamento get ordem => _ordem;

  /// Todos os orçamentos visíveis, sem filtros (usado pelo painel).
  List<Orcamento> get todos =>
      List.unmodifiable(_orcamentos.where((o) => !estaOculto(o.id)));

  Orcamento? buscarPorId(int id) {
    for (final o in _orcamentos) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Histórico de orçamentos de um cliente, mais recentes primeiro.
  List<Orcamento> doCliente(int clienteId) => List.unmodifiable(
      todos.where((o) => o.clienteId == clienteId).toList()
        ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0)));

  /// Atalho usado na tela de detalhe para aprovar/recusar/cancelar.
  Future<String?> alterarStatus(Orcamento orcamento, StatusOrcamento status) =>
      salvar(orcamento.comStatus(status.valor));

  /// Lista filtrada por status e por cliente, na ordem escolhida.
  List<Orcamento> get orcamentos {
    final termo = _busca.toLowerCase();
    final filtrados = todos.where((o) {
      final statusOk =
          _statusFiltro == null || o.status == _statusFiltro!.valor;
      final buscaOk = termo.isEmpty ||
          o.clienteNome.toLowerCase().contains(termo) ||
          '${o.id}' == termo;
      return statusOk && buscaOk;
    }).toList();

    filtrados.sort(switch (_ordem) {
      OrdemOrcamento.maisRecentes => (a, b) => (b.id ?? 0).compareTo(a.id ?? 0),
      OrdemOrcamento.maisAntigos => (a, b) => (a.id ?? 0).compareTo(b.id ?? 0),
      OrdemOrcamento.maiorValor => (a, b) => b.valorTotal.compareTo(a.valorTotal),
      OrdemOrcamento.menorValor => (a, b) => a.valorTotal.compareTo(b.valorTotal),
      OrdemOrcamento.cliente => (a, b) =>
          a.clienteNome.toLowerCase().compareTo(b.clienteNome.toLowerCase()),
    });
    return List.unmodifiable(filtrados);
  }

  /// Soma dos orçamentos visíveis com o filtro atual.
  double get totalFiltrado =>
      orcamentos.fold(0, (soma, o) => soma + o.valorTotal);

  /// Quantidade de orçamentos por status (para os chips de filtro).
  int contarPorStatus(StatusOrcamento status) =>
      todos.where((o) => o.status == status.valor).length;

  void buscar(String texto) {
    _busca = texto.trim();
    notifyListeners();
  }

  void filtrarStatus(StatusOrcamento? status) {
    _statusFiltro = status;
    notifyListeners();
  }

  void ordenarPor(OrdemOrcamento ordem) {
    _ordem = ordem;
    notifyListeners();
  }

  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final resultado = await _repositorio.carregar(_service.listar);
      _orcamentos = resultado.dados;
      registrarOrigem(resultado);
    } on ApiException catch (e) {
      _erro = e.mensagem;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<String?> salvar(Orcamento orcamento) async {
    _salvando = true;
    notifyListeners();
    try {
      if (orcamento.id == null) {
        final criado = await _service.criar(orcamento);
        _orcamentos = [..._orcamentos, criado];
      } else {
        final atualizado = await _service.atualizar(orcamento);
        _orcamentos = [
          for (final o in _orcamentos) o.id == atualizado.id ? atualizado : o
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

  Future<String?> excluir(Orcamento orcamento) async {
    try {
      await _service.excluir(orcamento.id!);
      _orcamentos = _orcamentos.where((o) => o.id != orcamento.id).toList();
      reexibir(orcamento.id!);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensagem;
    }
  }
}
