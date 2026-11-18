import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movelcontrol_app/models/pedido_fornecedor.dart';
import 'package:movelcontrol_app/rotas.dart';
import 'package:movelcontrol_app/services/api_client.dart';
import 'package:movelcontrol_app/services/cliente_service.dart';
import 'package:movelcontrol_app/services/fornecedor_service.dart';
import 'package:movelcontrol_app/services/item_service.dart';
import 'package:movelcontrol_app/services/orcamento_service.dart';
import 'package:movelcontrol_app/viewmodels/cliente_viewmodel.dart';
import 'package:movelcontrol_app/viewmodels/dashboard_viewmodel.dart';
import 'package:movelcontrol_app/viewmodels/fornecedor_detalhe_viewmodel.dart';
import 'package:movelcontrol_app/viewmodels/item_viewmodel.dart';
import 'package:movelcontrol_app/viewmodels/navegacao_viewmodel.dart';
import 'package:movelcontrol_app/viewmodels/orcamento_viewmodel.dart';

/// Simula a API respondendo um JSON fixo por caminho.
ApiClient _apiFalsa(Map<String, Object> respostas) => ApiClient(
      httpClient: MockClient((req) async {
        final corpo = respostas[req.url.path];
        if (corpo == null) return http.Response('', 404);
        return http.Response.bytes(utf8.encode(jsonEncode(corpo)), 200,
            headers: {'content-type': 'application/json'});
      }),
    );

Map<String, Object> _item(int id, String nome, double preco, int qtd) => {
      'id': id,
      'nome': nome,
      'descricao': 'd',
      'unidadeMedida': 'UN',
      'precoUnitario': preco,
      'quantidade_estoque': qtd,
    };

Map<String, Object> _orc(int id, String status, double total, int clienteId) => {
      'id': id,
      'dataCriacao': '2026-11-18',
      'status': status,
      'valorTotal': total,
      'cliente': {'id': clienteId, 'nome': 'Cliente $clienteId'},
      'itens': <Object>[],
    };

void main() {
  final api = _apiFalsa({
    '/item/todos': [
      _item(1, 'MDF', 100, 10),
      _item(2, 'Cola', 20, 2),
      _item(3, 'Parafuso', 0.5, 0),
    ],
    '/pf/listar': [
      {
        'nome': 'Ana',
        'cpf': '52998224725',
        'links': [
          {'rel': 'busca por Id', 'href': 'http://localhost:8080/pf/7'}
        ],
      }
    ],
    '/orcamentos': [
      _orc(1, 'EM_ANDAMENTO', 300, 7),
      _orc(2, 'APROVADO', 500, 7),
      _orc(3, 'EM_ANDAMENTO', 150, 8),
    ],
    '/pFornecedor/buscar/fornecedor/4': [
      {
        'id': 1,
        'status': 'PENDENTE',
        'dataPedido': '2026-11-18T00:00:00.000+00:00',
        'itens': [
          {'itemId': 1, 'nome': 'MDF', 'quantidade': 20}
        ],
      },
      {'id': 2, 'status': 'RECEBIDO', 'dataPedido': null, 'itens': []},
    ],
  });

  late ItemViewModel itens;
  late ClienteViewModel clientes;
  late OrcamentoViewModel orcamentos;

  setUp(() async {
    itens = ItemViewModel(service: ItemService(api: api));
    clientes = ClienteViewModel(service: ClienteService(api: api));
    orcamentos = OrcamentoViewModel(service: OrcamentoService(api: api));
    await Future.wait(
        [itens.carregar(), clientes.carregar(), orcamentos.carregar()]);
  });

  test('painel calcula estoque, orçamentos em aberto e estoque baixo', () {
    final painel = DashboardViewModel.calcular(
        itens: itens, clientes: clientes, orcamentos: orcamentos);

    expect(painel.totalItens, 3);
    expect(painel.unidadesEmEstoque, 12);
    expect(painel.valorEstoque, 1040); // 100*10 + 20*2 + 0.5*0
    expect(painel.orcamentosEmAberto, 2);
    expect(painel.valorEmAberto, 450);
    expect(painel.valorAprovado, 500);
    expect(painel.totalClientes, 1);
    // Menor estoque primeiro.
    expect(painel.itensEstoqueBaixo.map((i) => i.nome), ['Parafuso', 'Cola']);
    expect(painel.orcamentosRecentes.first.id, 3);
  });

  test('filtro de estoque baixo na lista de itens', () {
    expect(itens.itens.length, 3);
    itens.mostrarSomenteEstoqueBaixo(true);
    expect(itens.itens.map((i) => i.id), [2, 3]);
    itens.filtrar('cola');
    expect(itens.itens.single.nome, 'Cola');
  });

  test('histórico de orçamentos do cliente e busca por id', () {
    expect(orcamentos.doCliente(7).map((o) => o.id), [2, 1]);
    expect(orcamentos.buscarPorId(3)?.clienteId, 8);
    expect(clientes.buscarPorId(7)?.nome, 'Ana');
    expect(itens.buscarPorId(99), isNull);
  });

  test('detalhe do fornecedor carrega pedidos (mais recentes primeiro)',
      () async {
    final vm = FornecedorDetalheViewModel(
        fornecedorId: 4, service: FornecedorService(api: api));
    await vm.carregarPedidos();
    expect(vm.erro, isNull);
    expect(vm.pedidos.map((p) => p.id), [2, 1]);
    expect(vm.unidadesCompradas, 20);
    expect(vm.pedidos.last.dataPedido, DateTime(2026, 11, 18));
  });

  test('PedidoFornecedor aceita data nula', () {
    final p = PedidoFornecedor.fromJson(
        {'id': 9, 'status': 'X', 'dataPedido': null, 'itens': []});
    expect(p.dataPedido, isNull);
  });

  test('navegação troca destino e aba de cadastro', () {
    final nav = NavegacaoViewModel();
    expect(nav.destino, Destino.inicio);
    nav.abrirCadastro(AbaCadastro.clientes);
    expect(nav.destino, Destino.cadastros);
    expect(nav.abaCadastro, AbaCadastro.clientes);
  });

  test('caminhos das rotas nomeadas', () {
    expect(Rotas.orcamento(7), '/orcamentos/7');
    expect(Rotas.clienteEditar(3), '/clientes/3/editar');
    expect(Rotas.itemEditar(1), '/itens/1/editar');
    expect(Rotas.fornecedor(4), '/fornecedores/4');
  });
}
