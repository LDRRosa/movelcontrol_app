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

  /// Conteúdo opcional exibido entre a busca e a lista (ex.: filtros).
  final Widget? cabecalho;

  /// Botão exibido ao lado da busca (ex.: menu de ordenação).
  final Widget? acaoBusca;

  /// Aviso de modo offline (dados vindos do cache local).
  final String? avisoOffline;

  const ListaComEstado({
    this.cabecalho,
    this.acaoBusca,
    this.avisoOffline,
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
        if (avisoOffline != null) AvisoOffline(texto: avisoOffline!),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
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
              if (acaoBusca != null) acaoBusca!,
            ],
          ),
        ),
        if (cabecalho != null) cabecalho!,
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

/// Faixa avisando que os dados exibidos vieram do cache local (sem conexão).
class AvisoOffline extends StatelessWidget {
  final String texto;

  const AvisoOffline({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Material(
      color: tema.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off,
                size: 18, color: tema.colorScheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(texto,
                  style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onTertiaryContainer)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão de ordenação genérico (usado ao lado da busca nas listas).
class MenuOrdenacao<T> extends StatelessWidget {
  final T selecionada;
  final List<T> opcoes;
  final String Function(T) rotulo;
  final ValueChanged<T> onSelecionar;

  const MenuOrdenacao({
    super.key,
    required this.selecionada,
    required this.opcoes,
    required this.rotulo,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: 'Ordenar',
      icon: const Icon(Icons.sort),
      initialValue: selecionada,
      onSelected: onSelecionar,
      itemBuilder: (_) => [
        for (final opcao in opcoes)
          CheckedPopupMenuItem<T>(
            value: opcao,
            checked: opcao == selecionada,
            child: Text(rotulo(opcao)),
          ),
      ],
    );
  }
}
