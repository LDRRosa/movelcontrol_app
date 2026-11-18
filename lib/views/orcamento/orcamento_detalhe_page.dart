import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/orcamento.dart';
import '../../rotas.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/cliente_viewmodel.dart';
import '../../viewmodels/orcamento_viewmodel.dart';
import '../widgets/detalhe_widgets.dart';
import '../widgets/dialogos.dart';
import '../widgets/nao_encontrado.dart';
import 'status_orcamento_chip.dart';

/// Rota /orcamentos/:id. Lê o orçamento do OrcamentoViewModel, então reflete
/// na hora qualquer alteração feita na edição ou na troca de status.
class OrcamentoDetalhePage extends StatefulWidget {
  final int orcamentoId;

  const OrcamentoDetalhePage({super.key, required this.orcamentoId});

  @override
  State<OrcamentoDetalhePage> createState() => _OrcamentoDetalhePageState();
}

class _OrcamentoDetalhePageState extends State<OrcamentoDetalhePage> {
  /// Último valor exibido: evita piscar "não encontrado" logo após excluir.
  Orcamento? _ultimo;

  Future<void> _alterarStatus(Orcamento o, StatusOrcamento status) async {
    if (o.status == status.valor) return;
    final erro =
        await context.read<OrcamentoViewModel>().alterarStatus(o, status);
    if (!mounted) return;
    mostrarMensagem(context, erro ?? 'Status alterado para ${status.rotulo}.',
        erro: erro != null);
  }

  Future<void> _excluir(Orcamento o) async {
    if (!await confirmarExclusao(context, 'Orçamento #${o.id}')) return;
    if (!mounted) return;
    final erro = await context.read<OrcamentoViewModel>().excluir(o);
    if (!mounted) return;
    mostrarMensagem(context, erro ?? 'Orçamento excluído.', erro: erro != null);
    if (erro == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrcamentoViewModel>();
    final o = vm.buscarPorId(widget.orcamentoId) ?? _ultimo;
    if (o == null) return const NaoEncontradoPage();
    _ultimo = o;

    final tema = Theme.of(context);
    final clienteExiste =
        context.watch<ClienteViewModel>().buscarPorId(o.clienteId) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Orçamento #${o.id}'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, Rotas.orcamentoEditar(o.id!)),
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _excluir(o),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (vm.salvando) const LinearProgressIndicator(),
          // ---------- Cabeçalho ----------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusOrcamentoChip(status: o.status),
                      const Spacer(),
                      const Icon(Icons.event, size: 16),
                      const SizedBox(width: 4),
                      Text(Formatadores.data(o.dataCriacao)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Valor total', style: tema.textTheme.bodySmall),
                  Text(
                    Formatadores.moeda(o.valorTotal),
                    style: tema.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tema.colorScheme.primary),
                  ),
                  Text('${o.itens.length} item(ns) • ${o.quantidadeDeItens} unidade(s)',
                      style: tema.textTheme.bodySmall),
                ],
              ),
            ),
          ),

          // ---------- Cliente ----------
          const SecaoTitulo('Cliente'),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(o.clienteNome.isEmpty
                    ? '?'
                    : o.clienteNome[0].toUpperCase()),
              ),
              title: Text(o.clienteNome),
              subtitle: Text(clienteExiste
                  ? 'Toque para ver o cliente e o histórico'
                  : 'Cliente #${o.clienteId}'),
              trailing: clienteExiste ? const Icon(Icons.chevron_right) : null,
              onTap: clienteExiste
                  ? () => Navigator.pushNamed(context, Rotas.cliente(o.clienteId))
                  : null,
            ),
          ),

          // ---------- Status ----------
          const SecaoTitulo('Alterar status'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in StatusOrcamento.values)
                ChoiceChip(
                  label: Text(s.rotulo),
                  selected: o.status == s.valor,
                  onSelected:
                      vm.salvando ? null : (_) => _alterarStatus(o, s),
                ),
            ],
          ),

          // ---------- Itens ----------
          const SecaoTitulo('Itens'),
          Card(
            child: Column(
              children: [
                for (final item in o.itens)
                  ListTile(
                    title: Text(item.nome),
                    subtitle: Text(
                        '${item.quantidade} × ${Formatadores.moeda(item.precoUnitario)}'),
                    trailing: Text(Formatadores.moeda(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Total',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(
                    Formatadores.moeda(o.valorTotal),
                    style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tema.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
