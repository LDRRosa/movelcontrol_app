import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/fornecedor.dart';
import '../../models/pedido_fornecedor.dart';
import '../../rotas.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/fornecedor_detalhe_viewmodel.dart';
import '../../viewmodels/fornecedor_viewmodel.dart';
import '../widgets/detalhe_widgets.dart';
import '../widgets/dialogos.dart';
import '../widgets/nao_encontrado.dart';

/// Rota /fornecedores/:id: dados do fornecedor e pedidos de compra feitos a
/// ele. Os pedidos vêm do FornecedorDetalheViewModel, criado junto com a rota.
class FornecedorDetalhePage extends StatefulWidget {
  final int fornecedorId;

  const FornecedorDetalhePage({super.key, required this.fornecedorId});

  @override
  State<FornecedorDetalhePage> createState() => _FornecedorDetalhePageState();
}

class _FornecedorDetalhePageState extends State<FornecedorDetalhePage> {
  Fornecedor? _ultimo;

  Future<void> _excluir(Fornecedor f) async {
    if (!await confirmarExclusao(context, f.nome)) return;
    if (!mounted) return;
    final erro = await context.read<FornecedorViewModel>().excluir(f);
    if (!mounted) return;
    mostrarMensagem(context, erro ?? 'Fornecedor excluído.',
        erro: erro != null);
    if (erro == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FornecedorViewModel>().buscarPorId(widget.fornecedorId) ??
        _ultimo;
    if (f == null) return const NaoEncontradoPage();
    _ultimo = f;

    final detalhe = context.watch<FornecedorDetalheViewModel>();
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedor'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, Rotas.fornecedorEditar(f.id!)),
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _excluir(f),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: detalhe.carregarPedidos,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ---------- Cabeçalho ----------
            Row(
              children: [
                const CircleAvatar(
                    radius: 28, child: Icon(Icons.local_shipping, size: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.nome, style: tema.textTheme.titleLarge),
                      Text('CNPJ ${Formatadores.cnpj(f.cnpj)}',
                          style: tema.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Indicador(
                    valor: detalhe.carregando ? '…' : '${detalhe.pedidos.length}',
                    rotulo: 'pedidos'),
                Indicador(
                    valor: detalhe.carregando
                        ? '…'
                        : '${detalhe.unidadesCompradas}',
                    rotulo: 'unidades compradas'),
              ],
            ),

            const SecaoTitulo('Contato'),
            Card(
              child: Column(
                children: [
                  LinhaInfo(
                      icone: Icons.email_outlined,
                      rotulo: 'E-mail',
                      valor: f.email),
                  LinhaInfo(
                      icone: Icons.phone_outlined,
                      rotulo: 'Telefone',
                      valor: f.telefone),
                ],
              ),
            ),
            const SecaoTitulo('Endereço'),
            CartaoEndereco(endereco: f.endereco),

            // ---------- Pedidos ----------
            const SecaoTitulo('Pedidos de compra'),
            if (detalhe.carregando)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (detalhe.erro != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off),
                  title: Text(detalhe.erro!),
                  trailing: TextButton(
                    onPressed: detalhe.carregarPedidos,
                    child: const Text('Tentar de novo'),
                  ),
                ),
              )
            else if (detalhe.pedidos.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('Nenhum pedido feito a este fornecedor'),
                ),
              )
            else
              for (final p in detalhe.pedidos) _PedidoCard(pedido: p),
          ],
        ),
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final PedidoFornecedor pedido;

  const _PedidoCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Pedido #${pedido.id}', style: tema.textTheme.titleSmall),
                const SizedBox(width: 8),
                Chip(
                  label: Text(pedido.status.replaceAll('_', ' ')),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(Formatadores.data(pedido.dataPedido),
                    style: tema.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            for (final i in pedido.itens)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• ${i.quantidade} × ${i.nome}'),
              ),
          ],
        ),
      ),
    );
  }
}
