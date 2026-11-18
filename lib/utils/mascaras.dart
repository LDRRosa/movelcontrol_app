import 'package:flutter/services.dart';

import 'formatadores.dart';

/// Máscaras de digitação: formatam o texto enquanto o usuário digita.
/// Uso: TextFormField(inputFormatters: [Mascaras.cpf], ...)
class Mascaras {
  static final cpf = MascaraFormatter('###.###.###-##');
  static final cnpj = MascaraFormatter('##.###.###/####-##');
  static final cep = MascaraFormatter('#####-###');
  static final telefone = TelefoneFormatter();
  static final moeda = MoedaFormatter();
}

/// Máscara genérica: cada '#' é um dígito; os demais caracteres são
/// inseridos automaticamente (ex.: '###.###.###-##').
class MascaraFormatter extends TextInputFormatter {
  final String mascara;
  late final int maxDigitos = '#'.allMatches(mascara).length;

  MascaraFormatter(this.mascara);

  /// Aplica a máscara a um texto qualquer (só os dígitos são usados).
  String aplicar(String texto) {
    var digitos = Formatadores.somenteDigitos(texto);
    if (digitos.length > maxDigitos) digitos = digitos.substring(0, maxDigitos);

    final buffer = StringBuffer();
    var i = 0;
    for (final caractere in mascara.split('')) {
      // Para quando acabam os dígitos: o separador só aparece se houver
      // um dígito depois dele (assim apagar com backspace funciona).
      if (i >= digitos.length) break;
      if (caractere == '#') {
        buffer.write(digitos[i++]);
      } else {
        buffer.write(caractere);
      }
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = aplicar(newValue.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Telefone com DDD: (62) 3333-4444 (fixo) ou (62) 93333-4444 (celular).
class TelefoneFormatter extends TextInputFormatter {
  static final _fixo = MascaraFormatter('(##) ####-####');
  static final _celular = MascaraFormatter('(##) #####-####');

  String aplicar(String texto) {
    final digitos = Formatadores.somenteDigitos(texto);
    return digitos.length <= 10
        ? _fixo.aplicar(digitos)
        : _celular.aplicar(digitos);
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = aplicar(newValue.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Moeda no padrão brasileiro: os dígitos entram pelos centavos
/// (digitar 1, 2, 5, 0 resulta em 12,50 e depois 125,00 → 1.250,00...).
class MoedaFormatter extends TextInputFormatter {
  static const _maxDigitos = 12; // até 9.999.999.999,99

  String aplicar(String texto) {
    var digitos = Formatadores.somenteDigitos(texto);
    if (digitos.isEmpty) return '';
    if (digitos.length > _maxDigitos) {
      digitos = digitos.substring(0, _maxDigitos);
    }
    return Formatadores.moedaSemSimbolo(int.parse(digitos) / 100);
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = aplicar(newValue.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
