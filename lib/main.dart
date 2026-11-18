import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'rotas.dart';
import 'viewmodels/cliente_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/fornecedor_viewmodel.dart';
import 'viewmodels/item_viewmodel.dart';
import 'viewmodels/navegacao_viewmodel.dart';
import 'viewmodels/orcamento_viewmodel.dart';

void main() {
  runApp(
    // Os ViewModels ficam acima do MaterialApp para que todas as telas
    // (destinos e rotas abertas com Navigator) acessem o mesmo estado.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavegacaoViewModel()),
        ChangeNotifierProvider(create: (_) => ItemViewModel()..carregar()),
        ChangeNotifierProvider(
            create: (_) => FornecedorViewModel()..carregar()),
        ChangeNotifierProvider(create: (_) => ClienteViewModel()..carregar()),
        ChangeNotifierProvider(
            create: (_) => OrcamentoViewModel()..carregar()),
        // O painel é derivado dos três ViewModels acima: o ProxyProvider3
        // recalcula os indicadores sempre que algum deles notifica mudança.
        ProxyProvider3<ItemViewModel, ClienteViewModel, OrcamentoViewModel,
            DashboardViewModel>(
          update: (_, itens, clientes, orcamentos, __) =>
              DashboardViewModel.calcular(
            itens: itens,
            clientes: clientes,
            orcamentos: orcamentos,
          ),
        ),
      ],
      child: const MovelControlApp(),
    ),
  );
}

class MovelControlApp extends StatelessWidget {
  const MovelControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovelControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      // Rotas nomeadas centralizadas em rotas.dart (ex.: /orcamentos/7).
      initialRoute: Rotas.inicio,
      onGenerateRoute: Rotas.gerar,
    );
  }
}
