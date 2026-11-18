import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../rotas.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/item_viewmodel.dart';
import '../widgets/dialogos.dart';
import '../widgets/lista_com_estado.dart';

/// Aba "Itens": lista o estoque, destaca o estoque baixo e dispara o CRUD.
class ItemListView extends StatelessWidget {
  const ItemListView({super.key});

  void _abrirFormulario(BuildContext context, [Item? item]) {
    Navigator.pushNamed(
        context, item == null ? Rotas.itemNovo : Rotas.itemEditar(item.id!));
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
    final tema = Theme.of(context);

    return Scaffold(
      body: Consumer<ItemViewModel>(
        builder: (context, vm, child) {
          final itens = vm.itens;
          final qtdBaixo = vm.itensEstoqueBaixo.length;
          return ListaComEstado(
            carregando: vm.carregando,
            erro: vm.erro,
            semRegistros: vm.vazio,
            quantidade: itens.length,
            textoVazio: 'Nenhum item cadastrado.\nToque em + para adicionar.',
            dicaBusca: 'Buscar por nome ou descrição',
            onBuscar: vm.filtrar,
            onAtualizar: vm.carregar,
            cabecalho: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  avatar: Icon(Icons.warning_amber_rounded,
                      color: qtdBaixo > 0 ? tema.colorScheme.error : null),
                  label: Text('Estoque baixo ($qtdBaixo)'),
                  selected: vm.somenteEstoqueBaixo,
                  onSelected: vm.mostrarSomenteEstoqueBaixo,
                ),
              ),
            ),
            itemBuilder: (context, index) {
              final item = itens[index];
              final baixo = ItemViewModel.estaComEstoqueBaixo(item);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                // Alerta visual: fundo e borda avermelhados quando o estoque
                // está abaixo do mínimo.
                color: baixo ? tema.colorScheme.errorContainer : null,
                shape: baixo
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: tema.colorScheme.error),
                      )
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: baixo ? tema.colorScheme.error : null,
                    foregroundColor: baixo ? tema.colorScheme.onError : null,
                    child: baixo
                        ? const Icon(Icons.warning_amber_rounded)
                        : Text(_sigla(item.unidadeMedida)),
                  ),
                  title: Text(item.nome),
                  subtitle: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${item.descricao}\n'),
                      TextSpan(
                          text: '${Formatadores.moeda(item.precoUnitario)} • '),
                      TextSpan(
                        text: baixo
                            ? 'Estoque baixo: ${item.quantidadeEstoque} ${item.unidadeMedida}'
                            : 'Estoque: ${item.quantidadeEstoque} ${item.unidadeMedida}',
                        style: baixo
                            ? TextStyle(
                                color: tema.colorScheme.error,
                                fontWeight: FontWeight.bold)
                            : null,
                      ),
                    ]),
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
