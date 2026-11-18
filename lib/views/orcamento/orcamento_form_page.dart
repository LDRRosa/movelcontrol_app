import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/orcamento.dart';
import '../../utils/formatadores.dart';
import '../../viewmodels/cliente_viewmodel.dart';
import '../../viewmodels/item_viewmodel.dart';
import '../../viewmodels/orcamento_form_viewmodel.dart';
import '../../viewmodels/orcamento_viewmodel.dart';
import '../widgets/dialogos.dart';
import 'seletores.dart';

/// Formulário de criação/edição de orçamento.
/// O rascunho vive no OrcamentoFormViewModel (criado na rota) e a gravação
/// é feita pelo OrcamentoViewModel (global).
class OrcamentoFormPage extends StatefulWidget {
  const OrcamentoFormPage({super.key});

  @override
  State<OrcamentoFormPage> createState() => _OrcamentoFormPageState();
}

class _OrcamentoFormPageState extends State<OrcamentoFormPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Carrega clientes e itens caso as abas ainda não tenham sido abertas
    // (o estoque é usado para avisar quando a quantidade passa do disponível).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itens = context.read<ItemViewModel>();
      final clientes = context.read<ClienteViewModel>();
      if (itens.vazio && !itens.carregando) itens.carregar();
      if (clientes.vazio && !clientes.carregando) clientes.carregar();
    });
  }

  Future<void> _escolherCliente(FormFieldState<int> campo) async {
    final cliente = await selecionarCliente(context);
    if (cliente == null || !mounted) return;
    context.read<OrcamentoFormViewModel>().selecionarCliente(cliente);
    campo.didChange(cliente.id);
  }

  Future<void> _adicionarItem(FormFieldState<int> campo) async {
    final item = await selecionarItem(context);
    if (item == null || !mounted) return;
    final vm = context.read<OrcamentoFormViewModel>();
    vm.adicionarItem(item);
    campo.didChange(vm.linhas.length);
  }

  Future<void> _digitarQuantidade(ItemOrcamento linha) async {
    final controller = TextEditingController(text: '${linha.quantidade}');
    final valor = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(linha.nome),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
              labelText: 'Quantidade', border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, int.tryParse(controller.text)),
              child: const Text('OK')),
        ],
      ),
    );
    // O controller não é descartado aqui: a animação de fechamento do diálogo
    // ainda usa o TextField por alguns milissegundos.
    if (valor == null || !mounted) return;
    if (valor < 1) {
      mostrarMensagem(context, 'A quantidade mínima é 1.', erro: true);
      return;
    }
    context.read<OrcamentoFormViewModel>().alterarQuantidade(linha.itemId, valor);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final form = context.read<OrcamentoFormViewModel>();
    final erro =
        await context.read<OrcamentoViewModel>().salvar(form.montarOrcamento());
    if (!mounted) return;
    if (erro != null) {
      mostrarMensagem(context, erro, erro: true);
      return;
    }
    mostrarMensagem(
        context, form.editando ? 'Orçamento atualizado.' : 'Orçamento criado.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrcamentoFormViewModel>();
    final salvando = context.watch<OrcamentoViewModel>().salvando;
    final estoque = context.watch<ItemViewModel>();
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.editando ? 'Orçamento #${vm.id}' : 'Novo orçamento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ---------- Cliente ----------
            FormField<int>(
              initialValue: vm.clienteId,
              validator: (_) => vm.validarCliente(),
              builder: (campo) => InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => _escolherCliente(campo),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Cliente *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    errorText: campo.errorText,
                  ),
                  child: Text(
                    vm.clienteNome ?? 'Toque para selecionar',
                    style: vm.clienteNome == null
                        ? TextStyle(color: tema.hintColor)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------- Status ----------
            Text('Status', style: tema.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final s in StatusOrcamento.values)
                  ChoiceChip(
                    label: Text(s.rotulo),
                    selected: vm.status == s,
                    onSelected: (_) => vm.alterarStatus(s),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ---------- Itens ----------
            FormField<int>(
              initialValue: vm.linhas.length,
              validator: (_) => vm.validarItens(),
              builder: (campo) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Itens (${vm.linhas.length})',
                            style: tema.textTheme.titleSmall),
                      ),
                      TextButton.icon(
                        onPressed: () => _adicionarItem(campo),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Adicionar item'),
                      ),
                    ],
                  ),
                  if (vm.linhas.isEmpty)
                    _ItensVazio(
                      erro: campo.errorText,
                      onAdicionar: () => _adicionarItem(campo),
                    )
                  else
                    for (final linha in vm.linhas)
                      _LinhaItem(
                        linha: linha,
                        estoque: estoque
                            .buscarPorId(linha.itemId)
                            ?.quantidadeEstoque,
                        onMenos: () => vm.alterarQuantidade(
                            linha.itemId, linha.quantidade - 1),
                        onMais: () => vm.alterarQuantidade(
                            linha.itemId, linha.quantidade + 1),
                        onDigitar: () => _digitarQuantidade(linha),
                        onRemover: () {
                          vm.removerItem(linha.itemId);
                          campo.didChange(vm.linhas.length);
                        },
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BarraTotal(
        total: vm.total,
        quantidade: vm.quantidadeTotal,
        salvando: salvando,
        onSalvar: _salvar,
      ),
    );
  }
}

