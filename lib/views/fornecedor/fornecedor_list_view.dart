import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/fornecedor.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/cliente_viewmodel.dart' show OrdemNome;
import '../../viewmodels/fornecedor_viewmodel.dart';
import '../widgets/dialogos.dart';
import '../widgets/lista_com_estado.dart';
import '../../rotas.dart';

/// Aba "Fornecedores".
class FornecedorListView extends StatelessWidget {
  const FornecedorListView({super.key});

  /// Fornecedor existente abre o detalhe (com pedidos); sem ele, o cadastro.
  void _abrir(BuildContext context, [Fornecedor? fornecedor]) {
    Navigator.pushNamed(
        context,
        fornecedor == null
            ? Rotas.fornecedorNovo
            : Rotas.fornecedor(fornecedor.id!));
  }

  Future<void> _excluir(BuildContext context, Fornecedor fornecedor) async {
    if (!await confirmarExclusao(context, fornecedor.nome)) return;
    if (!context.mounted) return;
    final erro =
        await context.read<FornecedorViewModel>().excluir(fornecedor);
    if (!context.mounted) return;
    mostrarMensagem(context, erro ?? 'Fornecedor excluído.',
        erro: erro != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FornecedorViewModel>(
        builder: (context, vm, child) {
          final fornecedores = vm.fornecedores;
          return ListaComEstado(
            carregando: vm.carregando,
            erro: vm.erro,
            semRegistros: vm.vazio,
            quantidade: fornecedores.length,
            textoVazio:
                'Nenhum fornecedor cadastrado.\nToque em + para adicionar.',
            dicaBusca: 'Buscar por nome ou CNPJ',
            onBuscar: vm.filtrar,
            onAtualizar: vm.carregar,
            avisoOffline: vm.avisoOffline,
            acaoBusca: MenuOrdenacao<OrdemNome>(
              selecionada: vm.ordem,
              opcoes: OrdemNome.values,
              rotulo: (o) => o.rotulo,
              onSelecionar: vm.ordenarPor,
            ),
            itemBuilder: (context, index) {
              final f = fornecedores[index];
              return Dismissible(
                key: ValueKey('fornecedor-${f.id}'),
                direction: DismissDirection.endToStart,
                background: const FundoExcluir(),
                onDismissed: (_) => excluirComDesfazer(
                  context: context,
                  descricao: f.nome,
                  ocultar: () => vm.ocultar(f.id!),
                  reexibir: () => vm.reexibir(f.id!),
                  excluir: () => vm.excluir(f),
                ),
                child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
                  title: Text(f.nome),
                  subtitle: Text(
                    'CNPJ: ${Formatadores.cnpj(f.cnpj)}\n'
                    '${f.telefone} • ${f.email}',
                  ),
                  isThreeLine: true,
                  onTap: () => _abrir(context, f),
                  trailing: IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _excluir(context, f),
                  ),
                ),
              ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_fornecedor',
        tooltip: 'Novo fornecedor',
        onPressed: () => _abrir(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
