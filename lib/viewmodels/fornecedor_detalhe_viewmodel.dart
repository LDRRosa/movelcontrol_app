import 'package:flutter/foundation.dart';

import '../models/pedido_fornecedor.dart';
import '../services/api_client.dart';
import '../services/fornecedor_service.dart';

/// Estado da tela de detalhe do fornecedor: carrega os pedidos feitos a ele.
/// É criado junto com a rota (escopo da tela), pois os pedidos só interessam
/// enquanto o detalhe está aberto.
class FornecedorDetalheViewModel extends ChangeNotifier {
  final int fornecedorId;
  final FornecedorService _service;

  FornecedorDetalheViewModel({
    required this.fornecedorId,
    FornecedorService? service,
  }) : _service = service ?? FornecedorService();

  List<PedidoFornecedor> _pedidos = [];
  bool _carregando = false;
  String? _erro;

  List<PedidoFornecedor> get pedidos => List.unmodifiable(_pedidos);
  bool get carregando => _carregando;
  String? get erro => _erro;
  int get unidadesCompradas => _pedidos.fold(0, (s, p) => s + p.quantidadeTotal);

  Future<void> carregarPedidos() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final pedidos = await _service.listarPedidos(fornecedorId);
      pedidos.sort((a, b) => b.id.compareTo(a.id)); // mais recentes primeiro
      _pedidos = pedidos;
    } on ApiException catch (e) {
      _erro = e.mensagem;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
