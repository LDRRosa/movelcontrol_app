/// Item do estoque (entidade Item / tabela "estoque" na API).
class Item {
  final int? id;
  final String nome;
  final String descricao;
  final String unidadeMedida;
  final double precoUnitario;
  final int quantidadeEstoque;

  const Item({
    this.id,
    required this.nome,
    required this.descricao,
    required this.unidadeMedida,
    required this.precoUnitario,
    required this.quantidadeEstoque,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: (json['id'] as num?)?.toInt(),
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      unidadeMedida: json['unidadeMedida'] ?? '',
      precoUnitario: (json['precoUnitario'] as num?)?.toDouble() ?? 0,
      // A API expõe este campo com underscore (getQuantidade_estoque).
      quantidadeEstoque: (json['quantidade_estoque'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        // O PUT /item/atualizar/{id} copia o "id" do corpo para a entidade;
        // sem ele a API criaria um registro novo em vez de atualizar.
        if (id != null) 'id': id,
        'nome': nome,
        'descricao': descricao,
        'unidadeMedida': unidadeMedida,
        'precoUnitario': precoUnitario,
        'quantidade_estoque': quantidadeEstoque,
      };
}
