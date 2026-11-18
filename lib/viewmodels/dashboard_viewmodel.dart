import '../models/item.dart';
import '../models/orcamento.dart';
import 'cliente_viewmodel.dart';
import 'item_viewmodel.dart';
import 'orcamento_viewmodel.dart';

/// Indicadores do painel inicial.
///
/// Não busca nada na API: é recalculado a partir dos ViewModels de itens,
/// clientes e orçamentos. Em main.dart ele é fornecido por um ProxyProvider3,
/// que cria um novo DashboardViewModel sempre que um desses três notifica
/// mudança, então o painel está sempre sincronizado com o resto do app.
class DashboardViewModel {
  final int totalItens;
  final int unidadesEmEstoque;
  final double valorEstoque;
  final List<Item> itensEstoqueBaixo;
  final int totalClientes;
  final int orcamentosEmAberto;
  final double valorEmAberto;
  final double valorAprovado;
  final List<Orcamento> orcamentosRecentes;
  final bool carregando;
  final String? erro;

  const DashboardViewModel._({
    required this.totalItens,
    required this.unidadesEmEstoque,
    required this.valorEstoque,
    required this.itensEstoqueBaixo,
    required this.totalClientes,
    required this.orcamentosEmAberto,
    required this.valorEmAberto,
    required this.valorAprovado,
    required this.orcamentosRecentes,
    required this.carregando,
    required this.erro,
  });

  factory DashboardViewModel.calcular({
    required ItemViewModel itens,
    required ClienteViewModel clientes,
    required OrcamentoViewModel orcamentos,
  }) {
    final listaItens = itens.todos;
    final listaOrc = orcamentos.todos;

    final emAberto = listaOrc
        .where((o) => o.status == StatusOrcamento.emAndamento.valor)
        .toList();
    final aprovados = listaOrc
        .where((o) => o.status == StatusOrcamento.aprovado.valor);

    final recentes = [...listaOrc]
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    return DashboardViewModel._(
      totalItens: listaItens.length,
      unidadesEmEstoque:
          listaItens.fold(0, (s, i) => s + i.quantidadeEstoque),
      valorEstoque: listaItens.fold(
          0, (s, i) => s + i.precoUnitario * i.quantidadeEstoque),
      itensEstoqueBaixo: itens.itensEstoqueBaixo,
      totalClientes: clientes.todos.length,
      orcamentosEmAberto: emAberto.length,
      valorEmAberto: emAberto.fold(0, (s, o) => s + o.valorTotal),
      valorAprovado: aprovados.fold(0, (s, o) => s + o.valorTotal),
      orcamentosRecentes: recentes.take(5).toList(),
      carregando: itens.carregando || clientes.carregando || orcamentos.carregando,
      erro: itens.erro ?? clientes.erro ?? orcamentos.erro,
    );
  }
}
