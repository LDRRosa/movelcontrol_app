import 'package:flutter/material.dart';

import '../../utils/mascaras.dart';
import '../../utils/validadores.dart';
import '../../viewmodels/endereco_form_viewmodel.dart';

/// Campos de endereço com máscara de CEP, busca automática no ViaCEP e
/// validação (limites conforme a tabela "endereco" da API).
///
/// Usa ListenableBuilder (Aula 10) para reagir ao EnderecoFormViewModel
/// enquanto o CEP é consultado.
class EnderecoCampos extends StatelessWidget {
  final EnderecoFormViewModel endereco;

  const EnderecoCampos({super.key, required this.endereco});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Endereço', style: tema.textTheme.titleMedium),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: endereco,
          builder: (context, _) => TextFormField(
            controller: endereco.cep,
            decoration: InputDecoration(
              labelText: 'CEP *',
              hintText: '00000-000',
              helperText: endereco.cidadeUf ??
                  'Rua e bairro são preenchidos automaticamente',
              errorText: endereco.erroCep,
              border: const OutlineInputBorder(),
              suffixIcon: endereco.buscando
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Buscar CEP',
                      icon: const Icon(Icons.search),
                      onPressed: endereco.buscarCep,
                    ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [Mascaras.cep],
            validator: Validadores.cep,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: endereco.rua,
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
                controller: endereco.numero,
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
                controller: endereco.complemento,
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
          controller: endereco.bairro,
          decoration: const InputDecoration(
              labelText: 'Bairro *', border: OutlineInputBorder()),
          validator: (v) =>
              Validadores.obrigatorio(v, campo: 'Bairro', max: 100),
        ),
      ],
    );
  }
}
