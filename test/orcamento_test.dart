import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movelcontrol_app/models/cliente.dart';
import 'package:movelcontrol_app/models/item.dart';
import 'package:movelcontrol_app/models/orcamento.dart';
import 'package:movelcontrol_app/services/api_client.dart';
import 'package:movelcontrol_app/services/cache_local_service.dart';
import 'package:movelcontrol_app/services/orcamento_service.dart';
import 'package:movelcontrol_app/viewmodels/orcamento_form_viewmodel.dart';
import 'package:movelcontrol_app/viewmodels/orcamento_viewmodel.dart';

/// Resposta real de GET /orcamentos capturada da API MovelControl.
const _jsonApi = '''
[{"id":1,"dataCriacao":"2026-11-18","status":"EM_ANDAMENTO","valorTotal":225.0,
  "cliente":{"id":2,"nome":"Ana","tipoPessoa":null},
  "itens":[
    {"itemId":3,"nomeItem":"MDF","descricaoItem":"x","precoUnitarioItem":100.0,"quantity":2,"subtotal":200.0},
    {"itemId":4,"nomeItem":"Dobradiça","descricaoItem":"y","precoUnitarioItem":2.5,"quantity":10,"subtotal":25.0}],
  "links":[{"rel":"self","href":"http://localhost:8080/orcamentos/1"}]},
 {"id":2,"dataCriacao":"2026-11-18T20:31:19.197+00:00","status":"APROVADO","valorTotal":50.0,
  "cliente":{"id":5,"nome":"Bruno","tipoPessoa":null},
  "itens":[{"itemId":4,"nomeItem":"Dobradiça","descricaoItem":"y","precoUnitarioItem":2.5,"quantity":20,"subtotal":50.0}]}]
''';

const _mdf = Item(
    id: 3,
    nome: 'MDF',
    descricao: 'x',
    unidadeMedida: 'UN',
    precoUnitario: 100,
    quantidadeEstoque: 5);
const _dobradica = Item(
    id: 4,
    nome: 'Dobradiça',
    descricao: 'y',
    unidadeMedida: 'UN',
    precoUnitario: 2.5,
    quantidadeEstoque: 50);

void main() {
  group('Orcamento.fromJson', () {
    test('lê cliente, itens e total', () {
      final o = Orcamento.fromJson((jsonDecode(_jsonApi) as List).first);
      expect(o.id, 1);
      expect(o.clienteId, 2);
      expect(o.clienteNome, 'Ana');
      expect(o.itens.length, 2);
      expect(o.valorTotal, 225.0);
      expect(o.quantidadeDeItens, 12);
    });

    test('aceita data simples e data com hora/fuso', () {
      final lista = jsonDecode(_jsonApi) as List;
      expect(Orcamento.fromJson(lista[0]).dataCriacao, DateTime(2026, 11, 18));
      expect(Orcamento.fromJson(lista[1]).dataCriacao, DateTime(2026, 11, 18));
    });

    test('toJson envia o formato do OrcamentoRequestDTO', () {
      final o = Orcamento.fromJson((jsonDecode(_jsonApi) as List).first);
      expect(o.toJson(), {
        'status': 'EM_ANDAMENTO',
        'clienteId': 2,
        'dataCriacao': '2026-11-18',
        'itens': [
          {'itemId': 4, 'quantity': 10},
          {'itemId': 3, 'quantity': 2},
        ],
      });
    });
  });

  group('OrcamentoFormViewModel', () {
    test('adicionar o mesmo item soma quantidade e recalcula o total', () {
      final vm = OrcamentoFormViewModel();
      vm.adicionarItem(_mdf);
      vm.adicionarItem(_mdf);
      vm.adicionarItem(_dobradica);
      expect(vm.linhas.length, 2);
      expect(vm.linhas.first.quantidade, 2);
      expect(vm.total, 202.5);
    });

    test('quantidade mínima é 1 e remover tira a linha', () {
      final vm = OrcamentoFormViewModel()..adicionarItem(_mdf);
      vm.alterarQuantidade(3, 0);
      expect(vm.linhas.single.quantidade, 1);
      vm.alterarQuantidade(3, 4);
      expect(vm.total, 400);
      vm.removerItem(3);
      expect(vm.linhas, isEmpty);
    });

    test('valida cliente e itens obrigatórios', () {
      final vm = OrcamentoFormViewModel();
      expect(vm.validarCliente(), isNotNull);
      expect(vm.validarItens(), isNotNull);
      vm.selecionarCliente(const Cliente(
          id: 2, nome: 'Ana', cpf: '52998224725', email: 'a@a.com', telefone: '1'));
      vm.adicionarItem(_mdf);
      expect(vm.valido, isTrue);
      final o = vm.montarOrcamento();
      expect(o.clienteId, 2);
      expect(o.status, 'EM_ANDAMENTO');
    });

    test('edição parte do orçamento existente', () {
      final existente = Orcamento.fromJson((jsonDecode(_jsonApi) as List)[1]);
      final vm = OrcamentoFormViewModel(orcamento: existente);
      expect(vm.editando, isTrue);
      expect(vm.status, StatusOrcamento.aprovado);
      expect(vm.total, 50);
    });
  });

  test('OrcamentoViewModel filtra por status e busca por cliente', () async {
    final api = ApiClient(
        httpClient: MockClient((_) async => http.Response.bytes(
            utf8.encode(_jsonApi), 200,
            headers: {'content-type': 'application/json'})));
    final vm = OrcamentoViewModel(cache: MemoriaCacheLocal(), service: OrcamentoService(api: api));

    await vm.carregar();
    expect(vm.orcamentos.map((o) => o.id), [2, 1]); // mais recentes primeiro
    expect(vm.totalFiltrado, 275);

    vm.filtrarStatus(StatusOrcamento.aprovado);
    expect(vm.orcamentos.single.clienteNome, 'Bruno');
    expect(vm.contarPorStatus(StatusOrcamento.emAndamento), 1);

    vm.filtrarStatus(null);
    vm.buscar('ana');
    expect(vm.orcamentos.single.id, 1);
  });
}
