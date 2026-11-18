/// Endereço usado por Fornecedor e Cliente (EnderecoRequestDTO/ResponseDTO).
class Endereco {
  final String rua;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cep;

  const Endereco({
    required this.rua,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cep,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      rua: json['rua'] ?? '',
      numero: json['numero'] ?? '',
      complemento: json['complemento'],
      bairro: json['bairro'] ?? '',
      cep: json['cep'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'rua': rua,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cep': cep,
      };

  /// Texto curto para exibir em listas.
  String get resumo {
    final partes = [
      if (rua.isNotEmpty) '$rua, $numero',
      if (bairro.isNotEmpty) bairro,
    ];
    return partes.join(' - ');
  }
}
