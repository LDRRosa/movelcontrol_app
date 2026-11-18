import 'endereco.dart';

/// Cliente pessoa física (PessoaFisicaRequestDTO/ResponseDTO, rota /pf).
class Cliente {
  /// A resposta da API não traz o id no corpo; ele é extraído dos links
  /// HATEOAS pelo ClienteService. Pode ser nulo logo após um cadastro.
  final int? id;
  final String nome;
  final String cpf; // somente dígitos
  final String email;
  final String telefone;
  final Endereco? endereco;

  const Cliente({
    this.id,
    required this.nome,
    required this.cpf,
    required this.email,
    required this.telefone,
    this.endereco,
  });

  factory Cliente.fromJson(Map<String, dynamic> json, {int? id}) {
    return Cliente(
      id: id ?? (json['id'] as num?)?.toInt(),
      nome: json['nome'] ?? '',
      cpf: json['cpf'] ?? '',
      email: json['email'] ?? '',
      telefone: json['telefone'] ?? '',
      endereco: json['endereco'] is Map<String, dynamic>
          ? Endereco.fromJson(json['endereco'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'cpf': cpf,
        'email': email,
        'telefone': telefone,
        'tipo': 'FISICA',
        'endereco': endereco?.toJson(),
      };

  /// Formato salvo no cache offline (inclui o id; lido por fromJson).
  Map<String, dynamic> toCacheJson() => {...toJson(), 'id': id};
}
