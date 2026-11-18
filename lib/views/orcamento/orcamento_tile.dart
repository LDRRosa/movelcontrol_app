import 'package:flutter/material.dart';

import '../../models/orcamento.dart';
import '../../rotas.dart';
import '../../utils/formatadores.dart';
import 'status_orcamento_chip.dart';

/// Resumo compacto de um orçamento (painel e histórico do cliente).
/// Tocar abre a tela de detalhe.
class OrcamentoTile extends StatelessWidget {
  final Orcamento orcamento;

  /// Mostra o nome do cliente (desnecessário no histórico do próprio cliente).
  final bool mostrarCliente;

  const OrcamentoTile(
      {super.key, required this.orcamento, this.mostrarCliente = true});

  @override
  Widget build(BuildContext context) {
    final o = orcamento;
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: o.id == null
            ? null
            : () => Navigator.pushNamed(context, Rotas.orcamento(o.id!)),
        title: Row(
          children: [
            Text('#${o.id}  '),
            if (mostrarCliente)
              Expanded(
                  child: Text(o.clienteNome, overflow: TextOverflow.ellipsis))
            else
              const Spacer(),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              StatusOrcamentoChip(status: o.status),
              const SizedBox(width: 8),
              Text(Formatadores.data(o.dataCriacao),
                  style: tema.textTheme.bodySmall),
            ],
          ),
        ),
        trailing: Text(Formatadores.moeda(o.valorTotal),
            style: tema.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
