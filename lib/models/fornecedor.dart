import 'endereco.dart';

/// Fornecedor (FornecedorRequestDTO/ResponseDTO).
class Fornecedor {
  final int? id;
  final String nome;
  final String cnpj; // somente dígitos (a coluna no banco tem 14 caracteres)
  final String telefone;
  final String email;
  final Endereco? endereco;

  const Fornecedor({
    this.id,
    required this.nome,
    required this.cnpj,
    required this.telefone,
    required this.email,
    this.endereco,
  });

  factory Fornecedor.fromJson(Map<String, dynamic> json) {
    return Fornecedor(
      id: (json['id'] as num?)?.toInt(),
      nome: json['nome'] ?? '',
      cnpj: json['cnpj'] ?? '',
      telefone: json['telefone'] ?? '',
      email: json['email'] ?? '',
      endereco: json['endereco'] is Map<String, dynamic>
          ? Endereco.fromJson(json['endereco'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'cnpj': cnpj,
        'telefone': telefone,
        'email': email,
        'endereco': endereco?.toJson(),
      };
}
