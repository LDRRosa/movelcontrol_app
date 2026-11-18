import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../utils/formatadores.dart';
import '../../utils/mascaras.dart';
import '../../utils/validadores.dart';
import '../../viewmodels/item_viewmodel.dart';
import '../widgets/dialogos.dart';

/// Formulário de cadastro (item == null) e edição de item.
class ItemFormPage extends StatefulWidget {
  final Item? item;

  const ItemFormPage({super.key, this.item});

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _unidade = TextEditingController();
  final _preco = TextEditingController();
  final _quantidade = TextEditingController();

  bool get _editando => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _nome.text = item.nome;
      _descricao.text = item.descricao;
      _unidade.text = item.unidadeMedida;
      _preco.text = Formatadores.moedaSemSimbolo(item.precoUnitario);
      _quantidade.text = item.quantidadeEstoque.toString();
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _unidade.dispose();
    _preco.dispose();
    _quantidade.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final item = Item(
      id: widget.item?.id,
      nome: _nome.text.trim(),
      descricao: _descricao.text.trim(),
      unidadeMedida: _unidade.text.trim().toUpperCase(),
      precoUnitario: Formatadores.parseMoeda(_preco.text)!,
      quantidadeEstoque: int.parse(_quantidade.text.trim()),
    );

    final erro = await context.read<ItemViewModel>().salvar(item);
    if (!mounted) return;
    if (erro != null) {
      mostrarMensagem(context, erro, erro: true);
      return;
    }
    mostrarMensagem(context, _editando ? 'Item atualizado.' : 'Item cadastrado.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final salvando = context.watch<ItemViewModel>().salvando;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar item' : 'Novo item')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(
                  labelText: 'Nome *', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  Validadores.obrigatorio(v, campo: 'Nome', max: 100),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricao,
              decoration: const InputDecoration(
                  labelText: 'Descrição *', border: OutlineInputBorder()),
              maxLines: 2,
              validator: (v) =>
                  Validadores.obrigatorio(v, campo: 'Descrição', max: 150),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unidade,
              decoration: const InputDecoration(
                labelText: 'Unidade de medida *',
                hintText: 'Ex.: UN, M, M2, KG, CX',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  Validadores.obrigatorio(v, campo: 'Unidade', max: 10),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _preco,
                    decoration: const InputDecoration(
                      labelText: 'Preço unitário *',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      Mascaras.moeda, // digita-se pelos centavos: 1250 -> 12,50
                    ],
                    validator: Validadores.precoPositivo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantidade,
                    decoration: const InputDecoration(
                      labelText: 'Qtd. em estoque *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        Validadores.inteiroNaoNegativo(v, campo: 'Quantidade'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: salvando ? null : _salvar,
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
    );
  }
}
