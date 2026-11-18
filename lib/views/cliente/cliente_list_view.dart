import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/cliente_viewmodel.dart';
import '../widgets/dialogos.dart';
import '../widgets/lista_com_estado.dart';
import '../../rotas.dart';

/// Aba "Clientes" (pessoa física).
class ClienteListView extends StatelessWidget {
  const ClienteListView({super.key});

  /// Cliente existente abre o detalhe (com histórico); sem cliente, o cadastro.
  void _abrir(BuildContext context, [Cliente? cliente]) {
    Navigator.pushNamed(context,
        cliente == null ? Rotas.clienteNovo : Rotas.cliente(cliente.id!));
  }

  Future<void> _excluir(BuildContext context, Cliente cliente) async {
    if (!await confirmarExclusao(context, cliente.nome)) return;
    if (!context.mounted) return;
    final erro = await context.read<ClienteViewModel>().excluir(cliente);
    if (!context.mounted) return;
    mostrarMensagem(context, erro ?? 'Cliente excluído.', erro: erro != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ClienteViewModel>(
        builder: (context, vm, child) {
          final clientes = vm.clientes;
          return ListaComEstado(
            carregando: vm.carregando,
            erro: vm.erro,
            semRegistros: vm.vazio,
            quantidade: clientes.length,
            textoVazio:
                'Nenhum cliente cadastrado.\nToque em + para adicionar.',
            dicaBusca: 'Buscar por nome ou CPF',
            onBuscar: vm.filtrar,
            onAtualizar: vm.carregar,
            itemBuilder: (context, index) {
              final c = clientes[index];
              // Sem id (não veio nos links da API) não há como editar/excluir.
              final temId = c.id != null;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(c.nome.isEmpty ? '?' : c.nome[0].toUpperCase()),
                  ),
                  title: Text(c.nome),
                  subtitle: Text(
                    'CPF: ${Formatadores.cpf(c.cpf)}\n'
                    '${c.telefone} • ${c.email}',
                  ),
                  isThreeLine: true,
                  onTap: temId ? () => _abrir(context, c) : null,
                  trailing: IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: temId ? () => _excluir(context, c) : null,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_cliente',
        tooltip: 'Novo cliente',
        onPressed: () => _abrir(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
