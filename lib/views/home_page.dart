import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/orcamento.dart';
import '../viewmodels/navegacao_viewmodel.dart';
import '../viewmodels/orcamento_viewmodel.dart';
import 'cadastros_page.dart';
import 'dashboard/dashboard_page.dart';
import 'orcamento/orcamento_list_view.dart';

/// Estrutura principal: NavigationBar inferior com Início, Orçamentos e
/// Cadastros. O destino atual fica no NavegacaoViewModel, então qualquer
/// tela (ex.: um card do painel) pode trocar de destino.
///
/// O IndexedStack mantém as três telas montadas: ao voltar para uma aba, a
/// rolagem e os filtros continuam onde estavam.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavegacaoViewModel>();
    final emAberto = context.select<OrcamentoViewModel, int>(
        (vm) => vm.contarPorStatus(StatusOrcamento.emAndamento));

    return Scaffold(
      body: IndexedStack(
        index: nav.destino.index,
        children: const [
          DashboardPage(),
          OrcamentoListView(),
          CadastrosPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.destino.index,
        onDestinationSelected: (i) => nav.irPara(Destino.values[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Início',
          ),
          NavigationDestination(
            // Selo com a quantidade de orçamentos em aberto.
            icon: Badge(
              isLabelVisible: emAberto > 0,
              label: Text('$emAberto'),
              child: const Icon(Icons.request_quote_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: emAberto > 0,
              label: Text('$emAberto'),
              child: const Icon(Icons.request_quote),
            ),
            label: 'Orçamentos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Cadastros',
          ),
        ],
      ),
    );
  }
}
