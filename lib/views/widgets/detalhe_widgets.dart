import 'package:flutter/material.dart';

import '../../models/endereco.dart';
import '../../utils/formatadores.dart';

/// Título de seção usado nas telas de detalhe e no painel.
class SecaoTitulo extends StatelessWidget {
  final String titulo;
  final Widget? acao;

  const SecaoTitulo(this.titulo, {super.key, this.acao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(titulo,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

/// Linha "ícone + rótulo + valor".
class LinhaInfo extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;

  const LinhaInfo(
      {super.key,
      required this.icone,
      required this.rotulo,
      required this.valor});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(icone, color: tema.colorScheme.primary),
      title: Text(rotulo, style: tema.textTheme.bodySmall),
      subtitle: Text(valor.isEmpty ? '—' : valor,
          style: tema.textTheme.bodyLarge),
    );
  }
}

/// Bloco com o endereço formatado.
class CartaoEndereco extends StatelessWidget {
  final Endereco? endereco;

  const CartaoEndereco({super.key, required this.endereco});

  @override
  Widget build(BuildContext context) {
    final e = endereco;
    return Card(
      child: e == null
          ? const ListTile(
              leading: Icon(Icons.location_off_outlined),
              title: Text('Endereço não informado'),
            )
          : LinhaInfo(
              icone: Icons.location_on_outlined,
              rotulo: 'CEP ${Formatadores.cep(e.cep)}',
              valor: [
                '${e.rua}, ${e.numero}',
                if ((e.complemento ?? '').isNotEmpty) e.complemento!,
                e.bairro,
              ].join(' - '),
            ),
    );
  }
}

/// Pequeno indicador numérico (ex.: "3 orçamentos").
class Indicador extends StatelessWidget {
  final String valor;
  final String rotulo;
  final Color? cor;

  const Indicador(
      {super.key, required this.valor, required this.rotulo, this.cor});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              FittedBox(
                child: Text(valor,
                    style: tema.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cor ?? tema.colorScheme.primary)),
              ),
              const SizedBox(height: 2),
              Text(rotulo,
                  style: tema.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
