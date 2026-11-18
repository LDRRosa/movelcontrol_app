import 'formatadores.dart';

/// Validadores reutilizáveis para TextFormField (propriedade validator).
/// Retornam null quando o valor é válido ou a mensagem de erro.
/// Os limites de tamanho seguem as colunas do banco da API MovelControl.
class Validadores {
  static String? obrigatorio(String? valor,
      {String campo = 'Campo', int? max}) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return '$campo é obrigatório';
    if (max != null && texto.length > max) {
      return '$campo deve ter no máximo $max caracteres';
    }
    return null;
  }

  static String? opcional(String? valor, {String campo = 'Campo', int? max}) {
    final texto = valor?.trim() ?? '';
    if (max != null && texto.length > max) {
      return '$campo deve ter no máximo $max caracteres';
    }
    return null;
  }

  static String? email(String? valor, {int max = 100}) {
    final erro = obrigatorio(valor, campo: 'E-mail', max: max);
    if (erro != null) return erro;
    final regex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
    if (!regex.hasMatch(valor!.trim())) return 'E-mail inválido';
    return null;
  }

  static String? telefone(String? valor) {
    final digitos = Formatadores.somenteDigitos(valor ?? '');
    if (digitos.isEmpty) return 'Telefone é obrigatório';
    if (digitos.length < 10 || digitos.length > 11) {
      return 'Informe DDD + número (10 ou 11 dígitos)';
    }
    return null;
  }

  static String? cep(String? valor) {
    final digitos = Formatadores.somenteDigitos(valor ?? '');
    if (digitos.isEmpty) return 'CEP é obrigatório';
    if (digitos.length != 8) return 'CEP deve ter 8 dígitos';
    return null;
  }

  static String? precoPositivo(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Preço é obrigatório';
    final numero = Formatadores.parseDecimal(valor);
    if (numero == null) return 'Informe um valor numérico (ex.: 12,50)';
    if (numero <= 0) return 'O preço deve ser maior que zero';
    return null;
  }

  static String? inteiroNaoNegativo(String? valor, {String campo = 'Valor'}) {
    if (valor == null || valor.trim().isEmpty) return '$campo é obrigatório';
    final numero = int.tryParse(valor.trim());
    if (numero == null) return '$campo deve ser um número inteiro';
    if (numero < 0) return '$campo não pode ser negativo';
    return null;
  }

  static String? cpf(String? valor) {
    final d = Formatadores.somenteDigitos(valor ?? '');
    if (d.isEmpty) return 'CPF é obrigatório';
    if (!cpfValido(d)) return 'CPF inválido';
    return null;
  }

  static String? cnpj(String? valor) {
    final d = Formatadores.somenteDigitos(valor ?? '');
    if (d.isEmpty) return 'CNPJ é obrigatório';
    if (!cnpjValido(d)) return 'CNPJ inválido';
    return null;
  }

  /// Confere os dígitos verificadores do CPF (mesma regra do @CPF da API).
  static bool cpfValido(String digitos) {
    if (digitos.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digitos)) return false;
    final n = digitos.split('').map(int.parse).toList();

    int calcular(int tamanho) {
      var soma = 0;
      for (var i = 0; i < tamanho; i++) {
        soma += n[i] * (tamanho + 1 - i);
      }
      final resto = (soma * 10) % 11;
      return resto == 10 ? 0 : resto;
    }

    return calcular(9) == n[9] && calcular(10) == n[10];
  }

  /// Confere os dígitos verificadores do CNPJ (mesma regra do @CNPJ da API).
  static bool cnpjValido(String digitos) {
    if (digitos.length != 14) return false;
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digitos)) return false;
    final n = digitos.split('').map(int.parse).toList();

    int calcular(List<int> pesos) {
      var soma = 0;
      for (var i = 0; i < pesos.length; i++) {
        soma += n[i] * pesos[i];
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    return calcular(pesos1) == n[12] && calcular(pesos2) == n[13];
  }
}
