import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/orcamento.dart';
import '../../rotas.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/orcamento_viewmodel.dart';
import '../widgets/dialogos.dart';
import '../widgets/lista_com_estado.dart';
import 'status_orcamento_chip.dart';

/// Destino "Orçamentos": lista, filtra por status e abre detalhe/cadastro.
/// (O rascunho do formulário, OrcamentoFormViewModel, é criado na rota em
/// rotas.dart: cada formulário aberto tem o seu, descartado ao fechar.)
class OrcamentoListView extends StatelessWidget {
  const OrcamentoListView({super.key});

  Future<void> _excluir(BuildContext context, Orcamento orcamento) async {
    if (!await confirmarExclusao(context, 'Orçamento #${orcamento.id}')) {
      return;
    }
    if (!context.mounted) return;
    final erro = await context.read<OrcamentoViewModel>().excluir(orcamento);
    if (!context.mounted) return;
    mostrarMensagem(context, erro ?? 'Orçamento excluído.', erro: erro != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos')),
      body: Consumer<OrcamentoViewModel>(
        builder: (context, vm, child) {
          final orcamentos = vm.orcamentos;
          return ListaComEstado(
            carregando: vm.carregando,
            erro: vm.erro,
            semRegistros: vm.vazio,
            quantidade: orcamentos.length,
            textoVazio:
                'Nenhum orçamento cadastrado.\nToque em + para criar o primeiro.',
            dicaBusca: 'Buscar por cliente ou nº do orçamento',
            onBuscar: vm.buscar,
            onAtualizar: vm.carregar,
            cabecalho: _Filtros(vm: vm, quantidadeVisivel: orcamentos.length),
            itemBuilder: (context, index) => _OrcamentoCard(
              orcamento: orcamentos[index],
              onTap: () => Navigator.pushNamed(
                  context, Rotas.orcamento(orcamentos[index].id!)),
              onExcluir: () => _excluir(context, orcamentos[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_orcamento',
        onPressed: () => Navigator.pushNamed(context, Rotas.orcamentoNovo),
        icon: const Icon(Icons.add),
        label: const Text('Novo orçamento'),
      ),
    );
  }
}

/// Chips de status + resumo (quantidade e soma dos orçamentos filtrados).
class _Filtros extends StatelessWidget {
  final OrcamentoViewModel vm;
  final int quantidadeVisivel;

  const _Filtros({required this.vm, required this.quantidadeVisivel});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: vm.statusFiltro == null,
                onSelected: (_) => vm.filtrarStatus(null),
              ),
              for (final status in StatusOrcamento.values) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('${status.rotulo} (${vm.contarPorStatus(status)})'),
                  selected: vm.statusFiltro == status,
                  onSelected: (_) => vm.filtrarStatus(status),
                ),
              ],
            ],
          ),
        ),
        if (!vm.vazio)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              '$quantidadeVisivel orçamento(s) • '
              'Total: ${Formatadores.moeda(vm.totalFiltrado)}',
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _OrcamentoCard extends StatelessWidget {
  final Orcamento orcamento;
  final VoidCallback onTap;
  final VoidCallback onExcluir;

  const _OrcamentoCard({
    required this.orcamento,
    required this.onTap,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final o = orcamento;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('#${o.id}',
                            style: tema.textTheme.labelLarge
                                ?.copyWith(color: tema.colorScheme.primary)),
                        const SizedBox(width: 8),
                        StatusOrcamentoChip(status: o.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(o.clienteNome.isEmpty ? 'Cliente não informado' : o.clienteNome,
                        style: tema.textTheme.titleMedium),
                    Text(
                      '${Formatadores.data(o.dataCriacao)} • '
                      '${o.itens.length} item(ns), ${o.quantidadeDeItens} unid.',
                      style: tema.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatadores.moeda(o.valorTotal),
                    style: tema.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onExcluir,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
