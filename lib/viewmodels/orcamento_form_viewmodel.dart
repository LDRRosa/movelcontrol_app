import 'package:flutter/foundation.dart';

import '../models/cliente.dart';
import '../models/item.dart';
import '../models/orcamento.dart';
import '../repositories/configuracoes_repository.dart';

/// Estado do orçamento que está sendo montado no formulário.
///
/// Fica separado do OrcamentoViewModel porque representa um rascunho local:
/// é criado quando a tela abre (ChangeNotifierProvider na rota) e descartado
/// ao sair. Só vira um Orcamento de verdade ao salvar.
///
/// Em orçamentos NOVOS, cada alteração também é gravada no
/// RascunhoOrcamentoRepository (shared_preferences): se o app fechar no meio,
/// o rascunho é restaurado na próxima vez que o formulário abrir.
class OrcamentoFormViewModel extends ChangeNotifier {
  final int? id;
  final DateTime? _dataCriacao;
  final RascunhoOrcamentoRepository? _rascunho;

  int? _clienteId;
  String? _clienteNome;
  StatusOrcamento _status;
  final List<ItemOrcamento> _linhas;

  OrcamentoFormViewModel({
    Orcamento? orcamento,
    Cliente? clienteInicial,
    RascunhoOrcamentoRepository? rascunho,
  })  : id = orcamento?.id,
        _dataCriacao = orcamento?.dataCriacao,
        _clienteId = orcamento?.clienteId ?? clienteInicial?.id,
        _clienteNome = orcamento?.clienteNome ?? clienteInicial?.nome,
        _status = StatusOrcamento.deValor(orcamento?.status ?? '') ??
            StatusOrcamento.emAndamento,
        _linhas = [...?orcamento?.itens],
        // Só orçamentos novos usam rascunho.
        _rascunho = orcamento == null ? rascunho : null;

  bool get editando => id != null;
  int? get clienteId => _clienteId;
  String? get clienteNome => _clienteNome;
  StatusOrcamento get status => _status;
  List<ItemOrcamento> get linhas => List.unmodifiable(_linhas);
  bool get vazio => _clienteId == null && _linhas.isEmpty;

  /// Total recalculado a cada alteração (a API recalcula ao salvar).
  double get total => _linhas.fold(0, (soma, l) => soma + l.subtotal);
  int get quantidadeTotal => _linhas.fold(0, (soma, l) => soma + l.quantidade);

  /// Notifica a View e grava o rascunho (se houver).
  void _alterou() {
    notifyListeners();
    _rascunho?.salvar(_paraRascunho());
  }

  void selecionarCliente(Cliente cliente) {
    _clienteId = cliente.id;
    _clienteNome = cliente.nome;
    _alterou();
  }

  void alterarStatus(StatusOrcamento status) {
    _status = status;
    _alterou();
  }

  /// Adiciona o item; se ele já estiver no orçamento, soma 1 à quantidade.
  void adicionarItem(Item item) {
    final indice = _linhas.indexWhere((l) => l.itemId == item.id);
    if (indice >= 0) {
      _linhas[indice] =
          _linhas[indice].comQuantidade(_linhas[indice].quantidade + 1);
    } else {
      _linhas.add(ItemOrcamento(
        itemId: item.id!,
        nome: item.nome,
        precoUnitario: item.precoUnitario,
        quantidade: 1,
      ));
    }
    _alterou();
  }

  /// Quantidade mínima é 1 (mesma regra do @Min(1) da API).
  void alterarQuantidade(int itemId, int quantidade) {
    if (quantidade < 1) return;
    final indice = _linhas.indexWhere((l) => l.itemId == itemId);
    if (indice < 0) return;
    _linhas[indice] = _linhas[indice].comQuantidade(quantidade);
    _alterou();
  }

  void removerItem(int itemId) {
    _linhas.removeWhere((l) => l.itemId == itemId);
    _alterou();
  }

  String? validarCliente() =>
      _clienteId == null ? 'Selecione o cliente do orçamento' : null;

  String? validarItens() =>
      _linhas.isEmpty ? 'Adicione ao menos um item ao orçamento' : null;

  bool get valido => validarCliente() == null && validarItens() == null;

  Orcamento montarOrcamento() => Orcamento(
        id: id,
        dataCriacao: _dataCriacao,
        status: _status.valor,
        clienteId: _clienteId!,
        clienteNome: _clienteNome ?? '',
        itens: List.of(_linhas),
      );

  // ---------- Rascunho ----------

  Map<String, dynamic> _paraRascunho() => {
        'clienteId': _clienteId,
        'clienteNome': _clienteNome,
        'status': _status.valor,
        'linhas': [
          for (final l in _linhas)
            {
              'itemId': l.itemId,
              'nome': l.nome,
              'precoUnitario': l.precoUnitario,
              'quantidade': l.quantidade,
            }
        ],
      };

  /// Restaura o rascunho salvo, se existir e se o formulário ainda estiver
  /// vazio (ex.: não foi aberto já com um cliente escolhido).
  /// Retorna true se algo foi restaurado.
  Future<bool> restaurarRascunho() async {
    if (_rascunho == null || !vazio) return false;
    final dados = await _rascunho.ler();
    if (dados == null) return false;

    final linhas = (dados['linhas'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((l) => ItemOrcamento(
              itemId: (l['itemId'] as num).toInt(),
              nome: l['nome'] ?? '',
              precoUnitario: (l['precoUnitario'] as num?)?.toDouble() ?? 0,
              quantidade: (l['quantidade'] as num?)?.toInt() ?? 1,
            ))
        .toList();
    final clienteId = (dados['clienteId'] as num?)?.toInt();
    if (clienteId == null && linhas.isEmpty) return false;

    _clienteId = clienteId;
    _clienteNome = dados['clienteNome'];
    _status = StatusOrcamento.deValor(dados['status'] ?? '') ??
        StatusOrcamento.emAndamento;
    _linhas
      ..clear()
      ..addAll(linhas);
    notifyListeners();
    return true;
  }

  /// Apaga o rascunho salvo (depois de salvar, ou se o usuário descartar).
  Future<void> descartarRascunho({bool limparFormulario = false}) async {
    await _rascunho?.limpar();
    if (limparFormulario) {
      _clienteId = null;
      _clienteNome = null;
      _status = StatusOrcamento.emAndamento;
      _linhas.clear();
      notifyListeners();
    }
  }
}
