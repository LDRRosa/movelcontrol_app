import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../models/orcamento.dart';
import '../../rotas.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/cliente_viewmodel.dart';
import '../../viewmodels/orcamento_viewmodel.dart';
import '../orcamento/orcamento_tile.dart';
import '../widgets/detalhe_widgets.dart';
import '../widgets/dialogos.dart';
import '../widgets/nao_encontrado.dart';

/// Rota /clientes/:id: dados do cliente e histórico de orçamentos.
/// Combina dois ViewModels: ClienteViewModel (dados) e OrcamentoViewModel
/// (histórico filtrado pelo id do cliente).
class ClienteDetalhePage extends StatefulWidget {
  final int clienteId;

  const ClienteDetalhePage({super.key, required this.clienteId});

  @override
  State<ClienteDetalhePage> createState() => _ClienteDetalhePageState();
}

class _ClienteDetalhePageState extends State<ClienteDetalhePage> {
  Cliente? _ultimo;

  Future<void> _excluir(Cliente c) async {
    if (!await confirmarExclusao(context, c.nome)) return;
    if (!mounted) return;
    final erro = await context.read<ClienteViewModel>().excluir(c);
    if (!mounted) return;
    mostrarMensagem(context, erro ?? 'Cliente excluído.', erro: erro != null);
    if (erro == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c =
        context.watch<ClienteViewModel>().buscarPorId(widget.clienteId) ?? _ultimo;
    if (c == null) return const NaoEncontradoPage();
    _ultimo = c;

    final historico =
        context.watch<OrcamentoViewModel>().doCliente(widget.clienteId);
    final aprovados = historico
        .where((o) => o.status == StatusOrcamento.aprovado.valor)
        .fold<double>(0, (s, o) => s + o.valorTotal);
    final emAberto = historico
        .where((o) => o.status == StatusOrcamento.emAndamento.valor)
        .length;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cliente'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, Rotas.clienteEditar(c.id!)),
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _excluir(c),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_cliente_orcamento',
        onPressed: () => Navigator.pushNamed(context, Rotas.orcamentoNovo,
            arguments: c.id),
        icon: const Icon(Icons.add),
        label: const Text('Novo orçamento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // ---------- Cabeçalho ----------
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Text(c.nome.isEmpty ? '?' : c.nome[0].toUpperCase(),
                    style: tema.textTheme.headlineSmall),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.nome, style: tema.textTheme.titleLarge),
                    Text('CPF ${Formatadores.cpf(c.cpf)}',
                        style: tema.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Indicador(valor: '${historico.length}', rotulo: 'orçamentos'),
              Indicador(valor: '$emAberto', rotulo: 'em aberto'),
              Indicador(
                  valor: Formatadores.moeda(aprovados),
                  rotulo: 'aprovado',
                  cor: Colors.green.shade700),
            ],
          ),

          // ---------- Contato ----------
          const SecaoTitulo('Contato'),
          Card(
            child: Column(
              children: [
                LinhaInfo(
                    icone: Icons.email_outlined, rotulo: 'E-mail', valor: c.email),
                LinhaInfo(
                    icone: Icons.phone_outlined,
                    rotulo: 'Telefone',
                    valor: c.telefone),
              ],
            ),
          ),
          const SecaoTitulo('Endereço'),
          CartaoEndereco(endereco: c.endereco),

          // ---------- Histórico ----------
          const SecaoTitulo('Histórico de orçamentos'),
          if (historico.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.history),
                title: Text('Nenhum orçamento para este cliente'),
              ),
            )
          else
            for (final o in historico)
              OrcamentoTile(orcamento: o, mostrarCliente: false),
        ],
      ),
    );
  }
}
