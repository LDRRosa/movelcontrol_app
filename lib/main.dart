import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'rotas.dart';
import 'services/sqflite_inicializacao.dart';
import 'viewmodels/cliente_viewmodel.dart';
import 'viewmodels/configuracoes_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/fornecedor_viewmodel.dart';
import 'viewmodels/item_viewmodel.dart';
import 'viewmodels/navegacao_viewmodel.dart';
import 'viewmodels/orcamento_viewmodel.dart';

Future<void> main() async {
  // Necessário antes de usar plugins (shared_preferences, sqflite) no main.
  WidgetsFlutterBinding.ensureInitialized();
  inicializarSqflite(); // sqflite via FFI no Windows/Linux

  // Lê as preferências salvas ANTES de abrir o app: assim o tema e a URL da
  // API já estão definidos quando as listas fizerem a primeira requisição.
  final configuracoes = ConfiguracoesViewModel();
  await configuracoes.carregar();

  runApp(
    // Os ViewModels ficam acima do MaterialApp para que todas as telas
    // (destinos e rotas abertas com Navigator) acessem o mesmo estado.
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: configuracoes),
        ChangeNotifierProvider(create: (_) => NavegacaoViewModel()),
        ChangeNotifierProvider(
            create: (_) =>
                ItemViewModel(estoqueMinimo: configuracoes.estoqueMinimo)
                  ..carregar()),
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

  static const _corBase = Colors.brown;

  @override
  Widget build(BuildContext context) {
    // O MaterialApp "ouve" o tema escolhido nas Configurações (Aula 13).
    final tema = context.select<ConfiguracoesViewModel, ThemeMode>(
        (config) => config.tema);

    return MaterialApp(
      title: 'MovelControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _corBase),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: _corBase, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: tema,
      // Rotas nomeadas centralizadas em rotas.dart (ex.: /orcamentos/7).
      initialRoute: Rotas.inicio,
      onGenerateRoute: Rotas.gerar,
    );
  }
}