class _ItensVazio extends StatelessWidget {
  final String? erro;
  final VoidCallback onAdicionar;

  const _ItensVazio({required this.erro, required this.onAdicionar});

  @override
  Widget build(BuildContext context) {
    final cor = erro != null
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.outline;
    return InkWell(
      onTap: onAdicionar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: cor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.shopping_cart_outlined, color: cor, size: 36),
            const SizedBox(height: 8),
            Text(erro ?? 'Nenhum item adicionado',
                style: TextStyle(color: cor), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LinhaItem extends StatelessWidget {
  final ItemOrcamento linha;
  final int? estoque;
  final VoidCallback onMenos;
  final VoidCallback onMais;
  final VoidCallback onDigitar;
  final VoidCallback onRemover;

  const _LinhaItem({
    required this.linha,
    required this.estoque,
    required this.onMenos,
    required this.onMais,
    required this.onDigitar,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final acimaDoEstoque = estoque != null && linha.quantidade > estoque!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(linha.nome, style: tema.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Remover item',
                  icon: const Icon(Icons.close),
                  onPressed: onRemover,
                ),
              ],
            ),
            Row(
              children: [
                Text('${Formatadores.moeda(linha.precoUnitario)} / unid.',
                    style: tema.textTheme.bodySmall),
                const Spacer(),
                IconButton.outlined(
                  tooltip: 'Diminuir',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: linha.quantidade > 1 ? onMenos : null,
                  icon: const Icon(Icons.remove),
                ),
                InkWell(
                  onTap: onDigitar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${linha.quantidade}',
                        style: tema.textTheme.titleMedium),
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Aumentar',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: onMais,
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(width: 8),
              ],
            ),
            Row(
              children: [
                if (acimaDoEstoque)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 16, color: Colors.orange.shade800),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Acima do estoque ($estoque disponível)',
                            style: TextStyle(
                                color: Colors.orange.shade800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    'Subtotal: ${Formatadores.moeda(linha.subtotal)}',
                    style: tema.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Rodapé fixo com o total em tempo real e o botão de salvar.
class _BarraTotal extends StatelessWidget {
  final double total;
  final int quantidade;
  final bool salvando;
  final VoidCallback onSalvar;

  const _BarraTotal({
    required this.total,
    required this.quantidade,
    required this.salvando,
    required this.onSalvar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Material(
      elevation: 8,
      color: tema.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total ($quantidade unid.)',
                        style: tema.textTheme.bodySmall),
                    Text(
                      Formatadores.moeda(total),
                      style: tema.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tema.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: salvando ? null : onSalvar,
                icon: salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(salvando ? 'Salvando...' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
