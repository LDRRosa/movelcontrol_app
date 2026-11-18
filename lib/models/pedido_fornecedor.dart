/// Pedido de compra feito a um fornecedor (PedidoFornecedorResponseDTO).
class PedidoFornecedor {
  final int id;
  final String status;
  final DateTime? dataPedido;
  final List<ItemPedidoFornecedor> itens;

  const PedidoFornecedor({
    required this.id,
    required this.status,
    this.dataPedido,
    required this.itens,
  });

  int get quantidadeTotal => itens.fold(0, (s, i) => s + i.quantidade);

  factory PedidoFornecedor.fromJson(Map<String, dynamic> json) {
    final data = json['dataPedido'];
    return PedidoFornecedor(
      id: (json['id'] as num).toInt(),
      status: json['status'] ?? '',
      // Usa só a parte da data ("2026-11-18T00:00:00+00:00") para não
      // deslocar o dia por causa do fuso.
      dataPedido: data is String && data.length >= 10
          ? DateTime.tryParse(data.substring(0, 10))
          : null,
      itens: (json['itens'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ItemPedidoFornecedor.fromJson)
          .toList(),
    );
  }
}

class ItemPedidoFornecedor {
  final int itemId;
  final String nome;
  final int quantidade;

  const ItemPedidoFornecedor({
    required this.itemId,
    required this.nome,
    required this.quantidade,
  });

  factory ItemPedidoFornecedor.fromJson(Map<String, dynamic> json) {
    return ItemPedidoFornecedor(
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      nome: json['nome'] ?? '',
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 0,
    );
  }
}
