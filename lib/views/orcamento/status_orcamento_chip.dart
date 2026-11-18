import 'package:flutter/material.dart';

import '../../models/orcamento.dart';

/// Etiqueta colorida com o status do orçamento.
class StatusOrcamentoChip extends StatelessWidget {
  final String status;

  const StatusOrcamentoChip({super.key, required this.status});

  static Color corDe(String status) {
    switch (StatusOrcamento.deValor(status)) {
      case StatusOrcamento.emAndamento:
        return Colors.amber.shade800;
      case StatusOrcamento.aprovado:
        return Colors.green.shade700;
      case StatusOrcamento.recusado:
        return Colors.red.shade700;
      case StatusOrcamento.cancelado:
      case null:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = corDe(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(cor.withAlpha(30), Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor),
      ),
      child: Text(
        StatusOrcamento.rotuloDe(status),
        style: TextStyle(
            color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
