import 'package:flutter_test/flutter_test.dart';
import 'package:movelcontrol_app/utils/formatadores.dart';
import 'package:movelcontrol_app/utils/validadores.dart';

void main() {
  group('CPF', () {
    test('aceita CPF válido com ou sem máscara', () {
      expect(Validadores.cpf('52998224725'), isNull);
      expect(Validadores.cpf('529.982.247-25'), isNull);
    });
    test('rejeita dígitos verificadores errados e sequências repetidas', () {
      expect(Validadores.cpf('52998224724'), isNotNull);
      expect(Validadores.cpf('11111111111'), isNotNull);
      expect(Validadores.cpf(''), 'CPF é obrigatório');
    });
  });

  group('CNPJ', () {
    test('aceita CNPJ válido', () {
      expect(Validadores.cnpj('11222333000181'), isNull);
    });
    test('rejeita CNPJ inválido', () {
      expect(Validadores.cnpj('11222333000180'), isNotNull);
      expect(Validadores.cnpj('123'), isNotNull);
    });
  });

  test('obrigatório respeita tamanho máximo', () {
    expect(Validadores.obrigatorio('  ', campo: 'Nome'), 'Nome é obrigatório');
    expect(Validadores.obrigatorio('abc', campo: 'Nome', max: 2), isNotNull);
    expect(Validadores.obrigatorio('ab', campo: 'Nome', max: 2), isNull);
  });

  test('preço aceita vírgula e exige valor positivo', () {
    expect(Validadores.precoPositivo('12,50'), isNull);
    expect(Validadores.precoPositivo('0'), isNotNull);
    expect(Validadores.precoPositivo('abc'), isNotNull);
    expect(Formatadores.parseDecimal('12,50'), 12.5);
  });

  test('e-mail, telefone e CEP', () {
    expect(Validadores.email('a@b.com'), isNull);
    expect(Validadores.email('a@b'), isNotNull);
    expect(Validadores.telefone('(62) 91234-5678'), isNull);
    expect(Validadores.telefone('1234'), isNotNull);
    expect(Validadores.cep('75790000'), isNull);
    expect(Formatadores.cep('75790000'), '75790-000');
  });
}
