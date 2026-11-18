import 'package:flutter/material.dart';

import 'cliente/cliente_list_view.dart';
import 'fornecedor/fornecedor_list_view.dart';
import 'item/item_list_view.dart';

/// Tela principal com navegação por abas (DefaultTabController + TabBar +
/// TabBarView). Cada aba é uma View ligada ao seu ViewModel via Provider.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MovelControl'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Itens'),
              Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Fornecedores'),
              Tab(icon: Icon(Icons.people_outline), text: 'Clientes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ItemListView(),
            FornecedorListView(),
            ClienteListView(),
          ],
        ),
      ),
    );
  }
}
