import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/cliente.dart';
import 'viewmodels/cliente_viewmodel.dart';
import 'viewmodels/fornecedor_detalhe_viewmodel.dart';
import 'viewmodels/fornecedor_viewmodel.dart';
import 'viewmodels/item_viewmodel.dart';
import 'viewmodels/orcamento_form_viewmodel.dart';
import 'viewmodels/orcamento_viewmodel.dart';
import 'views/cliente/cliente_detalhe_page.dart';
import 'views/cliente/cliente_form_page.dart';
import 'views/fornecedor/fornecedor_detalhe_page.dart';
import 'views/fornecedor/fornecedor_form_page.dart';
import 'views/home_page.dart';
import 'views/item/item_form_page.dart';
import 'views/orcamento/orcamento_detalhe_page.dart';
import 'views/orcamento/orcamento_form_page.dart';
import 'views/widgets/nao_encontrado.dart';

/// Rotas nomeadas do app, centralizadas em um único lugar.
///
/// As rotas levam apenas o id (ex.: /orcamentos/7). A tela busca o registro no
/// ViewModel correspondente, que é a fonte única da verdade: assim a tela de
/// detalhe sempre mostra o dado atualizado depois de uma edição.
class Rotas {
  static const inicio = '/';

  static const itemNovo = '/itens/novo';
  static String itemEditar(int id) => '/itens/$id/editar';

  static const clienteNovo = '/clientes/novo';
  static String cliente(int id) => '/clientes/$id';
  static String clienteEditar(int id) => '/clientes/$id/editar';

  static const fornecedorNovo = '/fornecedores/novo';
  static String fornecedor(int id) => '/fornecedores/$id';
  static String fornecedorEditar(int id) => '/fornecedores/$id/editar';

  /// Aceita `arguments: clienteId` para já abrir com o cliente escolhido.
  static const orcamentoNovo = '/orcamentos/novo';
  static String orcamento(int id) => '/orcamentos/$id';
  static String orcamentoEditar(int id) => '/orcamentos/$id/editar';

  /// Usado em MaterialApp.onGenerateRoute.
  static Route<dynamic> gerar(RouteSettings settings) {
    final segmentos = Uri.parse(settings.name ?? '/').pathSegments;

    // Pattern matching de listas (Dart 3) para interpretar o caminho.
    final Widget tela = switch (segmentos) {
      [] => const HomePage(),
      ['itens', 'novo'] => const ItemFormPage(),
      ['itens', final id, 'editar'] => _comRegistro(
          id, (ctx, i) => ctx.read<ItemViewModel>().buscarPorId(i),
          (item) => ItemFormPage(item: item)),
      ['clientes', 'novo'] => const ClienteFormPage(),
      ['clientes', final id] when _ehNumero(id) =>
        ClienteDetalhePage(clienteId: int.parse(id)),
      ['clientes', final id, 'editar'] => _comRegistro(
          id, (ctx, i) => ctx.read<ClienteViewModel>().buscarPorId(i),
          (c) => ClienteFormPage(cliente: c)),
      ['fornecedores', 'novo'] => const FornecedorFormPage(),
      ['fornecedores', final id] when _ehNumero(id) => ChangeNotifierProvider(
          create: (_) =>
              FornecedorDetalheViewModel(fornecedorId: int.parse(id))
                ..carregarPedidos(),
          child: FornecedorDetalhePage(fornecedorId: int.parse(id)),
        ),
      ['fornecedores', final id, 'editar'] => _comRegistro(
          id, (ctx, i) => ctx.read<FornecedorViewModel>().buscarPorId(i),
          (f) => FornecedorFormPage(fornecedor: f)),
      ['orcamentos', 'novo'] => ChangeNotifierProvider(
          create: (ctx) {
            final vm = OrcamentoFormViewModel();
            final clienteId = settings.arguments;
            if (clienteId is int) {
              final Cliente? cliente =
                  ctx.read<ClienteViewModel>().buscarPorId(clienteId);
              if (cliente != null) vm.selecionarCliente(cliente);
            }
            return vm;
          },
          child: const OrcamentoFormPage(),
        ),
      ['orcamentos', final id] when _ehNumero(id) =>
        OrcamentoDetalhePage(orcamentoId: int.parse(id)),
      ['orcamentos', final id, 'editar'] => _comRegistro(
          id, (ctx, i) => ctx.read<OrcamentoViewModel>().buscarPorId(i),
          (o) => ChangeNotifierProvider(
                create: (_) => OrcamentoFormViewModel(orcamento: o),
                child: const OrcamentoFormPage(),
              )),
      _ => const NaoEncontradoPage(),
    };

    return MaterialPageRoute(settings: settings, builder: (_) => tela);
  }

  static bool _ehNumero(String texto) => int.tryParse(texto) != null;

  /// Busca o registro pelo id no ViewModel e monta a tela com ele,
  /// ou mostra "não encontrado" (ex.: registro excluído ou id inválido).
  static Widget _comRegistro<T>(
    String id,
    T? Function(BuildContext, int) buscar,
    Widget Function(T) construir,
  ) {
    final numero = int.tryParse(id);
    if (numero == null) return const NaoEncontradoPage();
    return Builder(builder: (context) {
      final registro = buscar(context, numero);
      return registro == null ? const NaoEncontradoPage() : construir(registro);
    });
  }
}
