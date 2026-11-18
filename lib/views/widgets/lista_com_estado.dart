import 'package:flutter/material.dart';

/// Monta o corpo de uma aba de listagem a partir do estado do ViewModel:
/// carregando, erro, lista vazia ou a lista em si (com busca e
/// "puxar para atualizar").
class ListaComEstado extends StatelessWidget {
  final bool carregando;
  final String? erro;
  final bool semRegistros;
  final int quantidade;
  final String textoVazio;
  final String dicaBusca;
  final ValueChanged<String> onBuscar;
  final Future<void> Function() onAtualizar;
  final IndexedWidgetBuilder itemBuilder;

  const ListaComEstado({
    super.key,
    required this.carregando,
    required this.erro,
    required this.semRegistros,
    required this.quantidade,
    required this.textoVazio,
    required this.dicaBusca,
    required this.onBuscar,
    required this.onAtualizar,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (carregando && semRegistros) {
      return const Center(child: CircularProgressIndicator());
    }

    if (erro != null && semRegistros) {
      return _Mensagem(
        icone: Icons.cloud_off,
        texto: erro!,
        acao: FilledButton.icon(
          onPressed: onAtualizar,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: dicaBusca,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: onBuscar,
          ),
        ),
        if (carregando) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onAtualizar,
            child: quantidade == 0
                // ListView mesmo vazio para o "puxar para atualizar" funcionar.
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      _Mensagem(
                        icone: Icons.inbox_outlined,
                        texto: semRegistros
                            ? textoVazio
                            : 'Nenhum resultado para a busca.',
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: quantidade,
                    itemBuilder: itemBuilder,
                  ),
          ),
        ),
      ],
    );
  }
}

class _Mensagem extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Widget? acao;

  const _Mensagem({required this.icone, required this.texto, this.acao});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
            if (acao != null) ...[const SizedBox(height: 16), acao!],
          ],
        ),
      ),
    );
  }
}
