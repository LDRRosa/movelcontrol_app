import 'dart:convert';

import '../services/api_client.dart';
import '../services/cache_local_service.dart';

/// Resultado de uma carga: os dados e de onde eles vieram.
class ResultadoLista<T> {
  final List<T> dados;
  final bool doCache;
  final DateTime? atualizadoEm;

  const ResultadoLista(this.dados, {required this.doCache, this.atualizadoEm});
}

/// Repositório que combina a API (fonte principal) com o cache local
/// (Padrão Repositório da Aula 13), usando a estratégia "rede primeiro":
///
/// 1. tenta buscar na API e, se der certo, salva a lista no cache;
/// 2. se não houver conexão, devolve a última lista salva (modo offline).
///
/// Erros respondidos pelo servidor (400, 404, 500...) não são mascarados pelo
/// cache: só a falta de conexão aciona o modo offline.
class RepositorioComCache<T> {
  final String chave;
  final CacheLocal _cache;
  final Map<String, dynamic> Function(T) _paraJson;
  final T Function(Map<String, dynamic>) _deJson;

  RepositorioComCache({
    required this.chave,
    required CacheLocal cache,
    required Map<String, dynamic> Function(T) paraJson,
    required T Function(Map<String, dynamic>) deJson,
  })  : _cache = cache,
        _paraJson = paraJson,
        _deJson = deJson;

  Future<ResultadoLista<T>> carregar(
      Future<List<T>> Function() buscarNaApi) async {
    try {
      final dados = await buscarNaApi();
      await _salvar(dados);
      return ResultadoLista(dados, doCache: false, atualizadoEm: DateTime.now());
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow; // o servidor respondeu com erro
      final salvo = await _ler();
      if (salvo == null) rethrow; // offline e sem nada salvo
      return salvo;
    }
  }

  Future<void> _salvar(List<T> dados) async {
    try {
      await _cache.salvar(chave, jsonEncode(dados.map(_paraJson).toList()));
    } catch (_) {
      // Falha no cache não pode impedir o uso do app com a API.
    }
  }

  Future<ResultadoLista<T>?> _ler() async {
    try {
      final registro = await _cache.ler(chave);
      if (registro == null) return null;
      final lista = (jsonDecode(registro.json) as List)
          .whereType<Map<String, dynamic>>()
          .map(_deJson)
          .toList();
      return ResultadoLista(lista,
          doCache: true, atualizadoEm: registro.atualizadoEm);
    } catch (_) {
      return null;
    }
  }
}
