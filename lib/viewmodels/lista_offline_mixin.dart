import 'package:flutter/foundation.dart';

import '../repositories/repositorio_com_cache.dart';
import '../utils/formatadores.dart';

/// Comportamentos comuns aos ViewModels de listagem:
///
/// - **Modo offline**: guarda se a última carga veio do cache local e quando
///   esse cache foi salvo, para a View exibir um aviso.
/// - **Excluir com desfazer**: registros "ocultos" somem da lista na hora
///   (o Dismissible exige isso) e podem voltar se o usuário tocar em Desfazer;
///   só depois do prazo a exclusão é enviada à API.
mixin ListaOffline on ChangeNotifier {
  bool _offline = false;
  DateTime? _atualizadoEm;
  final Set<int> _ocultos = {};

  bool get offline => _offline;
  DateTime? get atualizadoEm => _atualizadoEm;

  String? get avisoOffline => _offline
      ? 'Sem conexão com a API. Exibindo os dados salvos em '
          '${Formatadores.dataHora(_atualizadoEm)}.'
      : null;

  /// Chamado pelo ViewModel depois de cada carga.
  @protected
  void registrarOrigem(ResultadoLista<dynamic> resultado) {
    _offline = resultado.doCache;
    _atualizadoEm = resultado.atualizadoEm;
  }

  @protected
  bool estaOculto(int? id) => id != null && _ocultos.contains(id);

  void ocultar(int id) {
    _ocultos.add(id);
    notifyListeners();
  }

  void reexibir(int id) {
    if (_ocultos.remove(id)) notifyListeners();
  }
}
