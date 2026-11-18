import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../models/item.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/cliente_viewmodel.dart';
import '../../viewmodels/item_viewmodel.dart';

/// Abre uma lista pesquisável de clientes e devolve o escolhido.
Future<Cliente?> selecionarCliente(BuildContext context) {
  return showModalBottomSheet<Cliente>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ListaSelecao<Cliente>(
      titulo: 'Selecionar cliente',
      dicaBusca: 'Buscar por nome ou CPF',
      carregar: () {
        final vm = context.read<ClienteViewModel>();
        if (vm.vazio && !vm.carregando) vm.carregar();
      },
      lerLista: (ctx) {
        final vm = ctx.watch<ClienteViewModel>();
        // Sem id não dá para vincular ao orçamento.
        return (vm.todos.where((c) => c.id != null).toList(), vm.carregando);
      },
      combina: (c, termo) =>
          c.nome.toLowerCase().contains(termo) || c.cpf.contains(termo),
      construirItem: (ctx, c) => ListTile(
        leading: CircleAvatar(
            child: Text(c.nome.isEmpty ? '?' : c.nome[0].toUpperCase())),
        title: Text(c.nome),
        subtitle: Text('CPF: ${Formatadores.cpf(c.cpf)}'),
      ),
      textoVazio: 'Nenhum cliente cadastrado.\nCadastre na aba Clientes.',
    ),
  );
}

/// Abre uma lista pesquisável de itens do estoque e devolve o escolhido.
Future<Item?> selecionarItem(BuildContext context) {
  return showModalBottomSheet<Item>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ListaSelecao<Item>(
      titulo: 'Adicionar item',
      dicaBusca: 'Buscar por nome ou descrição',
      carregar: () {
        final vm = context.read<ItemViewModel>();
        if (vm.vazio && !vm.carregando) vm.carregar();
      },
      lerLista: (ctx) {
        final vm = ctx.watch<ItemViewModel>();
        return (vm.todos, vm.carregando);
      },
      combina: (i, termo) =>
          i.nome.toLowerCase().contains(termo) ||
          i.descricao.toLowerCase().contains(termo),
      construirItem: (ctx, i) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Text(i.nome),
        subtitle: Text('${i.descricao}\nEstoque: ${i.quantidadeEstoque} ${i.unidadeMedida}'),
        isThreeLine: true,
        trailing: Text(Formatadores.moeda(i.precoUnitario),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      textoVazio: 'Nenhum item no estoque.\nCadastre na aba Itens.',
    ),
  );
}

/// Bottom sheet genérico: busca local + lista + retorno do item tocado.
class _ListaSelecao<T> extends StatefulWidget {
  final String titulo;
  final String dicaBusca;
  final String textoVazio;
  final VoidCallback carregar;
  final (List<T>, bool) Function(BuildContext) lerLista;
  final bool Function(T, String) combina;
  final Widget Function(BuildContext, T) construirItem;

  const _ListaSelecao({
    required this.titulo,
    required this.dicaBusca,
    required this.textoVazio,
    required this.carregar,
    required this.lerLista,
    required this.combina,
    required this.construirItem,
  });

  @override
  State<_ListaSelecao<T>> createState() => _ListaSelecaoState<T>();
}

class _ListaSelecaoState<T> extends State<_ListaSelecao<T>> {
  String _termo = '';

  @override
  void initState() {
    super.initState();
    // Garante os dados mesmo que a aba correspondente nunca tenha sido aberta.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.carregar());
  }

  @override
  Widget build(BuildContext context) {
    final (lista, carregando) = widget.lerLista(context);
    final filtrada = _termo.isEmpty
        ? lista
        : lista.where((e) => widget.combina(e, _termo)).toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Text(widget.titulo, style: Theme.of(context).textTheme.titleLarge),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: widget.dicaBusca,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _termo = v.trim().toLowerCase()),
            ),
          ),
          if (carregando) const LinearProgressIndicator(),
          Expanded(
            child: filtrada.isEmpty
                ? Center(
                    child: Text(
                      lista.isEmpty && !carregando
                          ? widget.textoVazio
                          : 'Nenhum resultado.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: filtrada.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) => InkWell(
                      onTap: () => Navigator.pop(context, filtrada[i]),
                      child: widget.construirItem(ctx, filtrada[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
