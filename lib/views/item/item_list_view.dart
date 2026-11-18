import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/item_viewmodel.dart';
import '../widgets/dialogos.dart';
import '../widgets/lista_com_estado.dart';
import 'item_form_page.dart';

/// Aba "Itens": lista o estoque e dispara as ações do CRUD.
class ItemListView extends StatelessWidget {
  const ItemListView({super.key});

  void _abrirFormulario(BuildContext context, [Item? item]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemFormPage(item: item)),
    );
  }

  String _sigla(String unidade) {
    if (unidade.isEmpty) return '?';
    return unidade.length > 3 ? unidade.substring(0, 3) : unidade;
  }

  Future<void> _excluir(BuildContext context, Item item) async {
    if (!await confirmarExclusao(context, item.nome)) return;
    if (!context.mounted) return;
    final erro = await context.read<ItemViewModel>().excluir(item);
    if (!context.mounted) return;
    mostrarMensagem(context, erro ?? 'Item excluído.', erro: erro != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ItemViewModel>(
        builder: (context, vm, child) {
          final itens = vm.itens;
          return ListaComEstado(
            carregando: vm.carregando,
            erro: vm.erro,
            semRegistros: vm.vazio,
            quantidade: itens.length,
            textoVazio: 'Nenhum item cadastrado.\nToque em + para adicionar.',
            dicaBusca: 'Buscar por nome ou descrição',
            onBuscar: vm.filtrar,
            onAtualizar: vm.carregar,
            itemBuilder: (context, index) {
              final item = itens[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(child: Text(_sigla(item.unidadeMedida))),
                  title: Text(item.nome),
                  subtitle: Text(
                    '${item.descricao}\n'
                    '${Formatadores.moeda(item.precoUnitario)} • '
                    'Estoque: ${item.quantidadeEstoque}',
                  ),
                  isThreeLine: true,
                  onTap: () => _abrirFormulario(context, item),
                  trailing: IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _excluir(context, item),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_item',
        tooltip: 'Novo item',
        onPressed: () => _abrirFormulario(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
