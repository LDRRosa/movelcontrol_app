import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/cliente_viewmodel.dart';
import 'viewmodels/fornecedor_viewmodel.dart';
import 'viewmodels/item_viewmodel.dart';
import 'views/home_page.dart';

void main() {
  runApp(
    // Os ViewModels ficam acima do MaterialApp para que todas as telas
    // (abas e formulários abertos com Navigator) acessem o mesmo estado.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ItemViewModel()..carregar()),
        ChangeNotifierProvider(
            create: (_) => FornecedorViewModel()..carregar()),
        ChangeNotifierProvider(create: (_) => ClienteViewModel()..carregar()),
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
      home: const HomePage(),
    );
  }
}
