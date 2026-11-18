/// Status de orçamento usados pelo app. A API guarda o status como texto livre
/// (VARCHAR 50), então valores desconhecidos também são exibidos.
enum StatusOrcamento {
  emAndamento('EM_ANDAMENTO', 'Em andamento'),
  aprovado('APROVADO', 'Aprovado'),
  recusado('RECUSADO', 'Recusado'),
  cancelado('CANCELADO', 'Cancelado');

  final String valor;
  final String rotulo;
  const StatusOrcamento(this.valor, this.rotulo);

  static StatusOrcamento? deValor(String valor) {
    for (final s in values) {
      if (s.valor == valor.toUpperCase()) return s;
    }
    return null;
  }

  /// Rótulo amigável para qualquer texto vindo da API.
  static String rotuloDe(String valor) =>
      deValor(valor)?.rotulo ?? valor.replaceAll('_', ' ');
}

/// Linha de um orçamento: um item do estoque e a quantidade orçada.
class ItemOrcamento {
  final int itemId;
  final String nome;
  final double precoUnitario;
  final int quantidade;

  const ItemOrcamento({
    required this.itemId,
    required this.nome,
    required this.precoUnitario,
    required this.quantidade,
  });

  double get subtotal => precoUnitario * quantidade;

  ItemOrcamento comQuantidade(int novaQuantidade) => ItemOrcamento(
        itemId: itemId,
        nome: nome,
        precoUnitario: precoUnitario,
        quantidade: novaQuantidade,
      );

  factory ItemOrcamento.fromJson(Map<String, dynamic> json) {
    return ItemOrcamento(
      itemId: (json['itemId'] as num).toInt(),
      nome: json['nomeItem'] ?? '',
      precoUnitario: (json['precoUnitarioItem'] as num?)?.toDouble() ?? 0,
      quantidade: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'itemId': itemId, 'quantity': quantidade};
}

/// Orçamento (OrcamentoRequestDTO/ResponseDTO, rota /orcamentos).
class Orcamento {
  final int? id;
  final DateTime? dataCriacao;
  final String status;
  final int clienteId;
  final String clienteNome;
  final List<ItemOrcamento> itens;

  /// Total informado pela API; se ausente, é calculado pelos itens.
  final double? _valorTotalApi;

  const Orcamento({
    this.id,
    this.dataCriacao,
    required this.status,
    required this.clienteId,
    required this.clienteNome,
    required this.itens,
    double? valorTotal,
  }) : _valorTotalApi = valorTotal;

  double get valorTotal =>
      _valorTotalApi ?? itens.fold(0, (soma, i) => soma + i.subtotal);

  int get quantidadeDeItens => itens.fold(0, (soma, i) => soma + i.quantidade);

  Orcamento comStatus(String novoStatus) => Orcamento(
        id: id,
        dataCriacao: dataCriacao,
        status: novoStatus,
        clienteId: clienteId,
        clienteNome: clienteNome,
        itens: itens,
        valorTotal: _valorTotalApi,
      );

  factory Orcamento.fromJson(Map<String, dynamic> json) {
    final cliente = json['cliente'] is Map ? json['cliente'] as Map : const {};
    final itens = (json['itens'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ItemOrcamento.fromJson)
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    return Orcamento(
      id: (json['id'] as num?)?.toInt(),
      dataCriacao: _lerData(json['dataCriacao']),
      status: json['status'] ?? '',
      clienteId: (cliente['id'] as num?)?.toInt() ?? 0,
      clienteNome: cliente['nome'] ?? '',
      itens: itens,
      valorTotal: (json['valorTotal'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'clienteId': clienteId,
        if (dataCriacao != null) 'dataCriacao': _formatarData(dataCriacao!),
        'itens': itens.map((i) => i.toJson()).toList(),
      };

  /// Formato salvo no cache offline: o mesmo da resposta da API,
  /// para ser lido de volta por fromJson.
  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'dataCriacao': dataCriacao == null ? null : _formatarData(dataCriacao!),
        'status': status,
        'valorTotal': valorTotal,
        'cliente': {'id': clienteId, 'nome': clienteNome},
        'itens': [
          for (final i in itens)
            {
              'itemId': i.itemId,
              'nomeItem': i.nome,
              'precoUnitarioItem': i.precoUnitario,
              'quantity': i.quantidade,
            }
        ],
      };

  /// A API devolve "2026-11-18" na listagem e "2026-11-18T20:31:19+00:00"
  /// ao criar. Usamos só a parte da data para não deslocar o dia pelo fuso.
  static DateTime? _lerData(dynamic valor) {
    if (valor is! String || valor.length < 10) return null;
    return DateTime.tryParse(valor.substring(0, 10));
  }

  static String _formatarData(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-'
      '${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';
}
