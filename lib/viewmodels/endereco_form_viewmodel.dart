import 'package:flutter/material.dart';

import '../models/endereco.dart';
import '../services/api_client.dart';
import '../services/cep_service.dart';
import '../utils/formatadores.dart';

/// Estado do bloco de endereço dos formulários de Cliente e Fornecedor:
/// os campos e a busca automática do CEP no ViaCEP.
///
/// Quando o CEP fica completo (8 dígitos), consulta o ViaCEP e preenche rua
/// e bairro — sem apagar o que o usuário já tiver digitado por conta própria.
class EnderecoFormViewModel extends ChangeNotifier {
  final CepService _cepService;

  final cep = TextEditingController();
  final rua = TextEditingController();
  final numero = TextEditingController();
  final complemento = TextEditingController();
  final bairro = TextEditingController();

  EnderecoFormViewModel({CepService? cepService})
      : _cepService = cepService ?? CepService() {
    cep.addListener(_aoMudarCep);
  }

  bool _buscando = false;
  String? _erroCep;
  String? _cidadeUf;
  String? _ultimoCepConsultado;
  String? _ruaAutomatica;
  String? _bairroAutomatico;
  bool _descartado = false;

  bool get buscando => _buscando;
  String? get erroCep => _erroCep;
  String? get cidadeUf => _cidadeUf;

  void preencher(Endereco? endereco) {
    if (endereco == null) return;
    // Marca o CEP como já consultado para não buscar de novo ao abrir a edição.
    _ultimoCepConsultado = Formatadores.somenteDigitos(endereco.cep);
    cep.text = Formatadores.cep(endereco.cep);
    rua.text = endereco.rua;
    numero.text = endereco.numero;
    complemento.text = endereco.complemento ?? '';
    bairro.text = endereco.bairro;
  }

  void _aoMudarCep() {
    final digitos = Formatadores.somenteDigitos(cep.text);
    if (digitos.length == 8 && digitos != _ultimoCepConsultado) {
      buscarCep();
    } else if (digitos.length < 8 && (_erroCep != null || _cidadeUf != null)) {
      _erroCep = null;
      _cidadeUf = null;
      _ultimoCepConsultado = null;
      notifyListeners();
    }
  }

  Future<void> buscarCep() async {
    final digitos = Formatadores.somenteDigitos(cep.text);
    _ultimoCepConsultado = digitos;
    _buscando = true;
    _erroCep = null;
    notifyListeners();
    try {
      final resultado = await _cepService.buscar(digitos);
      if (_descartado) return;
      if (resultado == null) {
        _erroCep = 'CEP não encontrado';
        _cidadeUf = null;
      } else {
        _cidadeUf = '${resultado.cidade} - ${resultado.uf}';
        // Só substitui campos vazios ou que foram preenchidos pelo ViaCEP.
        if (rua.text.trim().isEmpty || rua.text == _ruaAutomatica) {
          rua.text = resultado.rua;
          _ruaAutomatica = resultado.rua;
        }
        if (bairro.text.trim().isEmpty || bairro.text == _bairroAutomatico) {
          bairro.text = resultado.bairro;
          _bairroAutomatico = resultado.bairro;
        }
      }
    } on ApiException catch (e) {
      if (_descartado) return;
      _erroCep = e.mensagem;
    } finally {
      if (!_descartado) {
        _buscando = false;
        notifyListeners();
      }
    }
  }

  Endereco paraEndereco() => Endereco(
        cep: Formatadores.cep(cep.text),
        rua: rua.text.trim(),
        numero: numero.text.trim(),
        complemento:
            complemento.text.trim().isEmpty ? null : complemento.text.trim(),
        bairro: bairro.text.trim(),
      );

  @override
  void dispose() {
    _descartado = true;
    cep.removeListener(_aoMudarCep);
    cep.dispose();
    rua.dispose();
    numero.dispose();
    complemento.dispose();
    bairro.dispose();
    super.dispose();
  }
}
