import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movelcontrol_app/config/api_config.dart';
import 'package:movelcontrol_app/models/item.dart';
import 'package:movelcontrol_app/models/orcamento.dart';
import 'package:movelcontrol_app/repositories/configuracoes_repository.dart';
import 'package:movelcontrol_app/repositories/repositorio_com_cache.dart';
import 'package:movelcontrol_app/services/api_client.dart';
import 'package:movelcontrol_app/services/cache_local_service.dart';
import 'package:movelcontrol_app/services/cep_service.dart';
import 'package:movelcontrol_app/services/item_service.dart';
import 'package:movelcontrol_app/utils/formatadores.dart';
import 'package:movelcontrol_app/utils/mascaras.dart';
import 'package:movelcontrol_app/viewmodels/configuracoes_viewmodel.dart';
import 'package:movelcontrol_app/viewmodels/endereco_form_viewmodel.dart';
import 'package:movelcontrol_app/viewmodels/item_viewmodel.dart';
import 'package:movelcontrol_app/viewmodels/orcamento_form_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mdf = Item(
    id: 1,
    nome: 'MDF',
    descricao: 'Chapa',
    unidadeMedida: 'UN',
    precoUnitario: 100,
    quantidadeEstoque: 3);

/// Deixa terminar gravações assíncronas disparadas sem await.
Future<void> _esperar() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => ApiConfig.definirUrl(null));

  group('Cache offline (RepositorioComCache)', () {
    RepositorioComCache<Item> repositorio(CacheLocal cache) =>
        RepositorioComCache<Item>(
          chave: 'itens',
          cache: cache,
          paraJson: (i) => i.toJson(),
          deJson: Item.fromJson,
        );

    test('salva no cache quando a API responde e usa o cache sem conexão',
        () async {
      final cache = MemoriaCacheLocal();
      final repo = repositorio(cache);

      final online = await repo.carregar(() async => [_mdf]);
      expect(online.doCache, isFalse);

      final offline = await repo.carregar(
          () async => throw ApiException('Sem conexão')); // sem statusCode
      expect(offline.doCache, isTrue);
      expect(offline.dados.single.nome, 'MDF');
      expect(offline.dados.single.quantidadeEstoque, 3);
    });

    test('erro respondido pelo servidor não é escondido pelo cache', () async {
      final cache = MemoriaCacheLocal();
      final repo = repositorio(cache);
      await repo.carregar(() async => [_mdf]);

      expect(
        () => repo.carregar(
            () async => throw ApiException('Erro', statusCode: 500)),
        throwsA(isA<ApiException>()),
      );
    });

    test('sem conexão e sem cache, o erro chega ao ViewModel', () async {
      final repo = repositorio(MemoriaCacheLocal());
      expect(() => repo.carregar(() async => throw ApiException('x')),
          throwsA(isA<ApiException>()));
    });

    test('ItemViewModel entra em modo offline quando a API cai', () async {
      var online = true;
      final api = ApiClient(
        httpClient: MockClient((_) async {
          if (!online) throw http.ClientException('sem rede');
          return http.Response(jsonEncode([_mdf.toJson()]), 200);
        }),
      );
      final vm =
          ItemViewModel(cache: MemoriaCacheLocal(), service: ItemService(api: api));

      await vm.carregar();
      expect(vm.offline, isFalse);

      online = false;
      await vm.carregar();
      expect(vm.erro, isNull);
      expect(vm.offline, isTrue);
      expect(vm.avisoOffline, contains('Sem conexão'));
      expect(vm.itens.single.nome, 'MDF');
    });
  });

  group('Configurações (shared_preferences)', () {
    test('valores padrão e persistência do tema e do estoque mínimo',
        () async {
      final vm = ConfiguracoesViewModel(cache: MemoriaCacheLocal());
      await vm.carregar();
      expect(vm.tema, ThemeMode.system);
      expect(vm.estoqueMinimo, ConfiguracoesViewModel.estoqueMinimoPadrao);

      await vm.alterarTema(ThemeMode.dark);
      await vm.alterarEstoqueMinimo(10);

      final reaberto = ConfiguracoesViewModel(cache: MemoriaCacheLocal());
      await reaberto.carregar();
      expect(reaberto.tema, ThemeMode.dark);
      expect(reaberto.estoqueMinimo, 10);
    });

    test('URL personalizada passa a ser usada pela API', () async {
      final vm = ConfiguracoesViewModel(cache: MemoriaCacheLocal());
      await vm.carregar();
      await vm.salvarUrlApi('http://192.168.0.10:8080/');
      expect(ApiConfig.baseUrl, 'http://192.168.0.10:8080');

      await vm.salvarUrlApi('');
      expect(ApiConfig.baseUrl, ApiConfig.urlPadrao);
    });

    test('validação da URL', () {
      expect(ConfiguracoesViewModel.validarUrl(''), isNull);
      expect(ConfiguracoesViewModel.validarUrl('http://10.0.2.2:8080'), isNull);
      expect(ConfiguracoesViewModel.validarUrl('localhost:8080'), isNotNull);
      expect(ConfiguracoesViewModel.validarUrl('ftp://x'), isNotNull);
    });
  });

  group('Rascunho de orçamento', () {
    test('é salvo a cada alteração e restaurado ao reabrir', () async {
      final repo = RascunhoOrcamentoRepository();
      final form = OrcamentoFormViewModel(rascunho: repo);
      form.adicionarItem(_mdf);
      form.alterarQuantidade(1, 4);
      form.alterarStatus(StatusOrcamento.aprovado);
      await _esperar();

      // "App fechado e aberto de novo": novo ViewModel, mesmo armazenamento.
      final reaberto = OrcamentoFormViewModel(rascunho: repo);
      expect(await reaberto.restaurarRascunho(), isTrue);
      expect(reaberto.linhas.single.quantidade, 4);
      expect(reaberto.total, 400);
      expect(reaberto.status, StatusOrcamento.aprovado);

      await reaberto.descartarRascunho();
      final terceiro = OrcamentoFormViewModel(rascunho: repo);
      expect(await terceiro.restaurarRascunho(), isFalse);
    });

    test('edição de orçamento existente não usa rascunho', () async {
      final repo = RascunhoOrcamentoRepository();
      await repo.salvar({
        'clienteId': 9,
        'linhas': [
          {'itemId': 1, 'nome': 'MDF', 'precoUnitario': 100, 'quantidade': 2}
        ],
      });
      final edicao = OrcamentoFormViewModel(
        orcamento: const Orcamento(
            id: 5, status: 'EM_ANDAMENTO', clienteId: 1, clienteNome: 'A', itens: []),
        rascunho: repo,
      );
      expect(await edicao.restaurarRascunho(), isFalse);
    });
  });

  group('Máscaras de digitação', () {
    test('CPF, CNPJ e CEP', () {
      expect(Mascaras.cpf.aplicar('52998224725'), '529.982.247-25');
      expect(Mascaras.cpf.aplicar('529982'), '529.982');
      expect(Mascaras.cpf.aplicar('5299822472599'), '529.982.247-25');
      expect(Mascaras.cnpj.aplicar('11222333000181'), '11.222.333/0001-81');
      expect(Mascaras.cep.aplicar('75790000'), '75790-000');
    });

    test('telefone fixo e celular', () {
      expect(Mascaras.telefone.aplicar('6233334444'), '(62) 3333-4444');
      expect(Mascaras.telefone.aplicar('62933334444'), '(62) 93333-4444');
    });

    test('moeda é digitada pelos centavos', () {
      expect(Mascaras.moeda.aplicar('1250'), '12,50');
      expect(Mascaras.moeda.aplicar('123456'), '1.234,56');
      expect(Mascaras.moeda.aplicar(''), '');
      expect(Formatadores.parseMoeda('1.234,56'), 1234.56);
      expect(Formatadores.moeda(1234.5), r'R$ 1.234,50');
    });

    test('formatter devolve o cursor no fim do texto', () {
      final r = Mascaras.cpf.formatEditUpdate(
          TextEditingValue.empty, const TextEditingValue(text: '5299822'));
      expect(r.text, '529.982.2');
      expect(r.selection.baseOffset, r.text.length);
    });
  });

  group('CEP automático (ViaCEP)', () {
    final viaCep = MockClient((req) async {
      final cep = req.url.pathSegments[1];
      if (cep == '75790000') {
        return http.Response.bytes(
            utf8.encode(jsonEncode({
              'logradouro': 'Rodovia Geraldo Silva Nascimento',
              'bairro': 'Zona Rural',
              'localidade': 'Urutaí',
              'uf': 'GO',
            })),
            200);
      }
      return http.Response('{"erro": true}', 200);
    });

    test('CepService encontra e trata CEP inexistente', () async {
      final service = CepService(httpClient: viaCep);
      expect((await service.buscar('75790-000'))?.cidade, 'Urutaí');
      expect(await service.buscar('00000000'), isNull);
      expect(await service.buscar('123'), isNull);
    });

    test('preenche rua e bairro sem apagar o que o usuário digitou', () async {
      final vm = EnderecoFormViewModel(cepService: CepService(httpClient: viaCep));
      vm.bairro.text = 'Centro'; // digitado pelo usuário
      vm.cep.text = '75790-000';
      await _esperar();

      expect(vm.rua.text, 'Rodovia Geraldo Silva Nascimento');
      expect(vm.bairro.text, 'Centro');
      expect(vm.cidadeUf, 'Urutaí - GO');

      vm.cep.text = '00000-000';
      await _esperar();
      expect(vm.erroCep, 'CEP não encontrado');
      vm.dispose();
    });
  });
}
