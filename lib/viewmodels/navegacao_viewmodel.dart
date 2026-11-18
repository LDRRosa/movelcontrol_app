import 'package:flutter/foundation.dart';

/// Destinos da NavigationBar inferior.
enum Destino { inicio, orcamentos, cadastros }

/// Abas dentro de "Cadastros".
enum AbaCadastro { itens, clientes, fornecedores }

/// Estado da navegação principal. Fica num ViewModel para que qualquer tela
/// (ex.: um card do painel) consiga trocar de destino ou de aba.
class NavegacaoViewModel extends ChangeNotifier {
  Destino _destino = Destino.inicio;
  AbaCadastro _abaCadastro = AbaCadastro.itens;

  Destino get destino => _destino;
  AbaCadastro get abaCadastro => _abaCadastro;

  void irPara(Destino destino) {
    if (_destino == destino) return;
    _destino = destino;
    notifyListeners();
  }

  void abrirCadastro(AbaCadastro aba) {
    _destino = Destino.cadastros;
    _abaCadastro = aba;
    notifyListeners();
  }

  /// Chamado quando o usuário troca de aba deslizando ou tocando na TabBar.
  void abaCadastroAlterada(AbaCadastro aba) {
    if (_abaCadastro == aba) return;
    _abaCadastro = aba;
    notifyListeners();
  }
}
