import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../utils/formatadores.dart';
import '../../utils/validadores.dart';
import '../../viewmodels/cliente_viewmodel.dart';
import '../widgets/dialogos.dart';
import '../widgets/endereco_campos.dart';

/// Formulário de cadastro e edição de cliente (pessoa física).
class ClienteFormPage extends StatefulWidget {
  final Cliente? cliente;

  const ClienteFormPage({super.key, this.cliente});

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _endereco = EnderecoControllers();

  bool get _editando => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    if (c != null) {
      _nome.text = c.nome;
      _cpf.text = Formatadores.somenteDigitos(c.cpf);
      _email.text = c.email;
      _telefone.text = c.telefone;
      _endereco.preencher(c.endereco);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _email.dispose();
    _telefone.dispose();
    _endereco.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final cliente = Cliente(
      id: widget.cliente?.id,
      nome: _nome.text.trim(),
      cpf: Formatadores.somenteDigitos(_cpf.text),
      email: _email.text.trim(),
      telefone: _telefone.text.trim(),
      endereco: _endereco.paraEndereco(),
    );

    final erro = await context.read<ClienteViewModel>().salvar(cliente);
    if (!mounted) return;
    if (erro != null) {
      mostrarMensagem(context, erro, erro: true);
      return;
    }
    mostrarMensagem(
        context, _editando ? 'Cliente atualizado.' : 'Cliente cadastrado.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final salvando = context.watch<ClienteViewModel>().salvando;

    return Scaffold(
      appBar:
          AppBar(title: Text(_editando ? 'Editar cliente' : 'Novo cliente')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(
                  labelText: 'Nome completo *', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  Validadores.obrigatorio(v, campo: 'Nome', max: 50),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cpf,
              decoration: const InputDecoration(
                labelText: 'CPF *',
                hintText: 'Somente números (11 dígitos)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: Validadores.cpf,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                  labelText: 'E-mail *', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => Validadores.email(v, max: 50),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefone,
              decoration: const InputDecoration(
                labelText: 'Telefone *',
                hintText: '(64) 99999-9999',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              validator: Validadores.telefone,
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
