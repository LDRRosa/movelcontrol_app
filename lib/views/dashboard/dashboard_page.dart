import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/orcamento.dart';
import '../../rotas.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/cliente_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/item_viewmodel.dart';
import '../../viewmodels/navegacao_viewmodel.dart';
import '../../viewmodels/orcamento_viewmodel.dart';
import '../orcamento/orcamento_tile.dart';
import '../widgets/detalhe_widgets.dart';

/// Destino "Início": indicadores do negócio, alertas e atalhos.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _atualizarTudo(BuildContext context) => Future.wait([
        context.read<ItemViewModel>().carregar(),
        context.read<ClienteViewModel>().carregar(),
        context.read<OrcamentoViewModel>().carregar(),
      ]);

  void _verEstoqueBaixo(BuildContext context) {
    context.read<ItemViewModel>().mostrarSomenteEstoqueBaixo(true);
    context.read<NavegacaoViewModel>().abrirCadastro(AbaCadastro.itens);
  }

  void _verOrcamentosEmAberto(BuildContext context) {
    context.read<OrcamentoViewModel>().filtrarStatus(StatusOrcamento.emAndamento);
    context.read<NavegacaoViewModel>().irPara(Destino.orcamentos);
  }

  @override
  Widget build(BuildContext context) {
    final painel = context.watch<DashboardViewModel>();
    final tema = Theme.of(context);
    final larguraTela = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MovelControl'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => _atualizarTudo(context),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _atualizarTudo(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (painel.carregando) const LinearProgressIndicator(),
            if (painel.erro != null)
              Card(
                color: tema.colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(Icons.cloud_off,
                      color: tema.colorScheme.onErrorContainer),
                  title: Text(painel.erro!,
                      style:
                          TextStyle(color: tema.colorScheme.onErrorContainer)),
                  trailing: TextButton(
                    onPressed: () => _atualizarTudo(context),
                    child: const Text('Tentar de novo'),
                  ),
                ),
              ),
            const SecaoTitulo('Visão geral'),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: larguraTela > 700 ? 4 : 2,
                mainAxisExtent: 128,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              children: [
                _CardIndicador(
                  icone: Icons.inventory_2_outlined,
                  titulo: 'Itens no estoque',
                  valor: '${painel.totalItens}',
                  detalhe: '${painel.unidadesEmEstoque} unidades',
                  onTap: () => context
                      .read<NavegacaoViewModel>()
                      .abrirCadastro(AbaCadastro.itens),
                ),
                _CardIndicador(
                  icone: Icons.payments_outlined,
                  titulo: 'Valor do estoque',
                  valor: Formatadores.moeda(painel.valorEstoque),
                  detalhe: '${painel.totalClientes} cliente(s) cadastrado(s)',
                ),
                _CardIndicador(
                  icone: Icons.request_quote_outlined,
                  titulo: 'Orçamentos em aberto',
                  valor: '${painel.orcamentosEmAberto}',
                  detalhe: Formatadores.moeda(painel.valorEmAberto),
                  onTap: () => _verOrcamentosEmAberto(context),
                ),
                _CardIndicador(
                  icone: Icons.warning_amber_rounded,
                  titulo: 'Estoque baixo',
                  valor: '${painel.itensEstoqueBaixo.length}',
                  detalhe: 'abaixo de ${ItemViewModel.estoqueMinimo} unid.',
                  alerta: painel.itensEstoqueBaixo.isNotEmpty,
                  onTap: () => _verEstoqueBaixo(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Total aprovado em orçamentos: '
                '${Formatadores.moeda(painel.valorAprovado)}',
                style: tema.textTheme.bodyMedium,
              ),
            ),

            const SecaoTitulo('Atalhos'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, Rotas.orcamentoNovo),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo orçamento'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.pushNamed(context, Rotas.itemNovo),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Novo item'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      Navigator.pushNamed(context, Rotas.clienteNovo),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Novo cliente'),
                ),
              ],
            ),

            if (painel.itensEstoqueBaixo.isNotEmpty) ...[
              SecaoTitulo(
                'Estoque baixo',
                acao: TextButton(
                  onPressed: () => _verEstoqueBaixo(context),
                  child: const Text('Ver todos'),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (final item in painel.itensEstoqueBaixo.take(5))
                      ListTile(
                        leading: Icon(Icons.warning_amber_rounded,
                            color: tema.colorScheme.error),
                        title: Text(item.nome),
                        subtitle: Text(item.descricao,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          '${item.quantidadeEstoque} ${item.unidadeMedida}',
                          style: TextStyle(
                              color: tema.colorScheme.error,
                              fontWeight: FontWeight.bold),
                        ),
                        onTap: () => Navigator.pushNamed(
                            context, Rotas.itemEditar(item.id!)),
                      ),
                  ],
                ),
              ),
            ],

            SecaoTitulo(
              'Orçamentos recentes',
              acao: TextButton(
                onPressed: () {
                  context.read<OrcamentoViewModel>().filtrarStatus(null);
                  context.read<NavegacaoViewModel>().irPara(Destino.orcamentos);
                },
                child: const Text('Ver todos'),
              ),
            ),
            if (painel.orcamentosRecentes.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.inbox_outlined),
                  title: Text('Nenhum orçamento ainda'),
                  subtitle: Text('Use "Novo orçamento" para começar.'),
                ),
              )
            else
              for (final o in painel.orcamentosRecentes) OrcamentoTile(orcamento: o),
          ],
        ),
      ),
    );
  }
}

class _CardIndicador extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final String detalhe;
  final bool alerta;
  final VoidCallback? onTap;

  const _CardIndicador({
    required this.icone,
    required this.titulo,
    required this.valor,
    required this.detalhe,
    this.alerta = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final corFundo = alerta ? tema.colorScheme.errorContainer : null;
    final corTexto =
        alerta ? tema.colorScheme.onErrorContainer : tema.colorScheme.primary;

    return Card(
      color: corFundo,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icone, size: 20, color: corTexto),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(titulo,
                        style: tema.textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right,
                        size: 18, color: tema.colorScheme.outline),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valor,
                    style: tema.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: corTexto)),
              ),
              Text(detalhe,
                  style: tema.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
