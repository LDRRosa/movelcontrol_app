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

/// Fluxo de "excluir com desfazer" usado ao arrastar um card:
/// 1. [ocultar] tira o registro da lista na hora;
/// 2. aparece a mensagem com o botão Desfazer por alguns segundos;
/// 3. se o usuário desfizer, [reexibir] devolve o registro à lista;
///    senão, [excluir] apaga na API (e, se a API recusar, o registro volta).
///
/// Não depende do fechamento do SnackBar (que pode não fechar sozinho
/// quando tem ação, por acessibilidade): o prazo é controlado aqui.
Future<void> excluirComDesfazer({
  required BuildContext context,
  required String descricao,
  required VoidCallback ocultar,
  required VoidCallback reexibir,
  required Future<String?> Function() excluir,
  Duration prazo = const Duration(seconds: 4),
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final corErro = Theme.of(context).colorScheme.error;
  var desfeito = false;

  ocultar();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$descricao excluído(a).'),
      duration: prazo,
      action: SnackBarAction(
        label: 'Desfazer',
        onPressed: () {
          desfeito = true;
          reexibir();
        },
      ),
    ));

  await Future<void>.delayed(prazo);
  if (desfeito) return;
  messenger.hideCurrentSnackBar();

  final erro = await excluir();
  if (erro != null) {
    reexibir();
    messenger.showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: corErro));
  }
}

/// Fundo vermelho exibido enquanto o card é arrastado para excluir.
class FundoExcluir extends StatelessWidget {
  const FundoExcluir({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: tema.colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Excluir',
              style: TextStyle(
                  color: tema.colorScheme.onError,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(Icons.delete_outline, color: tema.colorScheme.onError),
        ],
      ),
    );
  }
}

void mostrarMensagem(BuildContext context, String texto, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: erro ? Theme.of(context).colorScheme.error : null,
    ));
}
