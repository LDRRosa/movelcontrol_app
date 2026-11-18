import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/fornecedor.dart';
import '../../utils/formatadores.dart';
import '../../utils/validadores.dart';
import '../../viewmodels/fornecedor_viewmodel.dart';
import '../widgets/dialogos.dart';
import '../widgets/endereco_campos.dart';

/// Formulário de cadastro e edição de fornecedor.
class FornecedorFormPage extends StatefulWidget {
  final Fornecedor? fornecedor;

  const FornecedorFormPage({super.key, this.fornecedor});

  @override
  State<FornecedorFormPage> createState() => _FornecedorFormPageState();
}

class _FornecedorFormPageState extends State<FornecedorFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cnpj = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _endereco = EnderecoControllers();

  bool get _editando => widget.fornecedor != null;

  @override
  void initState() {
    super.initState();
    final f = widget.fornecedor;
    if (f != null) {
      _nome.text = f.nome;
      _cnpj.text = Formatadores.somenteDigitos(f.cnpj);
      _telefone.text = f.telefone;
      _email.text = f.email;
      _endereco.preencher(f.endereco);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _cnpj.dispose();
    _telefone.dispose();
    _email.dispose();
    _endereco.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final fornecedor = Fornecedor(
      id: widget.fornecedor?.id,
      nome: _nome.text.trim(),
      cnpj: Formatadores.somenteDigitos(_cnpj.text),
      telefone: _telefone.text.trim(),
      email: _email.text.trim(),
      endereco: _endereco.paraEndereco(),
    );

    final erro = await context.read<FornecedorViewModel>().salvar(fornecedor);
    if (!mounted) return;
    if (erro != null) {
      mostrarMensagem(context, erro, erro: true);
      return;
    }
    mostrarMensagem(context,
        _editando ? 'Fornecedor atualizado.' : 'Fornecedor cadastrado.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final salvando = context.watch<FornecedorViewModel>().salvando;

    return Scaffold(
      appBar: AppBar(
          title: Text(_editando ? 'Editar fornecedor' : 'Novo fornecedor')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(
                  labelText: 'Razão social / nome *',
                  border: OutlineInputBorder()),
              validator: (v) =>
                  Validadores.obrigatorio(v, campo: 'Nome', max: 100),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cnpj,
              decoration: const InputDecoration(
                labelText: 'CNPJ *',
                hintText: 'Somente números (14 dígitos)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
              ],
              validator: Validadores.cnpj,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefone,
              decoration: const InputDecoration(
                labelText: 'Telefone *',
                hintText: '(62) 91234-5678',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              validator: Validadores.telefone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                  labelText: 'E-mail *', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => Validadores.email(v, max: 100),
            ),
            const SizedBox(height: 24),
            EnderecoCampos(controllers: _endereco),
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
