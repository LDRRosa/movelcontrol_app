import 'package:flutter/material.dart';

/// Pede confirmação antes de excluir. Retorna true se o usuário confirmar.
Future<bool> confirmarExclusao(BuildContext context, String descricao) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar exclusão'),
      content: Text('Deseja realmente excluir "$descricao"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return resposta ?? false;
}

void mostrarMensagem(BuildContext context, String texto, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: erro ? Theme.of(context).colorScheme.error : null,
    ));
}
