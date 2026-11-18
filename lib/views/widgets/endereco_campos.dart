import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/endereco.dart';
import '../../utils/formatadores.dart';
import '../../utils/validadores.dart';

/// Agrupa os TextEditingControllers do endereço, usados nos formulários
/// de Fornecedor e Cliente.
class EnderecoControllers {
  final cep = TextEditingController();
  final rua = TextEditingController();
  final numero = TextEditingController();
  final complemento = TextEditingController();
  final bairro = TextEditingController();

  void preencher(Endereco? endereco) {
    if (endereco == null) return;
    cep.text = Formatadores.somenteDigitos(endereco.cep);
    rua.text = endereco.rua;
    numero.text = endereco.numero;
    complemento.text = endereco.complemento ?? '';
    bairro.text = endereco.bairro;
  }

  Endereco paraEndereco() => Endereco(
        cep: Formatadores.cep(cep.text),
        rua: rua.text.trim(),
        numero: numero.text.trim(),
        complemento:
            complemento.text.trim().isEmpty ? null : complemento.text.trim(),
        bairro: bairro.text.trim(),
      );

  void dispose() {
    cep.dispose();
    rua.dispose();
    numero.dispose();
    complemento.dispose();
    bairro.dispose();
  }
}

/// Campos de endereço com validação (limites conforme a tabela "endereco").
class EnderecoCampos extends StatelessWidget {
  final EnderecoControllers controllers;

  const EnderecoCampos({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Endereço', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: controllers.cep,
          decoration: const InputDecoration(
            labelText: 'CEP *',
            hintText: 'Somente números',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          validator: Validadores.cep,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controllers.rua,
          decoration: const InputDecoration(
              labelText: 'Rua *', border: OutlineInputBorder()),
          validator: (v) => Validadores.obrigatorio(v, campo: 'Rua', max: 100),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controllers.numero,
                decoration: const InputDecoration(
                    labelText: 'Número *', border: OutlineInputBorder()),
                validator: (v) =>
                    Validadores.obrigatorio(v, campo: 'Número', max: 10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: controllers.complemento,
                decoration: const InputDecoration(
                    labelText: 'Complemento', border: OutlineInputBorder()),
                validator: (v) =>
                    Validadores.opcional(v, campo: 'Complemento', max: 100),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controllers.bairro,
          decoration: const InputDecoration(
              labelText: 'Bairro *', border: OutlineInputBorder()),
          validator: (v) =>
              Validadores.obrigatorio(v, campo: 'Bairro', max: 100),
        ),
      ],
    );
  }
}
