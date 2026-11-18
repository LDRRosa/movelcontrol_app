import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/navegacao_viewmodel.dart';
import 'cliente/cliente_list_view.dart';
import 'fornecedor/fornecedor_list_view.dart';
import 'item/item_list_view.dart';

/// Destino "Cadastros": abas de Itens, Clientes e Fornecedores.
///
/// Usa um TabController próprio (em vez de DefaultTabController) para que o
/// NavegacaoViewModel consiga abrir uma aba específica, por exemplo ao tocar
/// em "Estoque baixo" no painel.
class CadastrosPage extends StatefulWidget {
  const CadastrosPage({super.key});

  @override
  State<CadastrosPage> createState() => _CadastrosPageState();
}

class _CadastrosPageState extends State<CadastrosPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    final nav = context.read<NavegacaoViewModel>();
    _tabs = TabController(
      length: AbaCadastro.values.length,
      vsync: this,
      initialIndex: nav.abaCadastro.index,
    );
    // Usuário trocou de aba: informa o ViewModel.
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        nav.abaCadastroAlterada(AbaCadastro.values[_tabs.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ViewModel pediu outra aba: anima até ela depois do frame atual.
    final aba = context.select<NavegacaoViewModel, AbaCadastro>(
        (nav) => nav.abaCadastro);
    if (aba.index != _tabs.index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabs.index != aba.index) _tabs.animateTo(aba.index);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastros'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Itens'),
            Tab(icon: Icon(Icons.people_outline), text: 'Clientes'),
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Fornecedores'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          ItemListView(),
          ClienteListView(),
          FornecedorListView(),
        ],
      ),
    );
  }
}
