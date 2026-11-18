import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movelcontrol_app/models/item.dart';
import 'package:movelcontrol_app/services/api_client.dart';
import 'package:movelcontrol_app/services/cliente_service.dart';
import 'package:movelcontrol_app/services/fornecedor_service.dart';
import 'package:movelcontrol_app/services/item_service.dart';
import 'package:movelcontrol_app/viewmodels/item_viewmodel.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

void main() {
  test('extrai o id do cliente a partir dos links HATEOAS', () {
    expect(
      ClienteService.extrairId({
        'nome': 'Ana',
        'links': [
          {'rel': 'busca por Id', 'href': 'http://localhost:8080/pf/7'},
          {'rel': 'busca por Nome', 'href': 'http://localhost:8080/pf/nome/Ana'},
        ],
      }),
      7,
    );
    expect(
      ClienteService.extrairId({
        '_links': {
          'self': {'href': 'http://localhost:8080/pf/12'}
        },
      }),
      12,
    );
    expect(ClienteService.extrairId({'nome': 'Sem links'}), isNull);
  });

  test('lê a coleção HAL de fornecedores (com e sem registros)', () {
    final lista = FornecedorService.extrairLista({
      '_embedded': {
        'fornecedorResponseDTOList': [
          {'id': 1, 'nome': 'Madeireira'}
        ]
      }
    });
    expect(lista.single['nome'], 'Madeireira');
    expect(FornecedorService.extrairLista(<String, dynamic>{}), isEmpty);
  });

  test('ApiClient usa a mensagem do ErrorResponseDTO', () async {
    final api = ApiClient(
      httpClient: MockClient((_) async => http.Response(
          jsonEncode({'status': 409, 'message': 'CNPJ já cadastrado'}), 409, headers: _json)),
    );
    expect(
      () => api.get('/fornecedor/buscartudo'),
      throwsA(isA<ApiException>()
          .having((e) => e.mensagem, 'mensagem', 'CNPJ já cadastrado')
          .having((e) => e.statusCode, 'statusCode', 409)),
    );
  });

  test('ItemViewModel carrega, cria e filtra itens', () async {
    final mock = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
            jsonEncode([
              {
                'id': 1,
                'nome': 'MDF Branco',
                'descricao': 'Chapa 15mm',
                'unidadeMedida': 'UN',
                'precoUnitario': 189.9,
                'quantidade_estoque': 10,
              }
            ]),
            200, headers: _json);
      }
      final corpo = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({...corpo, 'id': 2}), 200, headers: _json);
    });

    final vm = ItemViewModel(
        service: ItemService(api: ApiClient(httpClient: mock)));

    await vm.carregar();
    expect(vm.itens.single.quantidadeEstoque, 10);

    final erro = await vm.salvar(const Item(
      nome: 'Dobradiça',
      descricao: 'Dobradiça 35mm',
      unidadeMedida: 'UN',
      precoUnitario: 4.5,
      quantidadeEstoque: 100,
    ));
    expect(erro, isNull);
    expect(vm.itens.length, 2);

    vm.filtrar('dobra');
    expect(vm.itens.single.id, 2);
  });
}
