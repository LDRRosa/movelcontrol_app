import 'package:flutter/foundation.dart';

import '../models/cliente.dart';
import '../models/item.dart';
import '../models/orcamento.dart';

/// Estado do orçamento que está sendo montado no formulário.
///
/// Fica separado do OrcamentoViewModel porque representa um rascunho local:
/// é criado quando a tela abre (ChangeNotifierProvider na rota) e descartado
/// ao sair. Só vira um Orcamento de verdade ao salvar.
class OrcamentoFormViewModel extends ChangeNotifier {
  final int? id;
  final DateTime? _dataCriacao;

  int? _clienteId;
  String? _clienteNome;
  StatusOrcamento _status;
  final List<ItemOrcamento> _linhas;

  OrcamentoFormViewModel({Orcamento? orcamento})
      : id = orcamento?.id,
        _dataCriacao = orcamento?.dataCriacao,
        _clienteId = orcamento?.clienteId,
        _clienteNome = orcamento?.clienteNome,
        _status = StatusOrcamento.deValor(orcamento?.status ?? '') ??
            StatusOrcamento.emAndamento,
        _linhas = [...?orcamento?.itens];

  bool get editando => id != null;
  int? get clienteId => _clienteId;
  String? get clienteNome => _clienteNome;
  StatusOrcamento get status => _status;
  List<ItemOrcamento> get linhas => List.unmodifiable(_linhas);

  /// Total recalculado a cada alteração (a API recalcula ao salvar).
  double get total => _linhas.fold(0, (soma, l) => soma + l.subtotal);
  int get quantidadeTotal => _linhas.fold(0, (soma, l) => soma + l.quantidade);

  void selecionarCliente(Cliente cliente) {
    _clienteId = cliente.id;
    _clienteNome = cliente.nome;
    notifyListeners();
  }

  void alterarStatus(StatusOrcamento status) {
    _status = status;
    notifyListeners();
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
    notifyListeners();
  }

  /// Quantidade mínima é 1 (mesma regra do @Min(1) da API).
  void alterarQuantidade(int itemId, int quantidade) {
    if (quantidade < 1) return;
    final indice = _linhas.indexWhere((l) => l.itemId == itemId);
    if (indice < 0) return;
    _linhas[indice] = _linhas[indice].comQuantidade(quantidade);
    notifyListeners();
  }

  void removerItem(int itemId) {
    _linhas.removeWhere((l) => l.itemId == itemId);
    notifyListeners();
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
}
